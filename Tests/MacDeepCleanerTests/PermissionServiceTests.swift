import XCTest
@testable import MacDeepCleanerCore

final class PermissionServiceTests: XCTestCase {
    func testSettingsURLUsesAppleSystemPreferencesScheme() {
        let url = PermissionService().fullDiskAccessSettingsURL
        XCTAssertEqual(url.scheme, "x-apple.systempreferences")
    }
}
