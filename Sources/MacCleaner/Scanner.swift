import Foundation

struct CleanableItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    var size: Int64
    var isSelected: Bool = true
    var fileExtensionFilter: String? = nil
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

class Scanner: ObservableObject {
    @Published var items: [CleanableItem] = []
    @Published var isScanning: Bool = false
    @Published var totalSize: Int64 = 0
    
    private let fileManager = FileManager.default
    
    func scan() {
        isScanning = true
        items = []
        totalSize = 0
        
        let pathsToScan = [
            ("User Caches", "Library/Caches", nil),
            ("User Logs", "Library/Logs", nil),
            ("Xcode DerivedData", "Library/Developer/Xcode/DerivedData", nil),
            ("iOS Backups", "Library/Application Support/MobileSync/Backups", nil),
            ("Message Attachments", "Library/Messages/Attachments", nil),
            ("Mail Downloads", "Library/Containers/com.apple.mail/Data/Library/Mail Downloads", nil),
            ("Unused Disk Images", "Downloads", "dmg")
        ]
        
        DispatchQueue.global(qos: .userInitiated).async {
            var newItems: [CleanableItem] = []
            var calculatedTotal: Int64 = 0
            
            let homeDir = self.fileManager.homeDirectoryForCurrentUser
            
            for (name, relativePath, filter) in pathsToScan {
                let fullURL = homeDir.appendingPathComponent(relativePath)
                var isDir: ObjCBool = false
                
                if self.fileManager.fileExists(atPath: fullURL.path, isDirectory: &isDir), isDir.boolValue {
                    let size = self.getDirectorySize(url: fullURL, filter: filter)
                    if size > 0 {
                        var item = CleanableItem(name: name, path: fullURL.path, size: size)
                        item.fileExtensionFilter = filter
                        newItems.append(item)
                        calculatedTotal += size
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.items = newItems
                self.totalSize = calculatedTotal
                self.isScanning = false
            }
        }
    }
    
    private func getDirectorySize(url: URL, filter: String? = nil) -> Int64 {
        var size: Int64 = 0
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey], options: [], errorHandler: nil) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if let filter = filter {
                guard fileURL.pathExtension.lowercased() == filter.lowercased() else { continue }
            }
            
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
