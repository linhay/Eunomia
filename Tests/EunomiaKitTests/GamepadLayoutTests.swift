import XCTest
@testable import EunomiaKit

final class GamepadLayoutTests: XCTestCase {
    func testButtonMapping() {
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Button 1"), .faceSouth)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Button 4"), .faceNorth)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Button 10"), .start)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Button 12"), .rightStickPress)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Button 13"), .home)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Button 14"), .touchpad)
    }

    func testSonyFaceButtonMapping() {
        XCTAssertEqual(GamepadLayoutMapper.control(for: "1356:3302:1~Button 1"), .faceWest)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "1356:3302:1~Button 2"), .faceSouth)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "1356:3302:1~Button 3"), .faceEast)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "1356:3302:1~Button 4"), .faceNorth)
    }

    func testAxisMapping() {
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Axis 1~Low"), .leftStickLeft)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Axis 1~High"), .leftStickRight)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Axis 2~Low"), .leftStickUp)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Axis 4~High"), .rightStickDown)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Axis 5~High"), .leftTrigger)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Axis 6~Low"), .rightTrigger)
    }

    func testHatMapping() {
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Hat Switch 1~Up"), .dpadUp)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Hat Switch 1~Right"), .dpadRight)
    }

    func testUnknownInputReturnsNil() {
        XCTAssertNil(GamepadLayoutMapper.control(for: "123:456:1~Button 99"))
        XCTAssertNil(GamepadLayoutMapper.control(for: "123:456:1~Axis 9~Low"))
        XCTAssertNil(GamepadLayoutMapper.control(for: "123:456:1"))
    }

    func testAccessibilityLabelUsesReadableControlName() {
        XCTAssertEqual(GamepadControl.faceSouth.accessibilityLabel(controlPrefix: "Control"), "Control A")
        XCTAssertEqual(GamepadControl.dpadUp.accessibilityLabel(controlPrefix: "Control"), "Control D-Pad Up")
        XCTAssertEqual(GamepadControl.rightTrigger.accessibilityLabel(controlPrefix: "Control"), "Control Right Trigger")
    }

    func testAccessibilityIdentifiersAreStable() {
        XCTAssertEqual(GamepadControl.faceSouth.accessibilityIdentifier, "gamepad.control.faceSouth")
        XCTAssertEqual(GamepadControl.touchpad.accessibilityIdentifier, "gamepad.control.touchpad")
    }
}
