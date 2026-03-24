# Inspector Panel 背景补齐实现说明（2026-03-23）

关联需求文档：`docs-linhay/features/inspector-panel-collapsible-list-2026-03-23.md`

## 目标
- 为 `EunomiaInspectorPanelView` 增加统一背景色，避免 Inspector 区域透明或底色不一致。

## 实现
1. 在 `EunomiaRootComponents.swift` 新增统一策略 `SidebarSurfacePolicy`：
   - `usesUnifiedBackground = true`
2. `EunomiaInspectorPanelView.body` 与 `EunomiaDeviceRuntimeSidebarView.body` 同时改为：
   - 使用相同策略开关
   - 使用相同背景 modifier：`nativeSidebarBackground()`
3. 不调整列表结构、分组折叠、选择逻辑，仅统一背景来源。

## 测试
1. `AppleNativeDesignTests` 新增：
   - `testDeviceAndInspectorUseUnifiedSidebarBackgroundPolicy`
2. 全量验证：
   - `swift test` 通过（以本次执行结果为准）。
