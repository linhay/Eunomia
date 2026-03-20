import AppKit
import ApplicationServices
import SwiftUI

enum OutputType: String, CaseIterable, Identifiable {
    case none
    case keyPress
    case mapping
    case mouseMove
    case mouseButton
    case mouseScroll

    var id: String { rawValue }
}

struct OutputDraft: Equatable {
    struct KeyStep: Equatable {
        var keyCode: CGKeyCode
        var delayMilliseconds: Int
    }

    var type: OutputType = .none
    var keyCode: CGKeyCode = NJKeyInputFieldEmpty
    var keySequenceSteps: [KeyStep] = []
    var keyActivationThreshold: Float = NJOutputKeyPress.defaultActivationThreshold
    var mappingIndex: Int = 0
    var mouseAxis: Int32 = 0
    var mouseSpeed: Float = 10
    var mouseButton: UInt32 = 0
    var scrollDirection: Int32 = 1
    var scrollSpeed: Float = 0
    var scrollSmooth: Bool = false

    func configuredForQuickKeyPress() -> OutputDraft {
        var next = self
        next.type = .keyPress
        return next
    }

    static func from(output: NJOutput?, mappings: [NJMapping]) -> OutputDraft {
        var draft = OutputDraft()

        if let key = output as? NJOutputKeyPress {
            draft.type = .keyPress
            draft.keyCode = key.keyCode
            draft.keySequenceSteps = key.keySequence.map {
                KeyStep(keyCode: $0.keyCode, delayMilliseconds: $0.delayMilliseconds)
            }
            if draft.keySequenceSteps.isEmpty, key.keyCode != NJKeyInputFieldEmpty {
                draft.keySequenceSteps = [KeyStep(keyCode: key.keyCode, delayMilliseconds: 0)]
            }
            draft.keyActivationThreshold = key.activationThreshold
        } else if let mappingOutput = output as? NJOutputMapping {
            draft.type = .mapping
            if let mapping = mappingOutput.mapping,
               let idx = mappings.firstIndex(where: { $0 === mapping }) {
                draft.mappingIndex = idx
            }
        } else if let move = output as? NJOutputMouseMove {
            draft.type = .mouseMove
            draft.mouseAxis = move.axis
            draft.mouseSpeed = move.speed
        } else if let button = output as? NJOutputMouseButton {
            draft.type = .mouseButton
            draft.mouseButton = button.button.rawValue
        } else if let scroll = output as? NJOutputMouseScroll {
            draft.type = .mouseScroll
            draft.scrollDirection = scroll.direction
            draft.scrollSpeed = scroll.speed
            draft.scrollSmooth = scroll.smooth
        }

        return draft
    }

    func buildOutput(mappings: [NJMapping]) -> NJOutput? {
        switch type {
        case .none:
            return nil
        case .keyPress:
            let normalizedSteps = keySequenceSteps
                .filter { $0.keyCode != NJKeyInputFieldEmpty }
                .map { NJKeySequenceStep(keyCode: $0.keyCode, delayMilliseconds: max(0, $0.delayMilliseconds)) }
            let resolvedKey = keyCode != NJKeyInputFieldEmpty ? keyCode : normalizedSteps.first?.keyCode ?? NJKeyInputFieldEmpty
            guard resolvedKey != NJKeyInputFieldEmpty else { return nil }
            let output = NJOutputKeyPress()
            output.keyCode = resolvedKey
            output.keySequence = normalizedSteps
            output.activationThreshold = min(max(keyActivationThreshold, 0), 1)
            return output
        case .mapping:
            guard mappings.indices.contains(mappingIndex) else { return nil }
            let output = NJOutputMapping()
            output.mapping = mappings[mappingIndex]
            output.mappingName = mappings[mappingIndex].name
            return output
        case .mouseMove:
            let output = NJOutputMouseMove()
            output.axis = mouseAxis
            output.speed = mouseSpeed == 0 ? 10 : mouseSpeed
            return output
        case .mouseButton:
            let output = NJOutputMouseButton()
            output.button = CGMouseButton(rawValue: mouseButton) ?? .left
            return output
        case .mouseScroll:
            let output = NJOutputMouseScroll()
            output.direction = scrollDirection
            output.smooth = scrollSmooth
            output.speed = scrollSmooth ? scrollSpeed : 0
            return output
        }
    }
}

struct KeyMappingEditorState: Equatable, Identifiable {
    let id = UUID()
    var inputID: String
    var inputPath: String
    var enabled: Bool
    var keyCode: CGKeyCode
    var keySequenceSteps: [OutputDraft.KeyStep]
    var activationThreshold: Float
    var isResolvable: Bool
    var unavailableReason: String?
}

