import XCTest
@testable import MacDeepCleanerCore

final class FileScannerTests: XCTestCase {
    func testScannerSkipsSymlinkByDefault() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }
        try fixture.write("hello", to: "alive.txt")
        let link = fixture.root.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: fixture.root)

        let scanner = FileScannerService(supportedPaths: [fixture.root])
        let items = try await scanner.scan(options: ScanOptions(followSymbolicLinks: false, showHiddenFiles: true))

        XCTAssertTrue(items.contains { $0.url.lastPathComponent == "alive.txt" })
        XCTAssertFalse(items.contains { $0.url.lastPathComponent == "link" })
    }

    func testScannerToleratesFileDeletedDuringScan() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }
        for index in 0..<200 {
            try fixture.write("value-\(index)", to: "file-\(index).txt")
        }
        let victim = fixture.root.appendingPathComponent("file-42.txt")
        let scanner = FileScannerService(supportedPaths: [fixture.root])

        async let items = scanner.scan(options: ScanOptions(showHiddenFiles: true))
        try? FileManager.default.removeItem(at: victim)

        _ = try await items
    }

    #if os(macOS)
    func testScannerToleratesUnreadableFile() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }
        try fixture.write("secret", to: "no-read.txt")
        let file = fixture.root.appendingPathComponent("no-read.txt")
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: file.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path) }

        let scanner = FileScannerService(supportedPaths: [fixture.root])
        _ = try await scanner.scan(options: ScanOptions(showHiddenFiles: true))
    }
    #endif
}
