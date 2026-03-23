import SwiftUI

struct AppleKeyMappingEditorSheet: View {
    enum EditorLayout {
        static let leftPanelMinWidth: CGFloat = 260
        static let leftPanelIdealWidth: CGFloat = 280
        static let leftPanelMaxWidth: CGFloat = 320
        static let labelColumnWidth: CGFloat = 118
    }
    
    let initialState: KeyMappingEditorState
    let onCancel: () -> Void
    let onSave: (KeyMappingEditorState) -> Void
    
    @State var state: KeyMappingEditorState
    @State var showsDiscardConfirmation = false
    @State var selectedStepIndex: Int?
    
    init(
        initialState: KeyMappingEditorState,
        onCancel: @escaping () -> Void,
        onSave: @escaping (KeyMappingEditorState) -> Void
    ) {
        self.initialState = initialState
        self.onCancel = onCancel
        self.onSave = onSave
        _state = State(initialValue: initialState)
        _selectedStepIndex = State(initialValue: initialState.keySequenceSteps.isEmpty ? nil : 0)
    }
    
    var body: some View {
        NavigationSplitView(sidebar: {
            sourceAndDiagnosticsPanel
                .frame(
                    minWidth: EditorLayout.leftPanelMinWidth,
                    idealWidth: EditorLayout.leftPanelIdealWidth,
                    maxWidth: EditorLayout.leftPanelMaxWidth
                )
        }, detail: {
            VStack {
                editorForm
                .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                header
            }
        })
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 860, minHeight: 560)
        .confirmationDialog(
            L10n.text("discard_changes_title"),
            isPresented: $showsDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("discard_changes_confirm")) {
                onCancel()
            }
            Button(L10n.text("discard_changes_keep_editing"), role: .cancel) {}
        } message: {
            Text(L10n.text("discard_changes_message"))
        }
    }
}
