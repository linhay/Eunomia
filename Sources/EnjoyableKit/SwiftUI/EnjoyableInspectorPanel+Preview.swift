import SwiftUI

#if DEBUG
struct EnjoyableInspectorPanel_Previews: PreviewProvider {
    static var previews: some View {
        EnjoyableInspectorPanelView(
            inspectorRoles: [.status, .mappingManager, .outputEditor],
            expandedRoles: [.status, .mappingManager, .outputEditor],
            onSetExpanded: { _, _ in },
            statusCard: {
                EnjoyableStatusCardView(
                    statusKind: .liveInput,
                    activeMappingName: "FPS Layout",
                    activeInputPath: "DualSense 5 / Button A",
                    hasDevices: true
                )
            },
            mappingManagerPanel: {
                NativePanelCard(
                    title: L10n.text("mappings_title"),
                    symbol: "list.bullet",
                    surfaceStyle: .solid
                ) {
                    Text("Preview Mapping Manager")
                        .foregroundStyle(.secondary)
                }
            },
            outputEditorCard: {
                NativePanelCard(
                    title: L10n.text("output_editor_title"),
                    symbol: "keyboard.badge.ellipsis",
                    surfaceStyle: .solid
                ) {
                    Text("Preview Output Editor")
                        .foregroundStyle(.secondary)
                }
            }
        )
        .frame(width: 440, height: 520)
        .padding()
        .previewDisplayName("Inspector Panel")
    }
}
#endif
