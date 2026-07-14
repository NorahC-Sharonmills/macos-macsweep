import Foundation

public struct CacheScannerService: CleanerScanner {
    public let identifier = "cache"
    public let displayName = "Cache Cleaner"
    public let riskLevel: RiskLevel = .safe
    public let supportedPaths: [URL]
    private let reader: FileSystemReader
    private let manager: FileManager

    public init(home: URL = URL(fileURLWithPath: NSHomeDirectory()), reader: FileSystemReader = FileSystemReader(), manager: FileManager = .default) {
        self.supportedPaths = [
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent("Library/Logs"),
            home.appendingPathComponent("Library/Saved Application State"),
            home.appendingPathComponent("Library/WebKit"),
            home.appendingPathComponent("Library/HTTPStorages")
        ]
        self.reader = reader
        self.manager = manager
    }

    public func scan(options: ScanOptions) async throws -> [ScanItem] {
        var results: [ScanItem] = []
        for folder in supportedPaths where manager.fileExists(atPath: folder.path) {
            let children = (try? manager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
            for child in children where !options.exclusions.excludes(child) {
                if Task.isCancelled { throw CancellationError() }
                let metadata = try? reader.metadata(for: child)
                let size = try await reader.directoryAllocatedSize(child, options: options)
                let risk = riskLevel(for: child, under: folder)
                results.append(ScanItem(
                    url: child,
                    size: metadata?.isDirectory == true ? size : (metadata?.size ?? 0),
                    category: folder.lastPathComponent == "Logs" ? .logs : .cache,
                    riskLevel: risk,
                    isDirectory: metadata?.isDirectory ?? false,
                    lastModified: metadata?.lastModified,
                    lastAccessed: metadata?.lastAccessed,
                    typeDescription: metadata?.typeDescription ?? "Cache",
                    warning: risk == .safe ? nil : "Cache or logs may contain app state. Review before cleaning."
                ))
            }
        }
        return results.sorted { $0.size > $1.size }
    }

    private func riskLevel(for url: URL, under folder: URL) -> RiskLevel {
        let path = url.path
        if path.contains("Keychains") || path.contains("Mail") || path.contains("Messages") || path.contains("Photos") || path.contains("Mobile Documents") {
            return .doNotDelete
        }
        if folder.lastPathComponent == "Logs" || folder.lastPathComponent == "WebKit" {
            return .review
        }
        return .safe
    }
}
