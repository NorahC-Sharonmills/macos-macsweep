# Mac Deep Cleaner

Native macOS disk review app built with Swift 6, SwiftUI, AppKit, and SwiftPM. It scans locally, marks risk, previews files, reveals Finder locations, and moves selected items to Trash only after user confirmation.

## Requirements

- macOS 14+
- Xcode 16+ with Swift 6
- Apple Silicon or Intel Mac

## Build

Debug:

```sh
open Package.swift
# Xcode: Product > Run
```

Release:

```sh
swift build -c release
```

Tests:

```sh
swift test
```

This workspace was generated on Windows, so `swift` and `xcodebuild` could not be executed here. Run the commands above on macOS.

## Full Disk Access

1. Open System Settings.
2. Privacy & Security.
3. Full Disk Access.
4. Add the built MacDeepCleaner app.
5. Relaunch the app.

Without Full Disk Access, iOS backups, Mail, Messages, and some `~/Library` paths may be incomplete. The app reports limited access instead of pretending the scan is complete.

## Entitlements

See `MacDeepCleaner.entitlements`:

- `com.apple.security.app-sandbox`
- `com.apple.security.files.user-selected.read-write`
- `com.apple.security.files.bookmarks.app-scope`
- `com.apple.security.files.downloads.read-write`

Full Disk Access is a user-granted TCC permission, not an entitlement.
