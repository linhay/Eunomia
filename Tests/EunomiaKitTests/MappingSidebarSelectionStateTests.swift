import XCTest
@testable import EunomiaKit

final class MappingSidebarSelectionStateTests: XCTestCase {
    func testUsesExplicitSelectionWhenSelectionIsValid() {
        let state = MappingSidebarSelectionState(
            mappingNames: ["Default", "Racing", "FPS"],
            selectedIndex: 2,
            activeIndex: 1
        )

        XCTAssertEqual(state.effectiveSelectedIndex, 2)
        XCTAssertEqual(state.selectedName, "FPS")
    }

    func testFallsBackToActiveWhenSelectionIsMissing() {
        let state = MappingSidebarSelectionState(
            mappingNames: ["Default", "Racing", "FPS"],
            selectedIndex: nil,
            activeIndex: 1
        )

        XCTAssertEqual(state.effectiveSelectedIndex, 1)
        XCTAssertEqual(state.selectedName, "Racing")
    }

    func testFallsBackToFirstWhenSelectionAndActiveAreOutOfRange() {
        let state = MappingSidebarSelectionState(
            mappingNames: ["Default", "Racing"],
            selectedIndex: 6,
            activeIndex: 4
        )

        XCTAssertEqual(state.effectiveSelectedIndex, 0)
        XCTAssertEqual(state.selectedName, "Default")
    }

    func testReturnsNilWhenNoMappings() {
        let state = MappingSidebarSelectionState(
            mappingNames: [],
            selectedIndex: nil,
            activeIndex: 0
        )

        XCTAssertNil(state.effectiveSelectedIndex)
        XCTAssertEqual(state.selectedName, "")
    }
}