func makeKeyMappingEditorState(
    inputID: String,
    inputPath: String,
    mappedOutput: NJOutputKeyPress?,
    forceEnable: Bool
) -> KeyMappingEditorState {
    KeyMappingEditorState(
        inputID: inputID,
        inputPath: inputPath,
        enabled: forceEnable || mappedOutput != nil,
        keyCode: mappedOutput?.keyCode ?? NJKeyInputFieldEmpty,
        keySequenceSteps: {
            let steps = mappedOutput?.keySequence.map {
                OutputDraft.KeyStep(keyCode: $0.keyCode, delayMilliseconds: $0.delayMilliseconds)
            } ?? []
            if !steps.isEmpty { return steps }
            if let mapped = mappedOutput, mapped.keyCode != NJKeyInputFieldEmpty {
                return [OutputDraft.KeyStep(keyCode: mapped.keyCode, delayMilliseconds: 0)]
            }
            return []
        }(),
        activationThreshold: mappedOutput?.activationThreshold ?? NJOutputKeyPress.defaultActivationThreshold,
        isResolvable: true,
        unavailableReason: nil
    )
}

struct InputNode: Identifiable, Hashable {
    let id: String
    let name: String
    let isLeaf: Bool
    let children: [InputNode]?

    init(_ element: NJInputPathElement) {
        id = element.uid
        name = element.name
        let subs = element.children ?? []
        children = subs.isEmpty ? nil : subs.map(InputNode.init)
        isLeaf = subs.isEmpty
    }
}

enum LiveAxisParser {
    enum Direction {
        case low
        case high
    }

    static func parse(_ uid: String) -> (index: Int, direction: Direction?)? {
        let parts = uid.split(separator: "~").map(String.init)
        guard let axisPart = parts.first(where: { $0.hasPrefix("Axis ") }),
              let index = Int(axisPart.dropFirst("Axis ".count)) else {
            return nil
        }

        if let last = parts.last {
            if last == "Low" { return (index, .low) }
            if last == "High" { return (index, .high) }
        }
        return (index, nil)
    }
}

func preferredInputUID(
    for control: GamepadControl,
    from lookup: [GamepadControl: [String]],
    selectedInputID: String?,
    firstDeviceUID: String?
) -> String? {
    guard let candidates = lookup[control], !candidates.isEmpty else { return nil }

    func devicePrefix(for uid: String) -> String {
        uid.split(separator: "~").first.map(String.init) ?? uid
    }

    if let selectedInputID {
        let selectedPrefix = devicePrefix(for: selectedInputID)
        if let match = candidates.first(where: { devicePrefix(for: $0) == selectedPrefix }) {
            return match
        }
    }

    if let firstDeviceUID,
       let match = candidates.first(where: { devicePrefix(for: $0) == firstDeviceUID }) {
        return match
    }

    return candidates.first
}

@MainActor
public final class EnjoyableStore: NSObject, ObservableObject, @preconcurrency NJInputControllerDelegate, @preconcurrency NJOutputMappingActivationDelegate {
    @Published var selectedInputID: String?
    @Published var simulatingEvents = false {
        didSet {
            if simulatingEvents != oldValue {
                controller.simulatingEvents = simulatingEvents
                refreshAccessibilityPermission()
            }
        }
    }

    @Published private(set) var hidRunning = false
    @Published private(set) var mappingNames: [String] = []
    @Published private(set) var activeMappingIndex = 0
    @Published private(set) var deviceTree: [InputNode] = []
    @Published private(set) var draft = OutputDraft()
    @Published private(set) var activeInputPath = ""
    @Published private(set) var highlightedControls: Set<GamepadControl> = []
    @Published private(set) var liveAxisValues: [Int: Float] = [:]
    @Published private(set) var liveAxisLabels: [Int: String] = [:]
    @Published private(set) var configurableControls: Set<GamepadControl> = []
    @Published private(set) var hasAccessibilityPermission = AXIsProcessTrusted()
    @Published var keyMappingEditorState: KeyMappingEditorState?

    private let controller: NJInputController
    private var selectedInput: NJInput?
    private var highlightTracker = ControlHighlightTracker()
    private var highlightCleanupTimer: Timer?
    private var controlInputLookup: [GamepadControl: [String]] = [:]
    private var didBecomeActiveObserver: NSObjectProtocol?

