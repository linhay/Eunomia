import XCTest
@testable import EunomiaKit

final class MappingSidebarContextActionStateTests: XCTestCase {
    func testDefaultMappingCannotBeRemovedOrMoved() {
        let state = MappingSidebarContextActionState(index: 0, totalCount: 3)

        XCTAssertFalse(state.canRemove)
        XCTAssertFalse(state.canMoveUp)
        XCTAssertFalse(state.canMoveDown)
    }

    func testMiddleMappingCanBeRemovedAndMovedBothDirections() {
        let state = MappingSidebarContextActionState(index: 1, totalCount: 4)

        XCTAssertTrue(state.canRemove)
        XCTAssertFalse(state.canMoveUp)
        XCTAssertTrue(state.canMoveDown)
    }

    func testNonDefaultMappingCanMoveUpWhenNotNearTop() {
        let state = MappingSidebarContextActionState(index: 2, totalCount: 4)

        XCTAssertTrue(state.canRemove)
        XCTAssertTrue(state.canMoveUp)
        XCTAssertTrue(state.canMoveDown)
    }

    func testLastMappingCannotMoveDown() {
        let state = MappingSidebarContextActionState(index: 3, totalCount: 4)

        XCTAssertTrue(state.canRemove)
        XCTAssertTrue(state.canMoveUp)
        XCTAssertFalse(state.canMoveDown)
    }
}
