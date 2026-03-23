import ComposableArchitecture
import SwiftUI

enum AppleNativeDesignMetrics {
    static let sidebarCornerRadius: CGFloat = 14
    static let cardCornerRadius: CGFloat = 16
    static let compactCardCornerRadius: CGFloat = 12

    static let spacingXS: CGFloat = 6
    static let spacingS: CGFloat = 10
    static let spacingM: CGFloat = 14
    static let spacingL: CGFloat = 20
    static let sidebarToolsSpacing: CGFloat = 10
    static let panelBackgroundOpacity: Double = 0.84
    static let inputFieldBackgroundOpacity: Double = 0.7

    static let sidebarMinWidth: CGFloat = 240
    static let sidebarIdealWidth: CGFloat = 280
    static let sidebarMaxWidth: CGFloat = 320
    static let mainMinWidth: CGFloat = 560
    static let inspectorIdealWidth: CGFloat = 340
    static let inspectorMaxWidth: CGFloat = 420
}

enum AppleNativePalette {
    static let canvasTop = Color(red: 241 / 255, green: 244 / 255, blue: 248 / 255)
    static let canvasBottom = Color(red: 232 / 255, green: 236 / 255, blue: 242 / 255)
    static let stroke = Color.black.opacity(0.08)
    static let sidebarBackground = Color(red: 224 / 255, green: 230 / 255, blue: 238 / 255)
}

enum RootCardSurfacePolicy {
    static let controllerCardStyle: NativeCardSurfaceStyle = .solid
    static let liveAxisCardStyle: NativeCardSurfaceStyle = .solid
    static let mappingManagerCardStyle: NativeCardSurfaceStyle = .solid
    static let outputEditorCardStyle: NativeCardSurfaceStyle = .solid
}

enum MappingManagerLayoutPolicy {
    static let usesMainstreamSidebarList: Bool = true
}

public struct EnjoyableRootView: View {
    private let store: StoreOf<EnjoyableRootFeature>
    private let panelLayout = RootPanelLayout.current

    @MainActor
    public init() {
        store = Store(initialState: EnjoyableRootFeature.State()) {
            EnjoyableRootFeature()
        }
    }

    public var body: some View {
        rootNavigation
            .frame(minWidth: 1080, minHeight: 720)
            .sheet(item: keyMappingEditorBinding) { state in
                AppleKeyMappingEditorSheet(
                    initialState: state,
                    onCancel: {
                        send(.dismissKeyMappingEditor)
                    },
                    onSave: { next in
                        send(.saveKeyMappingEditor(next))
                    }
                )
            }
            .onAppear {
                sendView(.onAppear)
            }
    }

    @ViewBuilder
    private var rootNavigation: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(
                    min: AppleNativeDesignMetrics.sidebarMinWidth,
                    ideal: AppleNativeDesignMetrics.sidebarIdealWidth,
                    max: AppleNativeDesignMetrics.sidebarMaxWidth
                )
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var keyMappingEditorBinding: Binding<KeyMappingEditorState?> {
        Binding(
            get: { store.keyMappingEditorState },
            set: { next in
                if next == nil {
                    send(.dismissKeyMappingEditor)
                }
            }
        )
    }

    private var statusKind: DashboardStatusKind {
        dashboardStatusKind(hidRunning: store.hidRunning, hasDevices: store.hasDevices)
    }

