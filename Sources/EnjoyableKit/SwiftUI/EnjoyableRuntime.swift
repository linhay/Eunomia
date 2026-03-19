import AppKit
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
    var type: OutputType = .none
    var keyCode: CGKeyCode = NJKeyInputFieldEmpty
    var mappingIndex: Int = 0
    var mouseAxis: Int32 = 0
    var mouseSpeed: Float = 10
    var mouseButton: UInt32 = 0
    var scrollDirection: Int32 = 1
    var scrollSpeed: Float = 0
    var scrollSmooth: Bool = false

    static func from(output: NJOutput?, mappings: [NJMapping]) -> OutputDraft {
        var draft = OutputDraft()

        if let key = output as? NJOutputKeyPress {
            draft.type = .keyPress
            draft.keyCode = key.keyCode
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
            guard keyCode != NJKeyInputFieldEmpty else { return nil }
            let output = NJOutputKeyPress()
            output.keyCode = keyCode
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

@MainActor
public final class EnjoyableStore: NSObject, ObservableObject, @preconcurrency NJInputControllerDelegate, @preconcurrency NJOutputMappingActivationDelegate {
    @Published var selectedInputID: String?
    @Published var simulatingEvents = false {
        didSet {
            if simulatingEvents != oldValue {
                controller.simulatingEvents = simulatingEvents
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

    private let controller: NJInputController
    private var selectedInput: NJInput?
    private var highlightTracker = ControlHighlightTracker()
    private var highlightCleanupTimer: Timer?

    public override init() {
        controller = NJInputController()
        super.init()

        controller.delegate = self
        NJOutputMapping.setActivationDelegate(self)

        controller.load()
        simulatingEvents = controller.simulatingEvents
        refreshAll()

        // In SwiftUI lifecycle, app active notifications may not replay for newly
        // created controller instances. Start HID once when already active.
        if NSApplication.shared.isActive || simulatingEvents {
            controller.startHid()
        }
    }

    deinit {
        NJOutputMapping.setActivationDelegate(nil)
        highlightCleanupTimer?.invalidate()
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
        if let selectedInputID, controller.element(forUID: selectedInputID) == nil {
            setSelectedInput(id: nil)
        }
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
        liveAxisLabels[parsed.index] = "Axis \(parsed.index)"

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

public struct EnjoyableRootView: View {
    @StateObject private var store = EnjoyableStore()
    @State private var mappingName = ""

    public init() {}

    public var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mappings")
                    .font(.headline)

                Picker("", selection: Binding(get: {
                    store.activeMappingIndex
                }, set: {
                    store.activateMapping(index: $0)
                })) {
                    ForEach(Array(store.mappingNames.enumerated()), id: \.offset) { idx, name in
                        Text(name).tag(idx)
                    }
                }
                .labelsHidden()

                HStack {
                    Button("Add") { store.addMapping() }
                    Button("Remove") { store.removeActiveMapping() }
                        .disabled(store.activeMappingIndex == 0)
                    Button("Up") { store.moveActiveMappingUp() }
                        .disabled(store.activeMappingIndex <= 1)
                    Button("Down") { store.moveActiveMappingDown() }
                        .disabled(store.activeMappingIndex <= 0 || store.activeMappingIndex >= store.mappingNames.count - 1)
                }

                TextField("Rename mapping", text: $mappingName, onCommit: {
                        store.renameActiveMapping(mappingName)
                    })
                    .onAppear {
                        mappingName = store.mappingNames[safe: store.activeMappingIndex] ?? ""
                    }
                    .onChange(of: store.activeMappingIndex) { _ in
                        mappingName = store.mappingNames[safe: store.activeMappingIndex] ?? ""
                    }

                Toggle("Simulate Events", isOn: $store.simulatingEvents)

                Divider()

                if !store.hidRunning {
                    Text("Input monitoring is stopped.")
                        .foregroundColor(.secondary)
                } else if !store.hasDevices {
                    Text("No game controllers detected.")
                        .foregroundColor(.secondary)
                } else {
                    List(selection: Binding(get: {
                        store.selectedInputID
                    }, set: {
                        store.setSelectedInput(id: $0)
                    })) {
                        OutlineGroup(store.deviceTree, children: \.children) { node in
                            Text(node.name)
                                .tag(node.isLeaf ? Optional(node.id) : nil)
                                .foregroundColor(node.isLeaf ? Color.primary : Color.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .frame(minWidth: 320)

            VStack(alignment: .leading, spacing: 16) {
                Text(store.activeInputPath)
                    .font(.headline)

                Text("Controller Layout")
                    .font(.headline)
                GamepadLayoutView(highlightedControls: store.highlightedControls)

                if !store.liveAxisValues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live Axes")
                            .font(.headline)
                        ForEach(store.liveAxisValues.keys.sorted(), id: \.self) { axis in
                            let value = store.liveAxisValues[axis] ?? 0
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(store.liveAxisLabels[axis] ?? "Axis \(axis)")
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(String(format: "%.3f", value))
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                ProgressView(value: Double((value + 1) / 2))
                            }
                        }
                    }
                }

                outputEditor
                    .disabled(!store.canEditOutput)

                Spacer()
            }
            .padding()
            .frame(minWidth: 600)
        }
    }

    @ViewBuilder
    private var outputEditor: some View {
        Picker("Output Type", selection: Binding(get: {
            store.draft.type
        }, set: { value in
            var next = store.draft
            next.type = value
            store.updateDraft(next)
        })) {
            Text("None").tag(OutputType.none)
            Text("Key Press").tag(OutputType.keyPress)
            Text("Mapping").tag(OutputType.mapping)
            Text("Mouse Move").tag(OutputType.mouseMove)
            Text("Mouse Button").tag(OutputType.mouseButton)
            Text("Mouse Scroll").tag(OutputType.mouseScroll)
        }

        switch store.draft.type {
        case .none:
            EmptyView()
        case .keyPress:
            KeyCodeField(keyCode: Binding(get: {
                store.draft.keyCode
            }, set: { value in
                var next = store.draft
                next.keyCode = value
                store.updateDraft(next)
            }), isEnabled: .constant(store.canEditOutput))
            .frame(width: 180)
        case .mapping:
            Picker("Mapping", selection: Binding(get: {
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
            Picker("Direction", selection: Binding(get: {
                store.draft.mouseAxis
            }, set: { value in
                var next = store.draft
                next.mouseAxis = value
                store.updateDraft(next)
            })) {
                Text("Left").tag(Int32(0))
                Text("Right").tag(Int32(1))
                Text("Up").tag(Int32(2))
                Text("Down").tag(Int32(3))
            }
            Slider(value: Binding(get: {
                Double(store.draft.mouseSpeed)
            }, set: { value in
                var next = store.draft
                next.mouseSpeed = Float(value)
                store.updateDraft(next)
            }), in: 1...100)
        case .mouseButton:
            Picker("Button", selection: Binding(get: {
                store.draft.mouseButton
            }, set: { value in
                var next = store.draft
                next.mouseButton = value
                store.updateDraft(next)
            })) {
                Text("Left").tag(UInt32(0))
                Text("Right").tag(UInt32(1))
                Text("Middle").tag(UInt32(2))
            }
        case .mouseScroll:
            Picker("Direction", selection: Binding(get: {
                store.draft.scrollDirection
            }, set: { value in
                var next = store.draft
                next.scrollDirection = value
                store.updateDraft(next)
            })) {
                Text("Vertical +").tag(Int32(1))
                Text("Vertical -").tag(Int32(-1))
                Text("Horizontal +").tag(Int32(2))
                Text("Horizontal -").tag(Int32(-2))
            }
            Toggle("Smooth", isOn: Binding(get: {
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

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
