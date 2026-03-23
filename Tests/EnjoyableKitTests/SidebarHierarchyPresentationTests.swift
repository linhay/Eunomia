import XCTest
@testable import EnjoyableKit

final class SidebarHierarchyPresentationTests: XCTestCase {
    func testDeviceTreeProjectionFlattensIntoTwoLevels() {
        let source: [InputNode] = [
            InputNode(
                id: "controller-1",
                name: "Controller 1",
                isLeaf: false,
                children: [
                    InputNode(
                        id: "controller-1-buttons",
                        name: "Buttons",
                        isLeaf: false,
                        children: [
                            InputNode(id: "controller-1~Button A", name: "Button A", isLeaf: true),
                            InputNode(id: "controller-1~Button B", name: "Button B", isLeaf: true)
                        ]
                    ),
                    InputNode(
                        id: "controller-1-axes",
                        name: "Axes",
                        isLeaf: false,
                        children: [
                            InputNode(id: "controller-1~Axis 1", name: "Axis 1", isLeaf: true)
                        ]
                    )
                ]
            )
        ]

        let projected = DeviceRuntimeSidebarHierarchy.project(source)

        XCTAssertEqual(maxDepth(of: projected), 2)
        XCTAssertEqual(projected.count, 1)
        XCTAssertEqual(projected[0].children?.count, 3)
    }

    func testDeviceTreeProjectionKeepsLeafIdentityAndContext() {
        let source: [InputNode] = [
            InputNode(
                id: "controller-1",
                name: "Controller 1",
                isLeaf: false,
                children: [
                    InputNode(
                        id: "controller-1-buttons",
                        name: "Buttons",
                        isLeaf: false,
                        children: [
                            InputNode(id: "controller-1~Button A", name: "Button A", isLeaf: true)
                        ]
                    )
                ]
            )
        ]

        let projected = DeviceRuntimeSidebarHierarchy.project(source)
        let leaf = projected.first?.children?.first

        XCTAssertEqual(leaf?.id, "controller-1~Button A")
        XCTAssertEqual(leaf?.name, "Buttons · Button A")
        XCTAssertEqual(leaf?.isLeaf, true)
    }

    private func maxDepth(of nodes: [InputNode], current: Int = 1) -> Int {
        let childDepths = nodes.compactMap { node -> Int? in
            guard let children = node.children, !children.isEmpty else { return nil }
            return maxDepth(of: children, current: current + 1)
        }
        return childDepths.max() ?? current
    }
}