    private var mappingSelection: Binding<Int?> {
        Binding(get: { store.activeMappingIndex }) { next in
            guard let next else { return }
            sendView(.activateMapping(next))
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        switch panelLayout.sidebarRole {
        case .deviceRuntime:
            deviceRuntimeSidebar
        }
    }

    private var detail: some View {
        EnjoyableDetailSplitView(
            mainWorkspace: {
                mainWorkspace
            },
            inspectorPanel: {
                inspectorPanel
            }
        )
        .padding(AppleNativeDesignMetrics.spacingL)
    }

    private var mainWorkspace: some View {
        EnjoyableMainWorkspaceView(
            controllerCard: {
                controllerCard
            },
            liveAxisCard: {
                liveAxisCard
            }
        )
    }

    private var inspectorPanel: some View {
        EnjoyableInspectorPanelView(
            inspectorRoles: panelLayout.inspectorRoles,
            statusCard: {
                statusCard
            },
            mappingManagerPanel: {
                mappingManagerPanel
            },
            outputEditorCard: {
                outputEditorCard
            }
        )
    }

    private var deviceRuntimeSidebar: some View {
        EnjoyableDeviceRuntimeSidebarView(
            deviceTree: store.deviceTree,
            selectedInputID: binding(
                get: { store.selectedInputID },
                send: EnjoyableRootFeature.View.setSelectedInput
            ),
            simulatingEvents: binding(
                get: { store.simulatingEvents },
                send: EnjoyableRootFeature.View.setSimulatingEvents
            ),
            hasAccessibilityPermission: store.hasAccessibilityPermission,
            onOpenAccessibilitySettings: {
                sendView(.openAccessibilitySettings)
            },
            onOpenKeyMappingEditor: {
                sendView(.openKeyMappingEditorForInput($0, forceEnable: false))
            }
        )
    }

    @ViewBuilder
    private var mappingManagerPanel: some View {
        if panelLayout.inspectorRoles.contains(.mappingManager) {
            EnjoyableMappingSidebarView(
                mappingNames: store.mappingNames,
                activeMappingIndex: store.activeMappingIndex,
                mappingSelection: mappingSelection,
                mappingName: binding(
                    get: { store.mappingName },
                    send: EnjoyableRootFeature.View.setMappingName
                ),
                showsTitle: false,
                usesSidebarBackground: false,
                usesSidebarListStyle: MappingManagerLayoutPolicy.usesMainstreamSidebarList,
                onRenameCommit: {
                    sendView(.commitRename)
                },
                onAddMapping: {
                    sendView(.addMapping)
                },
                onRemoveActiveMapping: {
                    sendView(.removeActiveMapping)
                },
                onMoveActiveMappingUp: {
                    sendView(.moveActiveMappingUp)
                },
                onMoveActiveMappingDown: {
                    sendView(.moveActiveMappingDown)
                }
            )
            .frame(minHeight: 280)
            .nativeCardSurface(RootCardSurfacePolicy.mappingManagerCardStyle)
        }
    }

    private var statusCard: some View {
        EnjoyableStatusCardView(
            statusKind: statusKind,
            activeMappingName: store.mappingNames[safe: store.activeMappingIndex] ?? "-",
            activeInputPath: store.activeInputPath,
            hasDevices: store.hasDevices
        )
    }

    private var controllerCard: some View {
        NativePanelCard(
            title: L10n.text("controller_layout_title"),
            symbol: "gamecontroller",
            surfaceStyle: RootCardSurfacePolicy.controllerCardStyle
        ) {
            GamepadLayoutView(
                highlightedControls: store.highlightedControls,
                canConfigureControl: { store.configurableControls.contains($0) },
                onConfigureKeyPress: { sendView(.quickConfigureKeyPress($0)) },
                onClearMapping: { sendView(.clearOutput($0)) }
            )
            .frame(maxWidth: .infinity)
            .frame(height: 360)
        }
    }

    private var liveAxisCard: some View {
        EnjoyableLiveAxisCardView(
            liveAxisValues: store.liveAxisValues,
            surfaceStyle: RootCardSurfacePolicy.liveAxisCardStyle
        )
    }

    private var outputEditorCard: some View {
        NativePanelCard(
            title: L10n.text("output_editor_title"),
            symbol: "keyboard.badge.ellipsis",
            surfaceStyle: RootCardSurfacePolicy.outputEditorCardStyle
        ) {
            VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingM) {
                if !store.canEditOutput {
                    Text(L10n.text("selected_input_placeholder"))
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Picker(L10n.text("output_type"), selection: outputTypeBinding) {
                        ForEach(OutputType.allCases) { type in
                            Label(L10n.text("output_\(type.rawValue)"), systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    outputTypeSettings
                }
            }
        }
    }

    @ViewBuilder
    private var outputTypeSettings: some View {
        switch store.draft.type {
        case .none:
            Text(L10n.text("output_none"))
                .font(.callout)
                .foregroundColor(.secondary)

        case .keyPress:
            VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingS) {
                Text(L10n.text("key_binding_title"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                KeyCodeField(keyCode: keyCodeBinding, isEnabled: .constant(true))
                    .frame(height: 34)
                    .padding(.horizontal, AppleNativeDesignMetrics.spacingXS)
                    .nativeInputFieldBackground()

                VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingXS) {
                    HStack {
                        Text(L10n.text("trigger_threshold"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", store.draft.keyActivationThreshold))
                            .font(.system(.caption, design: .monospaced))
                    }
                    Slider(value: keyThresholdBinding, in: 0...1)
                }

                if !store.draft.keySequenceSteps.isEmpty {
                    VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingS) {
                        Text(L10n.text("macro_sequence"))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(Array(store.draft.keySequenceSteps.enumerated()), id: \.offset) { idx, step in
                            HStack(spacing: AppleNativeDesignMetrics.spacingS) {
                                Text("#\(idx + 1)")
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(width: 26, alignment: .leading)

                                KeyCodeField(keyCode: keySequenceKeyBinding(index: idx), isEnabled: .constant(true))
                                    .frame(height: 30)
                                    .frame(width: 120)
                                    .padding(.horizontal, AppleNativeDesignMetrics.spacingXS)
                                    .nativeInputFieldBackground()

                                Stepper(value: keySequenceDelayBinding(index: idx), in: 0...1000, step: 10) {
                                    Text("\(L10n.text("step_delay_ms")) \(step.delayMilliseconds)")
                                        .font(.caption)
                                }
                            }
                        }

                        HStack(spacing: AppleNativeDesignMetrics.spacingS) {
                            Button(L10n.text("add_step")) {
                                sendView(.appendSequenceStep)
                            }
                            Button(L10n.text("remove_step")) {
                                sendView(.removeLastSequenceStep)
                            }
                            .disabled(store.draft.keySequenceSteps.count <= 1)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                } else {
                    Button(L10n.text("add_step")) {
                        sendView(.appendSequenceStep)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

        case .mapping:
            Picker(L10n.text("output_mapping"), selection: mappingIndexBinding) {
                ForEach(Array(store.mappingNames.enumerated()), id: \.offset) { idx, name in
                    Text(name).tag(idx)
                }
            }
            .pickerStyle(.menu)

        case .mouseMove:
            VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingS) {
                Picker(L10n.text("direction"), selection: mouseAxisBinding) {
                    Text(L10n.text("left")).tag(Int32(0))
                    Text(L10n.text("right")).tag(Int32(1))
                    Text(L10n.text("up")).tag(Int32(2))
                    Text(L10n.text("down")).tag(Int32(3))
                }
                .pickerStyle(.segmented)

                Slider(value: mouseSpeedBinding, in: 1...100)
            }

        case .mouseButton:
            Picker(L10n.text("button"), selection: mouseButtonBinding) {
                Text(L10n.text("left")).tag(UInt32(0))
                Text(L10n.text("right")).tag(UInt32(1))
                Text(L10n.text("middle")).tag(UInt32(2))
            }
            .pickerStyle(.segmented)

        case .mouseScroll:
            VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingS) {
                Picker(L10n.text("direction"), selection: scrollDirectionBinding) {
                    Text(L10n.text("vertical_plus")).tag(Int32(1))
                    Text(L10n.text("vertical_minus")).tag(Int32(-1))
                    Text(L10n.text("horizontal_plus")).tag(Int32(2))
                    Text(L10n.text("horizontal_minus")).tag(Int32(-2))
                }
                .pickerStyle(.menu)

                Toggle(L10n.text("smooth"), isOn: scrollSmoothBinding)

                Slider(value: scrollSpeedBinding, in: 1...100)
                    .disabled(!store.draft.scrollSmooth)
            }
        }
    }

    private var outputTypeBinding: Binding<OutputType> {
        binding(
            get: { store.draft.type },
            send: EnjoyableRootFeature.View.setOutputType
        )
    }

    private var keyCodeBinding: Binding<UInt16> {
        binding(
            get: { store.draft.keyCode },
            send: EnjoyableRootFeature.View.setKeyCode
        )
    }

    private var keyThresholdBinding: Binding<Double> {
        binding(
            get: { Double(store.draft.keyActivationThreshold) },
            send: EnjoyableRootFeature.View.setKeyThreshold
        )
    }

    private func keySequenceKeyBinding(index: Int) -> Binding<UInt16> {
        binding(
            get: {
                guard store.draft.keySequenceSteps.indices.contains(index) else {
                    return NJKeyInputFieldEmpty
                }
                return store.draft.keySequenceSteps[index].keyCode
            },
            set: { sendView(.setKeySequenceKey(index: index, value: $0)) }
        )
    }

    private func keySequenceDelayBinding(index: Int) -> Binding<Int> {
        binding(
            get: {
                guard store.draft.keySequenceSteps.indices.contains(index) else { return 0 }
                return Int(store.draft.keySequenceSteps[index].delayMilliseconds)
            },
            set: { sendView(.setKeySequenceDelay(index: index, value: $0)) }
        )
    }

    private var mappingIndexBinding: Binding<Int> {
        binding(
            get: { store.draft.mappingIndex },
            send: EnjoyableRootFeature.View.setMappingIndex
        )
    }

    private var mouseAxisBinding: Binding<Int32> {
        binding(
            get: { store.draft.mouseAxis },
            send: EnjoyableRootFeature.View.setMouseAxis
        )
    }

    private var mouseSpeedBinding: Binding<Double> {
        binding(
            get: { Double(store.draft.mouseSpeed) },
            send: EnjoyableRootFeature.View.setMouseSpeed
        )
    }

    private var mouseButtonBinding: Binding<UInt32> {
        binding(
            get: { store.draft.mouseButton },
            send: EnjoyableRootFeature.View.setMouseButton
        )
    }

    private var scrollDirectionBinding: Binding<Int32> {
        binding(
            get: { store.draft.scrollDirection },
            send: EnjoyableRootFeature.View.setScrollDirection
        )
    }

    private var scrollSmoothBinding: Binding<Bool> {
        binding(
            get: { store.draft.scrollSmooth },
            send: EnjoyableRootFeature.View.setScrollSmooth
        )
    }

    private var scrollSpeedBinding: Binding<Double> {
        binding(
            get: { Double(store.draft.scrollSpeed) },
            send: EnjoyableRootFeature.View.setScrollSpeed
        )
    }

    private func binding<Value>(
        get: @escaping () -> Value,
        send action: @escaping (Value) -> EnjoyableRootFeature.View
    ) -> Binding<Value> {
        binding(
            get: get,
            set: { value in
                sendView(action(value))
            }
        )
    }

    private func binding<Value>(
        get: @escaping () -> Value,
        set: @escaping (Value) -> Void
    ) -> Binding<Value> {
        Binding(
            get: get,
            set: set
        )
    }

    private func sendView(_ action: EnjoyableRootFeature.View) {
        send(.view(action))
    }

    private func send(_ action: EnjoyableRootFeature.Action) {
        store.send(action)
    }
}
