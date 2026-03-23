import SwiftUI

extension AppleKeyMappingEditorSheet {
    static func normalizedSelectedStepIndex(_ selectedIndex: Int?, stepCount: Int) -> Int? {
        AppleKeyMappingEditorFeature.State.normalizedSelectedStepIndex(selectedIndex, stepCount: stepCount)
    }

    var initialState: KeyMappingEditorState {
        store.initialState
    }

    var state: KeyMappingEditorState {
        store.draft
    }

    var hasUnsavedChanges: Bool {
        !state.hasSameEditingPayload(as: store.initialState)
    }

    var selectedStepIndex: Int? {
        store.selectedStepIndex
    }

    var isBindingControlEnabled: Binding<Bool> {
        Binding(
            get: { state.canEditBindingControls },
            set: { _ in }
        )
    }

    var effectiveSelectedStepIndex: Int? {
        AppleKeyMappingEditorFeature.State.normalizedSelectedStepIndex(
            selectedStepIndex,
            stepCount: state.keySequenceSteps.count
        )
    }

    func isStepSelected(index: Int) -> Bool {
        effectiveSelectedStepIndex == index
    }

    func selectStep(index: Int) {
        store.send(.setSelectedStepIndex(index))
    }

    var showsDiscardConfirmationBinding: Binding<Bool> {
        Binding(
            get: { store.showsDiscardConfirmation },
            set: { store.send(.setShowsDiscardConfirmation($0)) }
        )
    }

    var enabledBinding: Binding<Bool> {
        Binding(
            get: { state.enabled },
            set: { store.send(.setEnabled($0)) }
        )
    }
}

extension AppleKeyMappingEditorSheet {
    func handleCancelTapped() {
        store.send(.cancelTapped)
    }

    var thresholdBinding: Binding<Double> {
        Binding(
            get: { Double(state.activationThreshold) },
            set: { value in
                store.send(.setActivationThreshold(value))
            }
        )
    }

    func keySequenceKeysBinding(index: Int) -> Binding<[UInt16]> {
        Binding(
            get: {
                guard state.keySequenceSteps.indices.contains(index) else { return [] }
                return state.keySequenceSteps[index].keys.filter { $0 != NJKeyInputFieldEmpty }
            },
            set: { keys in
                store.send(.setKeySequenceKeys(index: index, keys: keys))
            }
        )
    }

    func keySequenceDelayBinding(index: Int) -> Binding<Int> {
        Binding(
            get: {
                guard state.keySequenceSteps.indices.contains(index) else { return 0 }
                return Int(state.keySequenceSteps[index].delayMilliseconds)
            },
            set: { value in
                store.send(.setKeySequenceDelay(index: index, value: value))
            }
        )
    }

    func moveStep(from source: IndexSet, to destination: Int) {
        store.send(.moveStep(from: source, to: destination))
    }

    func appendStep() {
        store.send(.appendStep)
    }

    func removeStep() {
        store.send(.removeStep)
    }
}

extension AppleKeyMappingEditorSheet {
    
