import ComposableArchitecture
import XCTest
@testable import EnjoyableKit

@MainActor
final class EnjoyableRootFeatureTests: XCTestCase {
    private func makeStoreWithDraftSnapshot(
        _ snapshot: LockIsolated<EnjoyableRuntimeSnapshot>
    ) -> TestStoreOf<EnjoyableRootFeature> {
        var initialState = EnjoyableRootFeature.State()
        initialState.apply(snapshot: snapshot.value)

        return TestStore(initialState: initialState) {
            EnjoyableRootFeature(
                runtime: makeRuntime(
                    snapshot: { snapshot.value },
                    updates: {
                        AsyncStream { continuation in
                            continuation.finish()
                        }
                    },
                    updateDraft: { next in
                        snapshot.withValue { value in
                            value.draft = next
                        }
                    }
                )
            )
        }
    }

    private func makeRuntime(
        snapshot: @escaping @Sendable () async -> EnjoyableRuntimeSnapshot,
        updates: (@Sendable () async -> AsyncStream<EnjoyableRuntimeSnapshot>)? = nil,
        setSelectedInput: @escaping @Sendable (String?) async -> Void = { _ in },
        setSimulatingEvents: @escaping @Sendable (Bool) async -> Void = { _ in },
        openAccessibilitySettings: @escaping @Sendable () async -> Void = {},
        activateMapping: @escaping @Sendable (Int) async -> Void = { _ in },
        renameActiveMapping: @escaping @Sendable (String) async -> Void = { _ in },
        addMapping: @escaping @Sendable () async -> Void = {},
        removeActiveMapping: @escaping @Sendable () async -> Void = {},
        moveActiveMappingUp: @escaping @Sendable () async -> Void = {},
        moveActiveMappingDown: @escaping @Sendable () async -> Void = {},
        updateDraft: @escaping @Sendable (OutputDraft) async -> Void = { _ in },
        openKeyMappingEditorForInput: @escaping @Sendable (String, Bool) async -> Void = { _, _ in },
        dismissKeyMappingEditor: @escaping @Sendable () async -> Void = {},
        applyKeyMappingEditorState: @escaping @Sendable (KeyMappingEditorState) async -> Void = { _ in },
        quickConfigureKeyPress: @escaping @Sendable (GamepadControl) async -> Void = { _ in },
        clearOutput: @escaping @Sendable (GamepadControl) async -> Void = { _ in }
    ) -> EnjoyableRuntimeClient {
        let updatesStream = updates ?? {
            AsyncStream { continuation in
                Task {
                    continuation.yield(await snapshot())
                    continuation.finish()
                }
            }
        }

        return .init(
            snapshot: snapshot,
            updates: updatesStream,
            setSelectedInput: setSelectedInput,
            setSimulatingEvents: setSimulatingEvents,
            openAccessibilitySettings: openAccessibilitySettings,
            activateMapping: activateMapping,
            renameActiveMapping: renameActiveMapping,
            addMapping: addMapping,
            removeActiveMapping: removeActiveMapping,
            moveActiveMappingUp: moveActiveMappingUp,
            moveActiveMappingDown: moveActiveMappingDown,
            updateDraft: updateDraft,
            openKeyMappingEditorForInput: openKeyMappingEditorForInput,
            dismissKeyMappingEditor: dismissKeyMappingEditor,
            applyKeyMappingEditorState: applyKeyMappingEditorState,
            quickConfigureKeyPress: quickConfigureKeyPress,
            clearOutput: clearOutput
        )
    }

