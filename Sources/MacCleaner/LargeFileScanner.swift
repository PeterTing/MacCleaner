import Foundation

struct LargeFileItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

class LargeFileScanner: ObservableObject {
    @Published var items: [LargeFileItem] = []
    @Published var isScanning: Bool = false
    
    private let fileManager = FileManager.default
    
    func scan() {
        isScanning = true
        items = []
        
        let pathsToScan = [
            ("Containers", "Library/Containers"),
            ("Application Support", "Library/Application Support")
        ]
        
        DispatchQueue.global(qos: .userInitiated).async {
            var newItems: [LargeFileItem] = []
            let homeDir = self.fileManager.homeDirectoryForCurrentUser
            
            for (category, relativePath) in pathsToScan {
                let fullURL = homeDir.appendingPathComponent(relativePath)
                
                // We want to find the largest subfolders in these directories
                guard let contents = try? self.fileManager.contentsOfDirectory(at: fullURL, includingPropertiesForKeys: [.fileSizeKey], options: []) else {
                    continue
                }
                
                for url in contents {
                    let size = self.getDirectorySize(url: url)
                    // Filter for items larger than 500MB to be relevant
                    if size > 500 * 1024 * 1024 {
                        let itemName = url.lastPathComponent
                        newItems.append(LargeFileItem(name: "\(category)/\(itemName)", path: url.path, size: size))
                    }
                }
            }
            
            // Sort by size descending
            newItems.sort { $0.size > $1.size }
            
            DispatchQueue.main.async {
                self.items = newItems
                self.isScanning = false
            }
        }
    }
    
    private func getDirectorySize(url: URL) -> Int64 {
        // Simple recursive size calculation
        // Note: This can be slow for huge directories. 
        // For a production app, we might want to use specific APIs or limit depth, 
        // but for this tool, a standard enumerator is okay.
        var size: Int64 = 0
        // Use totalFileAllocatedSizeKey to get the actual disk usage (handles sparse files like Docker.raw)
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey], options: [], errorHandler: nil) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                if let allocatedSize = resourceValues.totalFileAllocatedSize {
                    size += Int64(allocatedSize)
                }
            } catch {
                // Ignore errors
            }
        }
        return size
    }
}
