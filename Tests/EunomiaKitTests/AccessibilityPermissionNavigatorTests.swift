import ApplicationServices
import XCTest
@testable import EunomiaKit

final class AccessibilityPermissionNavigatorTests: XCTestCase {
    func testPromptOptionsContainsTrustedPromptKey() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as CFString
        let options = AccessibilityPermissionNavigator.promptOptions

        XCTAssertEqual(options.count, 1)
        XCTAssertEqual(options[key] as? Bool, true)
    }
}
