# MacCleaner 編碼規範

本文檔定義 MacCleaner 專案的 Swift 編碼規範，所有貢獻者應遵循這些準則以確保程式碼的一致性和可維護性。

## 目錄
- [命名規範](#命名規範)
- [程式碼組織](#程式碼組織)
- [文檔規範](#文檔規範)
- [SwiftUI 最佳實踐](#swiftui-最佳實踐)
- [錯誤處理](#錯誤處理)
- [格式化規則](#格式化規則)

---

## 命名規範

### 基本規則
遵循 Apple 的 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)。

### Types 和 Protocols
使用 `UpperCamelCase`（大駝峰命名法）：

```swift
// ✅ 正確
class Scanner { }
struct CleanableItem { }
enum CleanupLevel { }
protocol Cleanable { }

// ❌ 錯誤
class scanner { }
struct cleanable_item { }
```

### Variables、Functions 和 Properties
使用 `lowerCamelCase`（小駝峰命名法）：

```swift
// ✅ 正確
var isScanning: Bool
let totalSize: Int64
func getDirectorySize(url: URL) -> Int64

// ❌ 錯誤
var IsScanning: Bool
let total_size: Int64
func GetDirectorySize(url: URL) -> Int64
```

### Constants
使用 `lowerCamelCase`，全域常數可使用 `SCREAMING_SNAKE_CASE`：

```swift
// ✅ 正確 - 區域常數
let maxFileSize = 1024 * 1024 * 500  // 500MB

// ✅ 正確 - 全域常數
let MAX_SCAN_DEPTH = 10

// ❌ 錯誤
let MaxFileSize = 500
```

### Boolean 變數
使用 `is`、`has`、`should` 等前綴清楚表達布林狀態：

```swift
// ✅ 正確
var isScanning: Bool
var hasError: Bool
var shouldClean: Bool
var canDelete: Bool

// ❌ 錯誤
var scanning: Bool
var error: Bool
```

### Enum Cases
使用 `lowerCamelCase`：

```swift
// ✅ 正確
enum ItemType {
    case volume
    case image
    case buildCache
}

// ❌ 錯誤
enum ItemType {
    case Volume
    case IMAGE
    case build_cache
}
```

---

## 程式碼組織

### MARK 註解
使用 `// MARK: -` 組織程式碼區塊：

```swift
class Scanner {
    // MARK: - Properties
    @Published var items: [CleanableItem] = []
    @Published var isScanning: Bool = false
    
    // MARK: - Initialization
    init() { }
    
    // MARK: - Public Methods
    func scan() { }
    
    // MARK: - Private Methods
    private func getDirectorySize(url: URL) -> Int64 { }
}
```

### Extensions
使用 Extensions 組織相關功能：

```swift
// ✅ 正確 - 使用 extension 分離不同功能
extension ContentView {
    // MARK: - Docker Cleanup
    private func cleanDocker(_ items: [DockerItem]) { }
}

extension ContentView {
    // MARK: - Formatting
    private func formatBytes(_ bytes: Int64) -> String { }
}
```

### Protocol Conformance
將 protocol conformance 放在獨立的 extension 中：

```swift
// ✅ 正確
class Scanner: ObservableObject {
    // 類別本身的實作
}

extension Scanner: Equatable {
    static func == (lhs: Scanner, rhs: Scanner) -> Bool {
        // Equatable 實作
    }
}

// ❌ 錯誤 - 不要在類別定義中混合多個 protocol
class Scanner: ObservableObject, Equatable {
    // ...
}
```

---

## 文檔規範

### Public API 文檔
使用三斜線註解 `///` 為公開 API 撰寫文檔：

```swift
/// 掃描系統中可清理的項目
///
/// 此方法會非同步掃描預定義的目錄，計算每個項目的大小，
/// 並在主執行緒上更新 `items` 和 `totalSize` 屬性。
///
/// - Note: 掃描過程中會忽略沒有讀取權限的檔案
/// - Warning: 大型目錄可能需要較長時間掃描
func scan() {
    // 實作
}
```

### 參數和返回值
使用標準的文檔標籤：

```swift
/// 計算指定目錄的總大小
///
/// - Parameters:
///   - url: 要計算大小的目錄 URL
///   - filter: 可選的檔案副檔名過濾器（例如 "dmg"）
/// - Returns: 目錄的總大小（以位元組為單位）
/// - Note: 使用 `totalFileAllocatedSizeKey` 處理稀疏檔案
private func getDirectorySize(url: URL, filter: String? = nil) -> Int64 {
    // 實作
}
```

### 範例程式碼
對於複雜的函數，提供使用範例：

```swift
/// 清理選定的項目
///
/// - Example:
///   ```swift
///   let items = scanner.items.filter { $0.isSelected }
///   Cleaner.shared.clean(items: items) { cleaned, errors, lastError in
///       print("Cleaned \(cleaned) bytes")
///   }
///   ```
func clean(items: [CleanableItem], completion: @escaping (Int64, Int, String?) -> Void) {
    // 實作
}
```

---

## SwiftUI 最佳實踐

### State Management
正確使用 SwiftUI 的狀態管理屬性包裝器：

```swift
// ✅ 正確
struct ContentView: View {
    @StateObject private var scanner = Scanner()        // View 擁有的物件
    @ObservedObject var dockerCleaner: DockerCleaner   // 從外部注入的物件
    @State private var showingAlert = false            // View 本地狀態
}

// ❌ 錯誤 - 不要對注入的物件使用 @StateObject
struct ContentView: View {
    @StateObject var dockerCleaner: DockerCleaner  // 應該使用 @ObservedObject
}
```

### View 分解
將複雜的 View 拆分成獨立的結構或計算屬性：

```swift
// ✅ 正確 - 將複雜的 section 提取為計算屬性
struct ContentView: View {
    var body: some View {
        VStack {
            headerView
            scanResultsList
            actionButtons
        }
    }
    
    private var headerView: some View {
        Text("MacCleaner")
            .font(.largeTitle)
    }
    
    private var scanResultsList: some View {
        List {
            // ...
        }
    }
}

// 或提取為獨立的 View
struct ScanResultsListView: View {
    let items: [CleanableItem]
    
    var body: some View {
        List(items) { item in
            // ...
        }
    }
}
```

### Bindings
正確使用 Binding：

```swift
// ✅ 正確 - 手動建立 Binding
Toggle(isOn: Binding(
    get: { dockerCleaner.items[index].isSelected },
    set: { dockerCleaner.items[index].isSelected = $0 }
)) {
    Text(item.name)
}

// ✅ 正確 - 使用投影值
ForEach($scanner.items) { $item in
    Toggle(isOn: $item.isSelected) {
        Text(item.name)
    }
}
```

---

## 錯誤處理

### 使用 Swift Error Handling
優先使用 Swift 的錯誤處理機制，而非返回 optional：

```swift
// ✅ 正確
enum ScanError: Error {
    case permissionDenied
    case pathNotFound
    case unknown(Error)
}

func scan() throws {
    guard fileManager.fileExists(atPath: path) else {
        throw ScanError.pathNotFound
    }
    // ...
}

// ❌ 錯誤 - 錯誤情況應該拋出錯誤而非返回 nil
func scan() -> [CleanableItem]? {
    guard fileManager.fileExists(atPath: path) else {
        return nil
    }
    // ...
}
```

### Do-Catch 區塊
適當處理錯誤，避免過度使用 `try?`：

```swift
// ✅ 正確 - 適當處理錯誤
do {
    try fileManager.removeItem(at: fileUrl)
    cleanedSize += fileSize
} catch {
    print("Failed to delete \(fileUrl.lastPathComponent): \(error.localizedDescription)")
    errors += 1
    lastError = error.localizedDescription
}

// ⚠️ 謹慎使用 - 只在真的不關心錯誤時使用
let contents = try? fileManager.contentsOfDirectory(at: url)
```

---

## 格式化規則

所有格式化規則由 SwiftLint 強制執行（詳見 `.swiftlint.yml`）。

### 主要規則

**行長度**：
- 警告：120 字元
- 錯誤：150 字元

**縮排**：
- 使用 4 個空格（Xcode 預設）

**大括號**：
```swift
// ✅ 正確 - K&R 風格
if condition {
    // ...
} else {
    // ...
}

// ❌ 錯誤
if condition 
{
    // ...
}
```

**Force Unwrapping**：
避免使用強制解包 `!`，除非絕對確定值存在：

```swift
// ✅ 正確
if let value = optional {
    use(value)
}

guard let value = optional else { return }

// ❌ 避免
let value = optional!
```

**尾隨閉包**：
當閉包是最後一個參數時，使用尾隨閉包語法：

```swift
// ✅ 正確
items.filter { $0.isSelected }

DispatchQueue.main.async {
    self.isScanning = false
}

// ❌ 錯誤
items.filter({ $0.isSelected })
```

---

## 遵循規範

本專案使用 **SwiftLint** 自動檢查程式碼風格。在提交 PR 之前，請確保：

```bash
# 安裝 SwiftLint
brew install swiftlint

# 執行檢查
swiftlint lint

# 自動修正可修正的問題（可選）
swiftlint --fix
```

CI/CD 流程會自動執行 SwiftLint 檢查，不符合規範的 PR 將無法合併。

---

## 參考資源

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Google Swift Style Guide](https://google.github.io/swift/)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
