# 按键详情编辑器交互重构技术说明（2026-03-21）

关联需求文档：`docs-linhay/features/key-mapping-editor-interaction-refresh-2026-03-21.md`

## 实施范围
1. `Sources/EunomiaKit/SwiftUI/AppleKeyMappingEditorSheet.swift`
2. `Sources/EunomiaKit/SwiftUI/EunomiaRuntime.swift`
3. `Sources/EunomiaKit/Resources/zh-Hans.lproj/Localizable.strings`
4. `Sources/EunomiaKit/Resources/en.lproj/Localizable.strings`
5. `Tests/EunomiaKitTests/KeyMappingEditorStateTests.swift`

## 交互重构要点
1. 页面结构改为 `HSplitView` 双栏：左栏“源输入+诊断”，右栏“编辑表单”。
2. 保存按钮在 `isResolvable == false` 时禁用。
3. 取消操作引入未保存变更确认弹窗，避免误关导致输入丢失。
4. 编辑控件禁用逻辑统一为 `KeyMappingEditorState` 计算属性：
   - `canEditBindingControls`
   - `canRemoveMacroStep`
5. 增加 payload 对比能力 `hasSameEditingPayload(as:)`，用于判断是否存在未保存变更。

## xcdocs 依据
1. `Form`：数据录入场景使用系统标准控件。
2. `HSplitView`：横向可调分栏容器，适合源信息与配置分区并列。
3. `Modal presentations > Getting confirmation for an action`：取消/放弃操作需确认流程。

## 测试
1. 先红后绿：新增测试后先失败（缺少交互状态属性），补实现后通过。
2. `swift test --filter KeyMappingEditorStateTests -q` 通过。
3. `swift test -q` 全量通过（55 tests, 0 failed）。

## 2026-03-21（二次重构：单路径编辑流 + 保存规则对齐）

### 问题复盘
1. 原 `HSplitView` 双栏在弹窗上下文中产生滚动与焦点竞争，交互路径不直观。
2. “启用映射但未配置有效按键”时，页面可进入保存动作，用户反馈体验不合理。
3. 宏区空态文案复用了轴值提示，语义错误。

### 实现调整
1. `AppleKeyMappingEditorSheet` 重构为单栏 `Form`：
   - 结构顺序：`源输入` -> `绑定编辑` -> `宏步骤`
   - 头部增加未保存标识（`editor_unsaved_changes`）
   - 保留取消确认弹窗
2. `KeyMappingEditorState` 新增保存与按键有效性规则：
   - `hasConfiguredMacroStep`
   - `resolvedPrimaryKeyCode`
   - `canSaveChanges`
3. `applyKeyMappingEditorState(_:)` 改为使用 `resolvedPrimaryKeyCode`，保证保存判定与落盘逻辑一致。
4. 文案修正：
   - 新增 `editor_binding_required_hint`
   - 新增 `macro_sequence_empty_hint`
   - 中英文本地化同步。

### TDD
1. 红灯：`KeyMappingEditorStateTests` 新增两条规则测试（`canSaveChanges`、`hasConfiguredMacroStep`），先编译失败。
2. 绿灯：补齐状态属性与保存逻辑后通过。

### 验证
1. `swift test --filter KeyMappingEditorStateTests` 通过。
2. `swift test` 全量通过（57 tests, 0 failed）。

## 二次收敛实现（2026-03-21 02:00）
1. `AppleKeyMappingEditorSheet` 从单 `Form` 调整为 `HStack + Divider + 右侧 Form`：
   - 左侧固定宽度 `280`
   - 右侧占满剩余空间
2. 右侧编辑区统一标签列宽 `118`，应用于：
   - 主键位编辑
   - 触发阈值
   - 宏步骤行与操作行
3. 新增文案键：`macro_step_prefix`（zh/en）。
4. 回归：`swift test -q` 通过（57 tests, 0 failed）。

