import XCTest
@testable import EunomiaKit

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

    func testEditingPayloadComparisonIgnoresIdentity() {
        let lhs = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 36,
            keySequenceSteps: [
                .init(keyCode: 36, delayMilliseconds: 0),
                .init(keyCode: 53, delayMilliseconds: 90)
            ],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        let rhs = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 36,
            keySequenceSteps: [
                .init(keyCode: 36, delayMilliseconds: 0),
                .init(keyCode: 53, delayMilliseconds: 90)
            ],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertTrue(lhs.hasSameEditingPayload(as: rhs))
    }

    func testCanEditBindingControlsRequiresResolvableAndEnabled() {
        var state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 36,
            keySequenceSteps: [.init(keyCode: 36, delayMilliseconds: 0)],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertTrue(state.canEditBindingControls)

        state.enabled = false
        XCTAssertFalse(state.canEditBindingControls)

        state.enabled = true
        state.isResolvable = false
        XCTAssertFalse(state.canEditBindingControls)
    }

    func testCanRemoveMacroStepNeedsEditableAndMultipleSteps() {
        var state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 36,
            keySequenceSteps: [.init(keyCode: 36, delayMilliseconds: 0)],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertFalse(state.canRemoveMacroStep)

        state.keySequenceSteps.append(.init(keyCode: 53, delayMilliseconds: 80))
        XCTAssertTrue(state.canRemoveMacroStep)

        state.enabled = false
        XCTAssertFalse(state.canRemoveMacroStep)
    }

    func testCanSaveChangesRequiresResolvableAndEffectiveBindingWhenEnabled() {
        var state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: NJKeyInputFieldEmpty,
            keySequenceSteps: [],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertFalse(state.canSaveChanges)

        state.keyCode = 36
        XCTAssertTrue(state.canSaveChanges)

        state.keyCode = NJKeyInputFieldEmpty
        state.enabled = false
        XCTAssertTrue(state.canSaveChanges)

        state.enabled = true
        state.isResolvable = false
        XCTAssertFalse(state.canSaveChanges)
    }

    func testCanSaveChangesAcceptsComboStepWhenPrimaryKeyEmpty() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: NJKeyInputFieldEmpty,
            keySequenceSteps: [
                .init(keys: [12, 13], delayMilliseconds: 80)
            ],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertTrue(state.canSaveChanges)
        XCTAssertEqual(state.resolvedPrimaryKeyCode, 12)
    }

    func testConfiguredMacroStepRequiresNonEmptyKeyCode() {
        var state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: NJKeyInputFieldEmpty,
            keySequenceSteps: [
                .init(keyCode: NJKeyInputFieldEmpty, delayMilliseconds: 0),
                .init(keyCode: NJKeyInputFieldEmpty, delayMilliseconds: 80)
            ],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertFalse(state.hasConfiguredMacroStep)

        state.keySequenceSteps[1] = .init(keyCode: 53, delayMilliseconds: 80)
        XCTAssertTrue(state.hasConfiguredMacroStep)
    }

    func testDiagnosticsStatusUsesResolvableVariant() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 36,
            keySequenceSteps: [.init(keyCode: 36, delayMilliseconds: 0)],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertEqual(state.diagnosticsStatusTextKey, "editor_state_resolvable")
        XCTAssertEqual(state.diagnosticsStatusSymbolName, "checkmark.circle.fill")
    }

    func testDiagnosticsStatusUsesUnresolvableVariant() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 36,
            keySequenceSteps: [.init(keyCode: 36, delayMilliseconds: 0)],
            activationThreshold: 0.55,
            isResolvable: false,
            unavailableReason: "Not supported"
        )

        XCTAssertEqual(state.diagnosticsStatusTextKey, "editor_state_unresolvable")
        XCTAssertEqual(state.diagnosticsStatusSymbolName, "exclamationmark.triangle.fill")
    }

    func testTriggerEventStepSummaryUsesReadableSingleKeyName() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 36,
            keySequenceSteps: [.init(keyCode: 36, delayMilliseconds: 80)],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        let expected = String(
            format: L10n.text("editor_trigger_events_single_summary"),
            NJKeyInputField.displayName(forKeyCode: 36),
            80
        )
        XCTAssertEqual(state.triggerEventStepSummary(for: .init(keyCode: 36, delayMilliseconds: 80)), expected)
    }

    func testTriggerEventStepSummaryUsesReadableComboKeyNames() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 12,
            keySequenceSteps: [.init(keys: [12, 13], delayMilliseconds: 120)],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        let expected = String(
            format: L10n.text("editor_trigger_events_combo_summary"),
            "\(NJKeyInputField.displayName(forKeyCode: 12)) + \(NJKeyInputField.displayName(forKeyCode: 13))",
            120
        )
        XCTAssertEqual(state.triggerEventStepSummary(for: .init(keys: [12, 13], delayMilliseconds: 120)), expected)
    }

    func testTriggerEventStepSummaryTruncatesLongComboSummary() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 12,
            keySequenceSteps: [.init(keys: [12, 13, 14], delayMilliseconds: 120)],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        let summary = state.triggerEventStepSummary(
            for: .init(keys: [12, 13, 14], delayMilliseconds: 120),
            maximumVisibleKeyNames: 2
        )

        XCTAssertTrue(summary.contains("key 0xc + key 0xd + ..."))
    }

    func testTriggerEventVisibleKeyNamesLimitsVisibleTokens() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 12,
            keySequenceSteps: [.init(keys: [12, 13, 14], delayMilliseconds: 120)],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertEqual(
            state.triggerEventVisibleKeyNames(for: .init(keys: [12, 13, 14], delayMilliseconds: 120), maximumVisibleKeyNames: 2),
            ["key 0xc", "key 0xd"]
        )
        XCTAssertEqual(
            state.triggerEventHiddenKeyCount(for: .init(keys: [12, 13, 14], delayMilliseconds: 120), maximumVisibleKeyNames: 2),
            1
        )
    }

    func testTriggerEventPrimaryAndSecondaryKeyNamesSplitCorrectly() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Button 1",
            inputPath: "Device ▸ button 1",
            enabled: true,
            keyCode: 12,
            keySequenceSteps: [.init(keys: [12, 13, 14, 15], delayMilliseconds: 120)],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        let step = NJKeySequenceStep(keys: [12, 13, 14, 15], delayMilliseconds: 120)
        XCTAssertEqual(state.triggerEventPrimaryKeyName(for: step), "key 0xc")
        XCTAssertEqual(
            state.triggerEventSecondaryKeyNames(for: step, maximumVisibleSecondaryKeyNames: 2),
            ["key 0xd", "key 0xe"]
        )
        XCTAssertEqual(
            state.triggerEventAdditionalSecondaryKeyCount(for: step, maximumVisibleSecondaryKeyNames: 2),
            1
        )
    }

    func testTriggerEventGestureModeIsHoldForSingleZeroDelayStep() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Axis 1~High",
            inputPath: "Device ▸ axis 1 ▸ high",
            enabled: true,
            keyCode: 12,
            keySequenceSteps: [.init(keys: [12, 13], delayMilliseconds: 0)],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertEqual(state.triggerEventGestureMode(forStepAt: 0), .hold)
    }

    func testTriggerEventGestureModeIsTapWhenDelayIsPositive() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Axis 1~High",
            inputPath: "Device ▸ axis 1 ▸ high",
            enabled: true,
            keyCode: 12,
            keySequenceSteps: [.init(keys: [12, 13], delayMilliseconds: 80)],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertEqual(state.triggerEventGestureMode(forStepAt: 0), .tap)
    }

    func testTriggerEventGestureModeUsesHoldOnlyForFirstStepInMultiStepSequence() {
        let state = KeyMappingEditorState(
            inputID: "1:2:1~Axis 1~High",
            inputPath: "Device ▸ axis 1 ▸ high",
            enabled: true,
            keyCode: 12,
            keySequenceSteps: [
                .init(keys: [12], delayMilliseconds: 0),
                .init(keys: [13], delayMilliseconds: 0)
            ],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        XCTAssertEqual(state.triggerEventGestureMode(forStepAt: 0), .hold)
        XCTAssertEqual(state.triggerEventGestureMode(forStepAt: 1), .tap)
    }
}
