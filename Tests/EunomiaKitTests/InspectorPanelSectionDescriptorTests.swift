import XCTest
@testable import EunomiaKit

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

    func testBuildMapsToExpectedSubtitleKeys() {
        let sections = InspectorPanelSectionDescriptor.build(
            from: [.status, .mappingManager, .outputEditor]
        )

        XCTAssertEqual(
            sections.map(\.subtitleKey),
            [
                "inspector_status_subtitle",
                "inspector_mappings_subtitle",
                "inspector_output_subtitle"
            ]
        )
    }
}
