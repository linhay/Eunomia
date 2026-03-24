import SwiftUI

#if DEBUG
struct EunomiaInspectorPanel_Previews: PreviewProvider {
    private static let allRoles: [RootInspectorRole] = [.status, .mappingManager, .outputEditor]

    @ViewBuilder
    private static func makePreview(
        title: String,
        inspectorRoles: [RootInspectorRole],
        expandedRoles: Set<RootInspectorRole>,
        statusKind: DashboardStatusKind,
        activeMappingName: String,
        activeInputPath: String,
        hasDevices: Bool,
        mappingDetailExpanded: Bool
    ) -> some View {
        EunomiaInspectorPanelView(
            inspectorRoles: inspectorRoles,
            expandedRoles: expandedRoles,
            onSetExpanded: { _, _ in },
            statusCard: {
                EunomiaStatusCardView(
                    statusKind: statusKind,
                    activeMappingName: activeMappingName,
                    activeInputPath: activeInputPath,
                    hasDevices: hasDevices
                )
            },
            mappingManagerPanel: {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("FPS", systemImage: "circle.inset.filled")
                        Label("Racing", systemImage: "circle")
                        Label("Story", systemImage: "circle")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)

                    Divider()

                    HStack {
                        Label("Racing", systemImage: "sidebar.bottom")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: mappingDetailExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)

                    if mappingDetailExpanded {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rename")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Racing")
                                .font(.callout)
                            HStack {
                                Spacer()
                                Text("Cancel")
                                    .foregroundStyle(.secondary)
                                Text("Save")
                                    .fontWeight(.semibold)
                            }
                            .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    }
                }
            },
            outputEditorCard: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type: Key Press")
                    Text("Keys: fn space")
                    Text("Threshold: 55%")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .frame(width: 440, height: 520)
        .padding()
        .previewDisplayName(title)
    }

    static var previews: some View {
        Group {
            makePreview(
                title: "Inspector · All Expanded",
                inspectorRoles: allRoles,
                expandedRoles: Set(allRoles),
                statusKind: .liveInput,
                activeMappingName: "FPS Layout",
                activeInputPath: "DualSense Edge / Button A",
                hasDevices: true,
                mappingDetailExpanded: true
            )

            makePreview(
                title: "Inspector · Mappings Collapsed",
                inspectorRoles: allRoles,
                expandedRoles: [.status, .mappingManager],
                statusKind: .liveInput,
                activeMappingName: "Racing",
                activeInputPath: "Xbox Elite / Trigger RT",
                hasDevices: true,
                mappingDetailExpanded: false
            )

            makePreview(
                title: "Inspector · No Controller",
                inspectorRoles: allRoles,
                expandedRoles: Set(allRoles),
                statusKind: .noController,
                activeMappingName: "-",
                activeInputPath: "-",
                hasDevices: false,
                mappingDetailExpanded: true
            )

            makePreview(
                title: "Inspector · Empty Roles",
                inspectorRoles: [],
                expandedRoles: [],
                statusKind: .monitoringStopped,
                activeMappingName: "-",
                activeInputPath: "-",
                hasDevices: false,
                mappingDetailExpanded: false
            )
        }
    }
}
#endif
