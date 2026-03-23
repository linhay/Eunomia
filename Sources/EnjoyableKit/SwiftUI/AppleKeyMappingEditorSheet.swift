import ComposableArchitecture
import SwiftUI

struct AppleKeyMappingEditorSheet: View {
    enum EditorLayout {
        static let leftPanelMinWidth: CGFloat = 260
        static let leftPanelIdealWidth: CGFloat = 280
        static let leftPanelMaxWidth: CGFloat = 320
        static let labelColumnWidth: CGFloat = 118
    }
    
    let store: StoreOf<AppleKeyMappingEditorFeature>

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
            isPresented: showsDiscardConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button(L10n.text("discard_changes_confirm")) {
                store.send(.discardConfirmed)
            }
            Button(L10n.text("discard_changes_keep_editing"), role: .cancel) {}
        } message: {
            Text(L10n.text("discard_changes_message"))
        }
    }
}
