# MacCleaner Implementation Plan

## Goal Description
Create a native macOS application (SwiftUI) to identify and clean unnecessary "System Data" to reclaim disk space. The app will focus on safe-to-delete user directories (Caches, Logs, Xcode Data) and provide a clear, user-friendly interface.

## User Review Required
> [!IMPORTANT]
> **Sandboxing & Permissions**: A sandboxed Mac App Store app cannot access `~/Library` freely. This app will likely need to be a non-sandboxed "Developer ID" signed app or run locally without sandboxing to function effectively. I will assume a non-sandboxed local build for this task.

> [!NOTE]
> **Missing Space**: The initial scan found ~18GB. The remaining space (up to 200GB) is likely in:
> 1. Local Time Machine Snapshots (requires `tmutil` / root)
> 2. System-level caches (`/Library/Caches`)
> 3. Adobe/Other App specific caches in `~/Library/Application Support`
> 4. Virtual Memory / Sleep Image

## Proposed Changes

### Project Structure
We will create a standard Swift Package Manager executable or a simple file structure that can be opened in Xcode.

#### [NEW] [Package.swift](file:///Users/peterting/Documents/program/MacCleaner/Package.swift)
- Define the project dependencies (none needed mostly) and targets.

#### [NEW] [MacCleanerApp.swift](file:///Users/peterting/Documents/program/MacCleaner/Sources/MacCleaner/MacCleanerApp.swift)
- Main entry point.

#### [NEW] [ContentView.swift](file:///Users/peterting/Documents/program/MacCleaner/Sources/MacCleaner/ContentView.swift)
- Main UI with:
    - "Scan" button.
    - List of categories (Caches, Logs, Xcode, etc.).
    - Progress bar.
    - "Clean" buttons for each item.

#### [NEW] [Scanner.swift](file:///Users/peterting/Documents/program/MacCleaner/Sources/MacCleaner/Scanner.swift)
- Logic to scan directories and calculate sizes.
- Returns a list of `CleanableItem` structs.

#### [NEW] [LargeFileScanner.swift](file:///Users/peterting/Documents/program/MacCleaner/Sources/MacCleaner/LargeFileScanner.swift)
- Logic to find largest folders in `~/Library/Containers` and `~/Library/Application Support`.
- Returns a list of `CleanableItem` but with a warning that these might be important.

#### [MODIFY] [Scanner.swift](file:///Users/peterting/Documents/program/MacCleaner/Sources/MacCleaner/Scanner.swift)
- Add new categories:
    - "Unused Disk Images" (scan `~/Downloads` for .dmg)
    - "Message Attachments" (scan `~/Library/Messages/Attachments`)
    - "Mail Downloads" (scan `~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads`)

#### [MODIFY] [ContentView.swift](file:///Users/peterting/Documents/program/MacCleaner/Sources/MacCleaner/ContentView.swift)
- Update UI to handle new categories.
- Add specific warnings for Messages (deleting here removes from iCloud if synced).

## Verification Plan

### Automated Tests
- We can write unit tests for the `Scanner` logic (mocking FileManager).

### Manual Verification
- Run the app (`swift run`).
- Click "Scan".
- Verify sizes match the script output.
- Click "Clean" on "Logs" (safest).
- Verify files are gone and space is reclaimed.
