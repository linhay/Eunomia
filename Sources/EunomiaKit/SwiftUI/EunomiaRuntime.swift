import AppKit
import ApplicationServices
import Combine
import Carbon
import SwiftUI
import UniformTypeIdentifiers

enum OutputType: String, CaseIterable, Identifiable {
    case none
    case keyPress
    case mapping
    case mouseMove
    case mouseButton
    case mouseScroll

    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "slash.circle"
        case .keyPress: return "keyboard"
        case .mapping: return "tray.2"
        case .mouseMove: return "cursorarrow.motionlines"
        case .mouseButton: return "cursorarrow.click"
        case .mouseScroll: return "scroll"
        }
    }
}

enum StitchPalette {
    static let primaryBlueHex = "#0072CE"
    static let accentGlowHex = "#A5C8FF"
    static let backgroundHex = "#111317"

    static let background = Color(red: 17 / 255, green: 19 / 255, blue: 23 / 255)
    static let surfaceLowest = Color(red: 12 / 255, green: 14 / 255, blue: 18 / 255)
    static let surfaceLow = Color(red: 26 / 255, green: 28 / 255, blue: 32 / 255)
    static let surface = Color(red: 30 / 255, green: 32 / 255, blue: 36 / 255)
    static let surfaceHigh = Color(red: 40 / 255, green: 42 / 255, blue: 46 / 255)
    static let stroke = Color(red: 65 / 255, green: 71 / 255, blue: 82 / 255)
    static let primaryBlue = Color(red: 0 / 255, green: 114 / 255, blue: 206 / 255)
    static let accentGlow = Color(red: 165 / 255, green: 200 / 255, blue: 255 / 255)
    static let textPrimary = Color(red: 226 / 255, green: 226 / 255, blue: 232 / 255)
    static let textSecondary = Color(red: 193 / 255, green: 199 / 255, blue: 212 / 255)
}

enum DashboardStatusKind: Equatable {
    case monitoringStopped
    case noController
    case liveInput

    var titleKey: String {
        switch self {
        case .monitoringStopped: return "input_monitoring_stopped"
        case .noController: return "no_game_controller_detected"
        case .liveInput: return "live_input"
        }
    }

    var icon: String {
        switch self {
        case .monitoringStopped: return "pause.circle"
        case .noController: return "exclamationmark.triangle"
        case .liveInput: return "dot.radiowaves.left.and.right"
        }
    }

    var tint: Color {
        switch self {
        case .monitoringStopped:
            return StitchPalette.textSecondary
        case .noController:
            return .orange
        case .liveInput:
            return StitchPalette.accentGlow
        }
    }
}

enum AccessibilityPermissionNavigator {
    static var promptOptions: [CFString: Any] {
        [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as CFString: true]
    }

    static func openAccessibilitySettingsPrompt() {
        _ = AXIsProcessTrustedWithOptions(promptOptions as CFDictionary)
    }
}

func dashboardStatusKind(hidRunning: Bool, hasDevices: Bool) -> DashboardStatusKind {
    if !hidRunning { return .monitoringStopped }
    if !hasDevices { return .noController }
    return .liveInput
}

struct OutputDraft: Equatable {
    var type: OutputType = .none
    var keyCode: CGKeyCode = NJKeyInputFieldEmpty
    var keySequenceSteps: [NJKeySequenceStep] = []
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
            draft.keySequenceSteps = key.keySequence
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
            let sanitizedSequence = keySequenceSteps
                .map { step in
                    let keys = step.keys.filter { $0 != NJKeyInputFieldEmpty }
                    return NJKeySequenceStep(keys: keys, delayMilliseconds: max(0, step.delayMilliseconds))
                }
                .filter { !$0.keys.isEmpty }
            guard keyCode != NJKeyInputFieldEmpty || !sanitizedSequence.isEmpty else { return nil }
            let output = NJOutputKeyPress()
            output.keyCode = keyCode != NJKeyInputFieldEmpty ? keyCode : (sanitizedSequence.first?.keys.first ?? NJKeyInputFieldEmpty)
            output.keySequence = sanitizedSequence
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
    var keySequenceSteps: [NJKeySequenceStep]
    var activationThreshold: Float
    var isResolvable: Bool
    var unavailableReason: String?
}

