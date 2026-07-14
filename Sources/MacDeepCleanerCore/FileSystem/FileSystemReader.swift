import Foundation

public struct FileMetadata: Sendable {
    public var url: URL
    public var size: Int64
    public var isDirectory: Bool
    public var isSymbolicLink: Bool
    public var isPackage: Bool
    public var lastModified: Date?
    public var lastAccessed: Date?
    public var typeDescription: String
}

public struct FileSystemReader {
    private let manager: FileManager
    private let keys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .isPackageKey,
        .fileSizeKey,
        .fileAllocatedSizeKey,
        .totalFileAllocatedSizeKey,
        .contentModificationDateKey,
        .contentAccessDateKey,
        .localizedTypeDescriptionKey,
        .volumeIdentifierKey,
        .isHiddenKey
    ]

    public init(manager: FileManager = .default) {
        self.manager = manager
    }

    public func metadata(for url: URL) throws -> FileMetadata {
        let values = try url.resourceValues(forKeys: keys)
        let size = Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? values.fileSize ?? 0)
        return FileMetadata(
            url: url,
            size: size,
            isDirectory: values.isDirectory ?? false,
            isSymbolicLink: values.isSymbolicLink ?? false,
            isPackage: values.isPackage ?? false,
            lastModified: values.contentModificationDate,
            lastAccessed: values.contentAccessDate,
            typeDescription: values.localizedTypeDescription ?? (values.isDirectory == true ? "Folder" : "File")
        )
    }

    public func directoryAllocatedSize(_ root: URL, options: ScanOptions) async throws -> Int64 {
        var total: Int64 = 0
        try await enumerate(root: root, options: options) { metadata in
            if !metadata.isDirectory { total += metadata.size }
        }
        return total
    }

    public func enumerate(root: URL, options: ScanOptions, visit: (FileMetadata) throws -> Void) async throws {
        let rootValues = try? root.resourceValues(forKeys: [.volumeIdentifierKey])
        let rootVolume = rootValues?.volumeIdentifier
        let enumerationOptions: FileManager.DirectoryEnumerationOptions = options.showHiddenFiles ? [] : [.skipsHiddenFiles]

        guard let enumerator = manager.enumerator(
            at: root,
            includingPropertiesForKeys: Array(keys),
            options: enumerationOptions,
            errorHandler: { _, _ in true }
        ) else { return }

        for case let url as URL in enumerator {
            if Task.isCancelled { throw CancellationError() }
            if options.exclusions.excludes(url) {
                enumerator.skipDescendants()
                continue
            }

            let metadata: FileMetadata
            do {
                metadata = try self.metadata(for: url)
            } catch {
                continue
            }

            if metadata.isSymbolicLink && !options.followSymbolicLinks {
                if metadata.isDirectory { enumerator.skipDescendants() }
                continue
            }

            if metadata.isPackage && options.exclusions.skipPackageContents {
                enumerator.skipDescendants()
            }

            if !options.scanExternalVolumes {
                let values = try? url.resourceValues(forKeys: [.volumeIdentifierKey])
                if let rootVolume, let volume = values?.volumeIdentifier, "\(volume)" != "\(rootVolume)" {
                    enumerator.skipDescendants()
                    continue
                }
            }

            try visit(metadata)
        }
    }
}
