import ComposableArchitecture

struct EunomiaRuntimeSnapshot: Equatable {
    var selectedInputID: String?
    var simulatingEvents: Bool
    var hidRunning: Bool
    var mappingNames: [String]
    var activeMappingIndex: Int
    var deviceTree: [InputNode]
    var draft: OutputDraft
    var activeInputPath: String
    var highlightedControls: Set<GamepadControl>
    var liveAxisValues: [Int: Float]
    var liveAxisLabels: [Int: String]
    var configurableControls: Set<GamepadControl>
    var hasAccessibilityPermission: Bool
    var keyMappingEditorState: KeyMappingEditorState?

    init(
        selectedInputID: String? = nil,
        simulatingEvents: Bool = false,
        hidRunning: Bool = false,
        mappingNames: [String] = [],
        activeMappingIndex: Int = 0,
        deviceTree: [InputNode] = [],
        draft: OutputDraft = OutputDraft(),
        activeInputPath: String = "",
        highlightedControls: Set<GamepadControl> = [],
        liveAxisValues: [Int: Float] = [:],
        liveAxisLabels: [Int: String] = [:],
        configurableControls: Set<GamepadControl> = [],
        hasAccessibilityPermission: Bool = false,
        keyMappingEditorState: KeyMappingEditorState? = nil
    ) {
        self.selectedInputID = selectedInputID
        self.simulatingEvents = simulatingEvents
        self.hidRunning = hidRunning
        self.mappingNames = mappingNames
        self.activeMappingIndex = activeMappingIndex
        self.deviceTree = deviceTree
        self.draft = draft
        self.activeInputPath = activeInputPath
        self.highlightedControls = highlightedControls
        self.liveAxisValues = liveAxisValues
        self.liveAxisLabels = liveAxisLabels
        self.configurableControls = configurableControls
        self.hasAccessibilityPermission = hasAccessibilityPermission
        self.keyMappingEditorState = keyMappingEditorState
    }
}

struct EunomiaRuntimeClient {
    var snapshot: @Sendable () async -> EunomiaRuntimeSnapshot
    var updates: @Sendable () async -> AsyncStream<EunomiaRuntimeSnapshot>
    var setSelectedInput: @Sendable (String?) async -> Void
    var setSimulatingEvents: @Sendable (Bool) async -> Void
    var openAccessibilitySettings: @Sendable () async -> Void
    var activateMapping: @Sendable (Int) async -> Void
    var renameActiveMapping: @Sendable (String) async -> Void
    var addMapping: @Sendable () async -> Void
    var importMapping: @Sendable () async -> Void
    var exportMapping: @Sendable () async -> Void
    var removeActiveMapping: @Sendable () async -> Void
    var moveActiveMappingUp: @Sendable () async -> Void
    var moveActiveMappingDown: @Sendable () async -> Void
    var updateDraft: @Sendable (OutputDraft) async -> Void
    var openKeyMappingEditorForInput: @Sendable (String, Bool) async -> Void
    var dismissKeyMappingEditor: @Sendable () async -> Void
    var applyKeyMappingEditorState: @Sendable (KeyMappingEditorState) async -> Void
    var quickConfigureKeyPress: @Sendable (GamepadControl) async -> Void
    var clearOutput: @Sendable (GamepadControl) async -> Void

