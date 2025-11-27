# MacCleaner 🧹

> A native macOS SwiftUI app for identifying and cleaning up disk space

MacCleaner is a lightweight macOS utility that helps you quickly find and clean cache files, large folders, and Docker resources, easily reclaiming gigabytes of disk space.

## ✨ Features

### 1. System Cache Cleanup
Automatically scans and cleans the following items:
- **User Caches** (`~/Library/Caches`) - Application cache files
- **User Logs** (`~/Library/Logs`) - System and application logs
- **Xcode DerivedData** - Xcode intermediate build files
- **iOS Backups** - Old iOS device backups
- **Message Attachments** - iMessage attachments cache
- **Mail Downloads** - Mail app downloaded attachments
- **Unused DMG Files** - Disk images in Downloads folder

✅ Supports filtering by file extension (e.g., clean only .dmg files)

### 2. Large File Detection
- Scans `~/Library/Containers` and `~/Library/Application Support`
- Identifies folders larger than **500MB**
- Provides "Reveal in Finder" functionality for manual review

### 3. Docker Cleanup
Automatically detects and cleans Docker resources:

**Granular Cleanup**:
- Scan and selectively delete unused Docker volumes
- View size and status of each volume

**Batch Cleanup Options**:
- 🟢 **Remove unused images and build cache** (Safe)
- 🟡 **Stop all containers and remove all images**
- 🔴 **Remove all volumes** (⚠️ Dangerous - causes data loss)

## 📦 Installation

### Option 1: Download Pre-built Release
Download the latest `.dmg` from [GitHub Releases](https://github.com/yourusername/MacCleaner/releases):
1. Download `MacCleaner-v1.0.0.dmg`
2. Open the DMG and drag `MacCleaner.app` to Applications folder
3. First launch: Allow execution in System Settings > Privacy & Security

### Option 2: Build from Source
```bash
git clone https://github.com/yourusername/MacCleaner.git
cd MacCleaner
./bundle.sh
open MacCleaner.app
```

## 🚀 Usage

1. Launch **MacCleaner**
2. Click **"Scan"** to scan for cleanable items
3. Review results and check/uncheck items to clean
4. Click **"Clean Selected"** to perform cleanup
5. Review the cleanup report to confirm freed space

**Docker Cleanup**:
- If Docker Desktop is installed, you'll see a "Docker Cleanup" section
- Click **"Clean Docker..."** to open the dedicated cleanup window
- Select volumes to clean or use batch cleanup options

## 💻 System Requirements

- **macOS**: 14.0+ (Sonoma)
- **Swift**: 5.9+
- **Docker Desktop**: Optional (only for Docker cleanup features)

## 📋 TODO List

### Feature Expansion
- [ ] Homebrew cache cleanup (`~/Library/Caches/Homebrew`)
- [ ] Trash/Bin management (show size and empty option)
- [ ] Simulator data cleanup (Xcode Simulators)
- [ ] Podcast/Music cache cleanup
- [ ] System-level cache cleanup (requires sudo)
- [ ] Add "Safe Mode" showing only completely safe cleanup items
- [ ] Configurable size threshold for large file scanning (currently hardcoded at 500MB)
- [ ] Docker cleanup additions: dangling images, stopped containers, networks

### User Experience
- [ ] Pre-cleanup confirmation dialog (showing items to be deleted)
- [ ] Progress bar with percentage (currently only ProgressView)
- [ ] Sort scan results (by size, name, type)
- [ ] Search/filter functionality
- [ ] Save/load cleanup configurations (remember user selections)
- [ ] Dark/light mode icon optimization
- [ ] Internationalization (i18n) support

### Performance Optimization
- [ ] Add depth limit for large directory scanning
- [ ] Show scan progress (currently scanning directory)
- [ ] Add caching mechanism to avoid redundant scans
- [ ] Improve async error handling

### Security
- [ ] Code signing and notarization
- [ ] Sandbox support
- [ ] Undo functionality or trash mode for deletions

### Distribution
- [ ] Homebrew Cask distribution
- [ ] Sparkle auto-update framework integration
- [ ] DMG background image and visual enhancements

## 🤝 Contributing

We welcome all forms of contribution!

### Reporting Issues
- Use [GitHub Issues](https://github.com/yourusername/MacCleaner/issues) to report bugs
- Provide detailed error messages and reproduction steps
- For security issues, please contact maintainers privately

### Submitting Pull Requests
1. Fork this repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Follow the [coding conventions](docs/coding-convention.md)
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

### Code Style
Please refer to [`docs/coding-convention.md`](docs/coding-convention.md) for Swift coding standards. This project uses SwiftLint for code quality checks.

## ⚠️ Known Limitations

- Large file scanning may take considerable time (depending on folder size)
- Docker cleanup requires Docker Desktop to be running
- Some system files may not be deletable due to permission restrictions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

Thanks to all contributors for their efforts!

---

**⭐ If this project helps you, please give us a Star!**
