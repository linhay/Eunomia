import XCTest
@testable import EnjoyableKit

final class KeyMappingEditorStateTests: XCTestCase {
    func testMakeEditorStateForceEnableWhenNoMapping() {
        let state = makeKeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            mappedOutput: nil,
            forceEnable: true
        )

        XCTAssertTrue(state.enabled)
        XCTAssertEqual(state.keyCode, NJKeyInputFieldEmpty)
        XCTAssertEqual(state.activationThreshold, NJOutputKeyPress.defaultActivationThreshold, accuracy: 0.0001)
    }

    func testMakeEditorStateUsesMappedKeyAndThreshold() {
        let output = NJOutputKeyPress()
        output.keyCode = 36
        output.keySequence = [
            NJKeySequenceStep(keyCode: 36, delayMilliseconds: 0),
            NJKeySequenceStep(keyCode: 53, delayMilliseconds: 110)
        ]
        output.activationThreshold = 0.78

        let state = makeKeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            mappedOutput: output,
            forceEnable: false
        )

        XCTAssertTrue(state.enabled)
        XCTAssertEqual(state.keyCode, 36)
        XCTAssertEqual(state.keySequenceSteps, [
            .init(keyCode: 36, delayMilliseconds: 0),
            .init(keyCode: 53, delayMilliseconds: 110)
        ])
        XCTAssertEqual(state.activationThreshold, 0.78, accuracy: 0.0001)
    }
}
