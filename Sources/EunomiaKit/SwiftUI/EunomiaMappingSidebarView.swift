import SwiftUI

struct MappingSidebarContextActionState {
    let index: Int
    let totalCount: Int

    var canRemove: Bool {
        index > 0
    }

    var canMoveUp: Bool {
        index > 1
    }

    var canMoveDown: Bool {
        index > 0 && index < totalCount - 1
    }
}

struct MappingSidebarSelectionState {
    let mappingNames: [String]
    let selectedIndex: Int?
    let activeIndex: Int

    var effectiveSelectedIndex: Int? {
        if let selectedIndex, mappingNames.indices.contains(selectedIndex) {
            return selectedIndex
        }
        if mappingNames.indices.contains(activeIndex) {
            return activeIndex
        }
        if mappingNames.isEmpty {
            return nil
        }
        return 0
    }

    var selectedName: String {
        guard let index = effectiveSelectedIndex else { return "" }
        return mappingNames[index]
    }
}

struct MappingRenamePanelState {
    let currentName: String
    let draftName: String

    private var trimmedCurrentName: String {
        currentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDraftName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasPendingChanges: Bool {
        trimmedDraftName != trimmedCurrentName
    }

    var canSave: Bool {
        !trimmedDraftName.isEmpty && hasPendingChanges
    }
}

struct EunomiaMappingSidebarView: View {
    let mappingNames: [String]
    let activeMappingIndex: Int
    let mappingSelection: Binding<Int?>
    let mappingName: Binding<String>
    let renameDraftName: Binding<String>
    let detailExpanded: Binding<Bool>
    let showsTitle: Bool
    let usesSidebarBackground: Bool
    let usesSidebarListStyle: Bool
    let onRenameCommit: () -> Void
    let onAddMapping: () -> Void
    let onImportMapping: () -> Void
    let onExportMapping: () -> Void
    let onRemoveActiveMapping: () -> Void
    let onMoveActiveMappingUp: () -> Void
    let onMoveActiveMappingDown: () -> Void

    init(
        mappingNames: [String],
        activeMappingIndex: Int,
        mappingSelection: Binding<Int?>,
        mappingName: Binding<String>,
        renameDraftName: Binding<String>,
        detailExpanded: Binding<Bool> = .constant(true),
        showsTitle: Bool = true,
        usesSidebarBackground: Bool = true,
        usesSidebarListStyle: Bool = true,
        onRenameCommit: @escaping () -> Void,
        onAddMapping: @escaping () -> Void,
        onImportMapping: @escaping () -> Void,
        onExportMapping: @escaping () -> Void,
        onRemoveActiveMapping: @escaping () -> Void,
        onMoveActiveMappingUp: @escaping () -> Void,
        onMoveActiveMappingDown: @escaping () -> Void
    ) {
        self.mappingNames = mappingNames
        self.activeMappingIndex = activeMappingIndex
        self.mappingSelection = mappingSelection
        self.mappingName = mappingName
        self.renameDraftName = renameDraftName
        self.detailExpanded = detailExpanded
        self.showsTitle = showsTitle
        self.usesSidebarBackground = usesSidebarBackground
        self.usesSidebarListStyle = usesSidebarListStyle
        self.onRenameCommit = onRenameCommit
        self.onAddMapping = onAddMapping
        self.onImportMapping = onImportMapping
        self.onExportMapping = onExportMapping
        self.onRemoveActiveMapping = onRemoveActiveMapping
        self.onMoveActiveMappingUp = onMoveActiveMappingUp
        self.onMoveActiveMappingDown = onMoveActiveMappingDown
    }

    private var mappingsList: some View {
        List(selection: mappingSelection) {
            Section(L10n.text("mappings_title")) {
                ForEach(Array(mappingNames.enumerated()), id: \.offset) { idx, name in
                    let actionState = MappingSidebarContextActionState(index: idx, totalCount: mappingNames.count)
                    HStack(spacing: AppleNativeDesignMetrics.spacingS) {
                        Image(systemName: idx == activeMappingIndex ? "circle.inset.filled" : "circle")
                            .font(.caption)
                            .foregroundColor(idx == activeMappingIndex ? .accentColor : .secondary)
                        Text(name)
                            .lineLimit(1)
                    }
                    .tag(idx)
                    .listRowBackground(rowHighlight(for: idx))
                    .contextMenu {
                        Button(L10n.text("button_add")) {
                            onAddMapping()
                        }

                        Button(L10n.text("button_import")) {
                            onImportMapping()
                        }

                        Button(L10n.text("button_export")) {
                            onExportMapping()
                        }

                        Divider()

                        Button(L10n.text("button_remove")) {
                            selectRowAndPerform(idx) {
                                onRemoveActiveMapping()
                            }
                        }
                        .disabled(!actionState.canRemove)

                        Button(L10n.text("button_up")) {
                            selectRowAndPerform(idx) {
                                onMoveActiveMappingUp()
                            }
                        }
                        .disabled(!actionState.canMoveUp)

                        Button(L10n.text("button_down")) {
                            selectRowAndPerform(idx) {
                                onMoveActiveMappingDown()
                            }
                        }
                        .disabled(!actionState.canMoveDown)
                    }
                }
            }
        }
    }

