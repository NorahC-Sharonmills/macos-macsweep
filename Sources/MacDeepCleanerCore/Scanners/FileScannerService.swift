import Foundation
import OSLog

public struct FileScannerService: CleanerScanner {
    public let identifier = "storage"
    public let displayName = "Storage Analyzer"
    public let riskLevel: RiskLevel = .review
    public let supportedPaths: [URL]
    private let reader: FileSystemReader

    public init(supportedPaths: [URL] = [URL(fileURLWithPath: NSHomeDirectory())], reader: FileSystemReader = FileSystemReader()) {
        self.supportedPaths = supportedPaths
        self.reader = reader
    }

    public func scan(options: ScanOptions) async throws -> [ScanItem] {
        CleanerLogger.scanner.info("Storage scan started")
        var items: [ScanItem] = []
        for root in supportedPaths {
            try await reader.enumerate(root: root, options: options) { metadata in
                let item = ScanItem(
                    url: metadata.url,
                    size: metadata.size,
                    category: .storage,
                    riskLevel: .review,
                    isDirectory: metadata.isDirectory,
                    lastModified: metadata.lastModified,
                    lastAccessed: metadata.lastAccessed,
                    typeDescription: metadata.typeDescription,
                    warning: "Review manually before moving to Trash."
                )
                items.append(item)
            }
        }
        CleanerLogger.scanner.info("Storage scan finished: \(items.count, privacy: .public) items")
        return items.sorted { $0.size > $1.size }
    }

    public func largeFiles(minimumSize: Int64, olderThanDays: Int?, options: ScanOptions) async throws -> [ScanItem] {
        let cutoff = olderThanDays.map { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) ?? .distantPast }
        return try await scan(options: options).filter { item in
            guard !item.isDirectory, item.size >= minimumSize else { return false }
            guard let cutoff else { return true }
            return (item.lastModified ?? .distantFuture) < cutoff
        }.map {
            var item = $0
            item.category = .largeFiles
            return item
        }
    }
}
