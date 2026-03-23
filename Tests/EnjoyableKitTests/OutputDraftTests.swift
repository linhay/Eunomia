import XCTest
@testable import EnjoyableKit

final class OutputDraftTests: XCTestCase {
    func testFromKeyOutput() {
        let output = NJOutputKeyPress()
        output.keyCode = 42
        output.activationThreshold = 0.7
        output.keySequence = [
            NJKeySequenceStep(keyCode: 42, delayMilliseconds: 0),
            NJKeySequenceStep(keyCode: 13, delayMilliseconds: 90)
        ]

        let draft = OutputDraft.from(output: output, mappings: [])
        XCTAssertEqual(draft.type, .keyPress)
        XCTAssertEqual(draft.keyCode, 42)
        XCTAssertEqual(draft.keySequenceSteps, [
            .init(keyCode: 42, delayMilliseconds: 0),
            .init(keyCode: 13, delayMilliseconds: 90)
        ])
        XCTAssertEqual(draft.keyActivationThreshold, 0.7, accuracy: 0.0001)
    }

    func testBuildKeyOutputIncludesThreshold() {
        var draft = OutputDraft()
        draft.type = .keyPress
        draft.keyCode = 36
        draft.keySequenceSteps = [
            .init(keyCode: 36, delayMilliseconds: 0),
            .init(keyCode: 53, delayMilliseconds: 140)
        ]
        draft.keyActivationThreshold = 0.65

        let built = draft.buildOutput(mappings: []) as? NJOutputKeyPress
        XCTAssertEqual(built?.keyCode, 36)
        XCTAssertNotNil(built)
        XCTAssertEqual(built?.keySequence, [
            .init(keyCode: 36, delayMilliseconds: 0),
            .init(keyCode: 53, delayMilliseconds: 140)
        ])
        XCTAssertEqual(built!.activationThreshold, 0.65, accuracy: 0.0001)
    }

    func testBuildKeyOutputSupportsComboStep() {
        var draft = OutputDraft()
        draft.type = .keyPress
        draft.keyCode = NJKeyInputFieldEmpty
        draft.keySequenceSteps = [
            .init(keys: [18, 19], delayMilliseconds: 120)
        ]
        draft.keyActivationThreshold = 0.4

        let built = draft.buildOutput(mappings: []) as? NJOutputKeyPress
        XCTAssertNotNil(built)
        XCTAssertEqual(built?.keyCode, 18)
        XCTAssertEqual(built?.keySequence, [
            .init(keys: [18, 19], delayMilliseconds: 120)
        ])
    }

    func testBuildMouseMoveOutput() {
        var draft = OutputDraft()
        draft.type = .mouseMove
        draft.mouseAxis = 3
        draft.mouseSpeed = 27

        let built = draft.buildOutput(mappings: []) as? NJOutputMouseMove
        XCTAssertNotNil(built)
        XCTAssertEqual(built?.axis, 3)
        XCTAssertEqual(built?.speed, 27)
    }

    func testBuildMappingOutputUsesSelectedIndex() {
        let first = NJMapping(name: "A")
        let second = NJMapping(name: "B")

        var draft = OutputDraft()
        draft.type = .mapping
        draft.mappingIndex = 1

        let built = draft.buildOutput(mappings: [first, second]) as? NJOutputMapping
        XCTAssertTrue(built?.mapping === second)
        XCTAssertEqual(built?.mappingName, "B")
    }

    func testScrollSpeedIsZeroWhenNotSmooth() {
        var draft = OutputDraft()
        draft.type = .mouseScroll
        draft.scrollSmooth = false
        draft.scrollSpeed = 90

        let built = draft.buildOutput(mappings: []) as? NJOutputMouseScroll
        XCTAssertNotNil(built)
        XCTAssertEqual(built?.smooth, false)
        XCTAssertEqual(built?.speed, 0)
    }

    func testQuickKeyPressConfigurationKeepsExistingKeyAndThreshold() {
        var draft = OutputDraft()
        draft.type = .none
        draft.keyCode = 40
        draft.keyActivationThreshold = 0.66

        let configured = draft.configuredForQuickKeyPress()
        XCTAssertEqual(configured.type, .keyPress)
        XCTAssertEqual(configured.keyCode, 40)
        XCTAssertEqual(configured.keyActivationThreshold, 0.66, accuracy: 0.0001)
    }
}
