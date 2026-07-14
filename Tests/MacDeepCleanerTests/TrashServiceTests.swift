import Foundation
import XCTest
@testable import MacDeepCleanerCore

private final class MockTrashPerformer: TrashPerforming {
    var moved: [URL] = []

    func trashItem(at url: URL) throws {
        moved.append(url)
    }
}

final class TrashServiceTests: XCTestCase {
    func testBlocksSystemPaths() {
        let service = TrashService(performer: MockTrashPerformer())
        let item = ScanItem(
            url: URL(fileURLWithPath: "/System/Library/file"),
            size: 10,
            category: .storage,
            riskLevel: .review,
            isDirectory: false
        )

        XCTAssertThrowsError(try service.moveToTrash([item]))
    }

    func testMockTrashReceivesItems() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }
        try fixture.write("x", to: "delete-me.txt")
        let file = fixture.root.appendingPathComponent("delete-me.txt")
        let performer = MockTrashPerformer()
        let service = TrashService(performer: performer)
        let item = ScanItem(url: file, size: 1, category: .cache, riskLevel: .safe, isDirectory: false)

        let summary = try service.moveToTrash([item])

        XCTAssertEqual(summary.count, 1)
        XCTAssertEqual(performer.moved, [file])
    }
}
