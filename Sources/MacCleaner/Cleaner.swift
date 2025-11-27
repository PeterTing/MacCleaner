import Foundation

class Cleaner {
    static let shared = Cleaner()
    private let fileManager = FileManager.default
    
    func clean(items: [CleanableItem], completion: @escaping (Int64, Int, String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var totalCleaned: Int64 = 0
            var errorCount: Int = 0
            var lastError: String?
            
            for item in items {
                if item.isSelected {
                    let (cleaned, errors, errStr) = self.cleanItem(item)
                    totalCleaned += cleaned
                    errorCount += errors
                    if let err = errStr {
                        lastError = err
                    }
                }
            }
            DispatchQueue.main.async {
                completion(totalCleaned, errorCount, lastError)
            }
        }
    }
    
    private func cleanItem(_ item: CleanableItem) -> (Int64, Int, String?) {
        let url = URL(fileURLWithPath: item.path)
        var cleanedSize: Int64 = 0
        var errors: Int = 0
        var lastError: String?
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey])
            for fileUrl in contents {
                // If a filter is set, only delete files matching the extension
                if let filter = item.fileExtensionFilter {
                    guard fileUrl.pathExtension.lowercased() == filter.lowercased() else { continue }
                }
                
                do {
                    let resourceValues = try fileUrl.resourceValues(forKeys: [.fileSizeKey])
                    let fileSize = Int64(resourceValues.fileSize ?? 0)
                    
                    try fileManager.removeItem(at: fileUrl)
                    cleanedSize += fileSize
                } catch {
                    print("Failed to delete \(fileUrl.lastPathComponent): \(error.localizedDescription)")
                    errors += 1
                    lastError = error.localizedDescription
                }
            }
        } catch {
            print("Failed to list \(item.path): \(error)")
            errors += 1
            lastError = error.localizedDescription
        }
        return (cleanedSize, errors, lastError)
    }
}