    func testOnAppearLoadsSnapshot() async {
        let snapshot = EnjoyableRuntimeSnapshot(
            selectedInputID: "dev~Button 1",
            simulatingEvents: true,
            hidRunning: true,
            mappingNames: ["Default"],
            activeMappingIndex: 0,
            deviceTree: [InputNode(id: "dev", name: "Device", isLeaf: false)],
            draft: OutputDraft(type: .keyPress, keyCode: 12),
            activeInputPath: "Device ▸ Button 1",
            highlightedControls: [],
            liveAxisValues: [:],
            liveAxisLabels: [:],
            configurableControls: [],
            hasAccessibilityPermission: true,
            keyMappingEditorState: nil
        )

        let store = TestStore(initialState: EnjoyableRootFeature.State()) {
            EnjoyableRootFeature(
                runtime: makeRuntime(
                    snapshot: { snapshot }
                )
            )
        }

        await store.send(.view(.onAppear))
        await store.receive(.observeRuntime)
        await store.receive(.runtimeUpdated(snapshot)) {
            $0.selectedInputID = "dev~Button 1"
            $0.simulatingEvents = true
            $0.hidRunning = true
            $0.mappingNames = ["Default"]
            $0.activeMappingIndex = 0
            $0.deviceTree = [InputNode(id: "dev", name: "Device", isLeaf: false)]
            $0.draft = OutputDraft(type: .keyPress, keyCode: 12)
            $0.activeInputPath = "Device ▸ Button 1"
            $0.hasAccessibilityPermission = true
            $0.mappingName = "Default"
        }
    }

    func testCommitRenameTrimsAndCallsRuntime() async {
        let calls = LockIsolated([String]())
        let snapshot = LockIsolated(
            EnjoyableRuntimeSnapshot(
                mappingNames: ["Default"],
                activeMappingIndex: 0
            )
        )

        let store = TestStore(initialState: EnjoyableRootFeature.State(mappingName: "Default")) {
            EnjoyableRootFeature(
                runtime: makeRuntime(
                    snapshot: { snapshot.value },
                    updates: {
                        AsyncStream { continuation in
                            continuation.finish()
                        }
                    },
                    renameActiveMapping: { name in
                        calls.withValue { $0.append(name) }
                        snapshot.withValue { value in
                            value.mappingNames[0] = name
                        }
                    }
                )
            )
        }

        await store.send(.view(.setMappingName("  Arcade  "))) {
            $0.mappingName = "  Arcade  "
        }

        await store.send(.view(.commitRename))
        await store.receive(.runtimeUpdated(snapshot.value)) {
            $0.mappingNames = ["Arcade"]
            $0.activeMappingIndex = 0
            $0.mappingName = "Arcade"
        }

        XCTAssertEqual(calls.value, ["Arcade"])
    }

    func testDismissKeyMappingEditorClearsEditorState() async {
        let dismissCalls = LockIsolated(0)
        let snapshot = LockIsolated(
            EnjoyableRuntimeSnapshot(
                keyMappingEditorState: KeyMappingEditorState(
                    inputID: "dev~Button 1",
                    inputPath: "Device ▸ Button 1",
                    enabled: true,
                    keyCode: 12,
                    keySequenceSteps: [],
                    activationThreshold: 0.3,
                    isResolvable: true,
                    unavailableReason: nil
                )
            )
        )

        let initialState = KeyMappingEditorState(
            inputID: "dev~Button 1",
            inputPath: "Device ▸ Button 1",
            enabled: true,
            keyCode: 12,
            keySequenceSteps: [],
            activationThreshold: 0.3,
            isResolvable: true,
            unavailableReason: nil
        )

        var featureState = EnjoyableRootFeature.State()
        featureState.keyMappingEditorState = initialState

        let store = TestStore(initialState: featureState) {
            EnjoyableRootFeature(
                runtime: makeRuntime(
                    snapshot: { snapshot.value },
                    updates: {
                        AsyncStream { continuation in
                            continuation.finish()
                        }
                    },
                    dismissKeyMappingEditor: {
                        dismissCalls.withValue { $0 += 1 }
                        snapshot.withValue { value in
                            value.keyMappingEditorState = nil
                        }
                    }
                )
            )
        }

        await store.send(.dismissKeyMappingEditor)
        await store.receive(.runtimeUpdated(snapshot.value)) {
            $0.keyMappingEditorState = nil
        }

        XCTAssertEqual(dismissCalls.value, 1)
    }

