import CryptoKit
import Foundation

public struct DuplicateGroup: Identifiable, Codable, Hashable, Sendable {
    public var id: String { fullHash }
    public var fullHash: String
    public var size: Int64
    public var files: [ScanItem]
}

public struct DuplicateScannerService: CleanerScanner {
    public let identifier = "duplicates"
    public let displayName = "Duplicate Finder"
    public let riskLevel: RiskLevel = .review
    public let supportedPaths: [URL]
    private let reader: FileSystemReader

    public init(supportedPaths: [URL] = [URL(fileURLWithPath: NSHomeDirectory())], reader: FileSystemReader = FileSystemReader()) {
        self.supportedPaths = supportedPaths
        self.reader = reader
    }

    public func scan(options: ScanOptions) async throws -> [ScanItem] {
        try await duplicateGroups(options: options).flatMap(\.files)
    }

    public func duplicateGroups(options: ScanOptions) async throws -> [DuplicateGroup] {
        var bySize: [Int64: [FileMetadata]] = [:]
        for root in supportedPaths {
            try await reader.enumerate(root: root, options: options) { metadata in
                guard !metadata.isDirectory, metadata.size > 0 else { return }
                bySize[metadata.size, default: []].append(metadata)
            }
        }

        var groups: [DuplicateGroup] = []
        for (size, files) in bySize where files.count > 1 {
            var byPartial: [String: [FileMetadata]] = [:]
            for file in files {
                if let hash = try? partialHash(file.url) {
                    byPartial[hash, default: []].append(file)
                }
            }
            for partialMatches in byPartial.values where partialMatches.count > 1 {
                var byFull: [String: [FileMetadata]] = [:]
                for file in partialMatches {
                    if Task.isCancelled { throw CancellationError() }
                    let hash = try sha256(file.url)
                    byFull[hash, default: []].append(file)
                }
                for (hash, exact) in byFull where exact.count > 1 {
                    groups.append(DuplicateGroup(
                        fullHash: hash,
                        size: size,
                        files: exact.map {
                            ScanItem(
                                url: $0.url,
                                size: $0.size,
                                category: .duplicateFiles,
                                riskLevel: .review,
                                isDirectory: false,
                                lastModified: $0.lastModified,
                                lastAccessed: $0.lastAccessed,
                                typeDescription: $0.typeDescription,
                                warning: "No copy is selected automatically. Choose manually."
                            )
                        }
                    ))
                }
            }
        }
        return groups.sorted { $0.size > $1.size }
    }

    private func partialHash(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        if let head = try handle.read(upToCount: 64 * 1024) { hasher.update(data: head) }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        if size > 128 * 1024 {
            try handle.seek(toOffset: UInt64(max(0, size - 64 * 1024)))
            if let tail = try handle.read(upToCount: 64 * 1024) { hasher.update(data: tail) }
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            if Task.isCancelled { throw CancellationError() }
            let data = try handle.read(upToCount: 1024 * 1024) ?? Data()
            if data.isEmpty { break }
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
