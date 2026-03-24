import XCTest
@testable import EunomiaKit

final class RootPanelLayoutTests: XCTestCase {
    func testCurrentLayoutPlacesDeviceRuntimeInSidebar() {
        XCTAssertEqual(RootPanelLayout.current.sidebarRole, .deviceRuntime)
    }

    func testCurrentLayoutPlacesMappingManagerInInspector() {
        XCTAssertEqual(
            RootPanelLayout.current.inspectorRoles,
            [.status, .mappingManager, .outputEditor]
        )
    }
}
