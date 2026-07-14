import Foundation

public struct DeveloperScannerService: CleanerScanner {
    public let identifier = "developer"
    public let displayName = "Developer Cleaner"
    public let riskLevel: RiskLevel = .review
    public let supportedPaths: [URL]
    private let reader: FileSystemReader
    private let manager: FileManager

    public init(home: URL = URL(fileURLWithPath: NSHomeDirectory()), reader: FileSystemReader = FileSystemReader(), manager: FileManager = .default) {
        self.supportedPaths = [
            home.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
            home.appendingPathComponent("Library/Developer/Xcode/Archives"),
            home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport"),
            home.appendingPathComponent("Library/Developer/CoreSimulator/Devices"),
            home.appendingPathComponent("Library/Caches/org.swift.swiftpm"),
            home.appendingPathComponent(".npm"),
            home.appendingPathComponent("Library/pnpm/store"),
            home.appendingPathComponent("Library/Caches/Yarn"),
            home.appendingPathComponent("Library/Caches/pip"),
            home.appendingPathComponent("Library/Caches/Homebrew"),
            home.appendingPathComponent("Library/Unity/cache")
        ]
        self.reader = reader
        self.manager = manager
    }

    public func scan(options: ScanOptions) async throws -> [ScanItem] {
        var results: [ScanItem] = []
        for path in supportedPaths where manager.fileExists(atPath: path.path) {
            let metadata = try? reader.metadata(for: path)
            let size = try await reader.directoryAllocatedSize(path, options: options)
            results.append(ScanItem(
                url: path,
                size: size,
                category: .developerFiles,
                riskLevel: path.path.contains("Archives") ? .review : .safe,
                isDirectory: metadata?.isDirectory ?? true,
                lastModified: metadata?.lastModified,
                lastAccessed: metadata?.lastAccessed,
                typeDescription: developerType(for: path),
                warning: warning(for: path)
            ))
        }
        try await scanProjectFolders(options: options, into: &results)
        return results.sorted { $0.size > $1.size }
    }

    private func scanProjectFolders(options: ScanOptions, into results: inout [ScanItem]) async throws {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let roots = ["Developer", "Documents", "Desktop"].map { home.appendingPathComponent($0) }
        let names = Set(["node_modules", ".venv", "venv", "__pycache__", "Library", "Temp", "Logs", "obj"])
        for root in roots where manager.fileExists(atPath: root.path) {
            guard let enumerator = manager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey],
                options: options.showHiddenFiles ? [] : [.skipsHiddenFiles]
            ) else { continue }
            for case let url as URL in enumerator {
                if Task.isCancelled { throw CancellationError() }
                guard !options.exclusions.excludes(url.deletingLastPathComponent()) else {
                    enumerator.skipDescendants()
                    continue
                }
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                guard values?.isDirectory == true, values?.isSymbolicLink != true, names.contains(url.lastPathComponent) else { continue }
                enumerator.skipDescendants()
                let metadata = try? reader.metadata(for: url)
                var sizeOptions = options
                sizeOptions.exclusions.skipNodeModules = false
                sizeOptions.exclusions.skipVirtualEnvironments = false
                let size = try await reader.directoryAllocatedSize(url, options: sizeOptions)
                let warning = url.lastPathComponent == "Library" ? "Unity Library can be rebuilt, but reimport may take a long time." : nil
                results.append(ScanItem(
                    url: url,
                    size: size,
                    category: .developerFiles,
                    riskLevel: .review,
                    isDirectory: true,
                    lastModified: metadata?.lastModified,
                    lastAccessed: metadata?.lastAccessed,
                    typeDescription: developerType(for: url),
                    warning: warning
                ))
            }
        }
    }

    private func developerType(for url: URL) -> String {
        let path = url.path
        if path.contains("Xcode") || path.contains("CoreSimulator") { return "Xcode" }
        if path.contains("node_modules") || path.contains(".npm") || path.contains("Yarn") || path.contains("pnpm") { return "Node.js" }
        if path.contains(".venv") || path.contains("venv") || path.contains("pip") || path.contains("__pycache__") { return "Python" }
        if path.contains("Homebrew") { return "Homebrew" }
        if path.contains("Unity") || url.lastPathComponent == "Library" { return "Unity" }
        return "Developer data"
    }

    private func warning(for url: URL) -> String? {
        if url.path.contains("Archives") { return "Xcode archives may be needed for symbolication or release records." }
        if url.lastPathComponent == "Library" { return "Unity Library can be rebuilt, but project import may take a long time." }
        return nil
    }
}