    @MainActor
    static func live() -> Self {
        let runtimeStore = EunomiaStore()
        return Self(
            snapshot: {
                await MainActor.run {
                    runtimeStore.snapshot()
                }
            },
            updates: {
                await MainActor.run {
                    runtimeStore.snapshotStream()
                }
            },
            setSelectedInput: { id in
                await MainActor.run {
                    runtimeStore.setSelectedInput(id: id)
                }
            },
            setSimulatingEvents: { isOn in
                await MainActor.run {
                    runtimeStore.simulatingEvents = isOn
                }
            },
            openAccessibilitySettings: {
                await MainActor.run {
                    runtimeStore.openAccessibilitySettings()
                }
            },
            activateMapping: { index in
                await MainActor.run {
                    runtimeStore.activateMapping(index: index)
                }
            },
            renameActiveMapping: { name in
                await MainActor.run {
                    runtimeStore.renameActiveMapping(name)
                }
            },
            addMapping: {
                await MainActor.run {
                    runtimeStore.addMapping()
                }
            },
            importMapping: {
                await MainActor.run {
                    runtimeStore.importMapping()
                }
            },
            exportMapping: {
                await MainActor.run {
                    runtimeStore.exportMapping()
                }
            },
            removeActiveMapping: {
                await MainActor.run {
                    runtimeStore.removeActiveMapping()
                }
            },
            moveActiveMappingUp: {
                await MainActor.run {
                    runtimeStore.moveActiveMappingUp()
                }
            },
            moveActiveMappingDown: {
                await MainActor.run {
                    runtimeStore.moveActiveMappingDown()
                }
            },
            updateDraft: { next in
                await MainActor.run {
                    runtimeStore.updateDraft(next)
                }
            },
            openKeyMappingEditorForInput: { id, forceEnable in
                await MainActor.run {
                    runtimeStore.openKeyMappingEditor(forInputID: id, forceEnable: forceEnable)
                }
            },
            dismissKeyMappingEditor: {
                await MainActor.run {
                    runtimeStore.keyMappingEditorState = nil
                }
            },
            applyKeyMappingEditorState: { state in
                await MainActor.run {
                    runtimeStore.applyKeyMappingEditorState(state)
                }
            },
            quickConfigureKeyPress: { control in
                await MainActor.run {
                    runtimeStore.quickConfigureKeyPress(for: control)
                }
            },
            clearOutput: { control in
                await MainActor.run {
                    runtimeStore.clearOutput(for: control)
                }
            }
        )
    }
}

@Reducer
struct EunomiaRootFeature {
    @ObservableState
    struct State: Equatable {
        var selectedInputID: String?
        var simulatingEvents = false
        var hidRunning = false
        var mappingNames: [String] = []
        var activeMappingIndex = 0
        var deviceTree: [InputNode] = []
        var draft = OutputDraft()
        var activeInputPath = ""
        var highlightedControls: Set<GamepadControl> = []
        var liveAxisValues: [Int: Float] = [:]
        var liveAxisLabels: [Int: String] = [:]
        var configurableControls: Set<GamepadControl> = []
        var hasAccessibilityPermission = false
        var keyMappingEditor: AppleKeyMappingEditorFeature.State?
        var mappingName = ""
        var mappingRenameDraftName = ""
        var mappingDetailExpanded = true
        var inspectorExpandedRoles: Set<RootInspectorRole> = Set(RootPanelLayout.current.inspectorRoles)

        init(mappingName: String = "") {
            self.mappingName = mappingName
            self.mappingRenameDraftName = mappingName
        }

        var hasDevices: Bool {
            !deviceTree.isEmpty
        }

        var canEditOutput: Bool {
            selectedInputID != nil
        }

        mutating func apply(snapshot: EunomiaRuntimeSnapshot) {
            let hadPendingRename = mappingRenamePanelState.hasPendingChanges
            selectedInputID = snapshot.selectedInputID
            simulatingEvents = snapshot.simulatingEvents
            hidRunning = snapshot.hidRunning
            mappingNames = snapshot.mappingNames
            activeMappingIndex = snapshot.activeMappingIndex
            deviceTree = snapshot.deviceTree
            draft = snapshot.draft
            activeInputPath = snapshot.activeInputPath
            highlightedControls = snapshot.highlightedControls
            liveAxisValues = snapshot.liveAxisValues
            liveAxisLabels = snapshot.liveAxisLabels
            configurableControls = snapshot.configurableControls
            hasAccessibilityPermission = snapshot.hasAccessibilityPermission
            if let editorSnapshot = snapshot.keyMappingEditorState {
                if keyMappingEditor == nil {
                    keyMappingEditor = AppleKeyMappingEditorFeature.State(initialState: editorSnapshot)
                }
            } else {
                keyMappingEditor = nil
            }
            mappingName = snapshot.mappingNames[safe: snapshot.activeMappingIndex] ?? ""
            if !hadPendingRename {
                mappingRenameDraftName = mappingName
            }
        }

