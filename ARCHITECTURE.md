# Architecture

SwiftPM targets:

- `MacDeepCleanerApp`: SwiftUI/AppKit UI, sidebar, tables, Quick Look, Finder actions.
- `MacDeepCleanerCore`: models, scanners, filesystem, permissions, persistence, trash workflow.
- `MacDeepCleanerTests`: temp-directory unit tests.

Core layout:

- `Models`: `ScanItem`, `RiskLevel`, `CleanerCategory`, `ScanOptions`, scanner protocol.
- `FileSystem`: `FileSystemReader` with `FileManager` enumerator and `URLResourceValues`.
- `Scanners`: storage, cache, apps, developer files, iOS backups, duplicates.
- `Services`: disk usage and Trash.
- `Permissions`: Full Disk Access status helper.
- `Persistence`: JSON cleaning history.

Scanner contract:

```swift
protocol CleanerScanner {
    var identifier: String { get }
    var displayName: String { get }
    var riskLevel: RiskLevel { get }
    var supportedPaths: [URL] { get }
    func scan(options: ScanOptions) async throws -> [ScanItem]
}
```

Safety defaults:

- Old files are `Review`, never auto-trash.
- Generic storage findings are `Review`.
- Known sensitive locations are blocked or excluded.
- Trash uses `FileManager.trashItem`, not shell deletion.
