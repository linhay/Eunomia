import XCTest
@testable import EnjoyableKit

final class ControlContextRoutingTests: XCTestCase {
    func testPreferredInputUsesSelectedDeviceFirst() {
        let lookup: [GamepadControl: [String]] = [
            .faceSouth: [
                "111:222:1~Button 1",
                "333:444:1~Button 1"
            ]
        ]

        let preferred = preferredInputUID(
            for: .faceSouth,
            from: lookup,
            selectedInputID: "333:444:1~Axis 1~Low",
            firstDeviceUID: "111:222:1"
        )

        XCTAssertEqual(preferred, "333:444:1~Button 1")
    }

    func testPreferredInputFallsBackToFirstDevice() {
        let lookup: [GamepadControl: [String]] = [
            .faceSouth: [
                "111:222:1~Button 1",
                "333:444:1~Button 1"
            ]
        ]

        let preferred = preferredInputUID(
            for: .faceSouth,
            from: lookup,
            selectedInputID: nil,
            firstDeviceUID: "111:222:1"
        )

        XCTAssertEqual(preferred, "111:222:1~Button 1")
    }
}
