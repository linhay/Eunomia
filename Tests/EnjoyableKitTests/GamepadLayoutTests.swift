import XCTest
@testable import EnjoyableKit

final class GamepadLayoutTests: XCTestCase {
    func testButtonMapping() {
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Button 1"), .faceSouth)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Button 4"), .faceNorth)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Button 10"), .start)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Button 12"), .rightStickPress)
    }

    func testAxisMapping() {
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Axis 1~Low"), .leftStickLeft)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Axis 1~High"), .leftStickRight)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Axis 2~Low"), .leftStickUp)
        XCTAssertEqual(GamepadLayoutMapper.control(for: "123:456:1~Axis 4~High"), .rightStickDown)
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
}