    var header: some View {
        HStack(spacing: AppleNativeDesignMetrics.spacingS) {
            if hasUnsavedChanges {
                Text(L10n.text("editor_unsaved_changes"))
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, AppleNativeDesignMetrics.spacingXS)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(.capsule)
            }

            Spacer()

            Button(L10n.text("cancel"), action: handleCancelTapped)
            Button(L10n.text("save")) {
                store.send(.saveTapped)
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!state.canSaveChanges)
        }
        .padding(AppleNativeDesignMetrics.spacingL)
    }

    var sourceAndDiagnosticsPanel: some View {
        List {
            Section(L10n.text("editor_source_input_title")) {
                Text(state.inputPath)
                    .font(.callout)
                    .textSelection(.enabled)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section(L10n.text("editor_diagnostics_title")) {
                Label(
                    L10n.text(state.diagnosticsStatusTextKey),
                    systemImage: state.diagnosticsStatusSymbolName
                )
                .font(.caption)
                .foregroundStyle(state.isResolvable ? .green : .orange)

                Text(String(format: L10n.text("editor_threshold_summary"), state.activationThreshold))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !state.isResolvable {
                    Text(state.unavailableReason ?? L10n.text("editor_unavailable_hint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
    }

    var editorForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingL) {
                triggerEventsCard
            }
            .padding(AppleNativeDesignMetrics.spacingL)
        }
    }

    var buttonStateSection: some View {
        VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingM) {
            if !state.isResolvable {
                Label(
                    state.unavailableReason ?? L10n.text("editor_unavailable_hint"),
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(.horizontal, AppleNativeDesignMetrics.spacingS)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Divider()
                .opacity(0.6)

            VStack(alignment: .leading, spacing: AppleNativeDesignMetrics.spacingS) {
                HStack {
                    Label(L10n.text("editor_trigger_mode_title"), systemImage: "bolt.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: EditorLayout.labelColumnWidth, alignment: .leading)

                    Text(L10n.text("editor_trigger_mode_press"))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                HStack(alignment: .center) {
                    Label(L10n.text("trigger_threshold"), systemImage: "gauge.with.needle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: EditorLayout.labelColumnWidth, alignment: .leading)

                    Slider(value: thresholdBinding, in: 0...1)
                        .tint(.accentColor)
                        .disabled(!state.canEditBindingControls)

                    Text(String(format: "%.0f%%", state.activationThreshold * 100))
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 44, alignment: .trailing)
                }
            }

            if state.enabled && !state.canSaveChanges {
                HStack(spacing: AppleNativeDesignMetrics.spacingXS) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(L10n.text("editor_binding_required_hint"))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(.top, 4)
            }
        }
    }

    var triggerEventsCard: some View {
        NativePanelCard(
            title: L10n.text("editor_trigger_events_card_title"),
            symbol: "list.bullet.indent",
            surfaceStyle: .solid,
            headerTrailing: {
            Toggle(L10n.text("key_mapping_editor_enabled"), isOn: enabledBinding)
                .toggleStyle(.switch)
                .disabled(!state.isResolvable)
        }
        ) {
            VStack(alignment: .leading, spacing: 0) {
                buttonStateSection
                    .padding(.bottom, AppleNativeDesignMetrics.spacingL)

                // TABLE SECTION
                if state.keySequenceSteps.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "keyboard.badge.ellipsis").font(.title3).foregroundStyle(.quaternary)
                        Text(L10n.text("macro_sequence_empty_hint")).font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    triggerEventsTable
                }

                // TABLE FOOTER
                HStack(spacing: 12) {
                    Button(action: appendStep) {
                        Image(systemName: "plus.circle.fill")
                        Text(L10n.text("add_step"))
                    }
                    .disabled(!state.canEditBindingControls)
                    
                    Button(action: removeStep) {
                        Image(systemName: "minus.circle.fill")
                        Text(L10n.text("remove_step"))
                    }
                    .disabled(!state.canRemoveMacroStep)
                    
                    Spacer()
                }
                .padding(.top, 16)
                .controlSize(.small)
            }
        }
    }

    var triggerEventsTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Table Header
            HStack(spacing: 12) {
                Text("#").frame(width: 24, alignment: .leading)
                Text(L10n.text("editor_trigger_events_field_keys")).frame(maxWidth: .infinity, alignment: .leading)
                Text(L10n.text("editor_trigger_events_field_gesture")).frame(width: 52, alignment: .leading)
                Text(L10n.text("editor_trigger_events_field_delay")).frame(width: 110, alignment: .leading)
                Spacer().frame(width: 16) // Drag handle column
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)

            Divider()

            // Table Body
            VStack(spacing: 0) {
                ForEach(Array(state.keySequenceSteps.enumerated()), id: \.offset) { rowIndex, step in
                    let isSelected = isStepSelected(index: rowIndex)
                    let gestureMode = state.triggerEventGestureMode(forStepAt: rowIndex)
                    
                    HStack(spacing: 12) {
                        // Col 1: Index
                        Text(String(format: "%02d", rowIndex + 1))
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(.tertiary)
                            .frame(width: 24, alignment: .leading)

                        // Col 2: Keys (Row-integrated cell)
                        triggerEventsKeysCell(rowIndex: rowIndex)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Col 3: Gesture mode
                        Text(L10n.text(gestureMode.textKey))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(gestureMode == .hold ? .green : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(gestureMode == .hold ? Color.green.opacity(0.14) : Color.secondary.opacity(0.14))
                            )
                            .frame(width: 52, alignment: .leading)

                        // Col 4: Delay
                        HStack(spacing: 4) {
                            TextField("", value: keySequenceDelayBinding(index: rowIndex), formatter: NumberFormatter())
                                .textFieldStyle(.plain)
                                .frame(width: 36)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.caption, design: .monospaced).weight(.semibold))
                                .padding(2)
                                .background(Color.primary.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                            
                            Text("ms").font(.system(size: 8)).foregroundStyle(.tertiary)
                            
                            Stepper("", value: keySequenceDelayBinding(index: rowIndex), in: 0...5000, step: 10)
                                .labelsHidden()
                                .controlSize(.mini)
                        }
                        .frame(width: 110, alignment: .leading)

                        // Col 5: Drag
                        Image(systemName: "line.3.horizontal")
                            .font(.caption2)
                            .foregroundStyle(.quaternary)
                            .frame(width: 16)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                    .background(isSelected ? Color.accentColor.opacity(0.06) : Color.clear)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.2)) {
                            selectStep(index: rowIndex)
                        }
                    }
                    .onDrag {
                        selectStep(index: rowIndex)
                        return NSItemProvider(object: "\(rowIndex)" as NSString)
                    }

                    if rowIndex < state.keySequenceSteps.count - 1 {
                        Divider().padding(.leading, 36)
                    }
                }
                .onMove(perform: moveStep)
            }
        }
        .background(Color.primary.opacity(0.01))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    func triggerEventsKeysCell(rowIndex: Int) -> some View {
        KeyComboField(
            keyCodes: keySequenceKeysBinding(index: rowIndex),
            isEnabled: isBindingControlEnabled
        )
        .frame(height: 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nativeTokenFieldStyle()
    }
}
