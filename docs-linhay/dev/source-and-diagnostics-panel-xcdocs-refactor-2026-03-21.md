# Source & Diagnostics Panel 按 xcdocs 收敛（2026-03-21）

## 目标
1. 按 `xcdocs` 的 SwiftUI 文档语义，确保 `sourceAndDiagnosticsPanel` 使用 Sidebar List 风格。
2. 将诊断状态分支从视图内联判断收敛为状态层衍生属性，降低 UI 分支重复。

## xcdocs 依据
1. `/documentation/SwiftUI/SidebarListStyle`
2. `/documentation/SwiftUI/ListStyle/sidebar`
3. `/documentation/SwiftUI/List#Styling-lists`

结论：侧栏列表应通过 `listStyle(_:)` 显式应用 `.sidebar`，以获得 Sidebar 交互与呈现语义。

## BDD 场景
1. Given 用户打开按键编辑页左侧 Source & Diagnostics，When 页面渲染，Then 左侧列表应使用 Sidebar 风格。
2. Given 诊断状态在可解析/不可解析之间切换，When 页面渲染诊断行，Then 文案 key 与图标名称应稳定映射到对应状态。

## TDD
1. 红灯：在 `KeyMappingEditorStateTests` 新增诊断状态断言，首次执行失败（缺少状态衍生属性）。
2. 绿灯：补齐状态衍生属性并改造面板后，测试通过。

## 实施
1. `KeyMappingEditorState` 新增：
   - `diagnosticsStatusTextKey`
   - `diagnosticsStatusSymbolName`
2. `sourceAndDiagnosticsPanel` 改造：
   - 诊断 `Label` 改为使用状态衍生属性。
   - `List` 增加 `.listStyle(.sidebar)`。

## 验证
1. `swift test --filter KeyMappingEditorStateTests -q` 通过。
2. `swift test -q` 全量通过（76 tests, 0 failed）。
