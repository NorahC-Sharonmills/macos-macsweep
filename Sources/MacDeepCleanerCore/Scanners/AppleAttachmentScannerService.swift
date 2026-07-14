import Foundation

public struct AppleAttachmentScannerService: CleanerScanner {
    public let identifier = "apple-attachments"
    public let displayName = "Mail and Messages Attachments"
    public let riskLevel: RiskLevel = .review
    public let supportedPaths: [URL]
    private let reader: FileSystemReader
    private let manager: FileManager

    public init(home: URL = URL(fileURLWithPath: NSHomeDirectory()), reader: FileSystemReader = FileSystemReader(), manager: FileManager = .default) {
        self.supportedPaths = [
            home.appendingPathComponent("Library/Containers/com.apple.mail/Data/Library/Mail Downloads"),
            home.appendingPathComponent("Library/Messages/Attachments")
        ]
        self.reader = reader
        self.manager = manager
    }

    public func scan(options: ScanOptions) async throws -> [ScanItem] {
        var items: [ScanItem] = []
        for root in supportedPaths where manager.fileExists(atPath: root.path) {
            let category: CleanerCategory = root.path.contains("Messages") ? .messagesAttachments : .mailAttachments
            try await reader.enumerate(root: root, options: options) { metadata in
                guard !metadata.isDirectory else { return }
                items.append(ScanItem(
                    url: metadata.url,
                    size: metadata.size,
                    category: category,
                    riskLevel: .review,
                    isDirectory: false,
                    lastModified: metadata.lastModified,
                    lastAccessed: metadata.lastAccessed,
                    typeDescription: metadata.typeDescription,
                    warning: "Attachment may be user data. Review manually before cleaning."
                ))
            }
        }
        return items.sorted { $0.size > $1.size }
    }
}
