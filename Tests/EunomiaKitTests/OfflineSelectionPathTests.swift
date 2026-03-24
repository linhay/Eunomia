import XCTest
@testable import EunomiaKit

final class OfflineSelectionPathTests: XCTestCase {
    func testOfflineInputPathUsesUIDSegments() {
        let uid = "111:222:1~Axis 1~Low"
        XCTAssertEqual(
            offlineInputPath(for: uid),
            "111:222:1 ▸ Axis 1 ▸ Low"
        )
    }

    func testOfflineInputPathFallsBackToUIDWhenNoSegments() {
        let uid = "111:222:1"
        XCTAssertEqual(
            offlineInputPath(for: uid),
            "111:222:1"
        )
    }
}