        var mappingRenamePanelState: MappingRenamePanelState {
            MappingRenamePanelState(
                currentName: mappingName,
                draftName: mappingRenameDraftName
            )
        }
    }

    enum Action: Equatable {
        case view(View)
        case observeRuntime
        case runtimeUpdated(EunomiaRuntimeSnapshot)
        case dismissKeyMappingEditor
        case keyMappingEditor(AppleKeyMappingEditorFeature.Action)
    }

    enum View: Equatable {
        case onAppear
        case setSelectedInput(String?)
        case setSimulatingEvents(Bool)
        case openAccessibilitySettings
        case openKeyMappingEditorForInput(String, forceEnable: Bool)
        case activateMapping(Int)
        case setMappingName(String)
        case setMappingRenameDraftName(String)
        case setMappingDetailExpanded(Bool)
        case resetMappingRenameDraftName
        case commitRename
        case addMapping
        case importMapping
        case exportMapping
        case removeActiveMapping
        case moveActiveMappingUp
        case moveActiveMappingDown
        case quickConfigureKeyPress(GamepadControl)
        case clearOutput(GamepadControl)
        case setOutputType(OutputType)
        case setKeyCode(UInt16)
        case setKeyThreshold(Double)
        case setKeySequenceKey(index: Int, value: UInt16)
        case setKeySequenceDelay(index: Int, value: Int)
        case appendSequenceStep
        case removeLastSequenceStep
        case setMappingIndex(Int)
        case setMouseAxis(Int32)
        case setMouseSpeed(Double)
        case setMouseButton(UInt32)
        case setScrollDirection(Int32)
        case setScrollSmooth(Bool)
        case setScrollSpeed(Double)
        case setInspectorSectionExpanded(role: RootInspectorRole, isExpanded: Bool)
    }

    private enum CancelID {
        case runtimeUpdates
    }

    private let runtime: EunomiaRuntimeClient

    init(runtime: EunomiaRuntimeClient) {
        self.runtime = runtime
    }

    @MainActor
    init() {
        self.runtime = .live()
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.observeRuntime)

            case .observeRuntime:
                return .run { [runtime] send in
                    let stream = await runtime.updates()
                    for await snapshot in stream {
                        await send(.runtimeUpdated(snapshot))
                    }
                }
                .cancellable(id: CancelID.runtimeUpdates, cancelInFlight: true)

            case let .runtimeUpdated(snapshot):
                state.apply(snapshot: snapshot)
                return .none

            case let .view(.setSelectedInput(id)):
                return runAndRefresh(id, keyPath: \.setSelectedInput)

            case let .view(.setSimulatingEvents(isOn)):
                return runAndRefresh(isOn, keyPath: \.setSimulatingEvents)

            case .view(.openAccessibilitySettings):
                return runAndRefresh(keyPath: \.openAccessibilitySettings)

            case let .view(.openKeyMappingEditorForInput(id, forceEnable)):
                return runAndRefresh(id, forceEnable, keyPath: \.openKeyMappingEditorForInput)

            case let .view(.activateMapping(index)):
                return runAndRefresh(index, keyPath: \.activateMapping)

            case let .view(.setMappingName(name)):
                state.mappingName = name
                return .none

            case let .view(.setMappingRenameDraftName(name)):
                state.mappingRenameDraftName = name
                return .none

            case let .view(.setMappingDetailExpanded(isExpanded)):
                state.mappingDetailExpanded = isExpanded
                return .none

            case .view(.resetMappingRenameDraftName):
                state.mappingRenameDraftName = state.mappingName
                return .none

