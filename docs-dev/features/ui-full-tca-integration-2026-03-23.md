# UI 全面接入 TCA（2026-03-23）

## 目标
- 将业务界面的本地状态（`@State`）上收到 reducer，统一由 TCA 管理。

## 本轮完成
1. `AppleKeyMappingEditorSheet` 全量迁移为 `Store` 驱动。
2. `EnjoyableInspectorPanelView` 折叠状态迁移到 `EnjoyableRootFeature.State`。
3. `EnjoyableMappingSidebarView` 的 `renameDraftName` 从本地 `@State` 上收至 `EnjoyableRootFeature.State.mappingRenameDraftName`。

## 结果
- `Sources/EnjoyableKit/SwiftUI` 下业务视图已无本地 `@State`；仅预览文件保留 `@State`（用于 Canvas 交互演示）。

## 验证
- `swift build` 通过。
- 关键测试通过：
  - `AppleKeyMappingEditorFeatureTests`
  - `EnjoyableRootFeatureTests`（TCA 新增场景）
  - `MappingRenamePanelStateTests`
  - `MappingSidebarSelectionStateTests`

## 清理阶段（17:16）
- 移除历史演示实现：`Sources/EnjoyableKit/SwiftUI/KeyMappingEditorTCAFeature.swift`。
- 移除对应示例测试：`Tests/EnjoyableKitTests/TCAIntegrationTests.swift`。
- 原因：该 feature 已被 `AppleKeyMappingEditorFeature + EnjoyableRootFeature(ifLet 组合)` 完整替代，保留会造成双实现认知负担。
- 顺带修复：`EnjoyableMappingSidebarView` 的 `onChange` 迁移到 macOS 14 新签名，消除弃用警告。
- 验证：`swift test` 全量通过（111 tests, 0 failed）。