    private var selectionState: MappingSidebarSelectionState {
        MappingSidebarSelectionState(
            mappingNames: mappingNames,
            selectedIndex: mappingSelection.wrappedValue,
            activeIndex: activeMappingIndex
        )
    }

    private var renamePanelState: MappingRenamePanelState {
        MappingRenamePanelState(
            currentName: mappingName.wrappedValue,
            draftName: renameDraftName.wrappedValue
        )
    }

    private func rowHighlight(for index: Int) -> Color {
        if isSelected(index) {
            return Color.accentColor.opacity(0.18)
        }
        return Color.clear
    }

    private func isSelected(_ index: Int) -> Bool {
        selectionState.effectiveSelectedIndex == index
    }

    private func selectRowAndPerform(_ index: Int, action: @escaping () -> Void) {
        mappingSelection.wrappedValue = index
        DispatchQueue.main.async {
            action()
        }
    }

    @ViewBuilder
    private var renameAndActionsSection: some View {
        VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.sidebarToolsSpacing) {
            TextField(
                L10n.text("rename_mapping_placeholder"),
                text: mappingName,
                onCommit: onRenameCommit
            )
            .textFieldStyle(.roundedBorder)

            if !usesSidebarListStyle {
                HStack(spacing: AppleNativeDesignMetrics.spacingS) {
                    Button(action: onAddMapping) {
                        Label(L10n.text("button_add"), systemImage: "plus")
                    }

                    Button(L10n.text("button_import")) {
                        onImportMapping()
                    }

                    Button(L10n.text("button_export")) {
                        onExportMapping()
                    }

                    Button(L10n.text("button_remove")) {
                        onRemoveActiveMapping()
                    }
                    .disabled(activeMappingIndex == 0)

                    Spacer()

                    Button(action: onMoveActiveMappingUp) {
                        Image(systemName: "arrow.up")
                    }
                    .disabled(activeMappingIndex <= 1)

                    Button(action: onMoveActiveMappingDown) {
                        Image(systemName: "arrow.down")
                    }
                    .disabled(activeMappingIndex <= 0 || activeMappingIndex >= mappingNames.count - 1)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private var mappingDetailPanel: some View {
        VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingM) {
            if selectionState.effectiveSelectedIndex == nil {
                Text(L10n.text("selected_input_placeholder"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Label(selectionState.selectedName, systemImage: "person.crop.circle")
                    .font(.headline)

                Divider()

                TextField(
                    L10n.text("rename_mapping_placeholder"),
                    text: renameDraftName
                )
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    saveRenameFromDetailPanel()
                }

                HStack(spacing: AppleNativeDesignMetrics.spacingS) {
                    Spacer()
                    Button(L10n.text("cancel")) {
                        resetRenameDraft()
                    }
                    .disabled(!renamePanelState.hasPendingChanges)

                    Button(L10n.text("save")) {
                        saveRenameFromDetailPanel()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!renamePanelState.canSave)
                }
                .buttonStyle(.bordered)
            }

            Spacer(minLength: 0)
        }
        .padding(AppleNativeDesignMetrics.spacingM)
        .onAppear {
            resetRenameDraft()
        }
        .onChange(of: selectionState.effectiveSelectedIndex) {
            resetRenameDraft()
        }
        .onChange(of: mappingName.wrappedValue) { _, newValue in
            if !renamePanelState.hasPendingChanges {
                renameDraftName.wrappedValue = newValue
            }
        }
    }

    private var mainstreamSidebarContent: some View {
        VStack(spacing: 0) {
            mappingsList
                .listStyle(.sidebar)
                .frame(minHeight: 220, maxHeight: .infinity)

            Divider()

            VStack(spacing: 0) {
                HStack(spacing: AppleNativeDesignMetrics.spacingS) {
                    Label(
                        selectionState.selectedName.isEmpty ? L10n.text("selected_input_placeholder") : selectionState.selectedName,
                        systemImage: "sidebar.bottom"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            detailExpanded.wrappedValue.toggle()
                        }
                    } label: {
                        Image(systemName: detailExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppleNativeDesignMetrics.spacingM)
                .padding(.vertical, AppleNativeDesignMetrics.spacingS)

                if detailExpanded.wrappedValue {
                    mappingDetailPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            if showsTitle {
                Text(L10n.text("mappings_title"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppleNativeDesignMetrics.spacingM)
                    .padding(.top, AppleNativeDesignMetrics.spacingM)
                    .padding(.bottom, AppleNativeDesignMetrics.spacingXS)
            }

            if usesSidebarListStyle {
                mainstreamSidebarContent
            } else {
                mappingsList
                    .listStyle(.plain)
                Divider()

                renameAndActionsSection
                    .padding(AppleNativeDesignMetrics.spacingM)
            }
        }
    }

    var body: some View {
        if usesSidebarBackground {
            content
                .nativeSidebarBackground()
        } else {
            content
        }
    }

    private func resetRenameDraft() {
        renameDraftName.wrappedValue = mappingName.wrappedValue
    }

    private func saveRenameFromDetailPanel() {
        guard renamePanelState.canSave else { return }
        mappingName.wrappedValue = renameDraftName.wrappedValue
        onRenameCommit()
        renameDraftName.wrappedValue = mappingName.wrappedValue
    }
}
