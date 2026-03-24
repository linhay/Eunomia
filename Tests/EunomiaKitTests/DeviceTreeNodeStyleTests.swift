import XCTest
@testable import EunomiaKit

final class DeviceTreeNodeStyleTests: XCTestCase {
    func testUsesControllerSymbolForControllerGroupNode() {
        let node = InputNode(id: "dev1", name: "DualSense Wireless Controller", isLeaf: false)
        XCTAssertEqual(DeviceTreeNodeStyle.symbolName(for: node), "gamecontroller")
    }

    func testUsesAxisSymbolForAxisGroupNode() {
        let node = InputNode(id: "dev1-axes", name: "Axes", isLeaf: false)
        XCTAssertEqual(DeviceTreeNodeStyle.symbolName(for: node), "dial.horizontal")
    }

    func testUsesButtonSymbolForButtonGroupNode() {
        let node = InputNode(id: "dev1-buttons", name: "Buttons", isLeaf: false)
        XCTAssertEqual(DeviceTreeNodeStyle.symbolName(for: node), "button.horizontal")
    }

    func testUsesLeafSymbolForLeafNode() {
        let node = InputNode(id: "dev1~Button A", name: "Button A", isLeaf: true)
        XCTAssertEqual(DeviceTreeNodeStyle.symbolName(for: node), "smallcircle.filled.circle")
    }
}
