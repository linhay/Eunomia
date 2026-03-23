import XCTest
@testable import EnjoyableKit

final class DashboardThemeTests: XCTestCase {
    func testDashboardStatusKindMapping() {
        XCTAssertEqual(dashboardStatusKind(hidRunning: false, hasDevices: true), .monitoringStopped)
        XCTAssertEqual(dashboardStatusKind(hidRunning: true, hasDevices: false), .noController)
        XCTAssertEqual(dashboardStatusKind(hidRunning: true, hasDevices: true), .liveInput)
    }

    func testDashboardStatusKindTitleKey() {
        XCTAssertEqual(DashboardStatusKind.monitoringStopped.titleKey, "input_monitoring_stopped")
        XCTAssertEqual(DashboardStatusKind.noController.titleKey, "no_game_controller_detected")
        XCTAssertEqual(DashboardStatusKind.liveInput.titleKey, "live_input")
    }

    func testStitchPalettePrimaryColorIsPlayStationBlue() {
        XCTAssertEqual(StitchPalette.primaryBlueHex, "#0072CE")
        XCTAssertEqual(StitchPalette.accentGlowHex, "#A5C8FF")
        XCTAssertEqual(StitchPalette.backgroundHex, "#111317")
    }
}