## xcdocs 规范化调整（2026-03-21 02:36）
依据文档：
1. `/documentation/SwiftUI/Form`
2. `/documentation/SwiftUI/HSplitView`
3. `/documentation/SwiftUI/Modal-presentations#Getting-confirmation-for-an-action`

落地结果：
1. 编辑器容器保持 `Form` 作为数据录入主容器（遵循平台原生表单行为）。
2. 主体布局切换到 `HSplitView`，支持分栏拖拽调整宽度。
3. 取消未保存修改优先使用 `confirmationDialog`；为 `macOS 11` 保留 `Alert` 兜底分支。
4. 右侧标签保持冒号风格与对齐列，接近 macOS 偏好设置语义。

## Preview 故障修复（2026-03-21 10:25）
问题：Xcode Preview JIT 报错 `CouldNotLoadInputObjectFile`，缺失 `resource_bundle_accessor.o`。

处理：
1. `Package.swift` 中 `EunomiaKit` product 从显式 `.static` 改为默认库类型（交由 SwiftPM 选择）。
2. 执行 `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme EunomiaKit -configuration Debug clean build` 重建预览所需中间产物。
3. 验证目标文件存在：
   - `.../Objects-normal/arm64/resource_bundle_accessor.o`

附加重构（swiftui-view-refactor）：
1. `AppleKeyMappingEditorSheet.swift` 按主结构 + `// MARK` + `private extension` 方式分区。
2. 顺序与职责更清晰：主结构仅保留状态、init、body；Subviews / View State / Actions-Bindings 分组。

回归：
1. `swift test -q` 通过（57 tests, 0 failed）。
2. `xcodebuild ... clean build` 成功。

## Sidebar 规范化修正（2026-03-21 10:33）
依据 `xcdocs`：
1. `/documentation/SwiftUI/SidebarListStyle`
2. `/documentation/SwiftUI/ListStyle/sidebar`
3. `/documentation/SwiftUI/List#Styling-lists`

调整：
1. `AppleKeyMappingEditorSheet` 左栏从 `ScrollView + GroupBox` 改为 `List + Section + .listStyle(.sidebar)`。
2. 保留原有信息内容（源输入、启用开关、诊断状态、阈值摘要、不可解析提示），仅调整容器语义与交互样式。

验证：
1. `swift test -q` 通过（57 tests, 0 failed）。
2. `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme EunomiaKit -configuration Debug build` 成功。

## 样式一致性收敛（2026-03-21 13:10）

### BDD 场景
1. Given 用户在主界面与按键详情页之间切换，When 查看按键输入控件底板，Then 两处视觉层级与圆角/透明度应一致。
2. Given 后续再次调整输入底板样式，When 修改设计 token，Then 主界面与详情页应同步生效，避免重复实现漂移。

### TDD
1. 红灯：在 `AppleNativeDesignTests` 增加 `inputFieldBackgroundOpacity` 断言，首次执行失败（缺少成员）。
2. 绿灯：新增统一 token 与修饰器后回归通过。

### 实施
1. `AppleNativeDesignMetrics` 新增统一 token：`inputFieldBackgroundOpacity = 0.7`。
2. `EunomiaRootStyling.swift` 新增 `nativeInputFieldBackground()` 修饰器，集中管理输入底板背景形态。
3. 替换重复实现：
   - `EunomiaRootView.swift` 的 key binding 与 macro step 输入背景改为 `.nativeInputFieldBackground()`。
   - `AppleKeyMappingEditorSheet.swift` 的对应输入背景改为 `.nativeInputFieldBackground()`。

### 验证
1. `swift test -q` 通过（57 tests, 0 failed）。
2. `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme EunomiaKit -configuration Debug build` 成功。

## 映射列表模式交互收敛（2026-03-21 13:20）

