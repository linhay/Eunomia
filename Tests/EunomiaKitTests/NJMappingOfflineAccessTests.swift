import XCTest
@testable import EunomiaKit

final class NJMappingOfflineAccessTests: XCTestCase {
    func testSetAndGetOutputByUID() {
        let mapping = NJMapping(name: "Offline")
        let uid = "111:222:1~Button 1"
        let output = NJOutputKeyPress()
        output.keyCode = 12

        mapping.setOutput(output, forUID: uid)

        let stored = mapping.output(forUID: uid) as? NJOutputKeyPress
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?.keyCode, 12)
    }

    func testSetNilOutputByUIDRemovesEntry() {
        let mapping = NJMapping(name: "Offline")
        let uid = "111:222:1~Button 2"
        let output = NJOutputKeyPress()
        output.keyCode = 14
        mapping.setOutput(output, forUID: uid)

        mapping.setOutput(nil, forUID: uid)

        XCTAssertNil(mapping.output(forUID: uid))
    }
}
