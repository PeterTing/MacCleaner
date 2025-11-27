import Foundation

struct DockerItem: Identifiable {
    let id = UUID()
    let type: ItemType
    let name: String
    let size: Int64
    var isSelected: Bool = true
    
    enum ItemType: String {
        case volume = "Volume"
        case image = "Image"
        case buildCache = "Build Cache"
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

class DockerCleaner: ObservableObject {
    static let shared = DockerCleaner()
    
    enum CleanupLevel: String, CaseIterable, Identifiable {
        case unused = "Remove Unused Images & Build Cache"
        case all = "Stop All Containers & Remove All Images"
        case volumes = "Remove All Volumes (DANGER)"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .unused:
                return "Removes unused images and build cache (safe)"
            case .all:
                return "Stops all containers and removes all images and build cache"
            case .volumes:
                return "⚠️ Also removes all volumes (DATA LOSS RISK)"
            }
        }
        
        var commands: [String] {
            switch self {
            case .unused:
                return [
                    "docker system prune -a -f",
                    "docker builder prune -a -f"
                ]
            case .all:
                return [
                    "docker stop $(docker ps -aq) 2>/dev/null || true",
                    "docker system prune -a -f",
                    "docker builder prune -a -f"
                ]
            case .volumes:
                return [
                    "docker stop $(docker ps -aq) 2>/dev/null || true",
                    "docker system prune -a -f --volumes",
                    "docker builder prune -a -f"
                ]
            }
        }
    }
    
    @Published var isDockerAvailable = false
    @Published var containerCount = 0
    @Published var imageCount = 0
    @Published var items: [DockerItem] = []
    @Published var isScanning = false
    
    func checkDocker() {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = "/usr/bin/env"
            task.arguments = ["docker", "info"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let available = task.terminationStatus == 0
                
                if available {
                    self.fetchDockerStats()
                }
                
                DispatchQueue.main.async {
                    self.isDockerAvailable = available
                }
            } catch {
                DispatchQueue.main.async {
                    self.isDockerAvailable = false
                }
            }
        }
    }
    
    private func fetchDockerStats() {
        // Get container count
        if let containerOutput = runCommand("docker", args: ["ps", "-aq"]) {
            let lines = containerOutput.components(separatedBy: "\n").filter { !$0.isEmpty }
            DispatchQueue.main.async {
                self.containerCount = lines.count
            }
        }
        
        // Get image count
        if let imageOutput = runCommand("docker", args: ["images", "-q"]) {
            let lines = imageOutput.components(separatedBy: "\n").filter { !$0.isEmpty }
            DispatchQueue.main.async {
                self.imageCount = lines.count
            }
        }
    }
    
    func scanItems() {
        DispatchQueue.main.async {
            self.isScanning = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var detectedItems: [DockerItem] = []
            
            // Get volumes with sizes
            if let volumeOutput = self.runCommand("docker", args: ["system", "df", "-v"]) {
                detectedItems.append(contentsOf: self.parseVolumes(volumeOutput))
            }
            
            DispatchQueue.main.async {
                self.items = detectedItems
                self.isScanning = false
            }
        }
    }
    
    private func parseVolumes(_ output: String) -> [DockerItem] {
        var volumes: [DockerItem] = []
        let lines = output.components(separatedBy: "\n")
        
        // Parse the volume section from docker system df -v
        var inVolumeSection = false
        for line in lines {
            if line.contains("VOLUME NAME") {
                inVolumeSection = true
                continue
            }
            if line.contains("Build cache usage:") {
                inVolumeSection = false
            }
            
            if inVolumeSection && !line.isEmpty {
                let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
                if parts.count >= 3 {
                    let volumeName = parts[0]
                    let links = parts[1]
                    let sizeStr = parts[2]
                    
                    // Only include volumes with 0 links (dangling)
                    if links == "0", let size = self.parseSizeString(sizeStr) {
                        volumes.append(DockerItem(
                            type: .volume,
                            name: volumeName,
                            size: size
                        ))
                    }
                }
            }
        }
        
        return volumes
    }
    
    private func parseSizeString(_ sizeStr: String) -> Int64? {
        let str = sizeStr.uppercased()
        var value: Double = 0
        var multiplier: Int64 = 1
        
        if str.hasSuffix("KB") {
            value = Double(str.dropLast(2)) ?? 0
            multiplier = 1024
        } else if str.hasSuffix("MB") {
            value = Double(str.dropLast(2)) ?? 0
            multiplier = 1024 * 1024
        } else if str.hasSuffix("GB") {
            value = Double(str.dropLast(2)) ?? 0
            multiplier = 1024 * 1024 * 1024
        } else if str.hasSuffix("B") {
            value = Double(str.dropLast(1)) ?? 0
            multiplier = 1
        } else {
            return nil
        }
        
        return Int64(value * Double(multiplier))
    }
    
    func cleanSelected(items: [DockerItem], completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var allSucceeded = true
            var output = ""
            
            let selectedVolumes = items.filter { $0.isSelected && $0.type == .volume }
            
            if !selectedVolumes.isEmpty {
                let volumeNames = selectedVolumes.map { $0.name }
                if let result = self.runCommand("docker", args: ["volume", "rm"] + volumeNames) {
                    output += "Removed volumes:\n\(result)\n"
                } else {
                    allSucceeded = false
                    output += "Failed to remove some volumes\n"
                }
            }
            
            // Re-scan after cleanup
            self.scanItems()
            
            DispatchQueue.main.async {
                completion(allSucceeded, output)
            }
        }
    }
    
    func clean(level: CleanupLevel, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var allSucceeded = true
            var output = ""
            
            for command in level.commands {
                let components = command.components(separatedBy: " ")
                guard let cmd = components.first else { continue }
                let args = Array(components.dropFirst())
                
                if let result = self.runCommand(cmd, args: args) {
                    output += result + "\n"
                } else {
                    allSucceeded = false
                }
            }
            
            // Re-fetch stats after cleanup
            self.fetchDockerStats()
            
            DispatchQueue.main.async {
                completion(allSucceeded, output)
            }
        }
    }
    
    private func runCommand(_ command: String, args: [String]) -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = [command] + args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
