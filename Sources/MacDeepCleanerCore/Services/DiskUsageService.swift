import Foundation

public struct DiskUsageService: Sendable {
    public init() {}

    public func usage(for url: URL = URL(fileURLWithPath: NSHomeDirectory())) throws -> DiskUsage {
        let values = try url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ])
        let total = Int64(values.volumeTotalCapacity ?? 0)
        let free = values.volumeAvailableCapacityForImportantUsage ?? Int64(values.volumeAvailableCapacity ?? 0)
        return DiskUsage(total: total, used: max(0, total - free), free: free)
    }
}
