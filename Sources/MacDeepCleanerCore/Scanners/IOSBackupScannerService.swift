import Foundation

public struct IOSBackup: Identifiable, Codable, Hashable, Sendable {
    public var id: String { url.path }
    public var url: URL
    public var deviceName: String?
    public var backupDate: Date?
    public var iOSVersion: String?
    public var encrypted: Bool?
    public var size: Int64
}

public struct IOSBackupScannerService {
    private let root: URL
    private let reader: FileSystemReader
    private let manager: FileManager

    public init(home: URL = URL(fileURLWithPath: NSHomeDirectory()), reader: FileSystemReader = FileSystemReader(), manager: FileManager = .default) {
        self.root = home.appendingPathComponent("Library/Application Support/MobileSync/Backup")
        self.reader = reader
        self.manager = manager
    }

    public func scan(options: ScanOptions) async throws -> [IOSBackup] {
        guard manager.fileExists(atPath: root.path) else { return [] }
        let folders = (try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        var backups: [IOSBackup] = []
        for folder in folders {
            if Task.isCancelled { throw CancellationError() }
            let info = folder.appendingPathComponent("Info.plist")
            let plist = NSDictionary(contentsOf: info) as? [String: Any]
            let size = try await reader.directoryAllocatedSize(folder, options: options)
            backups.append(IOSBackup(
                url: folder,
                deviceName: plist?["Device Name"] as? String,
                backupDate: plist?["Last Backup Date"] as? Date,
                iOSVersion: plist?["Product Version"] as? String,
                encrypted: plist?["Is Encrypted"] as? Bool,
                size: size
            ))
        }
        return backups.sorted { $0.size > $1.size }
    }
}