    public override init() {
        controller = NJInputController()
        super.init()

        controller.delegate = self
        NJOutputMapping.setActivationDelegate(self)

        controller.load()
        simulatingEvents = controller.simulatingEvents
        refreshAll()
        refreshAccessibilityPermission()

        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAccessibilityPermission()
            }
        }

        if NSApplication.shared.isActive || simulatingEvents {
            controller.startHid()
        }
    }

    deinit {
        NJOutputMapping.setActivationDelegate(nil)
        highlightCleanupTimer?.invalidate()
        if let didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(didBecomeActiveObserver)
        }
    }

    var hasDevices: Bool {
        !controller.devices.isEmpty
    }

    var canEditOutput: Bool {
        selectedInput != nil
    }

    func setSelectedInput(id: String?) {
        selectedInputID = id
        guard let id,
              let element = controller.element(forUID: id),
              element.children == nil,
              let input = element as? NJInput else {
            selectedInput = nil
            activeInputPath = ""
            draft = OutputDraft()
            return
        }

        selectedInput = input
        activeInputPath = inputPath(for: input)
        draft = OutputDraft.from(output: controller.currentMapping[input], mappings: controller.mappings)
    }

    func activateMapping(index: Int) {
        guard controller.mappings.indices.contains(index) else { return }
        controller.activateMapping(controller.mappings[index])
        refreshMappingState()
        if let selectedInput {
            draft = OutputDraft.from(output: controller.currentMapping[selectedInput], mappings: controller.mappings)
        }
    }

    func renameActiveMapping(_ name: String) {
        guard controller.mappings.indices.contains(activeMappingIndex) else { return }
        controller.renameMapping(controller.mappings[activeMappingIndex], to: name)
        refreshMappingState()
    }

    func addMapping() {
        controller.addMapping(NJMapping())
        controller.activateMapping(controller.mappings.last)
        refreshAll()
    }

    func removeActiveMapping() {
        guard activeMappingIndex != 0 else { return }
        controller.removeMapping(at: activeMappingIndex)
        refreshAll()
    }

    func moveActiveMappingUp() {
        guard activeMappingIndex > 1 else { return }
        controller.moveMoveMapping(fromIndex: activeMappingIndex, toIndex: activeMappingIndex - 1)
        refreshAll()
    }

    func moveActiveMappingDown() {
        guard activeMappingIndex > 0, activeMappingIndex + 1 < controller.mappings.count else { return }
        controller.moveMoveMapping(fromIndex: activeMappingIndex, toIndex: activeMappingIndex + 1)
        refreshAll()
    }

    func updateDraft(_ next: OutputDraft) {
        draft = next
        guard let selectedInput else { return }
        controller.currentMapping[selectedInput] = next.buildOutput(mappings: controller.mappings)
        controller.save()
    }

    func refreshAccessibilityPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    func quickConfigureKeyPress(forInputID id: String) {
        let template = draft
        setSelectedInput(id: id)
        guard canEditOutput else { return }
        var next = draft.configuredForQuickKeyPress()
        if next.keyCode == NJKeyInputFieldEmpty,
           template.type == .keyPress,
           template.keyCode != NJKeyInputFieldEmpty {
            next.keyCode = template.keyCode
            next.keyActivationThreshold = template.keyActivationThreshold
            next.keySequenceSteps = template.keySequenceSteps
        }
        updateDraft(next)
    }

    func clearOutput(forInputID id: String) {
        setSelectedInput(id: id)
        guard canEditOutput else { return }
        updateDraft(OutputDraft())
    }

    func openKeyMappingEditor(forInputID id: String, forceEnable: Bool = false) {
        guard let element = controller.element(forUID: id),
              element.children == nil,
              let input = element as? NJInput else { return }

        let mappedOutput = controller.currentMapping[input] as? NJOutputKeyPress
        let inputPath = inputPath(for: input)
        keyMappingEditorState = makeKeyMappingEditorState(
            inputID: id,
            inputPath: inputPath,
            mappedOutput: mappedOutput,
            forceEnable: forceEnable
        )
    }

    func openKeyMappingEditor(for control: GamepadControl) {
        guard let id = preferredInputUIDForControl(control) else {
            keyMappingEditorState = KeyMappingEditorState(
                inputID: "",
                inputPath: "\(L10n.text("control")) \(control.title)",
                enabled: false,
                keyCode: NJKeyInputFieldEmpty,
                keySequenceSteps: [],
                activationThreshold: NJOutputKeyPress.defaultActivationThreshold,
                isResolvable: false,
                unavailableReason: L10n.text("key_detail_unavailable_hint")
            )
            return
        }
        openKeyMappingEditor(forInputID: id, forceEnable: false)
    }

    func applyKeyMappingEditorState(_ state: KeyMappingEditorState) {
        guard state.isResolvable else { return }
        setSelectedInput(id: state.inputID)
        guard canEditOutput else { return }

        let validSteps = state.keySequenceSteps.filter { $0.keyCode != NJKeyInputFieldEmpty }
        if state.enabled && (state.keyCode != NJKeyInputFieldEmpty || !validSteps.isEmpty) {
            var next = draft
            next.type = .keyPress
            next.keyCode = state.keyCode != NJKeyInputFieldEmpty ? state.keyCode : (validSteps.first?.keyCode ?? NJKeyInputFieldEmpty)
            next.keySequenceSteps = validSteps
            next.keyActivationThreshold = state.activationThreshold
            updateDraft(next)
        } else {
            updateDraft(OutputDraft())
        }
    }

    func canConfigure(control: GamepadControl) -> Bool {
        preferredInputUIDForControl(control) != nil
    }

    func quickConfigureKeyPress(for control: GamepadControl) {
        openKeyMappingEditor(for: control)
    }

    func clearOutput(for control: GamepadControl) {
        guard let id = preferredInputUIDForControl(control) else { return }
        clearOutput(forInputID: id)
    }

    private func refreshAll() {
        refreshTree()
        refreshMappingState()
        if let selectedInput {
            draft = OutputDraft.from(output: controller.currentMapping[selectedInput], mappings: controller.mappings)
            activeInputPath = inputPath(for: selectedInput)
        } else {
            activeInputPath = ""
            draft = OutputDraft()
        }
    }

    private func refreshTree() {
        deviceTree = controller.devices.map(InputNode.init)
        rebuildControlInputLookup()
        if let selectedInputID, controller.element(forUID: selectedInputID) == nil {
            setSelectedInput(id: nil)
        }
    }

    private func rebuildControlInputLookup() {
        var next: [GamepadControl: [String]] = [:]
        for device in controller.devices {
            for uid in leafInputUIDs(from: device) {
                guard let control = GamepadLayoutMapper.control(for: uid) else { continue }
                next[control, default: []].append(uid)
            }
        }
        controlInputLookup = next
        configurableControls = Set(next.keys)
    }

    private func leafInputUIDs(from element: NJInputPathElement) -> [String] {
        let children = element.children ?? []
        if children.isEmpty {
            return [element.uid]
        }
        return children.flatMap { leafInputUIDs(from: $0) }
    }

    private func preferredInputUIDForControl(_ control: GamepadControl) -> String? {
        let deviceUID = selectedInputID?.split(separator: "~").first.map(String.init) ?? controller.devices.first?.uid
        let preferredEIDs = GamepadLayoutMapper.possibleInputEIDs(for: control, deviceUID: deviceUID)

        func extractEID(from uid: String) -> String {
            let parts = uid.split(separator: "~").map(String.init)
            guard parts.count > 1 else { return uid }
            return parts.dropFirst().joined(separator: "~")
        }

        func rank(_ uid: String) -> Int {
            let eid = extractEID(from: uid)
            return preferredEIDs.firstIndex(of: eid) ?? Int.max
        }

        func pickBest(from candidates: [String], for deviceUID: String?) -> String? {
            let scoped: [String]
            if let deviceUID {
                scoped = candidates.filter { $0.hasPrefix("\(deviceUID)~") }
            } else {
                scoped = candidates
            }
            let pool = scoped.isEmpty ? candidates : scoped
            return pool.min { lhs, rhs in
                let l = rank(lhs)
                let r = rank(rhs)
                if l == r { return lhs < rhs }
                return l < r
            }
        }

        if let candidates = controlInputLookup[control], let resolved = pickBest(from: candidates, for: deviceUID) {
            return resolved
        }

        guard let deviceUID else { return nil }

        for eid in preferredEIDs {
            let uid = "\(deviceUID)~\(eid)"
            if let element = controller.element(forUID: uid), element.children == nil {
                return uid
            }
        }
        return nil
    }

    private func refreshMappingState() {
        mappingNames = controller.mappings.map(\.name)
        activeMappingIndex = controller.indexOfMapping(controller.currentMapping)
    }

    private func inputPath(for input: NJInput) -> String {
        var names = [input.name]
        var current = input.parent
        while let node = current {
            names.append(node.name)
            current = node.parent
        }
        return names.reversed().joined(separator: " ▸ ")
    }

    func outputMapping(_ output: NJOutputMapping, activate mapping: NJMapping) {
        controller.activateMapping(mapping)
        output.mappingName = mapping.name
        refreshMappingState()
    }

    func inputController(_ ic: NJInputController, didAddDevice device: NJDevice) {
        refreshTree()
    }

    func inputController(_ ic: NJInputController, didRemoveDeviceAtIndex idx: Int) {
        refreshTree()
    }

    func inputControllerDidStartHID(_ ic: NJInputController) {
        hidRunning = true
    }

    func inputControllerDidStopHID(_ ic: NJInputController) {
        hidRunning = false
        highlightTracker = ControlHighlightTracker()
        highlightedControls = []
        liveAxisValues = [:]
        liveAxisLabels = [:]
        highlightCleanupTimer?.invalidate()
        highlightCleanupTimer = nil
    }

    func inputController(_ ic: NJInputController, didInput input: NJInput) {
        updateControlHighlight(from: input)
        updateLiveAxis(from: input)
        setSelectedInput(id: input.uid)
    }

    func inputController(_ ic: NJInputController, didError error: NSError) {
        NSLog("Enjoyable error: %@", error.localizedDescription)
    }

    private func updateControlHighlight(from input: NJInput) {
        guard let control = GamepadLayoutMapper.control(for: input.uid) else { return }
        let isActive = input.active || abs(input.magnitude) > 0.001
        highlightTracker.handle(control: control, isActive: isActive)
        refreshHighlightedControls(now: Date())
        ensureHighlightCleanupTimer()
    }

    private func ensureHighlightCleanupTimer() {
        if highlightCleanupTimer != nil { return }
        highlightCleanupTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.refreshHighlightedControls(now: Date())
                if self.highlightedControls.isEmpty {
                    self.highlightCleanupTimer?.invalidate()
                    self.highlightCleanupTimer = nil
                }
            }
        }
    }

    private func refreshHighlightedControls(now: Date) {
        highlightedControls = highlightTracker.visibleControls(now: now)
    }

    private func updateLiveAxis(from input: NJInput) {
        guard let parsed = LiveAxisParser.parse(input.uid) else { return }
        liveAxisLabels[parsed.index] = "\(L10n.text("axis_label")) \(parsed.index)"

        let magnitude = min(max(abs(input.magnitude), 0), 1)
        let epsilon: Float = 0.001
        let current = liveAxisValues[parsed.index] ?? 0

        switch parsed.direction {
        case .low:
            if magnitude > epsilon {
                liveAxisValues[parsed.index] = -magnitude
            } else if current < 0 {
                liveAxisValues[parsed.index] = 0
            }
        case .high:
            if magnitude > epsilon {
                liveAxisValues[parsed.index] = magnitude
            } else if current > 0 {
                liveAxisValues[parsed.index] = 0
            }
        case nil:
            liveAxisValues[parsed.index] = input.magnitude
        }
    }
}

