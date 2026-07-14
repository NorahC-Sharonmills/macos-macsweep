import Foundation

public enum PermissionState: String, Codable, Sendable {
    case available
    case limited
}

public struct PermissionStatus: Codable, Equatable, Sendable {
    public var fullDiskAccess: PermissionState
    public var limitedReason: String?
}

public struct PermissionService: Sendable {
    public init() {}

    public func status() -> PermissionStatus {
        let probe = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/MobileSync/Backup")
        if FileManager.default.isReadableFile(atPath: probe.path) {
            return PermissionStatus(fullDiskAccess: .available, limitedReason: nil)
        }
        return PermissionStatus(
            fullDiskAccess: .limited,
            limitedReason: "Full Disk Access may be required for Mail, Messages, iOS backups, and some Library folders."
        )
    }

    public var fullDiskAccessSettingsURL: URL {
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
    }
}
