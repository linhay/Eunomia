import ComposableArchitecture
import XCTest
@testable import EnjoyableKit

@MainActor
final class AppleKeyMappingEditorFeatureTests: XCTestCase {
    func testSetKeySequenceKeysDeduplicatesAndSyncsPrimaryKey() async {
        let initial = KeyMappingEditorState(
            inputID: "preview~button~1",
            inputPath: "DualSense 5 / Button 1",
            enabled: true,
            keyCode: NJKeyInputFieldEmpty,
            keySequenceSteps: [
                NJKeySequenceStep(keys: [], delayMilliseconds: 0)
            ],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        let store = TestStore(initialState: AppleKeyMappingEditorFeature.State(initialState: initial)) {
            AppleKeyMappingEditorFeature()
        }

        await store.send(.setKeySequenceKeys(index: 0, keys: [0x00, 0x00, 0x0B])) {
            $0.draft.keyCode = 0x00
            $0.draft.keySequenceSteps[0] = NJKeySequenceStep(keys: [0x00, 0x0B], delayMilliseconds: 0)
        }
    }

    func testRemoveStepNormalizesSelection() async {
        let initial = KeyMappingEditorState(
            inputID: "preview~button~1",
            inputPath: "DualSense 5 / Button 1",
            enabled: true,
            keyCode: 0x00,
            keySequenceSteps: [
                NJKeySequenceStep(keys: [0x00], delayMilliseconds: 0),
                NJKeySequenceStep(keys: [0x0B], delayMilliseconds: 80)
            ],
            activationThreshold: 0.55,
            isResolvable: true,
            unavailableReason: nil
        )

        var state = AppleKeyMappingEditorFeature.State(initialState: initial)
        state.selectedStepIndex = 1

        let store = TestStore(initialState: state) {
            AppleKeyMappingEditorFeature()
        }

        await store.send(.removeStep) {
            $0.draft.keySequenceSteps = [
                NJKeySequenceStep(keys: [0x00], delayMilliseconds: 0)
            ]
            $0.selectedStepIndex = 0
        }
    }
}