### BDD 场景
1. Given 用户处于映射列表模式，When 浏览账号（映射）列表，Then 不应出现底部增删移动作按钮。
2. Given 用户需要管理账号（映射），When 右键某一行，Then 可在上下文菜单完成新增、删除、上移、下移。
3. Given 当前账号（映射）处于选中态，When 列表渲染，Then 当前行应有高亮背景。

### TDD
1. 新增 `MappingSidebarContextActionStateTests`，覆盖删除/上移/下移可用性边界。
2. `swift test --filter MappingSidebarContextActionStateTests -q` 通过。

### 实施
1. `EunomiaMappingSidebarView.swift`
   - 新增 `MappingSidebarContextActionState`，集中管理右键菜单动作可用性。
   - 列表模式下移除底部增删移动作按钮，仅保留重命名输入框。
   - 将新增/删除/上移/下移统一放入 `contextMenu`。
   - 右键动作先切换当前选中行，再执行操作，确保操作目标与右键行一致。
   - 新增行高亮逻辑：当前选中或当前激活映射使用 `accentColor.opacity(0.18)`。
2. 新增测试文件：
   - `Tests/EunomiaKitTests/MappingSidebarContextActionStateTests.swift`

### 验证
1. `swift test -q` 通过（61 tests, 0 failed）。
2. `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme EunomiaKit -configuration Debug build` 成功。

## 设置面板主流侧边栏结构（2026-03-21 14:08）

### BDD 场景
1. Given 用户进入映射设置，When 浏览设置区域，Then 页面应呈现主流侧边栏结构（左侧导航列表 + 右侧详情）。
2. Given 用户在左侧选择账号（映射），When 详情区刷新，Then 右侧应显示当前选中账号信息与重命名入口。
3. Given 用户使用列表模式，When 进行账号管理，Then 仍只通过右键菜单执行新增/删除/上移/下移。

### TDD
1. 新增 `MappingSidebarSelectionStateTests`，先红灯（缺少 `MappingSidebarSelectionState`）。
2. 补实现后转绿，并全量回归通过。

### 实施
1. `EunomiaRootView.swift`
   - 新增 `MappingManagerLayoutPolicy.usesMainstreamSidebarList = true`。
   - 映射设置面板启用侧边栏模式渲染。
2. `EunomiaMappingSidebarView.swift`
   - 新增 `MappingSidebarSelectionState`，统一选中态回退规则（显式选中 > active > 首项 > 空）。
   - 列表改为 `Section + .sidebar` 结构。
   - 设置区域改为 `HSplitView`：
     - 左侧：账号（映射）侧边栏列表
     - 右侧：账号详情（标题 + 重命名）
   - 保留并延续右键菜单操作与当前行高亮。
3. 新增测试文件：
   - `Tests/EunomiaKitTests/MappingSidebarSelectionStateTests.swift`

### 验证
1. `swift test --filter MappingSidebarSelectionStateTests -q` 通过。
2. `swift test -q` 通过（65 tests, 0 failed）。
3. `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme EunomiaKit -configuration Debug build` 成功。

## 右侧详情内聚保存/取消（2026-03-21 14:21）

### BDD 场景
1. Given 用户在右侧详情编辑映射名称，When 修改名称后，Then 保存/取消按钮应出现在右侧详情面板内部。
2. Given 用户点击取消，When 草稿有变更，Then 草稿应回退为当前名称且不提交修改。
3. Given 用户点击保存或回车提交，When 草稿非空且有变化，Then 执行重命名并刷新为最新名称。

### TDD
1. 新增 `MappingRenamePanelStateTests` 并先红灯（缺少状态模型）。
2. 补实现后转绿，通过筛选与全量回归。

### 实施
1. `EunomiaMappingSidebarView.swift`
   - 新增 `MappingRenamePanelState`（`hasPendingChanges` / `canSave`）。
   - 新增 `@State renameDraftName` 作为右侧详情草稿。
   - 右侧详情改为：`TextField` + 面板内 `取消/保存` 按钮。
   - `取消` 回滚草稿；`保存` 与回车提交触发 `onRenameCommit`。
   - 选中项变化与名称变化时同步草稿。