            case .view(.commitRename):
                let trimmed = state.mappingName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    state.mappingName = state.mappingNames[safe: state.activeMappingIndex] ?? ""
                    state.mappingRenameDraftName = state.mappingName
                    return .none
                }
                return runAndRefresh(trimmed, keyPath: \.renameActiveMapping)

            case .view(.addMapping):
                return runAndRefresh(keyPath: \.addMapping)

            case .view(.importMapping):
                return runAndRefresh(keyPath: \.importMapping)

            case .view(.exportMapping):
                return runAndRefresh(keyPath: \.exportMapping)

            case .view(.removeActiveMapping):
                return runAndRefresh(keyPath: \.removeActiveMapping)

            case .view(.moveActiveMappingUp):
                return runAndRefresh(keyPath: \.moveActiveMappingUp)

            case .view(.moveActiveMappingDown):
                return runAndRefresh(keyPath: \.moveActiveMappingDown)

            case let .view(.quickConfigureKeyPress(control)):
                return runAndRefresh(control, keyPath: \.quickConfigureKeyPress)

            case let .view(.clearOutput(control)):
                return runAndRefresh(control, keyPath: \.clearOutput)

            case let .view(.setOutputType(nextType)):
                return updateDraft(&state) { draft in
                    draft.type = nextType
                }

            case let .view(.setKeyCode(value)):
                return updateDraftForKeyCode(&state, keyCode: value)

            case let .view(.setKeyThreshold(value)):
                return updateDraftFloat(&state, keyPath: \.keyActivationThreshold, value: value)

            case let .view(.setKeySequenceKey(index, value)):
                return updateKeySequenceStep(&state, at: index) { draft, step in
                    replaceKeySequenceStep(
                        draft: &draft,
                        index: index,
                        keyCode: value,
                        delayMilliseconds: step.delayMilliseconds
                    )
                    if index == 0 {
                        draft.keyCode = value
                    }
                }

            case let .view(.setKeySequenceDelay(index, value)):
                return updateKeySequenceStep(&state, at: index) { draft, step in
                    replaceKeySequenceStep(
                        draft: &draft,
                        index: index,
                        keyCode: step.keyCode,
                        delayMilliseconds: max(0, value)
                    )
                }

            case .view(.appendSequenceStep):
                return updateDraft(&state) { draft in
                    let seed = draft.keyCode == NJKeyInputFieldEmpty ? 0 : draft.keyCode
                    let delayMilliseconds = draft.keySequenceSteps.isEmpty ? 0 : 80
                    draft.keySequenceSteps.append(.init(keyCode: seed, delayMilliseconds: delayMilliseconds))
                }

            case .view(.removeLastSequenceStep):
                guard state.draft.keySequenceSteps.count > 1 else { return .none }
                return updateDraft(&state) { draft in
                    draft.keySequenceSteps.removeLast()
                }

            case let .view(.setMappingIndex(value)):
                return updateDraft(&state, keyPath: \.mappingIndex, value: value)

            case let .view(.setMouseAxis(value)):
                return updateDraft(&state, keyPath: \.mouseAxis, value: value)

            case let .view(.setMouseSpeed(value)):
                return updateDraftFloat(&state, keyPath: \.mouseSpeed, value: value)

            case let .view(.setMouseButton(value)):
                return updateDraft(&state, keyPath: \.mouseButton, value: value)

            case let .view(.setScrollDirection(value)):
                return updateDraft(&state, keyPath: \.scrollDirection, value: value)

            case let .view(.setScrollSmooth(value)):
                return updateDraft(&state, keyPath: \.scrollSmooth, value: value)

            case let .view(.setScrollSpeed(value)):
                return updateDraftFloat(&state, keyPath: \.scrollSpeed, value: value)

            case let .view(.setInspectorSectionExpanded(role, isExpanded)):
                var next = state.inspectorExpandedRoles
                if isExpanded {
                    next.insert(role)
                } else {
                    next.remove(role)
                }
                state.inspectorExpandedRoles = InspectorPanelExpansionState(
                    roles: RootPanelLayout.current.inspectorRoles,
                    expandedRoles: next
                ).normalizedExpandedRoles
                return .none

            case .dismissKeyMappingEditor:
                return runAndRefresh(keyPath: \.dismissKeyMappingEditor)

            case .keyMappingEditor(.delegate(.cancel)):
                return .send(.dismissKeyMappingEditor)

            case let .keyMappingEditor(.delegate(.save(editorState))):
                return runAndRefresh(editorState, keyPath: \.applyKeyMappingEditorState)

            case .keyMappingEditor:
                return .none
            }
        }
        .ifLet(\.keyMappingEditor, action: \.keyMappingEditor) {
            AppleKeyMappingEditorFeature()
        }
    }

    private func updateDraft(
        _ state: inout State,
        mutate: (inout OutputDraft) -> Void
    ) -> Effect<Action> {
        var next = state.draft
        mutate(&next)
        state.draft = next
        let draftToPersist = next

        return runAndRefresh { runtime in
            await runtime.updateDraft(draftToPersist)
        }
    }

    private func updateDraft<Value>(
        _ state: inout State,
        keyPath: WritableKeyPath<OutputDraft, Value>,
        value: Value
    ) -> Effect<Action> {
        updateDraft(&state) { draft in
            draft[keyPath: keyPath] = value
        }
    }

    private func updateDraftFloat(
        _ state: inout State,
        keyPath: WritableKeyPath<OutputDraft, Float>,
        value: Double
    ) -> Effect<Action> {
        updateDraft(&state, keyPath: keyPath, value: Float(value))
    }

    private func updateKeySequenceStep(
        _ state: inout State,
        at index: Int,
        mutate: (inout OutputDraft, NJKeySequenceStep) -> Void
    ) -> Effect<Action> {
        updateDraft(&state) { draft in
            guard draft.keySequenceSteps.indices.contains(index) else { return }
            let step = draft.keySequenceSteps[index]
            mutate(&draft, step)
        }
    }

    private func updateDraftForKeyCode(
        _ state: inout State,
        keyCode: UInt16
    ) -> Effect<Action> {
        updateDraft(&state) { draft in
            draft.keyCode = keyCode

            if draft.keySequenceSteps.isEmpty {
                if keyCode != NJKeyInputFieldEmpty {
                    draft.keySequenceSteps = [
                        NJKeySequenceStep(keyCode: keyCode, delayMilliseconds: 0)
                    ]
                }
                return
            }

            let firstDelay = draft.keySequenceSteps[0].delayMilliseconds
            replaceKeySequenceStep(
                draft: &draft,
                index: 0,
                keyCode: keyCode,
                delayMilliseconds: firstDelay
            )
        }
    }

    private func replaceKeySequenceStep(
        draft: inout OutputDraft,
        index: Int,
        keyCode: UInt16,
        delayMilliseconds: Int
    ) {
        draft.keySequenceSteps[index] = NJKeySequenceStep(
            keyCode: keyCode,
            delayMilliseconds: delayMilliseconds
        )
    }

    private func runAndRefresh(
        operation: @escaping @Sendable (EunomiaRuntimeClient) async -> Void
    ) -> Effect<Action> {
        .run { [runtime] send in
            await operation(runtime)
            await send(.runtimeUpdated(await runtime.snapshot()))
        }
    }

    private func runAndRefresh(
        keyPath: KeyPath<EunomiaRuntimeClient, @Sendable () async -> Void>
    ) -> Effect<Action> {
        runAndRefresh { runtime in
            await runtime[keyPath: keyPath]()
        }
    }

    private func runAndRefresh<Value>(
        _ value: Value,
        keyPath: KeyPath<EunomiaRuntimeClient, @Sendable (Value) async -> Void>
    ) -> Effect<Action> {
        runAndRefresh { runtime in
            await runtime[keyPath: keyPath](value)
        }
    }

    private func runAndRefresh<Value1, Value2>(
        _ value1: Value1,
        _ value2: Value2,
        keyPath: KeyPath<EunomiaRuntimeClient, @Sendable (Value1, Value2) async -> Void>
    ) -> Effect<Action> {
        runAndRefresh { runtime in
            await runtime[keyPath: keyPath](value1, value2)
        }
    }

}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
