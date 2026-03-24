import XCTest
@testable import EunomiaKit

final class SFSymbolCompatibilityTests: XCTestCase {
    func testOutputTypeUsesCompatibleMouseButtonSymbol() {
        XCTAssertEqual(OutputType.mouseButton.icon, "cursorarrow.click")
    }

    func testTriggerSymbolsUseCompatibleFallbacks() {
        XCTAssertEqual(GamepadControl.leftTrigger.symbol, "chevron.left.circle.fill")
        XCTAssertEqual(GamepadControl.rightTrigger.symbol, "chevron.right.circle.fill")
    }
}
