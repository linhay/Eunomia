import SwiftUI

#if DEBUG
private struct EunomiaMappingManagerPanelPreviewContainer: View {
    @State private var mappingSelection: Int? = 1
    @State private var mappingName = "Racing"
    @State private var mappingRenameDraftName = "Racing"
    @State private var detailExpanded = true

    var body: some View {
        EunomiaMappingSidebarView(
            mappingNames: ["Default", "Racing", "FPS Layout"],
            activeMappingIndex: mappingSelection ?? 1,
            mappingSelection: $mappingSelection,
            mappingName: $mappingName,
            renameDraftName: $mappingRenameDraftName,
            detailExpanded: $detailExpanded,
            onRenameCommit: {},
            onAddMapping: {},
            onImportMapping: {},
            onExportMapping: {},
            onRemoveActiveMapping: {},
            onMoveActiveMappingUp: {},
            onMoveActiveMappingDown: {}
        )
        .frame(width: 320, height: 620)
    }
}

struct EunomiaMappingManagerPanelView_Previews: PreviewProvider {
    static var previews: some View {
        EunomiaMappingManagerPanelPreviewContainer()
    }
}
#endif
