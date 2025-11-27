import Foundation

let fileManager = FileManager.default
let homeDir = fileManager.homeDirectoryForCurrentUser

let pathsToScan = [
    "Library/Caches",
    "Library/Logs",
    "Library/Developer/Xcode/DerivedData",
    "Library/Application Support/MobileSync/Backups"
]

func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useAll]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}

func getDirectorySize(url: URL) -> Int64 {
    var size: Int64 = 0
    guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [], errorHandler: nil) else {
        return 0
    }
    
    for case let fileURL as URL in enumerator {
        do {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                size += Int64(fileSize)
            }
        } catch {
            // Ignore errors
        }
    }
    return size
}

print("Scanning System Data Locations...")
print("--------------------------------")

var totalSize: Int64 = 0

for path in pathsToScan {
    let fullURL = homeDir.appendingPathComponent(path)
    print("Checking: \(fullURL.path)")
    
    var isDir: ObjCBool = false
    if fileManager.fileExists(atPath: fullURL.path, isDirectory: &isDir) {
        if isDir.boolValue {
            let size = getDirectorySize(url: fullURL)
            print("Size: \(formatBytes(size))")
            totalSize += size
        } else {
            print("Not a directory.")
        }
    } else {
        print("Not found.")
    }
    print("--------------------------------")
}

print("Total Potential Reclaimable Space: \(formatBytes(totalSize))")
