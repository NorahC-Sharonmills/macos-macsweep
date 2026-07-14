import Foundation

public struct CleaningHistoryRecord: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var date: Date
    public var paths: [String]
    public var bytes: Int64
    public var category: CleanerCategory

    public init(id: UUID = UUID(), date: Date = Date(), paths: [String], bytes: Int64, category: CleanerCategory) {
        self.id = id
        self.date = date
        self.paths = paths
        self.bytes = bytes
        self.category = category
    }
}

public struct CleaningHistoryService: Sendable {
    private let fileURL: URL

    public init(fileURL: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MacDeepCleaner", isDirectory: true)
        self.fileURL = fileURL ?? (base ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("history.json")
    }

    public func load() throws -> [CleaningHistoryRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([CleaningHistoryRecord].self, from: data)
    }

    public func append(_ record: CleaningHistoryRecord) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        var records = try load()
        records.insert(record, at: 0)
        let data = try JSONEncoder().encode(records)
        try data.write(to: fileURL, options: .atomic)
    }
}
