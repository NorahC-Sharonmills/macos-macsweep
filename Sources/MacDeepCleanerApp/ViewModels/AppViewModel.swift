import AppKit
import Foundation
import MacDeepCleanerCore

@MainActor
final class AppViewModel: ObservableObject {
    @Published var diskUsage = DiskUsage(total: 0, used: 0, free: 0)
    @Published var permissionStatus = PermissionService().status()
    @Published var statusText = "Ready"
    @Published var isScanning = false
    @Published var storageItems: [ScanItem] = []
    @Published var largeFiles: [ScanItem] = []
    @Published var cacheItems: [ScanItem] = []
    @Published var developerItems: [ScanItem] = []
    @Published var attachmentItems: [ScanItem] = []
    @Published var applications: [ApplicationInfo] = []
    @Published var backups: [IOSBackup] = []
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var history: [CleaningHistoryRecord] = []
    @Published var options = ScanOptions()
    @Published var selectedItems = Set<ScanItem.ID>()
    @Published var selectedLargeThreshold: Int64 = 500 * 1024 * 1024
    @Published var selectedOldDays: Int? = nil

    private var scanTask: Task<Void, Never>?
    private let diskService = DiskUsageService()
    private let trashService = TrashService()
    private let historyService = CleaningHistoryService()
    private let permissionService = PermissionService()

    init() {
        refreshDisk()
        history = (try? historyService.load()) ?? []
    }

    var reclaimable: Int64 {
        (cacheItems + developerItems + largeFiles).filter { $0.riskLevel != .doNotDelete }.reduce(0) { $0 + $1.size }
    }

    var dashboardCategories: [(CleanerCategory, Int64)] {
        CleanerCategory.allCases.map { category in
            let size: Int64
            switch category {
            case .applications: size = applications.reduce(0) { $0 + $1.size }
            case .cache, .logs: size = cacheItems.filter { $0.category == category }.reduce(0) { $0 + $1.size }
            case .developerFiles: size = developerItems.reduce(0) { $0 + $1.size }
            case .mailAttachments, .messagesAttachments: size = attachmentItems.filter { $0.category == category }.reduce(0) { $0 + $1.size }
            case .iOSBackups: size = backups.reduce(0) { $0 + $1.size }
            case .largeFiles: size = largeFiles.reduce(0) { $0 + $1.size }
            case .duplicateFiles: size = duplicateGroups.reduce(0) { $0 + $1.size * Int64(max(0, $1.files.count - 1)) }
            case .applicationLeftovers: size = applications.flatMap(\.leftovers).reduce(0) { $0 + $1.size }
            default: size = storageItems.filter { $0.category == category }.reduce(0) { $0 + $1.size }
            }
            return (category, size)
        }
    }

    func refreshDisk() {
        diskUsage = (try? diskService.usage()) ?? DiskUsage(total: 0, used: 0, free: 0)
        permissionStatus = permissionService.status()
    }

    func scanMac() {
        let opts = options
        runScan("Quick scanning Mac") {
            self.cacheItems = try await Self.background { try await CacheScannerService().scan(options: opts) }
            self.applications = try await Self.background { try await ApplicationScannerService().scan(options: opts) }
            self.attachmentItems = try await Self.background { try await AppleAttachmentScannerService().scan(options: opts) }
            self.backups = try await Self.background { try await IOSBackupScannerService().scan(options: opts) }
        }
    }

    func scanStorage() {
        let opts = options
        runScan("Scanning storage") {
            self.storageItems = try await Self.background { try await Self.cachedStorageScan(options: opts) }
        }
    }

    func scanLargeFiles() {
        let opts = options
        let minSize = selectedLargeThreshold
        let oldDays = selectedOldDays
        runScan("Scanning large files") {
            self.largeFiles = try await Self.background { try await FileScannerService().largeFiles(minimumSize: minSize, olderThanDays: oldDays, options: opts) }
        }
    }

    func scanCache() {
        let opts = options
        runScan("Scanning cache") { self.cacheItems = try await Self.background { try await CacheScannerService().scan(options: opts) } }
    }

    func scanApplications() {
        let opts = options
        runScan("Scanning applications") { self.applications = try await Self.background { try await ApplicationScannerService().scan(options: opts) } }
    }

    func scanDeveloper() {
        let opts = options
        runScan("Scanning developer files") { self.developerItems = try await Self.background { try await DeveloperScannerService().scan(options: opts) } }
    }

    func scanBackups() {
        let opts = options
        runScan("Scanning backups") { self.backups = try await Self.background { try await IOSBackupScannerService().scan(options: opts) } }
    }

    func scanDuplicates() {
        let opts = options
        runScan("Scanning duplicates") { self.duplicateGroups = try await Self.background { try await DuplicateScannerService().duplicateGroups(options: opts) } }
    }

    func cancelScan() {
        scanTask?.cancel()
        isScanning = false
        statusText = "Cancelled"
    }

    func cleanSelected(from items: [ScanItem]) {
        let targets = items.filter { selectedItems.contains($0.id) && $0.riskLevel != .doNotDelete }
        clean(targets)
    }

    func clean(_ targets: [ScanItem]) {
        guard !targets.isEmpty else { return }
        do {
            let summary = try trashService.moveToTrash(targets)
            try historyService.append(CleaningHistoryRecord(paths: summary.paths, bytes: summary.bytes, category: targets.first?.category ?? .storage))
            history = (try? historyService.load()) ?? history
            selectedItems.removeAll()
            statusText = "Moved \(summary.count) item(s) to Trash"
        } catch {
            statusText = error.localizedDescription
        }
    }

    func openSettingsForFullDiskAccess() {
        NSWorkspace.shared.open(permissionService.fullDiskAccessSettingsURL)
    }

    private func runScan(_ title: String, operation: @escaping () async throws -> Void) {
        scanTask?.cancel()
        isScanning = true
        statusText = title
        scanTask = Task {
            do {
                try await operation()
                refreshDisk()
                isScanning = false
                statusText = "Done"
            } catch is CancellationError {
                isScanning = false
                statusText = "Cancelled"
            } catch {
                isScanning = false
                statusText = error.localizedDescription
            }
        }
    }

    nonisolated private static func background<T: Sendable>(_ work: @escaping @Sendable () async throws -> T) async throws -> T {
        try await Task.detached(priority: .userInitiated, operation: work).value
    }

    nonisolated private static func cachedStorageScan(options: ScanOptions) async throws -> [ScanItem] {
        let cache = ScanResultCache()
        if let cached = try? cache.loadValid(options: options) { return cached }
        let items = try await FileScannerService().scan(options: options)
        try? cache.save(items, options: options)
        return items
    }

    private static func largeFiles(from items: [ScanItem], minimumSize: Int64, olderThanDays: Int?) -> [ScanItem] {
        let cutoff = olderThanDays.map { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) ?? .distantPast }
        return items.filter { item in
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
