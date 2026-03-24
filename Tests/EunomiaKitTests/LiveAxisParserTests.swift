import XCTest
@testable import EunomiaKit

final class LiveAxisParserTests: XCTestCase {
    func testParseAxisWithLowDirection() {
        let parsed = LiveAxisParser.parse("123:456:1~Axis 3~Low")
        XCTAssertEqual(parsed?.index, 3)
        XCTAssertEqual(parsed?.direction, .low)
    }

    func testParseAxisWithHighDirection() {
        let parsed = LiveAxisParser.parse("123:456:1~Axis 4~High")
        XCTAssertEqual(parsed?.index, 4)
        XCTAssertEqual(parsed?.direction, .high)
    }

    func testParseAxisParentUID() {
        let parsed = LiveAxisParser.parse("123:456:1~Axis 2")
        XCTAssertEqual(parsed?.index, 2)
        XCTAssertNil(parsed?.direction)
    }

    func testParseNonAxisUIDReturnsNil() {
        XCTAssertNil(LiveAxisParser.parse("123:456:1~Button 5"))
        XCTAssertNil(LiveAxisParser.parse("123:456:1~Hat Switch 1~Up"))
    }
}