extension KeyMappingEditorState {
    enum TriggerGestureMode {
        case hold
        case tap

        var textKey: String {
            switch self {
            case .hold:
                return "editor_trigger_events_mode_hold"
            case .tap:
                return "editor_trigger_events_mode_tap"
            }
        }
    }

    var diagnosticsStatusTextKey: String {
        isResolvable ? "editor_state_resolvable" : "editor_state_unresolvable"
    }

    var diagnosticsStatusSymbolName: String {
        isResolvable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    var hasConfiguredMacroStep: Bool {
        keySequenceSteps.contains(where: { !$0.keys.filter({ $0 != NJKeyInputFieldEmpty }).isEmpty })
    }

    var resolvedPrimaryKeyCode: CGKeyCode {
        if keyCode != NJKeyInputFieldEmpty { return keyCode }
        return keySequenceSteps
            .compactMap { $0.keys.first(where: { $0 != NJKeyInputFieldEmpty }) }
            .first ?? NJKeyInputFieldEmpty
    }

    func hasSameEditingPayload(as other: Self) -> Bool {
        inputID == other.inputID &&
            inputPath == other.inputPath &&
            enabled == other.enabled &&
            keyCode == other.keyCode &&
            keySequenceSteps == other.keySequenceSteps &&
            activationThreshold == other.activationThreshold &&
            isResolvable == other.isResolvable &&
            unavailableReason == other.unavailableReason
    }

    var canEditBindingControls: Bool {
        isResolvable && enabled
    }

    var canRemoveMacroStep: Bool {
        canEditBindingControls && keySequenceSteps.count > 1
    }

    var canSaveChanges: Bool {
        guard isResolvable else { return false }
        guard enabled else { return true }
        return resolvedPrimaryKeyCode != NJKeyInputFieldEmpty
    }

    func displayName(for keyCode: CGKeyCode) -> String? {
        guard keyCode != NJKeyInputFieldEmpty else { return nil }
        let name = NJKeyInputField.displayName(forKeyCode: keyCode)
        return name.isEmpty ? nil : name
    }

    func triggerEventStepSummary(for step: NJKeySequenceStep, maximumVisibleKeyNames: Int = 3) -> String {
        let keyNames = triggerEventVisibleKeyNames(for: step, maximumVisibleKeyNames: maximumVisibleKeyNames)

        guard !keyNames.isEmpty else {
            return L10n.text("editor_trigger_events_empty_summary")
        }

        let keySummary = keyNames.joined(separator: " + ") + (triggerEventHiddenKeyCount(for: step, maximumVisibleKeyNames: maximumVisibleKeyNames) > 0 ? " + ..." : "")
        if effectiveKeyNames(for: step).count == 1 {
            return String(
                format: L10n.text("editor_trigger_events_single_summary"),
                keySummary,
                step.delayMilliseconds
            )
        }

        return String(
            format: L10n.text("editor_trigger_events_combo_summary"),
            keySummary,
            step.delayMilliseconds
        )
    }

    func effectiveKeyNames(for step: NJKeySequenceStep) -> [String] {
        step.keys
            .filter { $0 != NJKeyInputFieldEmpty }
            .compactMap(displayName(for:))
    }

    func triggerEventVisibleKeyNames(for step: NJKeySequenceStep, maximumVisibleKeyNames: Int = 3) -> [String] {
        Array(effectiveKeyNames(for: step).prefix(max(1, maximumVisibleKeyNames)))
    }

    func triggerEventHiddenKeyCount(for step: NJKeySequenceStep, maximumVisibleKeyNames: Int = 3) -> Int {
        let all = effectiveKeyNames(for: step)
        return max(0, all.count - max(1, maximumVisibleKeyNames))
    }

    func triggerEventPrimaryKeyName(for step: NJKeySequenceStep) -> String? {
        effectiveKeyNames(for: step).first
    }

    func triggerEventSecondaryKeyNames(for step: NJKeySequenceStep, maximumVisibleSecondaryKeyNames: Int = 2) -> [String] {
        let secondary = Array(effectiveKeyNames(for: step).dropFirst())
        return Array(secondary.prefix(max(0, maximumVisibleSecondaryKeyNames)))
    }

    func triggerEventAdditionalSecondaryKeyCount(for step: NJKeySequenceStep, maximumVisibleSecondaryKeyNames: Int = 2) -> Int {
        let secondary = Array(effectiveKeyNames(for: step).dropFirst())
        return max(0, secondary.count - max(0, maximumVisibleSecondaryKeyNames))
    }

    func triggerEventGestureMode(forStepAt index: Int) -> TriggerGestureMode {
        guard keySequenceSteps.indices.contains(index) else { return .tap }
        if index == 0 && keySequenceSteps[index].delayMilliseconds == 0 {
            return .hold
        }
        return .tap
    }
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
        keySequenceSteps: mappedOutput?.keySequence ?? [],
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

    init(
        id: String,
        name: String,
        isLeaf: Bool,
        children: [InputNode]? = nil
    ) {
        self.id = id
        self.name = name
        self.isLeaf = isLeaf
        self.children = children
    }
}

enum DeviceTreeNodeStyle {
    static func symbolName(for node: InputNode) -> String {
        if node.isLeaf {
            return "smallcircle.filled.circle"
        }

        let lowerName = node.name.lowercased()
        if lowerName.contains("controller") || lowerName.contains("gamepad") {
            return "gamecontroller"
        }
        if lowerName.contains("axis") || lowerName.contains("axes") {
            return "dial.horizontal"
        }
        if lowerName.contains("button") || lowerName.contains("buttons") {
            return "button.horizontal"
        }
        return "list.bullet"
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

private enum MappingSuiteTransfer {
    static let format = "enjoyable.mapping-suite"
    static let version = 1
    static let formatKey = "format"
    static let versionKey = "version"
    static let mappingsKey = "mappings"
    static let selectedKey = "selected"

    static func payload(mappings: [[String: Any]], selectedIndex: Int) -> [String: Any] {
        [
            formatKey: format,
            versionKey: version,
            mappingsKey: mappings,
            selectedKey: max(0, selectedIndex)
        ]
    }

    static func decode(jsonObject: Any) -> (mappings: [[String: Any]], selectedIndex: Int)? {
        if let payload = jsonObject as? [String: Any],
           let mappings = payload[mappingsKey] as? [[String: Any]] {
            let selected = (payload[selectedKey] as? NSNumber)?.intValue ?? 0
            return (mappings, max(0, selected))
        }

        // Backward compatibility: accept raw mappings array payload.
        if let mappings = jsonObject as? [[String: Any]] {
            return (mappings, 0)
        }
        return nil
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

func offlineInputPath(for uid: String) -> String {
    let parts = uid.split(separator: "~").map(String.init).filter { !$0.isEmpty }
    guard let device = parts.first else { return uid }
    let segments = Array(parts.dropFirst())
    guard !segments.isEmpty else { return device }
    return "\(device) ▸ \(segments.joined(separator: " ▸ "))"
}

@MainActor
public final class EunomiaStore: NSObject, ObservableObject, @preconcurrency NJInputControllerDelegate, @preconcurrency NJOutputMappingActivationDelegate {
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
        selectedInputID != nil
    }

    func setSelectedInput(id: String?) {
        selectedInputID = id
        refreshSelectedInputContext()
    }

    private func clearSelectedInputContext() {
        selectedInputID = nil
        selectedInput = nil
        activeInputPath = ""
        draft = OutputDraft()
    }

    private func refreshSelectedInputContext() {
        guard let id = selectedInputID else {
            clearSelectedInputContext()
            return
        }

        if let element = controller.element(forUID: id),
           element.children == nil,
           let input = element as? NJInput {
            selectedInput = input
            activeInputPath = inputPath(for: input)
            draft = OutputDraft.from(output: controller.currentMapping[input], mappings: controller.mappings)
            return
        }

        // Offline fallback: keep selection by UID so mappings remain readable/editable.
        selectedInput = nil
        activeInputPath = offlineInputPath(for: id)
        draft = OutputDraft.from(output: controller.currentMapping.output(forUID: id), mappings: controller.mappings)
    }

    func activateMapping(index: Int) {
        guard controller.mappings.indices.contains(index) else { return }
        controller.activateMapping(controller.mappings[index])
        refreshMappingState()
        refreshSelectedInputContext()
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

    func importMapping() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.json]
        } else {
            panel.allowedFileTypes = ["json"]
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let object = try JSONSerialization.jsonObject(with: data)
            guard let decoded = MappingSuiteTransfer.decode(jsonObject: object), !decoded.mappings.isEmpty else {
                NSLog("Failed to import mapping suite: invalid payload")
                return
            }

            // Validate every mapping serialization before applying.
            let importedMappings = decoded.mappings.map { NJMapping(serialization: $0) }
            guard !importedMappings.isEmpty else {
                NSLog("Failed to import mapping suite: no mappings")
                return
            }

            let selected = min(max(0, decoded.selectedIndex), importedMappings.count - 1)
            UserDefaults.standard.set(decoded.mappings, forKey: "mappings")
            UserDefaults.standard.set(selected, forKey: "selected")
            controller.load()
            refreshAll()
        } catch {
            NSLog("Failed to import mapping suite: %@", error.localizedDescription)
            return
        }
    }

    func exportMapping() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.json]
        } else {
            panel.allowedFileTypes = ["json"]
        }
        panel.nameFieldStringValue = suggestedExportFileName()

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let payload = MappingSuiteTransfer.payload(
            mappings: controller.mappings.map { $0.serialize() },
            selectedIndex: activeMappingIndex
        )
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: url, options: [.atomic])
        } catch {
            NSLog("Failed to export mapping suite: %@", error.localizedDescription)
        }
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
        guard let selectedInputID else { return }
        let builtOutput = next.buildOutput(mappings: controller.mappings)
        if let selectedInput {
            controller.currentMapping[selectedInput] = builtOutput
        } else {
            controller.currentMapping.setOutput(builtOutput, forUID: selectedInputID)
        }
        controller.save()
    }

    func refreshAccessibilityPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    func openAccessibilitySettings() {
        AccessibilityPermissionNavigator.openAccessibilitySettingsPrompt()
        refreshAccessibilityPermission()
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
        // Dismiss first to avoid sheet flicker from intermediate snapshots.
        keyMappingEditorState = nil
        setSelectedInput(id: state.inputID)
        guard canEditOutput else { return }

        let resolvedKeyCode = state.resolvedPrimaryKeyCode
        if state.enabled && resolvedKeyCode != NJKeyInputFieldEmpty {
            var next = draft
            next.type = .keyPress
            next.keyCode = resolvedKeyCode
            next.keySequenceSteps = state.keySequenceSteps
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

    func snapshot() -> EunomiaRuntimeSnapshot {
        EunomiaRuntimeSnapshot(
            selectedInputID: selectedInputID,
            simulatingEvents: simulatingEvents,
            hidRunning: hidRunning,
            mappingNames: mappingNames,
            activeMappingIndex: activeMappingIndex,
            deviceTree: deviceTree,
            draft: draft,
            activeInputPath: activeInputPath,
            highlightedControls: highlightedControls,
            liveAxisValues: liveAxisValues,
            liveAxisLabels: liveAxisLabels,
            configurableControls: configurableControls,
            hasAccessibilityPermission: hasAccessibilityPermission,
            keyMappingEditorState: keyMappingEditorState
        )
    }

    func snapshotStream() -> AsyncStream<EunomiaRuntimeSnapshot> {
        AsyncStream { continuation in
            continuation.yield(snapshot())

            let cancellable = objectWillChange.sink { [weak self] _ in
                guard let self else { return }
                DispatchQueue.main.async {
                    continuation.yield(self.snapshot())
                }
            }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    private func refreshAll() {
        refreshTree()
        refreshMappingState()
        refreshSelectedInputContext()
    }

    private func suggestedExportFileName() -> String {
        "enjoyable-mapping-suite.json"
    }

    private func refreshTree() {
        deviceTree = controller.devices.map(InputNode.init)
        rebuildControlInputLookup()
        refreshSelectedInputContext()
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
        if let resolved = preferredInputUID(
            for: control,
            from: controlInputLookup,
            selectedInputID: selectedInputID,
            firstDeviceUID: controller.devices.first?.uid
        ) {
            return resolved
        }

        let deviceUID = selectedInputID?.split(separator: "~").first.map(String.init) ?? controller.devices.first?.uid
        guard let deviceUID else { return nil }

        for eid in GamepadLayoutMapper.possibleInputEIDs(for: control, deviceUID: deviceUID) {
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
        NSLog("Eunomia error: %@", error.localizedDescription)
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

struct KeyCodeField: NSViewRepresentable {
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

struct KeyComboField: NSViewRepresentable {
    @Binding var keyCodes: [UInt16]
    @Binding var isEnabled: Bool

    final class Coordinator: NSObject {
        @Binding var keyCodes: [UInt16]

        init(keyCodes: Binding<[UInt16]>) {
            _keyCodes = keyCodes
        }

        func didChangeKeys(_ keys: [UInt16]) {
            keyCodes = keys
        }

        func didClearKeys() {
            keyCodes = []
        }
    }

    final class CapturingTextField: NSTextField {
        weak var forwardingTarget: KeyComboInputView?

        override func mouseDown(with event: NSEvent) {
            forwardingTarget?.mouseDown(with: event)
        }
    }

    final class KeyComboInputView: NSControl {
        var onChangeKeys: (([UInt16]) -> Void)?
        var onClearKeys: (() -> Void)?

        var keyCodes: [UInt16] = [] {
            didSet { updateDisplay() }
        }

        override var isEnabled: Bool {
            didSet {
                field.isEnabled = isEnabled
                if !isEnabled {
                    _ = resignFirstResponder()
                }
            }
        }

        private var isFocused = false {
            didSet { updateDisplay() }
        }

        private let field: CapturingTextField
        private var keyMonitor: Any?

        override init(frame frameRect: NSRect) {
            field = CapturingTextField(frame: frameRect)
            super.init(frame: frameRect)
            commonInit()
        }

        required init?(coder: NSCoder) {
            field = CapturingTextField(frame: .zero)
            super.init(coder: coder)
            commonInit()
        }

        private func commonInit() {
            wantsLayer = true
            field.forwardingTarget = self
            field.frame = bounds
            field.autoresizingMask = [.width, .height]
            field.isEditable = false
            field.isSelectable = false
            field.isBordered = false
            field.drawsBackground = false
            field.alignment = .center
            field.font = .systemFont(ofSize: 13, weight: .medium)
            addSubview(field)
            updateDisplay()
        }

        override var acceptsFirstResponder: Bool {
            isEnabled
        }

        override func mouseDown(with event: NSEvent) {
            guard isEnabled else { return }
            window?.makeFirstResponder(self)
        }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }

        override func becomeFirstResponder() -> Bool {
            isFocused = true
            startKeyCaptureIfNeeded()
            return super.becomeFirstResponder()
        }

        override func resignFirstResponder() -> Bool {
            isFocused = false
            stopKeyCapture()
            return super.resignFirstResponder()
        }

        override func keyDown(with event: NSEvent) {
            handleKeyDown(event)
        }

        override func flagsChanged(with event: NSEvent) {
            guard isEnabled else { return }
            handleFlagsChanged(event)
        }

        private func handleKeyDown(_ event: NSEvent) {
            guard !event.isARepeat else { return }

            let clearMask: NSEvent.ModifierFlags = [.option, .command]
            if event.modifierFlags.intersection(clearMask).isEmpty == false,
               event.keyCode == UInt16(kVK_Delete) {
                keyCodes = []
                onClearKeys?()
                _ = resignFirstResponder()
                return
            }

            let next = Self.keyCodes(from: event)
            keyCodes = next
            onChangeKeys?(next)
            _ = resignFirstResponder()
        }

        private func handleFlagsChanged(_ event: NSEvent) {
            if let next = Self.nextKeyCodesAfterFlagsChanged(
                currentKeyCodes: keyCodes,
                modifierFlags: event.modifierFlags,
                eventKeyCode: event.keyCode
            ) {
                keyCodes = next
                onChangeKeys?(next)
            }
        }

        private func startKeyCaptureIfNeeded() {
            guard keyMonitor == nil else { return }
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                guard let self else { return event }
                guard self.window?.firstResponder === self else { return event }
                guard self.isEnabled else { return event }

                if event.type == .keyDown {
                    self.handleKeyDown(event)
                    return nil
                }

                if event.type == .flagsChanged {
                    self.handleFlagsChanged(event)
                    return nil
                }
                return event
            }
        }

        private func stopKeyCapture() {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
                self.keyMonitor = nil
            }
        }

        private func updateDisplay() {
            if isFocused && keyCodes.isEmpty {
                field.stringValue = NSLocalizedString("key_binding_listening", bundle: .module, comment: "")
                field.textColor = .tertiaryLabelColor
                return
            }

            if keyCodes.isEmpty {
                field.stringValue = ""
                field.textColor = .labelColor
                return
            }

            let labels = keyCodes.map { NJKeyInputField.displayName(forKeyCode: $0) }
            field.stringValue = labels.joined(separator: " ")
            field.textColor = .labelColor
        }

        private static func keyCodes(from event: NSEvent) -> [UInt16] {
            var values = modifierKeyCodes(from: event.modifierFlags)

            let main = event.keyCode
            if !isModifierKey(main) {
                if !values.contains(main) {
                    values.append(main)
                }
            } else if values.isEmpty {
                values.append(main)
            }

            return values
        }

        private static func modifierKeyCodes(from flags: NSEvent.ModifierFlags) -> [UInt16] {
            var values: [UInt16] = []

            func appendIfNeeded(_ code: UInt16) {
                if !values.contains(code) {
                    values.append(code)
                }
            }

            if flags.contains(.control) { appendIfNeeded(UInt16(kVK_Control)) }
            if flags.contains(.option) { appendIfNeeded(UInt16(kVK_Option)) }
            if flags.contains(.shift) { appendIfNeeded(UInt16(kVK_Shift)) }
            if flags.contains(.command) { appendIfNeeded(UInt16(kVK_Command)) }
            if flags.contains(.function) { appendIfNeeded(UInt16(kVK_Function)) }

            return values
        }

        static func nextKeyCodesAfterFlagsChanged(
            currentKeyCodes: [UInt16],
            modifierFlags: NSEvent.ModifierFlags,
            eventKeyCode: UInt16
        ) -> [UInt16]? {
            let modifierOnly = modifierKeyCodes(from: modifierFlags)
            if !modifierOnly.isEmpty {
                return modifierOnly
            }

            // Keep completed combos intact when modifier keys are released.
            let hasNonModifier = currentKeyCodes.contains(where: { !isModifierKey($0) })
            if hasNonModifier {
                return nil
            }

            if isModifierKey(eventKeyCode) {
                return [eventKeyCode]
            }
            return nil
        }

        private static func isModifierKey(_ code: UInt16) -> Bool {
            let modifierKeys: Set<UInt16> = [
                UInt16(kVK_Command),
                UInt16(kVK_RightCommand),
                UInt16(kVK_Option),
                UInt16(kVK_RightOption),
                UInt16(kVK_Control),
                UInt16(kVK_RightControl),
                UInt16(kVK_Shift),
                UInt16(kVK_RightShift),
                UInt16(kVK_CapsLock),
                UInt16(kVK_Function)
            ]
            return modifierKeys.contains(code)
        }

        deinit {
            stopKeyCapture()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(keyCodes: $keyCodes)
    }

    func makeNSView(context: Context) -> KeyComboInputView {
        let view = KeyComboInputView(frame: .zero)
        view.onChangeKeys = { keys in
            context.coordinator.didChangeKeys(keys)
        }
        view.onClearKeys = {
            context.coordinator.didClearKeys()
        }
        return view
    }

    func updateNSView(_ nsView: KeyComboInputView, context: Context) {
        nsView.isEnabled = isEnabled
        let next = keyCodes
        if nsView.keyCodes != next {
            nsView.keyCodes = next
        }
    }
}
