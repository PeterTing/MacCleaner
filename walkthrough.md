# MacCleaner Walkthrough

## Overview
MacCleaner is a native macOS application built with SwiftUI to help you reclaim disk space by removing safe-to-delete system data.

## Features
- **Scan**: Identifies reclaimable space in:
    - User Caches (`~/Library/Caches`)
    - User Logs (`~/Library/Logs`)
    - Xcode DerivedData (`~/Library/Developer/Xcode/DerivedData`)
    - iOS Backups (`~/Library/Application Support/MobileSync/Backups`)
- **Large System Folders**: Scans for large folders in:
    - Containers (`~/Library/Containers`)
    - Application Support (`~/Library/Application Support`)
    - *Note: These are shown for review only and can be revealed in Finder.*
- **Clean**: Safely removes selected items.

## Verification Results

### Build Verification
The project builds successfully using Swift Package Manager.

```bash
swift build
```

### Manual Verification Steps
1.  **Run the App**:
    ```bash
    swift run
    ```
2.  **Scan**: Click the "Scan" button. The app will list found categories and their sizes.
3.  **Select**: Uncheck any categories you want to keep (default is all selected).
4.  **Clean**: Click "Clean Selected". The app will remove the files and refresh the scan.

## Safety Notes
- The app targets **user-level** directories only. It does not touch system-level files (`/System/Library`).
- Deletion is permanent (files are not moved to Trash to ensure space is reclaimed immediately).
