import XCTest
@testable import EnjoyableKit

final class InspectorPanelNavigationStateTests: XCTestCase {
    func testUsesSelectedRoleWhenRoleIsAvailable() {
        let state = InspectorPanelNavigationState(
            roles: [.status, .mappingManager, .outputEditor],
            selectedRole: .mappingManager
        )

        XCTAssertEqual(state.effectiveRole, .mappingManager)
    }

    func testFallsBackToFirstRoleWhenSelectedRoleIsMissing() {
        let state = InspectorPanelNavigationState(
            roles: [.status, .outputEditor],
            selectedRole: .mappingManager
        )

        XCTAssertEqual(state.effectiveRole, .status)
    }

    func testReturnsNilWhenRolesAreEmpty() {
        let state = InspectorPanelNavigationState(
            roles: [],
            selectedRole: .status
        )

        XCTAssertNil(state.effectiveRole)
    }
}
