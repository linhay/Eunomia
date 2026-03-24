import XCTest
import AppKit
import Carbon
@testable import EunomiaKit

final class KeyComboFieldCaptureTests: XCTestCase {
    func testFlagsChangedWithModifierKeepsModifierSelection() {
        let next = KeyComboField.KeyComboInputView.nextKeyCodesAfterFlagsChanged(
            currentKeyCodes: [],
            modifierFlags: [.shift],
            eventKeyCode: UInt16(kVK_Shift)
        )

        XCTAssertEqual(next, [UInt16(kVK_Shift)])
    }

    func testFlagsChangedReleaseDoesNotOverrideCompletedCombo() {
        let next = KeyComboField.KeyComboInputView.nextKeyCodesAfterFlagsChanged(
            currentKeyCodes: [UInt16(kVK_Shift), UInt16(kVK_Return)],
            modifierFlags: [],
            eventKeyCode: UInt16(kVK_Shift)
        )

        XCTAssertNil(next)
    }

    func testFlagsChangedReleaseKeepsSingleModifierKey() {
        let next = KeyComboField.KeyComboInputView.nextKeyCodesAfterFlagsChanged(
            currentKeyCodes: [UInt16(kVK_Shift)],
            modifierFlags: [],
            eventKeyCode: UInt16(kVK_Shift)
        )

        XCTAssertEqual(next, [UInt16(kVK_Shift)])
    }
}
