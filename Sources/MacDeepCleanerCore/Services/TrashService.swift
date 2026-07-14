import Foundation
import OSLog

public protocol TrashPerforming {
    func trashItem(at url: URL) throws
}

public struct FileManagerTrashPerformer: TrashPerforming {
    private let manager: FileManager

    public init(manager: FileManager = .default) {
        self.manager = manager
    }

    public func trashItem(at url: URL) throws {
        var resultingURL: NSURL?
        try manager.trashItem(at: url, resultingItemURL: &resultingURL)
    }
}

public struct TrashSummary: Codable, Equatable, Sendable {
    public var count: Int
    public var bytes: Int64
    public var paths: [String]
}

public struct TrashService {
    private let performer: any TrashPerforming

    public init(performer: any TrashPerforming = FileManagerTrashPerformer()) {
        self.performer = performer
    }

    public func summary(for items: [ScanItem]) -> TrashSummary {
        TrashSummary(count: items.count, bytes: items.reduce(0) { $0 + $1.size }, paths: items.map(\.url.path))
    }

    public func moveToTrash(_ items: [ScanItem]) throws -> TrashSummary {
        let blocked = items.filter { $0.riskLevel == .doNotDelete || $0.url.path.hasPrefix("/System") }
        guard blocked.isEmpty else {
            CleanerLogger.trash.warning("Trash blocked protected item")
            throw CleanerError.blockedPath(blocked.map(\.url.path).joined(separator: "\n"))
        }
        for item in items {
            try performer.trashItem(at: item.url)
        }
        CleanerLogger.trash.info("Moved \(items.count, privacy: .public) item(s) to Trash")
        return summary(for: items)
    }
}

public enum CleanerError: LocalizedError, Sendable {
    case blockedPath(String)

    public var errorDescription: String? {
        switch self {
        case .blockedPath(let path): "Blocked path: \(path)"
        }
    }
}
