import SwiftUI

enum RootSidebarRole: Hashable {
    case deviceRuntime
}

enum RootInspectorRole: Hashable {
    case status
    case mappingManager
    case outputEditor
}

struct InspectorPanelNavigationState: Equatable {
    let roles: [RootInspectorRole]
    let selectedRole: RootInspectorRole?

    var effectiveRole: RootInspectorRole? {
        if let selectedRole, roles.contains(selectedRole) {
            return selectedRole
        }
        return roles.first
    }
}

struct InspectorPanelSectionDescriptor: Equatable {
    let role: RootInspectorRole
    let titleKey: String
    let symbol: String

    static func build(from roles: [RootInspectorRole]) -> [InspectorPanelSectionDescriptor] {
        roles.map { role in
            switch role {
            case .status:
                return InspectorPanelSectionDescriptor(
                    role: .status,
                    titleKey: "status_title",
                    symbol: DashboardStatusKind.liveInput.icon
                )
            case .mappingManager:
                return InspectorPanelSectionDescriptor(
                    role: .mappingManager,
                    titleKey: "mappings_title",
                    symbol: "list.bullet"
                )
            case .outputEditor:
                return InspectorPanelSectionDescriptor(
                    role: .outputEditor,
                    titleKey: "output_editor_title",
                    symbol: "keyboard.badge.ellipsis"
                )
            }
        }
    }
}

struct RootPanelLayout: Equatable {
    let sidebarRole: RootSidebarRole
    let inspectorRoles: [RootInspectorRole]

    static let current = RootPanelLayout(
        sidebarRole: .deviceRuntime,
        inspectorRoles: [.status, .mappingManager, .outputEditor]
    )
}

struct InspectorRuntimeControlState: Equatable {
    let simulatingEvents: Bool
    let hasAccessibilityPermission: Bool

    var showsAccessibilityHint: Bool {
        simulatingEvents && !hasAccessibilityPermission
    }
}

struct DeviceRuntimeSidebarHierarchy {
    static func project(_ nodes: [InputNode]) -> [InputNode] {
        nodes.map(projectTopLevel)
    }

    private static func projectTopLevel(_ node: InputNode) -> InputNode {
        guard let children = node.children, !children.isEmpty else { return node }

        let flattenedLeaves = children.flatMap { flattenLeaves(in: $0, groupPath: []) }
        return InputNode(
            id: node.id,
            name: node.name,
            isLeaf: false,
            children: flattenedLeaves
        )
    }

    private static func flattenLeaves(in node: InputNode, groupPath: [String]) -> [InputNode] {
        guard let children = node.children, !children.isEmpty else {
            let contextualName = contextualLeafName(groupPath: groupPath, leafName: node.name)
            return [
                InputNode(
                    id: node.id,
                    name: contextualName,
                    isLeaf: true
                )
            ]
        }

        let nextPath = groupPath + [node.name]
        return children.flatMap { flattenLeaves(in: $0, groupPath: nextPath) }
    }

    private static func contextualLeafName(groupPath: [String], leafName: String) -> String {
        guard !groupPath.isEmpty else { return leafName }
        return "\(groupPath.joined(separator: " · ")) · \(leafName)"
    }
}

struct EnjoyableDetailSplitView<MainWorkspace: View, InspectorPanel: View>: View {
    let mainWorkspace: MainWorkspace
    let inspectorPanel: InspectorPanel

    init(
        @ViewBuilder mainWorkspace: () -> MainWorkspace,
        @ViewBuilder inspectorPanel: () -> InspectorPanel
    ) {
        self.mainWorkspace = mainWorkspace()
        self.inspectorPanel = inspectorPanel()
    }

    var body: some View {
        HSplitView {
            mainWorkspace
                .frame(minWidth: AppleNativeDesignMetrics.mainMinWidth)
                .layoutPriority(1)

            inspectorPanel
                .frame(
                    minWidth: min(300, AppleNativeDesignMetrics.inspectorIdealWidth),
                    idealWidth: AppleNativeDesignMetrics.inspectorIdealWidth,
                    maxWidth: AppleNativeDesignMetrics.inspectorMaxWidth
                )
        }
    }
}

struct EnjoyableMainWorkspaceView<ControllerCard: View, LiveAxisCard: View>: View {
    let controllerCard: ControllerCard
    let liveAxisCard: LiveAxisCard

