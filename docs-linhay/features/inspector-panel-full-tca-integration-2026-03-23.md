# Inspector Panel 完整接入 TCA（2026-03-23）

## 目标
- `EunomiaInspectorPanelView` 不再持有本地 UI 状态。
- Inspector 折叠状态完全由 `EunomiaRootFeature.State` 驱动。

## 实现
1. `EunomiaRootFeature.State` 新增 `inspectorExpandedRoles`。
2. `EunomiaRootFeature.View` 新增 action：
   - `setInspectorSectionExpanded(role:isExpanded:)`
3. reducer 负责折叠状态更新与归一化（空集合回退全展开）。
4. `EunomiaRootView` 将 `store.inspectorExpandedRoles` + action 回调传给 `EunomiaInspectorPanelView`。
5. `EunomiaInspectorPanelView` 改为纯渲染 + binding 回调，不再使用本地 `@State`。

## BDD 验收
1. Given 用户在 Inspector 折叠任一模块
   When 触发展开状态变更
   Then 状态通过 `EunomiaRootFeature` action 更新。
2. Given 当前仅一个模块展开
   When 用户尝试将其折叠
   Then 状态回退到“全部展开”，避免出现全折叠空白。

## 测试
- 新增/更新并通过：
  - `testSetInspectorSectionExpandedCollapsesRole`
  - `testSetInspectorSectionExpandedFallsBackToAllWhenEmpty`
  - `InspectorPanelExpansionStateTests`
