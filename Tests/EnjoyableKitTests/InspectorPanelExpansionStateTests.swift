import XCTest
@testable import EnjoyableKit

final class InspectorPanelExpansionStateTests: XCTestCase {
    func testKeepsExpandedRolesWhenStillAvailable() {
        let state = InspectorPanelExpansionState(
            roles: [.status, .mappingManager, .outputEditor],
            expandedRoles: [.mappingManager]
        )

        XCTAssertEqual(state.normalizedExpandedRoles, [.mappingManager])
    }

    func testDropsUnavailableExpandedRoles() {
        let state = InspectorPanelExpansionState(
            roles: [.status, .outputEditor],
            expandedRoles: [.mappingManager, .status]
        )

        XCTAssertEqual(state.normalizedExpandedRoles, [.status])
    }

    func testFallsBackToExpandAllWhenNothingIsExpanded() {
        let state = InspectorPanelExpansionState(
            roles: [.status, .outputEditor],
            expandedRoles: []
        )

        XCTAssertEqual(state.normalizedExpandedRoles, [.status, .outputEditor])
    }
}
