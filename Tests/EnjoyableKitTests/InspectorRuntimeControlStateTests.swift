import XCTest
@testable import EnjoyableKit

final class InspectorRuntimeControlStateTests: XCTestCase {
    func testShowsAccessibilityHintOnlyWhenSimulationEnabledWithoutPermission() {
        XCTAssertFalse(InspectorRuntimeControlState(simulatingEvents: false, hasAccessibilityPermission: false).showsAccessibilityHint)
        XCTAssertFalse(InspectorRuntimeControlState(simulatingEvents: false, hasAccessibilityPermission: true).showsAccessibilityHint)
        XCTAssertFalse(InspectorRuntimeControlState(simulatingEvents: true, hasAccessibilityPermission: true).showsAccessibilityHint)
        XCTAssertTrue(InspectorRuntimeControlState(simulatingEvents: true, hasAccessibilityPermission: false).showsAccessibilityHint)
    }
}
