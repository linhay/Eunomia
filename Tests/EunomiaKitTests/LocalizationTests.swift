import XCTest
@testable import EunomiaKit

final class LocalizationTests: XCTestCase {
    func testLocalizedKeysResolve() {
        XCTAssertNotEqual(L10n.text("mappings_title"), "mappings_title")
        XCTAssertNotEqual(L10n.text("menu_configure_key_press"), "menu_configure_key_press")
        XCTAssertNotEqual(L10n.text("live_input"), "live_input")
    }
}