    func testSetKeySequenceDelayClampsToZero() async {
        let snapshot = LockIsolated(
            EnjoyableRuntimeSnapshot(
                draft: OutputDraft(
                    type: .keyPress,
                    keyCode: 12,
                    keySequenceSteps: [
                        NJKeySequenceStep(keyCode: 12, delayMilliseconds: 80)
                    ]
                )
            )
        )

        let store = makeStoreWithDraftSnapshot(snapshot)

        await store.send(.view(.setKeySequenceDelay(index: 0, value: -1)))
        await store.receive(.runtimeUpdated(snapshot.value)) {
            $0.draft.keySequenceSteps[0] = NJKeySequenceStep(
                keyCode: 12,
                delayMilliseconds: 0
            )
        }
    }

    func testSetKeyCodeSyncsFirstSequenceStep() async {
        let snapshot = LockIsolated(
            EnjoyableRuntimeSnapshot(
                draft: OutputDraft(
                    type: .keyPress,
                    keyCode: 7,
                    keySequenceSteps: [
                        NJKeySequenceStep(keyCode: 7, delayMilliseconds: 120)
                    ]
                )
            )
        )

        let store = makeStoreWithDraftSnapshot(snapshot)

        await store.send(.view(.setKeyCode(23)))
        await store.receive(.runtimeUpdated(snapshot.value)) {
            $0.draft.keyCode = 23
            $0.draft.keySequenceSteps[0] = NJKeySequenceStep(
                keyCode: 23,
                delayMilliseconds: 120
            )
        }
    }

    func testSetKeyCodeCreatesFirstSequenceStepWhenMissing() async {
        let snapshot = LockIsolated(
            EnjoyableRuntimeSnapshot(
                draft: OutputDraft(
                    type: .keyPress,
                    keyCode: NJKeyInputFieldEmpty,
                    keySequenceSteps: []
                )
            )
        )

        let store = makeStoreWithDraftSnapshot(snapshot)

        await store.send(.view(.setKeyCode(31)))
        await store.receive(.runtimeUpdated(snapshot.value)) {
            $0.draft.keyCode = 31
            $0.draft.keySequenceSteps = [
                NJKeySequenceStep(keyCode: 31, delayMilliseconds: 0)
            ]
        }
    }

    func testSetKeySequenceDelayOutOfBoundsKeepsDraftUnchanged() async {
        let snapshot = LockIsolated(
            EnjoyableRuntimeSnapshot(
                draft: OutputDraft(
                    type: .keyPress,
                    keyCode: 12,
                    keySequenceSteps: [
                        NJKeySequenceStep(keyCode: 12, delayMilliseconds: 80)
                    ]
                )
            )
        )

        let previous = snapshot.value.draft
        let store = makeStoreWithDraftSnapshot(snapshot)

        await store.send(.view(.setKeySequenceDelay(index: 9, value: 250)))
        await store.receive(.runtimeUpdated(snapshot.value)) {
            $0.draft = previous
        }
    }

    func testSetEmptyKeyCodeDoesNotCreateFirstSequenceStep() async {
        let snapshot = LockIsolated(
            EnjoyableRuntimeSnapshot(
                draft: OutputDraft(
                    type: .keyPress,
                    keyCode: NJKeyInputFieldEmpty,
                    keySequenceSteps: []
                )
            )
        )

        let store = makeStoreWithDraftSnapshot(snapshot)

        await store.send(.view(.setKeyCode(NJKeyInputFieldEmpty)))
        await store.receive(.runtimeUpdated(snapshot.value)) {
            $0.draft.keyCode = NJKeyInputFieldEmpty
            $0.draft.keySequenceSteps = []
        }
    }
}
