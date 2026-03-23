# Inspector Panel 列表化与可折叠交互（2026-03-23）

## 背景
- 右侧 `EnjoyableInspectorPanelView` 之前采用“左导航 + 右详情”两栏结构。
- 新需求要求改为单列表展示，并支持每个模块独立折叠，减少焦点切换成本。

## 设计决策
1. 布局改为单列 `List`。
2. 每个模块以 `Section(isExpanded:)` 呈现，默认全部展开。
3. 模块包括：`Status`、`Mappings`、`Output Editor`、`Settings`。
4. 当角色列表变化时：
   - 保留仍然有效的展开状态
   - 若展开状态为空，回退为“全部展开”

## Apple API 依据（XCDocs）
- `DisclosureGroup.init(isExpanded:content:label:)`
- `Section.init(isExpanded:content:header:)`
- `Section#Collapsible-sections`

## BDD 验收场景
1. Given 用户进入右侧 Inspector 面板
   When 页面加载
   Then 所有模块以列表形式展示，且默认展开。
2. Given 用户点击某模块头部折叠控件
   When 模块折叠/展开
   Then 仅影响当前模块内容可见性。
3. Given 角色列表发生变化（增删模块）
   When 重新渲染 Inspector
   Then 旧的有效展开状态会被保留，无效状态被清理。

## 测试
- 新增 `InspectorPanelExpansionStateTests`，覆盖展开状态归一化逻辑。
