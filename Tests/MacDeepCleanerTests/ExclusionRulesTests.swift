import XCTest
@testable import MacDeepCleanerCore

final class ExclusionRulesTests: XCTestCase {
    func testExcludesSystemAndExtensions() {
        let rules = ExclusionRules(
            folderPrefixes: ["/System"],
            extensions: ["tmp"],
            skipPackageContents: true,
            skipNodeModules: true,
            skipGitObjects: true,
            skipVirtualEnvironments: true
        )

        XCTAssertTrue(rules.excludes(URL(fileURLWithPath: "/System/Library/a")))
        XCTAssertTrue(rules.excludes(URL(fileURLWithPath: "/Users/me/a.tmp")))
        XCTAssertTrue(rules.excludes(URL(fileURLWithPath: "/Users/me/project/node_modules/pkg/index.js")))
        XCTAssertTrue(rules.excludes(URL(fileURLWithPath: "/Users/me/project/.git/objects/aa/bb")))
        XCTAssertTrue(rules.excludes(URL(fileURLWithPath: "/Users/me/project/.venv/bin/python")))
        XCTAssertFalse(rules.excludes(URL(fileURLWithPath: "/Users/me/Documents/report.pdf")))
    }
}
