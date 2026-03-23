import SwiftUI

#if DEBUG
private struct EnjoyableMappingManagerPanelPreviewContainer: View {
    @State private var mappingSelection: Int? = 1
    @State private var mappingName = "Racing"
    @State private var mappingRenameDraftName = "Racing"

    var body: some View {
        EnjoyableMappingSidebarView(
            mappingNames: ["Default", "Racing", "FPS Layout"],
            activeMappingIndex: mappingSelection ?? 1,
            mappingSelection: $mappingSelection,
            mappingName: $mappingName,
            renameDraftName: $mappingRenameDraftName,
            onRenameCommit: {},
            onAddMapping: {},
            onRemoveActiveMapping: {},
            onMoveActiveMappingUp: {},
            onMoveActiveMappingDown: {}
        )
        .frame(width: 320, height: 620)
    }
}

struct EnjoyableMappingManagerPanelView_Previews: PreviewProvider {
    static var previews: some View {
        EnjoyableMappingManagerPanelPreviewContainer()
    }
}
#endif
