import SwiftUI

#if DEBUG
private struct DeviceRuntimeSidebarPreviewContainer: View {
    let hasAccessibilityPermission: Bool
    @State private var selectedInputID: String? = "dual-sense-edge~Button A"
    @State private var simulatingEvents = true

    private let deviceTree: [InputNode] = [
        InputNode(
            id: "dual-sense-edge",
            name: "DualSense Edge Wireless Controller",
            isLeaf: false,
            children: [
                InputNode(
                    id: "dual-sense-edge-buttons",
                    name: "Buttons",
                    isLeaf: false,
                    children: [
                        InputNode(id: "dual-sense-edge~Button A", name: "Button A", isLeaf: true),
                        InputNode(id: "dual-sense-edge~Button B", name: "Button B", isLeaf: true),
                        InputNode(id: "dual-sense-edge~Button X", name: "Button X", isLeaf: true),
                        InputNode(id: "dual-sense-edge~Button Y", name: "Button Y", isLeaf: true)
                    ]
                ),
                InputNode(
                    id: "dual-sense-edge-axes",
                    name: "Axes",
                    isLeaf: false,
                    children: [
                        InputNode(id: "dual-sense-edge~Axis 1", name: "Left Stick X", isLeaf: true),
                        InputNode(id: "dual-sense-edge~Axis 2", name: "Left Stick Y", isLeaf: true),
                        InputNode(id: "dual-sense-edge~Axis 3", name: "Right Stick X", isLeaf: true),
                        InputNode(id: "dual-sense-edge~Axis 4", name: "Right Stick Y", isLeaf: true)
                    ]
                )
            ]
        ),
        InputNode(
            id: "xbox-elite-series-2",
            name: "Xbox Elite Wireless Controller Series 2",
            isLeaf: false,
            children: [
                InputNode(
                    id: "xbox-elite-series-2-buttons",
                    name: "Buttons",
                    isLeaf: false,
                    children: [
                        InputNode(id: "xbox-elite-series-2~Button A", name: "Button A", isLeaf: true),
                        InputNode(id: "xbox-elite-series-2~Button LB", name: "Button LB", isLeaf: true)
                    ]
                )
            ]
        )
    ]

    var body: some View {
        EunomiaDeviceRuntimeSidebarView(
            deviceTree: deviceTree,
            selectedInputID: $selectedInputID,
            simulatingEvents: $simulatingEvents,
            hasAccessibilityPermission: hasAccessibilityPermission,
            onOpenAccessibilitySettings: {},
            onOpenKeyMappingEditor: { _ in }
        )
    }
}

struct EunomiaRootComponents_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EunomiaStatusCardView(
                statusKind: .liveInput,
                activeMappingName: "FPS Layout",
                activeInputPath: "DualSense 5 / Axis 1~High",
                hasDevices: true
            )
            .padding()
            .frame(width: 520, height: 220)
            .previewDisplayName("Status Card")

            EunomiaLiveAxisCardView(
                liveAxisValues: [
                    1: 0.68,
                    2: -0.42,
                    3: 0.10,
                    4: -0.89
                ]
            )
            .padding()
            .frame(width: 560, height: 260)
            .previewDisplayName("Live Axis Card")

            EunomiaDetailSplitView(
                mainWorkspace: {
                    Text("Preview Main Workspace")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                },
                inspectorPanel: {
                    EunomiaInspectorPanelView(
                        inspectorRoles: [.status, .mappingManager, .outputEditor],
                        expandedRoles: [.status, .mappingManager, .outputEditor],
                        onSetExpanded: { _, _ in },
                        statusCard: {
                            EunomiaStatusCardView(
                                statusKind: .monitoringStopped,
                                activeMappingName: "Default",
                                activeInputPath: "",
                                hasDevices: false
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
                }
            )
            .padding()
            .frame(width: 980, height: 420)
            .previewDisplayName("Detail Split")

            EunomiaInspectorPanelView(
                inspectorRoles: [.status, .mappingManager, .outputEditor],
                expandedRoles: [.status, .mappingManager, .outputEditor],
                onSetExpanded: { _, _ in },
                statusCard: {
                    EunomiaStatusCardView(
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
            .frame(width: 780, height: 520)
            .previewDisplayName("Inspector Panel")

            DeviceRuntimeSidebarPreviewContainer(hasAccessibilityPermission: false)
                .frame(width: 280, height: 760, alignment: .topLeading)
                .previewDisplayName("Device Runtime Sidebar (No Permission)")

            DeviceRuntimeSidebarPreviewContainer(hasAccessibilityPermission: true)
                .frame(width: 280, height: 760, alignment: .topLeading)
                .previewDisplayName("Device Runtime Sidebar (Permission Ready)")
        }
    }
}
#endif
