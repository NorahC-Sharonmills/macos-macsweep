import XCTest
@testable import MacDeepCleanerCore

final class DuplicateScannerTests: XCTestCase {
    func testFindsDuplicatesWithoutLoadingWholeFileIntent() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }
        try fixture.write("same", to: "Một.txt")
        try fixture.write("same", to: "Hai.txt")
        try fixture.write("different", to: "Ba.txt")

        let scanner = DuplicateScannerService(supportedPaths: [fixture.root])
        let groups = try await scanner.duplicateGroups(options: ScanOptions(minimumFileSize: 0))

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].files.count, 2)
        XCTAssertEqual(Set(groups[0].files.map { $0.url.lastPathComponent }), ["Một.txt", "Hai.txt"])
    }
}
