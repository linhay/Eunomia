# Inspector Panel 列表化与可折叠交互（2026-03-23）

## 背景
- 右侧 `EunomiaInspectorPanelView` 之前采用“左导航 + 右详情”两栏结构。
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

## 追加变更：Mappings 上下布局（17:37）
- 用户反馈：Mappings 不要左右分栏。
- 调整：`EunomiaMappingSidebarView` 主流样式改为上下结构。
  - 上方：mapping 列表
  - 下方：mapping 详情
- 详情区支持展开/收起（chevron 按钮）。
- 展开状态由 TCA 状态驱动：`EunomiaRootFeature.State.mappingDetailExpanded`，通过 action `setMappingDetailExpanded(Bool)` 更新。
- 验证：`swift test --filter EunomiaRootFeatureTests` 通过（14 tests, 0 failed）。

## 追加变更：Inspector 面板背景统一（21:30）
- 用户反馈：`EunomiaInspectorPanelView` 也需要背景色，与侧边面板视觉保持一致。
- 调整：
  - Inspector 根容器应用统一 sidebar 背景样式（`nativeSidebarBackground`）。
  - 不改变当前列表结构与折叠交互，仅补充背景层。
- 验证目标：
  - 视觉上 Inspector 区域具有稳定底色，不再出现透明/纯白穿透感。
  - 既有交互（Section 折叠、列表选择）不受影响。

## 追加变更：Inspector 与左侧完全同色（21:36）
- 用户反馈：不仅要有背景，还要求 Inspector 与左侧设备栏完全同色。
- 调整：
  - 左右两栏改为共用同一背景策略开关 `SidebarSurfacePolicy.usesUnifiedBackground`。
  - `EunomiaInspectorPanelView` 与 `EunomiaDeviceRuntimeSidebarView` 均使用同一 `nativeSidebarBackground()`。
- 验证目标：
  - 左右栏背景色来源一致，不再出现色差。

## 追加变更：Inspector 面板现代化重构（22:05）
- 用户反馈：当前 `EunomiaInspectorPanel` 视觉和结构不够现代，需要直接重构。
- 重构目标：
  1. 从传统 `List + Section` 观感，升级为卡片化滚动面板。
  2. 每个模块卡片具备明确标题、副标题、图标与展开/收起操作。
  3. 保留现有功能与状态联动（`expandedRoles`、`onSetExpanded`）不变。
  4. 空态保持可读性，沿用 `ContentUnavailableView` 语义。
- BDD 验收场景：
  1. Given Inspector 包含多个角色
     When 面板渲染
     Then 各角色以独立卡片形式展示，卡片头部包含标题与副标题。
  2. Given 用户点击卡片头部展开控件
     When 展开状态切换
     Then 仅当前卡片内容显示或隐藏，其他卡片不受影响。
  3. Given Inspector 无角色
     When 面板渲染
     Then 显示统一空态，并保留背景样式一致性。