2. 新增测试：
   - `Tests/EunomiaKitTests/MappingRenamePanelStateTests.swift`

### 验证
1. `swift test --filter MappingRenamePanelStateTests -q` 通过。
2. `swift test -q` 通过（69 tests, 0 failed）。
3. `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme EunomiaKit -configuration Debug build` 成功。

## Inspector 结构化重设计（2026-03-21 15:45）

### xcdocs 依据
1. `/documentation/SwiftUI/Picking-Container-Views-for-Your-Content#Group-views-and-controls-for-data-entry`
2. `/documentation/SwiftUI/List#Styling-lists`
3. `/documentation/SwiftUI/Section#Collapsible-sections`

### BDD 场景
1. Given 用户查看右侧 inspector，When 识别功能区，Then 应按状态/映射/输出分区显示，具备清晰层级。
2. Given inspector 包含多块内容，When 滚动浏览，Then 区块应保持统一 section 语义和列表样式。

### TDD
1. 新增 `InspectorPanelSectionDescriptorTests`：
   - 验证角色顺序保持；
   - 验证角色到标题键映射正确。
2. `swift test --filter InspectorPanelSectionDescriptorTests -q` 通过。

### 实施
1. `EunomiaRootComponents.swift`
   - 新增 `InspectorPanelSectionDescriptor`，统一 inspector section 描述（role/title/symbol）。
   - `EunomiaInspectorPanelView` 改为 `List + Section` 结构，替代纯 `ScrollView + VStack` 堆叠。
   - 各 section 行统一 row insets / 分隔线隐藏 / 透明行背景，保证卡片式内容在列表中的一致性。
2. `EunomiaRootView.swift`
   - 传入 `panelLayout.inspectorRoles`，由 inspector 按角色动态组装 section。
3. 新增测试文件：
   - `Tests/EunomiaKitTests/InspectorPanelSectionDescriptorTests.swift`

### 验证
1. `swift test -q` 通过（71 tests, 0 failed）。
2. `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme EunomiaKit -configuration Debug build` 成功。

## Inspector 对齐 Prowl 设置结构（2026-03-21 23:08）

### xcdocs 依据
1. `/documentation/SwiftUI/NavigationSplitView/init(sidebar:detail:)`
2. `/documentation/SwiftUI/List/init(selection:content:)`

### BDD 场景
1. Given 用户进入右侧 inspector，When 查看模块入口，Then 应先看到左侧导航列表，再在右侧查看详情内容。
2. Given 用户切换左侧导航项，When 当前项变化，Then 右侧详情应切换为对应模块内容。
3. Given 当前选中项无效或为空，When inspector 初始化，Then 应自动回退到首个可用模块。

### TDD
1. 新增 `InspectorPanelNavigationStateTests`，先红灯（缺少 `InspectorPanelNavigationState`）。
2. 补实现后转绿，并通过筛选与全量回归。

### 实施
1. `EunomiaRootComponents.swift`
   - `RootSidebarRole` 与 `RootInspectorRole` 升级为 `Hashable`，支撑 `List(selection:)`。
   - 新增 `InspectorPanelNavigationState`，统一处理选中回退规则（显式选中 > 首项 > 空）。
   - `EunomiaInspectorPanelView` 改为内部 `HSplitView`：
     - 左侧：`List(selection:) + .sidebar` 导航；
     - 右侧：当前模块标题 + 对应详情内容。
   - 通过 `@State selectedRole` 保持切换状态，并在角色列表变化时自动纠正到有效值。
2. 新增测试文件：
   - `Tests/EunomiaKitTests/InspectorPanelNavigationStateTests.swift`

### 验证
1. `swift test --filter InspectorPanelNavigationStateTests -q` 通过。
2. `swift test -q` 通过（74 tests, 0 failed）。
3. `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme EunomiaKit -configuration Debug build` 成功。