private struct KeyCodeField: NSViewRepresentable {
    @Binding var keyCode: UInt16
    @Binding var isEnabled: Bool

    final class Coordinator: NSObject, NJKeyInputFieldDelegate {
        @Binding var keyCode: UInt16

        init(keyCode: Binding<UInt16>) {
            _keyCode = keyCode
        }

        func keyInputField(_ keyInput: NJKeyInputField, didChangeKey keyCode: CGKeyCode) {
            self.keyCode = keyCode
        }

        func keyInputFieldDidClear(_ keyInput: NJKeyInputField) {
            keyCode = NJKeyInputFieldEmpty
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(keyCode: $keyCode)
    }

    func makeNSView(context: Context) -> NJKeyInputField {
        let view = NJKeyInputField(frame: .zero)
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: NJKeyInputField, context: Context) {
        nsView.isEnabled = isEnabled
        if nsView.keyCode != keyCode {
            nsView.keyCode = keyCode
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

public struct EnjoyableRootView: View {
    @StateObject private var store = EnjoyableStore()
    @State private var mappingName = ""

    public init() {}

    public var body: some View {
        NavigationView {
            sidebar
            detailView
        }
        .sheet(item: $store.keyMappingEditorState) { state in
            KeyMappingEditorSheet(
                initialState: state,
                onCancel: {
                    store.keyMappingEditorState = nil
                },
                onSave: { next in
                    store.applyKeyMappingEditorState(next)
                    store.keyMappingEditorState = nil
                }
            )
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: Binding(get: {
                store.activeMappingIndex
            }, set: {
                if let val = $0 {
                    store.activateMapping(index: val)
                }
            })) {
                Section(header: Text(L10n.text("mappings_title"))) {
                    ForEach(Array(store.mappingNames.enumerated()), id: \.offset) { idx, name in
                        Label(name, systemImage: "tray.full.fill")
                            .tag(idx)
                    }
                }
            }
            .listStyle(SidebarListStyle())

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button { store.addMapping() } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)

                    Button { store.removeActiveMapping() } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.plain)
                    .disabled(store.activeMappingIndex == 0)

                    Spacer()

                    Button { store.moveActiveMappingUp() } label: {
                        Image(systemName: "chevron.up")
                    }
                    .buttonStyle(.plain)
                    .disabled(store.activeMappingIndex <= 1)

                    Button { store.moveActiveMappingDown() } label: {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.plain)
                    .disabled(store.activeMappingIndex <= 0 || store.activeMappingIndex >= store.mappingNames.count - 1)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Toggle(L10n.text("simulate_events"), isOn: $store.simulatingEvents)
                        .toggleStyle(.switch)
                        .controlSize(.small)

                    if store.simulatingEvents && !store.hasAccessibilityPermission {
                        Button {
                            store.openAccessibilitySettings()
                        } label: {
                            Label(L10n.text("accessibility_permission_required"), systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .background(VisualEffectView(material: .sidebar, blendingMode: .withinWindow))
        }
        .frame(minWidth: 200, maxWidth: 300)
    }

    private var detailView: some View {
        HStack(spacing: 0) {
            // Main Content Area
            VStack(spacing: 0) {
                // Header / ToolBar
                HStack {
                    TextField(L10n.text("rename_mapping_placeholder"), text: $mappingName, onCommit: {
                        store.renameActiveMapping(mappingName)
                    })
                    .textFieldStyle(.plain)
                    .font(.title2.bold())
                    .onAppear {
                        mappingName = store.mappingNames[safe: store.activeMappingIndex] ?? ""
                    }
                    .onChange(of: store.activeMappingIndex) { _ in
                        mappingName = store.mappingNames[safe: store.activeMappingIndex] ?? ""
                    }

                    Spacer()

                    if !store.hidRunning {
                        Label(L10n.text("input_monitoring_stopped"), systemImage: "pause.circle.fill")
                            .foregroundColor(.secondary)
                    } else if !store.hasDevices {
                        Label(L10n.text("no_game_controller_detected"), systemImage: "gamecontroller.fill")
                            .foregroundColor(.secondary)
                    } else {
                        Label(L10n.text("live_input"), systemImage: "dot.circle.and.cursorarrow")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 40)
                .padding(.bottom, 16)
                .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))

                ScrollView {
                    VStack(spacing: 24) {
                        // Gamepad Visualization
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.text("controller_layout_title"))
                                .font(.headline)
                                .foregroundColor(.secondary)

                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .shadow(color: Color.black.opacity(0.05), radius: 10)

                                GamepadLayoutView(
                                    highlightedControls: store.highlightedControls,
                                    canConfigureControl: { store.canConfigure(control: $0) },
                                    onConfigureKeyPress: { store.quickConfigureKeyPress(for: $0) },
                                    onClearMapping: { store.clearOutput(for: $0) }
                                )
                                .padding()
                            }
                            .frame(height: 320)
                        }

                        // Live Monitors
                        if !store.liveAxisValues.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(L10n.text("live_axes_title"))
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(store.liveAxisValues.keys.sorted(), id: \.self) { axis in
                                        let value = store.liveAxisValues[axis] ?? 0
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(store.liveAxisLabels[axis] ?? "\(L10n.text("axis_label")) \(axis)")
                                                    .font(.caption.weight(.medium))
                                                Spacer()
                                                Text(String(format: "%.2f", value))
                                                    .font(.system(.caption, design: .monospaced))
                                                    .foregroundColor(.secondary)
                                            }
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule().fill(Color.secondary.opacity(0.1))
                                                    Capsule()
                                                        .fill(Color.accentColor)
                                                        .frame(width: geo.size.width * CGFloat((value + 1) / 2))
                                                }
                                            }
                                            .frame(height: 4)
                                        }
                                        .padding(8)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                                    }
                                }
                            }
                        }

                        // Device Tree (Optional/Advanced)
                        DisclosureGroup(L10n.text("device_list_title")) {
                            List(selection: Binding(get: {
                                store.selectedInputID
                            }, set: {
                                store.setSelectedInput(id: $0)
                            })) {
                                OutlineGroup(store.deviceTree, children: \.children) { node in
                                    HStack {
                                        Image(systemName: node.isLeaf ? "circle.fill" : "folder.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(node.isLeaf ? .accentColor : .secondary)
                                        Text(node.name)
                                            .font(.subheadline)
                                    }
                                    .tag(node.isLeaf ? Optional(node.id) : nil)
                                    .contextMenu {
                                        if node.isLeaf {
                                            Button(L10n.text("menu_key_detail")) {
                                                store.openKeyMappingEditor(forInputID: node.id, forceEnable: false)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                            .listStyle(PlainListStyle())
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .font(.headline)
                    }
                    .padding()
                }
            }
            .frame(minWidth: 400)

            Divider()

            // Inspector Area (Configuration Editor)
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.text("output_type"))
                    .font(.headline)
                    .padding()

                if store.canEditOutput {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Section {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(store.activeInputPath.isEmpty ? L10n.text("selected_input_placeholder") : store.activeInputPath)
                                        .font(.subheadline.bold())
                                        .foregroundColor(store.activeInputPath.isEmpty ? .secondary : .primary)

                                    outputEditor
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
                            }
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.3))
                        Text(L10n.text("selected_input_placeholder"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
            }
            .frame(width: 280)
            .background(VisualEffectView(material: .sidebar, blendingMode: .withinWindow))
        }
    }

    @ViewBuilder
    private var outputEditor: some View {
        Picker(L10n.text("output_type"), selection: Binding(get: {
            store.draft.type
        }, set: { value in
            var next = store.draft
            next.type = value
            store.updateDraft(next)
        })) {
            Text(L10n.text("output_none")).tag(OutputType.none)
            Text(L10n.text("output_key_press")).tag(OutputType.keyPress)
            Text(L10n.text("output_mapping")).tag(OutputType.mapping)
            Text(L10n.text("output_mouse_move")).tag(OutputType.mouseMove)
            Text(L10n.text("output_mouse_button")).tag(OutputType.mouseButton)
            Text(L10n.text("output_mouse_scroll")).tag(OutputType.mouseScroll)
        }
        .labelsHidden()

        switch store.draft.type {
        case .none:
            EmptyView()
        case .keyPress:
            HStack {
                Text("主键")
                    .font(.caption)
                    .foregroundColor(.secondary)
                KeyCodeField(keyCode: Binding(get: {
                    store.draft.keyCode
                }, set: { value in
                    var next = store.draft
                    next.keyCode = value
                    if next.keySequenceSteps.isEmpty, value != NJKeyInputFieldEmpty {
                        next.keySequenceSteps = [.init(keyCode: value, delayMilliseconds: 0)]
                    } else if !next.keySequenceSteps.isEmpty {
                        next.keySequenceSteps[0].keyCode = value
                    }
                    store.updateDraft(next)
                }), isEnabled: .constant(store.canEditOutput))
                .frame(width: 140, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                        .allowsHitTesting(false)
                )
                Spacer()
                Button("新增步骤") {
                    var next = store.draft
                    let seed = next.keyCode != NJKeyInputFieldEmpty ? next.keyCode : 0
                    next.keySequenceSteps.append(.init(keyCode: seed, delayMilliseconds: 80))
                    store.updateDraft(next)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if !store.draft.keySequenceSteps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(store.draft.keySequenceSteps.enumerated()), id: \.offset) { idx, _ in
                        HStack(spacing: 8) {
                            Text("#\(idx + 1)")
                                .font(.caption2.monospacedDigit())
                                .foregroundColor(.secondary)
                                .frame(width: 22)

                            KeyCodeField(
                                keyCode: Binding(get: {
                                    store.draft.keySequenceSteps[safe: idx]?.keyCode ?? NJKeyInputFieldEmpty
                                }, set: { value in
                                    var next = store.draft
                                    guard next.keySequenceSteps.indices.contains(idx) else { return }
                                    next.keySequenceSteps[idx].keyCode = value
                                    if idx == 0 {
                                        next.keyCode = value
                                    }
                                    store.updateDraft(next)
                                }),
                                isEnabled: .constant(store.canEditOutput)
                            )
                            .frame(width: 120, height: 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.22), lineWidth: 1)
                                    .allowsHitTesting(false)
                            )

                            Stepper(value: Binding(get: {
                                store.draft.keySequenceSteps[safe: idx]?.delayMilliseconds ?? 0
                            }, set: { value in
                                var next = store.draft
                                guard next.keySequenceSteps.indices.contains(idx) else { return }
                                next.keySequenceSteps[idx].delayMilliseconds = max(0, value)
                                store.updateDraft(next)
                            }), in: 0...3000, step: 10) {
                                Text("\(store.draft.keySequenceSteps[safe: idx]?.delayMilliseconds ?? 0)ms")
                                    .font(.caption.monospacedDigit())
                            }

                            Button {
                                var next = store.draft
                                guard next.keySequenceSteps.indices.contains(idx) else { return }
                                next.keySequenceSteps.remove(at: idx)
                                next.keyCode = next.keySequenceSteps.first?.keyCode ?? NJKeyInputFieldEmpty
                                store.updateDraft(next)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack {
                Text(L10n.text("trigger_threshold"))
                Slider(value: Binding(get: {
                    Double(store.draft.keyActivationThreshold)
                }, set: { value in
                    var next = store.draft
                    next.keyActivationThreshold = Float(value)
                    store.updateDraft(next)
                }), in: 0...1)
                Text(String(format: "%.2f", store.draft.keyActivationThreshold))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        case .mapping:
            Picker(L10n.text("output_mapping"), selection: Binding(get: {
                store.draft.mappingIndex
            }, set: { value in
                var next = store.draft
                next.mappingIndex = value
                store.updateDraft(next)
            })) {
                ForEach(Array(store.mappingNames.enumerated()), id: \.offset) { idx, name in
                    Text(name).tag(idx)
                }
            }
        case .mouseMove:
            Picker(L10n.text("direction"), selection: Binding(get: {
                store.draft.mouseAxis
            }, set: { value in
                var next = store.draft
                next.mouseAxis = value
                store.updateDraft(next)
            })) {
                Text(L10n.text("left")).tag(Int32(0))
                Text(L10n.text("right")).tag(Int32(1))
                Text(L10n.text("up")).tag(Int32(2))
                Text(L10n.text("down")).tag(Int32(3))
            }
            Slider(value: Binding(get: {
                Double(store.draft.mouseSpeed)
            }, set: { value in
                var next = store.draft
                next.mouseSpeed = Float(value)
                store.updateDraft(next)
            }), in: 1...100)
        case .mouseButton:
            Picker(L10n.text("button"), selection: Binding(get: {
                store.draft.mouseButton
            }, set: { value in
                var next = store.draft
                next.mouseButton = value
                store.updateDraft(next)
            })) {
                Text(L10n.text("left")).tag(UInt32(0))
                Text(L10n.text("right")).tag(UInt32(1))
                Text(L10n.text("middle")).tag(UInt32(2))
            }
        case .mouseScroll:
            Picker(L10n.text("direction"), selection: Binding(get: {
                store.draft.scrollDirection
            }, set: { value in
                var next = store.draft
                next.scrollDirection = value
                store.updateDraft(next)
            })) {
                Text(L10n.text("vertical_plus")).tag(Int32(1))
                Text(L10n.text("vertical_minus")).tag(Int32(-1))
                Text(L10n.text("horizontal_plus")).tag(Int32(2))
                Text(L10n.text("horizontal_minus")).tag(Int32(-2))
            }
            Toggle(L10n.text("smooth"), isOn: Binding(get: {
                store.draft.scrollSmooth
            }, set: { value in
                var next = store.draft
                next.scrollSmooth = value
                store.updateDraft(next)
            }))
            Slider(value: Binding(get: {
                Double(store.draft.scrollSpeed)
            }, set: { value in
                var next = store.draft
                next.scrollSpeed = Float(value)
                store.updateDraft(next)
            }), in: 1...100)
            .disabled(!store.draft.scrollSmooth)
        }
    }

}

private struct KeyMappingEditorSheet: View {
    @State private var state: KeyMappingEditorState
    let onCancel: () -> Void
    let onSave: (KeyMappingEditorState) -> Void

    init(
        initialState: KeyMappingEditorState,
        onCancel: @escaping () -> Void,
        onSave: @escaping (KeyMappingEditorState) -> Void
    ) {
        _state = State(initialValue: initialState)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("key_mapping_editor_title"))
                        .font(.title2.bold())
                    Text(state.inputPath)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "keyboard")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor.opacity(0.8))
            }
            .padding(24)
            .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let reason = state.unavailableReason {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text(reason)
                                .font(.callout)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.1)))
                    }

                    // Binding Status & Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.text("binding_status"))
                                .font(.headline)
                            Text(state.enabled && (state.keyCode != NJKeyInputFieldEmpty || state.keySequenceSteps.contains(where: { $0.keyCode != NJKeyInputFieldEmpty })) ? L10n.text("binding_exists") : L10n.text("binding_empty"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $state.enabled)
                            .toggleStyle(.switch)
                            .disabled(!state.isResolvable)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))

                    // Key Capture Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label(L10n.text("key_binding_title"), systemImage: "record.circle")
                                .font(.headline)
                            Spacer()
                            if state.keyCode != NJKeyInputFieldEmpty || !state.keySequenceSteps.isEmpty {
                                Button(L10n.text("clear_key")) {
                                    state.keyCode = NJKeyInputFieldEmpty
                                    state.keySequenceSteps = []
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        VStack(spacing: 12) {
                            KeyCodeField(
                                keyCode: $state.keyCode,
                                isEnabled: .constant(state.enabled)
                            )
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.textBackgroundColor))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(state.enabled ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1.5)
                            )
                            .onChange(of: state.keyCode) { value in
                                if state.keySequenceSteps.isEmpty, value != NJKeyInputFieldEmpty {
                                    state.keySequenceSteps = [.init(keyCode: value, delayMilliseconds: 0)]
                                } else if !state.keySequenceSteps.isEmpty {
                                    state.keySequenceSteps[0].keyCode = value
                                }
                            }

                            Text(L10n.text("key_binding_hint"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("顺序触发")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Button("新增步骤") {
                                let seed = state.keyCode != NJKeyInputFieldEmpty ? state.keyCode : NJKeyInputFieldEmpty
                                state.keySequenceSteps.append(.init(keyCode: seed, delayMilliseconds: 80))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(!state.enabled)
                        }

                        if !state.keySequenceSteps.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(state.keySequenceSteps.enumerated()), id: \.offset) { idx, _ in
                                    HStack(spacing: 8) {
                                        Text("#\(idx + 1)")
                                            .font(.caption.monospacedDigit())
                                            .foregroundColor(.secondary)
                                            .frame(width: 24)

                                        KeyCodeField(
                                            keyCode: Binding(get: {
                                                state.keySequenceSteps[safe: idx]?.keyCode ?? NJKeyInputFieldEmpty
                                            }, set: { value in
                                                guard state.keySequenceSteps.indices.contains(idx) else { return }
                                                state.keySequenceSteps[idx].keyCode = value
                                                if idx == 0 {
                                                    state.keyCode = value
                                                }
                                            }),
                                            isEnabled: .constant(state.enabled)
                                        )
                                        .frame(width: 140, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(NSColor.textBackgroundColor))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(state.enabled ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
                                        )

                                        Stepper(value: Binding(get: {
                                            state.keySequenceSteps[safe: idx]?.delayMilliseconds ?? 0
                                        }, set: { value in
                                            guard state.keySequenceSteps.indices.contains(idx) else { return }
                                            state.keySequenceSteps[idx].delayMilliseconds = max(0, value)
                                        }), in: 0...3000, step: 10) {
                                            Text("\(state.keySequenceSteps[safe: idx]?.delayMilliseconds ?? 0)ms")
                                                .font(.caption.monospacedDigit())
                                        }

                                        Button {
                                            guard state.keySequenceSteps.indices.contains(idx) else { return }
                                            state.keySequenceSteps.remove(at: idx)
                                            state.keyCode = state.keySequenceSteps.first?.keyCode ?? NJKeyInputFieldEmpty
                                        } label: {
                                            Image(systemName: "minus.circle")
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
                    .opacity(state.enabled ? 1.0 : 0.6)

                    // Threshold Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label(L10n.text("trigger_threshold"), systemImage: "gauge.medium")
                            .font(.headline)

                        HStack(spacing: 16) {
                            Slider(value: Binding(get: {
                                Double(state.activationThreshold)
                            }, set: { value in
                                state.activationThreshold = Float(value)
                            }), in: 0...1)
                            .disabled(!state.enabled)

                            Text(String(format: "%.2f", state.activationThreshold))
                                .font(.system(.body, design: .monospaced).bold())
                                .foregroundColor(state.enabled ? .primary : .secondary)
                                .frame(width: 48)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.secondary.opacity(0.1)))
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
                    .opacity(state.enabled ? 1.0 : 0.6)
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Spacer()
                Button(L10n.text("cancel"), action: onCancel)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().stroke(Color.secondary.opacity(0.3), lineWidth: 1))

                Button(action: { onSave(state) }) {
                    Text(L10n.text("save"))
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(state.isResolvable ? Color.accentColor : Color.secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!state.isResolvable)
                .keyboardShortcut(.defaultAction)
            }
            .padding(24)
            .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
        }
        .frame(width: 480, height: 600)
        .background(VisualEffectView(material: .sidebar, blendingMode: .withinWindow))
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
