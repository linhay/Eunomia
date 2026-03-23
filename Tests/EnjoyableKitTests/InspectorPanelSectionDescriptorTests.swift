import XCTest
@testable import EnjoyableKit

final class InspectorPanelSectionDescriptorTests: XCTestCase {
    func testBuildPreservesRoleOrder() {
        let sections = InspectorPanelSectionDescriptor.build(
            from: [.mappingManager, .status, .outputEditor]
        )

        XCTAssertEqual(
            sections.map(\.role),
            [.mappingManager, .status, .outputEditor]
        )
    }

    func testBuildMapsToExpectedTitleKeys() {
        let sections = InspectorPanelSectionDescriptor.build(
            from: [.status, .mappingManager, .outputEditor]
        )

        XCTAssertEqual(
            sections.map(\.titleKey),
            ["status_title", "mappings_title", "output_editor_title"]
        )
    }
}
