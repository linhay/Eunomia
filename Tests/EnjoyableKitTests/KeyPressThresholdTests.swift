import XCTest
@testable import EnjoyableKit

final class KeyPressThresholdTests: XCTestCase {
    func testKeyPressSerializationRoundTripIncludesThreshold() {
        let output = NJOutputKeyPress()
        output.keyCode = 12
        output.activationThreshold = 0.72
        output.keySequence = [
            NJKeySequenceStep(keyCode: 12, delayMilliseconds: 0),
            NJKeySequenceStep(keyCode: 13, delayMilliseconds: 120)
        ]

        let serialized = output.serialize()
        let restored = NJOutputKeyPress.output(withSerialization: serialized) as? NJOutputKeyPress

        XCTAssertEqual(restored?.keyCode, 12)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored!.activationThreshold, 0.72, accuracy: 0.0001)
        XCTAssertEqual(restored?.keySequence, [
            NJKeySequenceStep(keyCode: 12, delayMilliseconds: 0),
            NJKeySequenceStep(keyCode: 13, delayMilliseconds: 120)
        ])
        XCTAssertNotNil(serialized?["steps"])
        XCTAssertNil(serialized?["sequence"])
    }

    func testKeyPressDeserializationDefaultsThresholdWhenThresholdMissing() {
        let serializedWithoutThreshold: [String: Any] = ["type": "key press", "key": 42]
        let restored = NJOutputKeyPress.output(withSerialization: serializedWithoutThreshold) as? NJOutputKeyPress
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored!.activationThreshold, NJOutputKeyPress.defaultActivationThreshold, accuracy: 0.0001)
        XCTAssertEqual(restored?.keySequence, [
            NJKeySequenceStep(keyCode: 42, delayMilliseconds: 0)
        ])
    }

    func testKeyPressDeserializationReadsLegacySequenceShape() {
        let legacy: [String: Any] = [
            "type": "key press",
            "key": 12,
            "sequence": [
                ["key": 12, "delayMs": 0],
                ["key": 13, "delayMs": 80]
            ]
        ]

        let restored = NJOutputKeyPress.output(withSerialization: legacy) as? NJOutputKeyPress
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.keySequence, [
            NJKeySequenceStep(keyCode: 12, delayMilliseconds: 0),
            NJKeySequenceStep(keyCode: 13, delayMilliseconds: 80)
        ])
    }

    func testKeyPressSerializationRoundTripWithComboStep() {
        let output = NJOutputKeyPress()
        output.activationThreshold = 0.58
        output.keySequence = [
            NJKeySequenceStep(keys: [12, 13], delayMilliseconds: 90)
        ]

        let serialized = output.serialize()
        let restored = NJOutputKeyPress.output(withSerialization: serialized) as? NJOutputKeyPress
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.keySequence, [
            NJKeySequenceStep(keys: [12, 13], delayMilliseconds: 90)
        ])
        XCTAssertEqual(restored?.keyCode, 12)
    }

    func testThresholdActivationForAxisLowInput() {
        let root = NJInputPathElement(name: "root", eid: "1:1:1", parent: nil)
        let axis = NJInputPathElement(name: "axis", eid: "Axis 5", parent: root)
        let low = NJInput(name: "low", eid: "Low", parent: axis)
        low.magnitude = 0.69

        let output = NJOutputKeyPress()
        output.activationThreshold = 0.7
        XCTAssertFalse(shouldRunOutput(output, with: low))

        low.magnitude = 0.71
        XCTAssertTrue(shouldRunOutput(output, with: low))
    }

    func testNonAxisInputStillUsesActiveState() {
        let root = NJInputPathElement(name: "root", eid: "1:1:1", parent: nil)
        let button = NJInput(name: "button", eid: "Button 1", parent: root)
        button.active = false
        button.magnitude = 1

        let output = NJOutputKeyPress()
        output.activationThreshold = 0.1
        XCTAssertFalse(shouldRunOutput(output, with: button))

        button.active = true
        XCTAssertTrue(shouldRunOutput(output, with: button))
    }

    func testHoldSemanticsEnabledForSingleZeroDelayComboStep() {
        let output = NJOutputKeyPress()
        let sequence = [NJKeySequenceStep(keys: [12, 13], delayMilliseconds: 0)]

        XCTAssertTrue(output.usesHoldSemantics(for: sequence))
    }

    func testHoldSemanticsDisabledWhenDelayIsPositive() {
        let output = NJOutputKeyPress()
        let sequence = [NJKeySequenceStep(keys: [12, 13], delayMilliseconds: 80)]

        XCTAssertFalse(output.usesHoldSemantics(for: sequence))
    }

    func testHoldSemanticsDisabledForMultipleSteps() {
        let output = NJOutputKeyPress()
        let sequence = [
            NJKeySequenceStep(keys: [12], delayMilliseconds: 0),
            NJKeySequenceStep(keys: [13], delayMilliseconds: 0)
        ]

        XCTAssertFalse(output.usesHoldSemantics(for: sequence))
    }
}
