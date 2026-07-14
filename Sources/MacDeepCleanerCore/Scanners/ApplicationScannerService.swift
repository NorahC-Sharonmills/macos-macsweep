import Foundation

public struct ApplicationInfo: Identifiable, Codable, Hashable, Sendable {
    public var id: String { url.path }
    public var url: URL
    public var name: String
    public var bundleIdentifier: String?
    public var version: String?
    public var size: Int64
    public var lastAccessed: Date?
    public var leftovers: [ScanItem]
}

public struct ApplicationScannerService {
    private let reader: FileSystemReader
    private let manager: FileManager

    public init(reader: FileSystemReader = FileSystemReader(), manager: FileManager = .default) {
        self.reader = reader
        self.manager = manager
    }

    public func scan(options: ScanOptions) async throws -> [ApplicationInfo] {
        let roots = [URL(fileURLWithPath: "/Applications"), URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications")]
        var apps: [ApplicationInfo] = []
        for root in roots where manager.fileExists(atPath: root.path) {
            let urls = (try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isPackageKey])) ?? []
            for appURL in urls where appURL.pathExtension == "app" {
                if Task.isCancelled { throw CancellationError() }
                let bundle = Bundle(url: appURL)
                let name = bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String ?? appURL.deletingPathExtension().lastPathComponent
                let identifier = bundle?.bundleIdentifier
                let version = bundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                let metadata = try? reader.metadata(for: appURL)
                let size = try await reader.directoryAllocatedSize(appURL, options: options)
                let leftovers = try await findLeftovers(bundleID: identifier, appName: name, options: options)
                apps.append(ApplicationInfo(
                    url: appURL,
                    name: name,
                    bundleIdentifier: identifier,
                    version: version,
                    size: size,
                    lastAccessed: metadata?.lastAccessed,
                    leftovers: leftovers
                ))
            }
        }
        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func findLeftovers(bundleID: String?, appName: String, options: ScanOptions) async throws -> [ScanItem] {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let roots = [
            "Library/Application Support",
            "Library/Caches",
            "Library/Preferences",
            "Library/Logs",
            "Library/Containers",
            "Library/Group Containers",
            "Library/Saved Application State",
            "Library/LaunchAgents"
        ].map { home.appendingPathComponent($0) }
        let tokens = [bundleID, appName, appName.replacingOccurrences(of: " ", with: "")].compactMap { $0?.lowercased() }
        guard !tokens.isEmpty else { return [] }
        var results: [ScanItem] = []
        for root in roots where manager.fileExists(atPath: root.path) {
            let children = (try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
            for child in children {
                let lower = child.lastPathComponent.lowercased()
                guard tokens.contains(where: { lower.contains($0) }) else { continue }
                let metadata = try? reader.metadata(for: child)
                let size = metadata?.isDirectory == true ? (try await reader.directoryAllocatedSize(child, options: options)) : (metadata?.size ?? 0)
                let reviewOnly = root.path.contains("Group Containers") || root.path.contains("Application Support")
                results.append(ScanItem(
                    url: child,
                    size: size,
                    category: .applicationLeftovers,
                    riskLevel: reviewOnly ? .review : .safe,
                    isDirectory: metadata?.isDirectory ?? false,
                    lastModified: metadata?.lastModified,
                    lastAccessed: metadata?.lastAccessed,
                    typeDescription: metadata?.typeDescription ?? "Application data",
                    warning: reviewOnly ? "May contain shared app data. Review manually." : nil
                ))
            }
        }
        return results
    }
}
