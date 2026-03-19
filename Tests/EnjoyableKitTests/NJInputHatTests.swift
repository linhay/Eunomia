import XCTest
@testable import EnjoyableKit

final class NJInputHatTests: XCTestCase {
    func testEightWayNeutralReturnsAllInactive() {
        let states = hatActiveStates(parsed: 8, maxValue: 7)
        XCTAssertEqual(states, [false, false, false, false])
    }

    func testOutOfRangeInputReturnsAllInactive() {
        let states = hatActiveStates(parsed: 999, maxValue: 7)
        XCTAssertEqual(states, [false, false, false, false])
    }

    func testFourWayRightDirection() {
        let states = hatActiveStates(parsed: 1, maxValue: 3)
        XCTAssertEqual(states, [false, false, false, true])
    }
}
