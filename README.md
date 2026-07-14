# 🧹 Mac Deep Cleaner

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![macOS](https://img.shields.io/badge/macOS-14.0+-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Apple%20Silicon%20%7C%20Intel-lightgrey.svg)

**Native | Secure | Intelligent | Open Source**

[Features](#-features) • [Installation](#-installation) • [Architecture](#-architecture) • [Privacy](#-privacy) • [License](#-license)

</div>

---

## 🎯 The Mission

**Mac Deep Cleaner** is a professional-grade macOS utility crafted with precision for those who demand the best. Built entirely in native Swift, it empowers you to understand and optimize your storage without compromising security or privacy.

> *"Clean smarter, not harder."*

---

## ✨ Features

### 🏠 Dashboard
- **Real-time Storage Analysis** - Visual overview of your disk usage
- **Smart Categorization** - 13+ categories including Applications, Cache, Developer Files, and more
- **Action Center** - Scan, Review, and Clean with confidence

### 📊 Storage Analyzer
- **Deep Directory Tree** - Explore storage usage at any depth
- **Intelligent Sorting** - Sort by Size, Name, Date Modified, or File Type
- **Quick Actions** - Reveal in Finder, Quick Look, or directly move to Trash
- **Real-time Progress** - Cancel anytime without freezing your system

### 📁 Large Files Finder
- **Flexible Filters** - 100MB to 5GB+ or custom sizes
- **Time-based Filtering** - 30 to 365 days untouched
- **Preview & Action** - Preview files, reveal in Finder, or send to Trash

### 🗑️ Cache Cleaner
- **Comprehensive Scanning** - Covers all major cache locations
- **App Grouping** - See cache organized by application
- **Safety Ratings** - Each item rated: Safe ✓ | Review ⚠️ | Do Not Delete ❌
- **Protected Zones** - Never touches Keychains, Mail, Messages, or Photos Library

### 📦 Application Uninstaller
- **Complete App Discovery** - Scans both /Applications and ~/Applications
- **Leftover Detection** - Finds orphaned files across 8+ Library directories
- **Smart Safety** - Differentiates between app-specific and shared files
- **Granular Control** - Choose exactly what to delete

### 👨‍💻 Developer Cleaner
- **Xcode** - DerivedData, Archives, DeviceSupport, Simulators, SPM cache
- **Node.js** - node_modules, npm/pnpm/Yarn caches
- **Python** - .venv, venv, pip cache, __pycache__
- **Docker** - Images, containers, build cache (info-only for volumes)
- **Homebrew** - Download cache, old versions, casks
- **Unity** - Library, Temp, Logs, obj

### 📱 iOS Backups
- **Device Detection** - Shows device name, iOS version, backup date
- **Size Analysis** - Identifies space-hogging backups
- **Encryption Status** - Detects encrypted backups
- **Privacy First** - Never reads backup contents

### 🔄 Duplicate Finder
- **Optimized Scanning** - Size grouping → Partial hash → Full hash when needed
- **SHA-256** - Industry-standard hashing
- **Smart Exclusions** - Skips system files, package contents, and common development folders
- **You Decide** - Never auto-selects files for deletion

### 📜 Cleaning History
- **Complete Audit Trail** - What was deleted, when, and how much
- **Undo Friendly** - Files go to Trash where they can be restored
- **Privacy Preserving** - Stores paths and sizes only, never file content

### ⚙️ Settings
- **Fine-tune Your Experience** - Minimum file sizes, exclusion lists, volume scanning
- **Safety Controls** - Require confirmation, follow symlinks (off by default)
- **Developer Mode** - Advanced options for power users

---

## 🚀 Installation

### Requirements
- macOS 14.0 Sonoma or later
- Apple Silicon (M1/M2/M3) or Intel processor
- Xcode 15.0+ for development

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/mac-deep-cleaner.git
cd mac-deep-cleaner

# Open in Xcode
open MacDeepCleaner.xcodeproj

# Build for development
xcodebuild -scheme MacDeepCleaner -configuration Debug build

# Build for release
xcodebuild -scheme MacDeepCleaner -configuration Release build
```

### Download Pre-built
[Download the latest release](https://github.com/yourusername/mac-deep-cleaner/releases)

---

## 🏗️ Architecture

Built on a solid foundation of clean architecture principles:

```
MacDeepCleaner/
├── App/                    # App entry & configuration
├── Models/                 # Core data models
├── Views/                  # SwiftUI + AppKit views
├── ViewModels/            # MVVM view models
├── Services/              # Business logic layer
│   ├── DiskUsageService   # Disk space analysis
│   ├── FileScannerService # File system scanning
│   ├── CacheScannerService # Cache detection
│   ├── ApplicationScannerService # App & leftover detection
│   ├── DeveloperScannerService # Dev tool analysis
│   ├── DuplicateScannerService # File hashing & comparison
│   ├── PermissionService # TCC & security-scoped access
│   ├── TrashService      # Safe file deletion
│   ├── CleaningHistoryService # History management
│   └── ExclusionService  # Exclusion rule handling
├── Scanners/              # Protocol-based scanner implementations
├── FileSystem/            # File operation utilities
├── Permissions/           # Permission handling
├── Persistence/           # Data persistence
├── Utilities/             # Helper functions
└── Tests/                 # Comprehensive test suite
```

### Core Principles
- **Protocol-Oriented** - All scanners conform to the same protocol for easy extension
- **Swift Concurrency** - async/await with TaskGroup for optimal performance
- **MainActor Safety** - UI never blocks, scans run in background
- **Memory Efficient** - No large file reads, uses URLResourceValues
- **Cancellable Operations** - All scans can be cancelled gracefully

---

## 🔒 Security & Privacy

### What We Do
- ✅ All processing done locally
- ✅ No analytics, telemetry, or data collection
- ✅ Never upload file paths or content
- ✅ Uses macOS security-scoped bookmarks
- ✅ Full Disk Access required for complete scanning

### What We Never Do
- ❌ Use `rm -rf` or shell commands for deletion
- ❌ Request root privileges or use `sudo`
- ❌ Touch system files in /System
- ❌ Delete files in /Library without safety rules
- ❌ Access Keychains, Mail, Messages, or Photos Library data
- ❌ Delete Docker volumes or Git repositories
- ❌ Follow symbolic links outside scan scope

### Permissions Required
- **Full Disk Access** - For comprehensive file system scanning
- **User-selected Folder Access** - For scanning specific directories
- All permissions are requested properly through macOS TCC system

---

## 🧪 Testing

We take testing seriously. Comprehensive test suite includes:

### Test Categories
- **Unit Tests** - Individual component testing
- **File Scanner Tests** - Directory traversal and file enumeration
- **Duplicate Detection Tests** - Hash-based duplicate finding
- **Exclusion Rule Tests** - Exclusion pattern matching
- **Trash Operation Tests** - Mock-based deletion tests
- **Permission State Tests** - TCC permission handling
- **Symbolic Link Tests** - Link following and cycle detection
- **Unicode/Vietnamese Tests** - International filename support
- **Race Condition Tests** - Files deleted during scan

### Running Tests
```bash
xcodebuild test -scheme MacDeepCleaner -destination 'platform=macOS,arch=arm64'
```

All tests use temporary directories - your actual files are safe.

---

## 📚 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - System design and architecture decisions
- [SECURITY.md](SECURITY.md) - Security model and threat analysis
- [PRIVACY.md](PRIVACY.md) - Data handling and privacy practices
- [TESTING.md](TESTING.md) - Testing strategy and coverage
- [Entitlements](Entitlements/) - Required macOS entitlements list

---

## 🎨 Design Philosophy

- **Native macOS** - Feels like it belongs on your Mac
- **System Settings Style** - Familiar sidebar navigation
- **Light & Dark Mode** - Seamless theme switching
- **Accessibility First** - Full VoiceOver and keyboard support
- **Calm & Professional** - No fear-inducing warning icons or fake alerts
- **Dynamic Type** - Scales gracefully for all display sizes

---

## 🛡️ Safety First

### Before Any Deletion
1. **Full Disclosure** - Shows total files, total size, and complete list
2. **Risk Assessment** - Each item rated Safe/Review/Do Not Delete
3. **User Confirmation** - Explicit confirmation required
4. **Trash Only** - All deletions go to Trash first
5. **Never Permanent** - Permanent deletion only in Advanced Settings with double confirmation

### Protected Items
- System frameworks & libraries
- User documents and personal data
- iCloud Drive metadata
- Photos Library
- Music/iTunes Library
- And more...

---

## 🤝 Contributing

We welcome contributions! Please see:
- [Contributing Guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Development Setup](DEVELOPMENT.md)

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Write tests for your changes
4. Ensure all tests pass
5. Submit a pull request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

Built with ❤️ using:
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Modern UI framework
- [AppKit](https://developer.apple.com/documentation/appkit) - Native macOS integration
- [Swift Concurrency](https://developer.apple.com/documentation/swift/swift-standard-library/concurrency) - Async/await patterns
- [FileManager](https://developer.apple.com/documentation/foundation/filemanager) - File system operations

---

## 📞 Support

- **Documentation**: [https://docs.macdeepcleaner.com](https://docs.macdeepcleaner.com)
- **Issues**: [GitHub Issues](https://github.com/yourusername/mac-deep-cleaner/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/mac-deep-cleaner/discussions)

---

<div align="center">

**Mac Deep Cleaner** - Professional macOS storage optimization

[⬆ Back to Top](#-mac-deep-cleaner)

</div>