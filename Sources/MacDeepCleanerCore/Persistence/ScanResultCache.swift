import Foundation

public struct ScanResultCache: Sendable {
    private let fileURL: URL

    public init(fileURL: URL? = nil) {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MacDeepCleaner", isDirectory: true)
        self.fileURL = fileURL ?? (base ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("scan-cache.json")
    }

    public func loadValid(options: ScanOptions) throws -> [ScanItem]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let cached = try JSONDecoder().decode(CachedScan.self, from: Data(contentsOf: fileURL))
        guard cached.options == options else { return nil }
        for item in cached.items {
            guard let values = try? item.url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else {
                return nil
            }
            let currentSize = Int64(values.fileSize ?? 0)
            if currentSize != item.size || values.contentModificationDate != item.lastModified {
                return nil
            }
        }
        return cached.items
    }

    public func save(_ items: [ScanItem]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(CachedScan(items: items, options: nil, savedAt: Date()))
        try data.write(to: fileURL, options: .atomic)
    }

    public func save(_ items: [ScanItem], options: ScanOptions) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(CachedScan(items: items, options: options, savedAt: Date()))
        try data.write(to: fileURL, options: .atomic)
    }
}

private struct CachedScan: Codable {
    var items: [ScanItem]
    var options: ScanOptions?
    var savedAt: Date
}