    init(
        @ViewBuilder controllerCard: () -> ControllerCard,
        @ViewBuilder liveAxisCard: () -> LiveAxisCard
    ) {
        self.controllerCard = controllerCard()
        self.liveAxisCard = liveAxisCard()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingL) {
                controllerCard
                liveAxisCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct EnjoyableInspectorPanelView<StatusCard: View, MappingManagerPanel: View, OutputEditorCard: View>: View {
    let inspectorRoles: [RootInspectorRole]
    let statusCard: StatusCard
    let mappingManagerPanel: MappingManagerPanel
    let outputEditorCard: OutputEditorCard
    @State private var selectedRole: RootInspectorRole?

    init(
        inspectorRoles: [RootInspectorRole],
        @ViewBuilder statusCard: () -> StatusCard,
        @ViewBuilder mappingManagerPanel: () -> MappingManagerPanel,
        @ViewBuilder outputEditorCard: () -> OutputEditorCard
    ) {
        self.inspectorRoles = inspectorRoles
        self.statusCard = statusCard()
        self.mappingManagerPanel = mappingManagerPanel()
        self.outputEditorCard = outputEditorCard()
    }

    private var sections: [InspectorPanelSectionDescriptor] {
        InspectorPanelSectionDescriptor.build(from: inspectorRoles)
    }

    private var navigationState: InspectorPanelNavigationState {
        InspectorPanelNavigationState(
            roles: sections.map(\.role),
            selectedRole: selectedRole
        )
    }

    private var selectedRoleBinding: Binding<RootInspectorRole?> {
        Binding(
            get: { navigationState.effectiveRole },
            set: { selectedRole = $0 }
        )
    }

    @ViewBuilder
    private func sectionContent(for role: RootInspectorRole) -> some View {
        switch role {
        case .status:
            statusCard
        case .mappingManager:
            mappingManagerPanel
        case .outputEditor:
            outputEditorCard
        }
    }

    private var sidebarNavigation: some View {
        List(selection: selectedRoleBinding) {
            ForEach(sections, id: \.role) { section in
                Label(L10n.text(section.titleKey), systemImage: section.symbol)
                    .tag(section.role)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 160, idealWidth: 188, maxWidth: 220)
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let role = navigationState.effectiveRole,
           let section = sections.first(where: { $0.role == role }) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingM) {
                    Label(L10n.text(section.titleKey), systemImage: section.symbol)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    sectionContent(for: role)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, AppleNativeDesignMetrics.spacingS)
            }
            .padding(.leading, AppleNativeDesignMetrics.spacingS)
        } else {
            ContentUnavailableView(
                L10n.text("selected_input_placeholder"),
                systemImage: "sidebar.left"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    var body: some View {
        HSplitView {
            sidebarNavigation
            detailPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .onAppear {
            selectedRole = navigationState.effectiveRole
        }
        .onChange(of: inspectorRoles) { _, _ in
            selectedRole = navigationState.effectiveRole
        }
    }
}

struct EnjoyableDeviceRuntimeSidebarView: View {
    let deviceTree: [InputNode]
    let selectedInputID: Binding<String?>
    let simulatingEvents: Binding<Bool>
    let hasAccessibilityPermission: Bool
    let onOpenAccessibilitySettings: () -> Void
    let onOpenKeyMappingEditor: (String) -> Void

    private var runtimeState: InspectorRuntimeControlState {
        InspectorRuntimeControlState(
            simulatingEvents: simulatingEvents.wrappedValue,
            hasAccessibilityPermission: hasAccessibilityPermission
        )
    }

    private var projectedDeviceTree: [InputNode] {
        DeviceRuntimeSidebarHierarchy.project(deviceTree)
    }

    private func symbolName(for node: InputNode) -> String {
        DeviceTreeNodeStyle.symbolName(for: node)
    }

    private var runtimeSection: some View {
        Section {
            Toggle(L10n.text("simulate_events"), isOn: simulatingEvents)
                .toggleStyle(.switch)

            if runtimeState.showsAccessibilityHint {
                VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingXS) {
                    Label {
                        Text(L10n.text("accessibility_permission_required"))
                            .font(.footnote)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                    }

                    Button(action: onOpenAccessibilitySettings) {
                        Label(L10n.text("open_accessibility_settings"), systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.vertical, AppleNativeDesignMetrics.spacingXS)
            }
        } header: {
            Text(L10n.text("runtime_title"))
        }
    }

    private var devicesSection: some View {
        Section {
            OutlineGroup(projectedDeviceTree, children: \.children) { node in
                HStack(spacing: AppleNativeDesignMetrics.spacingXS) {
                    Image(systemName: symbolName(for: node))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(node.isLeaf ? .tertiary : .secondary)

                    Text(node.name)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                .tag(node.isLeaf ? Optional(node.id) : nil)
                .contextMenu {
                    if node.isLeaf {
                        Button(L10n.text("menu_key_detail")) {
                            onOpenKeyMappingEditor(node.id)
                        }
                    }
                }
            }
        } header: {
            Text(L10n.text("device_list_title"))
        }
    }

    var body: some View {
        List(selection: selectedInputID) {
            runtimeSection
            devicesSection
        }
        .listStyle(.sidebar)
        .transaction { txn in
            txn.animation = nil
        }
        .defaultMinListRowHeight(26)
    }
}

private extension View {
    @ViewBuilder
    func defaultMinListRowHeight(_ value: CGFloat) -> some View {
        if #available(macOS 13.0, *) {
            self.environment(\.defaultMinListRowHeight, value)
        } else {
            self
        }
    }
}

struct EnjoyableStatusCardView: View {
    let statusKind: DashboardStatusKind
    let activeMappingName: String
    let activeInputPath: String
    let hasDevices: Bool

    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline, spacing: AppleNativeDesignMetrics.spacingM) {
                Label(L10n.text(statusKind.titleKey), systemImage: statusKind.icon)
                    .font(.headline)
                    .foregroundColor(statusKind.tint)

                Spacer()

                Text("\(L10n.text("mappings_title")): \(activeMappingName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack(alignment: .top, spacing: AppleNativeDesignMetrics.spacingL) {
                VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingXS) {
                    Text(L10n.text("selected_input"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(activeInputPath.isEmpty ? L10n.text("selected_input_placeholder") : activeInputPath)
                        .font(.callout)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppleNativeDesignMetrics.spacingXS) {
                    Text(L10n.text("device_list_title"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(hasDevices ? "1+" : "0")
                        .font(.title3.weight(.semibold))
                }
            }
        }
    }
}

struct NativePanelCard<Content: View>: View {
    let title: String
    let symbol: String
    let surfaceStyle: NativeCardSurfaceStyle
    let headerTrailing: AnyView?
    let content: Content

    init(
        title: String,
        symbol: String,
        surfaceStyle: NativeCardSurfaceStyle = .adaptiveGlass,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.surfaceStyle = surfaceStyle
        self.headerTrailing = nil
        self.content = content()
    }

    init<Trailing: View>(
        title: String,
        symbol: String,
        surfaceStyle: NativeCardSurfaceStyle = .adaptiveGlass,
        @ViewBuilder headerTrailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.surfaceStyle = surfaceStyle
        self.headerTrailing = AnyView(headerTrailing())
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingM) {
            HStack(alignment: .center, spacing: AppleNativeDesignMetrics.spacingS) {
                Label(title, systemImage: symbol)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if let headerTrailing {
                    headerTrailing
                }
            }

            content
        }
        .nativeCardSurface(surfaceStyle)
    }
}

struct EnjoyableLiveAxisCardView: View {
    let liveAxisValues: [Int: Float]
    let surfaceStyle: NativeCardSurfaceStyle

    init(
        liveAxisValues: [Int: Float],
        surfaceStyle: NativeCardSurfaceStyle = .adaptiveGlass
    ) {
        self.liveAxisValues = liveAxisValues
        self.surfaceStyle = surfaceStyle
    }

    var body: some View {
        NativePanelCard(
            title: L10n.text("live_axes_title"),
            symbol: "slider.horizontal.3",
            surfaceStyle: surfaceStyle
        ) {
            let sortedAxis = liveAxisValues.keys.sorted()

            if sortedAxis.isEmpty {
                Text(L10n.text("axes_empty_hint"))
                    .font(.callout)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: AppleNativeDesignMetrics.spacingS) {
                    ForEach(sortedAxis, id: \.self) { idx in
                        let value = liveAxisValues[idx] ?? 0
                        HStack(spacing: AppleNativeDesignMetrics.spacingS) {
                            Text("\(L10n.text("axis_label")) \(idx)")
                                .font(.caption)
                                .frame(width: 62, alignment: .leading)

                            ProgressView(value: Double(value + 1) / 2)
                                .accentColor(value >= 0 ? .green : .orange)

                            Text(String(format: "%.2f", value))
                                .font(.system(.caption, design: .monospaced))
                                .frame(width: 44, alignment: .trailing)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}
