import XCTest
@testable import EunomiaKit

final class ControlHighlightTrackerTests: XCTestCase {
    func testControlStaysVisibleWhileActive() {
        var tracker = ControlHighlightTracker(releaseDecay: 0.2)
        let now = Date()
        tracker.handle(control: .faceSouth, isActive: true, now: now)

        let visible = tracker.visibleControls(now: now.addingTimeInterval(1.0))
        XCTAssertTrue(visible.contains(.faceSouth))
    }

    func testControlFadesAfterReleaseDecay() {
        var tracker = ControlHighlightTracker(releaseDecay: 0.2)
        let now = Date()

        tracker.handle(control: .faceEast, isActive: true, now: now)
        tracker.handle(control: .faceEast, isActive: false, now: now.addingTimeInterval(0.01))

        let stillVisible = tracker.visibleControls(now: now.addingTimeInterval(0.15))
        XCTAssertTrue(stillVisible.contains(.faceEast))

        let expired = tracker.visibleControls(now: now.addingTimeInterval(0.5))
        XCTAssertFalse(expired.contains(.faceEast))
    }

    func testRepeatedInactiveEventsDoNotKeepControlAlive() {
        var tracker = ControlHighlightTracker(releaseDecay: 0.2)
        let now = Date()

        tracker.handle(control: .dpadUp, isActive: true, now: now)
        tracker.handle(control: .dpadUp, isActive: false, now: now.addingTimeInterval(0.01))
        tracker.handle(control: .dpadUp, isActive: false, now: now.addingTimeInterval(0.19))
        tracker.handle(control: .dpadUp, isActive: false, now: now.addingTimeInterval(0.39))

        let expired = tracker.visibleControls(now: now.addingTimeInterval(0.5))
        XCTAssertFalse(expired.contains(.dpadUp))
    }
}
