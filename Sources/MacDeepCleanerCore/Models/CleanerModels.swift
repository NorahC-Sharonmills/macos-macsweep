import Foundation

public enum CleanerCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case applications = "Applications"
    case downloads = "Downloads"
    case documents = "Documents"
    case developerFiles = "Developer Files"
    case cache = "Cache"
    case logs = "Logs"
    case iOSBackups = "iOS Backups"
    case mailAttachments = "Mail Attachments"
    case messagesAttachments = "Messages Attachments"
    case largeFiles = "Large Files"
    case oldFiles = "Old Files"
    case duplicateFiles = "Duplicate Files"
    case applicationLeftovers = "Application Leftovers"
    case storage = "Storage"

    public var id: String { rawValue }
}

public enum RiskLevel: String, CaseIterable, Codable, Sendable {
    case safe = "Safe"
    case review = "Review"
    case doNotDelete = "Do Not Delete"
}

public enum SortOption: String, CaseIterable, Codable, Sendable {
    case size = "Size"
    case name = "Name"
    case lastModified = "Last Modified"
    case lastAccessed = "Last Accessed"
    case fileType = "File Type"
}

public struct ScanItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var url: URL
    public var size: Int64
    public var category: CleanerCategory
    public var riskLevel: RiskLevel
    public var isDirectory: Bool
    public var lastModified: Date?
    public var lastAccessed: Date?
    public var typeDescription: String
    public var warning: String?

    public init(
        id: UUID = UUID(),
        url: URL,
        size: Int64,
        category: CleanerCategory,
        riskLevel: RiskLevel,
        isDirectory: Bool,
        lastModified: Date? = nil,
        lastAccessed: Date? = nil,
        typeDescription: String = "File",
        warning: String? = nil
    ) {
        self.id = id
        self.url = url
        self.size = size
        self.category = category
        self.riskLevel = riskLevel
        self.isDirectory = isDirectory
        self.lastModified = lastModified
        self.lastAccessed = lastAccessed
        self.typeDescription = typeDescription
        self.warning = warning
    }
}

public struct DiskUsage: Codable, Equatable, Sendable {
    public var total: Int64
    public var used: Int64
    public var free: Int64
    public var reclaimable: Int64

    public init(total: Int64, used: Int64, free: Int64, reclaimable: Int64 = 0) {
        self.total = total
        self.used = used
        self.free = free
        self.reclaimable = reclaimable
    }
}

public struct ScanOptions: Codable, Equatable, Sendable {
    public var minimumFileSize: Int64
    public var oldFileDays: Int
    public var followSymbolicLinks: Bool
    public var scanExternalVolumes: Bool
    public var scanNetworkVolumes: Bool
    public var showHiddenFiles: Bool
    public var developerMode: Bool
    public var exclusions: ExclusionRules

    public init(
        minimumFileSize: Int64 = 100 * 1024 * 1024,
        oldFileDays: Int = 180,
        followSymbolicLinks: Bool = false,
        scanExternalVolumes: Bool = false,
        scanNetworkVolumes: Bool = false,
        showHiddenFiles: Bool = false,
        developerMode: Bool = false,
        exclusions: ExclusionRules = .default
    ) {
        self.minimumFileSize = minimumFileSize
        self.oldFileDays = oldFileDays
        self.followSymbolicLinks = followSymbolicLinks
        self.scanExternalVolumes = scanExternalVolumes
        self.scanNetworkVolumes = scanNetworkVolumes
        self.showHiddenFiles = showHiddenFiles
        self.developerMode = developerMode
        self.exclusions = exclusions
    }
}

public struct ExclusionRules: Codable, Equatable, Sendable {
    public var folderPrefixes: [String]
    public var extensions: [String]
    public var skipPackageContents: Bool
    public var skipNodeModules: Bool
    public var skipGitObjects: Bool
    public var skipVirtualEnvironments: Bool

    public static let `default` = ExclusionRules(
        folderPrefixes: ["/System", "/private/var/db", "/Library/Apple", "/Library/SystemExtensions"],
        extensions: [],
        skipPackageContents: true,
        skipNodeModules: true,
        skipGitObjects: true,
        skipVirtualEnvironments: true
    )

    public init(
        folderPrefixes: [String],
        extensions: [String],
        skipPackageContents: Bool,
        skipNodeModules: Bool,
        skipGitObjects: Bool,
        skipVirtualEnvironments: Bool
    ) {
        self.folderPrefixes = folderPrefixes
        self.extensions = extensions
        self.skipPackageContents = skipPackageContents
        self.skipNodeModules = skipNodeModules
        self.skipGitObjects = skipGitObjects
        self.skipVirtualEnvironments = skipVirtualEnvironments
    }

    public func excludes(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        if folderPrefixes.contains(where: { path == $0 || path.hasPrefix($0 + "/") }) { return true }
        if extensions.contains(url.pathExtension.lowercased()) { return true }
        let parts = Set(path.split(separator: "/").map(String.init))
        if skipNodeModules && parts.contains("node_modules") { return true }
        if skipVirtualEnvironments && (parts.contains(".venv") || parts.contains("venv")) { return true }
        if skipGitObjects && path.contains("/.git/objects/") { return true }
        return false
    }
}

public protocol CleanerScanner {
    var identifier: String { get }
    var displayName: String { get }
    var riskLevel: RiskLevel { get }
    var supportedPaths: [URL] { get }
    func scan(options: ScanOptions) async throws -> [ScanItem]
}
