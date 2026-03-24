# Apple 原生 UI/UX 重设计技术方案（2026-03-20）

关联需求文档：`docs-linhay/features/apple-native-uiux-redesign-2026-03-20.md`

## 实施范围
1. `Sources/EunomiaKit/SwiftUI/EunomiaRuntime.swift`
2. `Tests/EunomiaKitTests/AppleNativeDesignTests.swift`
3. `Sources/EunomiaKit/Resources/en.lproj/Localizable.strings`
4. `Sources/EunomiaKit/Resources/zh-Hans.lproj/Localizable.strings`

## 信息架构（Apple 风格）
1. 顶层采用 `NavigationSplitView`：左侧 Sidebar 管理设备与运行控制，右侧 Detail 承载内容卡片与映射配置。
2. Detail 区升级为“主工作区 + 检查器”双栏：
   - 主工作区：手柄布局、实时轴值（高频观察区）
   - 检查器：运行状态、映射管理区（映射导航+工具）、输出编辑（配置与确认区）
3. 弹窗编辑器改为原生 `Form` + 清晰主次按钮层级。

## 视觉与交互策略
1. 统一间距与圆角 token，消除过度装饰与强视觉噪音。
2. 支持系统使用 Liquid Glass（`#available(macOS 26, *)`），低版本回退 `Material`。
3. 交互反馈使用系统控件默认动效与按钮样式，减少自定义复杂动画。

## 兼容与风险
1. 业务逻辑层（`EunomiaStore`）保持不改，降低功能回归风险。
2. 若当前 SDK 不支持 Liquid Glass API，则保持接口位并退化为 Material，以保证可编译与可运行。
3. 现有测试中关于旧视觉 token 的断言将迁移到 Apple 原生 token 断言。

## 验证计划
1. TDD 红灯：新增 Apple 设计门禁测试，先失败。
2. TDD 绿灯：实现设计 token 与新结构后测试通过。
3. 回归：`swift test`、`xcodebuild build`、`xcodebuild test`。

## 实际结果
1. 红灯阶段已触发：`AppleNativeDesignMetrics` 未实现导致编译失败。
2. 绿灯阶段已完成：
   - 新增 `EunomiaRootView.swift`，作为新默认根视图。
   - 旧根视图实现已下线，保留 `EunomiaStore` 与共享运行时模型供新 UI 使用。
   - `KeyCodeField` 放宽为文件内可复用，供新编辑界面使用。
3. 兼容策略落地：
   - 保持 `macOS 11` 可编译，避免 `foregroundStyle` / `Material` 等高版本 API 直接依赖。
   - `NavigationSplitView` 做 `macOS 13+` 可用性保护并提供 `NavigationView` 回退。
   - Liquid Glass 仅在编译器和系统能力满足时启用。
4. 验证通过：
   - `swift test` 全量通过。
   - Xcode 工程 `build` 通过。
   - Xcode 工程 `EunomiaTests` 通过。

## 2026-03-20（二次迭代）
1. 采用 TDD 为双栏布局补红灯：
   - `AppleNativeDesignTests` 新增断言：
     - `mainMinWidth == 560`
     - `inspectorIdealWidth == 340`
     - `inspectorMaxWidth == 420`
2. 绿灯实现：
   - `AppleNativeDesignMetrics` 增加上述布局 token。
   - `detail` 从单列 `ScrollView` 重构为 `HSplitView`。
   - 业务 `store` 绑定与卡片内部逻辑保持不变，仅做区块重排。
3. 回归结果：
   - `swift test`（39 tests）通过。
   - `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme Eunomia -destination 'platform=macOS' test -only-testing:EunomiaTests` 通过。

## 2026-03-20（三次迭代：Sidebar 语义修正）
1. 问题：Sidebar 之前使用了自定义卡片包裹与局部滚动区，偏离系统 Sidebar 语义。
2. 修正：
   - 侧栏改为顶层 `List(selection:)` + `.listStyle(.sidebar)`。
   - 移除自定义 `nativeSidebarSurface` 包裹和固定高度限制，恢复系统侧栏行为。
   - 将映射列表、映射操作、全局开关与权限引导整理为 Sidebar Section。
3. 结果：侧栏行为与 Apple 文档中的“导航+分组信息”模式一致，且不影响 `store` 业务绑定。

## 2026-03-20（四次迭代：默认入口切换）
1. 用户要求“直接换”为新版主界面默认入口。
2. 调整：
   - `ContentView` 默认分支改为 `EunomiaRootView`。
   - 移除旧入口回退路径，统一走新版根视图。
   - 测试环境 `XCTestConfigurationFilePath` fallback 逻辑保持不变。
3. 验证：
   - `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme Eunomia -destination 'platform=macOS' test -only-testing:EunomiaTests` 通过。

## 2026-03-20（五次迭代：侧边栏头部去重）
1. 问题：在 `NavigationSplitView` 下，侧边栏内额外渲染应用标题区，会和系统工具栏形成双层“导航头”观感。
2. 修正：
   - 移除 Sidebar 内部的 `app_title/app_subtitle` 自定义头部 section。
   - 保持侧边栏从映射分组开始，遵循系统导航层级。
3. 验证：
   - `swift test --filter AppleNativeDesignTests` 通过。
   - `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme Eunomia -destination 'platform=macOS' test -only-testing:EunomiaTests` 通过。

## 2026-03-20（六次迭代：侧边栏独立背景色）
1. 需求：侧边栏需要独立背景色，提升分栏识别度。
2. 实现：
   - 新增 token：`AppleNativeDesignMetrics.sidebarBackgroundOpacity = 0.84`。
   - 侧边栏 `List(.sidebar)` 应用 `nativeSidebarBackground()`。
   - `macOS 13+` 使用 `.scrollContentBackground(.hidden)` 避免系统滚动底色覆盖自定义背景。
3. 验证：
   - `swift test --filter AppleNativeDesignTests` 通过。
   - `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme Eunomia -destination 'platform=macOS' test -only-testing:EunomiaTests` 通过。

## 2026-03-20（七次迭代：去卡片化侧边栏）
1. 问题：侧边栏中混合了导航项与表单控件，`List` section 视觉上呈现卡片/设置面板风格。
2. 修正：
   - `List(.sidebar)` 仅保留映射导航列表（`mappings` section）。
   - 重命名、增删/排序、模拟事件开关与权限提示移动到 `List` 下方独立工具区。
   - 新增布局 token：`sidebarToolsSpacing`。
3. 验证：
   - `swift test --filter AppleNativeDesignTests` 通过。
   - `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme Eunomia -destination 'platform=macOS' test -only-testing:EunomiaTests` 通过。

## 2026-03-20（八次迭代：状态栏与侧边栏同色）
1. 需求：侧边栏继续去卡片化；状态栏与侧边栏背景保持一致。
2. 修正：
   - 侧边栏导航列表从 section 容器进一步简化为纯导航行（标题移出 `List`）。
   - 新增 `statusBarBackgroundOpacity`，并将状态区改为 `nativeStatusBar(...)`，背景复用侧边栏色板。
3. 验证：
   - `swift test --filter AppleNativeDesignTests` 通过。
   - `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme Eunomia -destination 'platform=macOS' test -only-testing:EunomiaTests` 通过。

## 2026-03-20（九次迭代：设备运行区右移）
1. 需求：侧边栏只保留映射导航与映射工具；设备列表与“模拟事件”控制移到右侧检查器。
2. TDD：
   - 新增 `InspectorRuntimeControlStateTests`，先以 `InspectorRuntimeControlState` 缺失触发红灯。
   - 实现 `InspectorRuntimeControlState` 与新卡片 `EunomiaDeviceRuntimeCardView` 后转绿。
3. 实现：
   - `EunomiaMappingSidebarView` 移除模拟事件与辅助功能权限引导，仅保留映射工具。
   - `EunomiaInspectorPanelView` 扩展为三段：状态卡、设备运行卡、输出编辑卡。
   - 新增 `EunomiaDeviceRuntimeCardView`：承载设备树（`OutlineGroup`）、模拟事件开关、权限提示与系统设置跳转。
4. 验证：
   - `swift test` 通过（40 tests, 0 failed）。

## 2026-03-20（十次迭代：侧栏与检查器职责再交换）
1. 需求：侧边栏显示“设备与运行”；右侧检查器显示“映射导航 + 映射工具”。
2. TDD：
   - 新增 `RootPanelLayoutTests`，先以 `RootPanelLayout` 缺失触发红灯。
   - 实现 `RootPanelLayout.current` 后转绿，锁定版面职责，防止回退。
3. 实现：
   - 新增 `RootPanelLayout`（`sidebarRole=.deviceRuntime`，`inspectorRoles=[.status, .mappingManager, .outputEditor]`）。
   - 新增 `EunomiaDeviceRuntimeSidebarView`，将设备树、模拟事件开关、辅助功能权限提示放入 Sidebar。
   - `EunomiaInspectorPanelView` 中间段改为映射管理面板，承载 `EunomiaMappingSidebarView`（映射导航+重命名+增删+上下移动）。
   - `EunomiaMappingSidebarView` 增加可配置样式参数，以便在 Sidebar / Inspector 场景复用。
4. 验证：
   - `swift test --filter RootPanelLayoutTests` 通过。
   - `swift test` 通过（42 tests, 0 failed）。

## 2026-03-20（十一次迭代：侧栏节点动效与图标语义）
1. 问题：
   - 设备树展开子节点出现插入动画，视觉上有“飞入”感，不符合侧栏稳态浏览体验。
   - 节点图标使用通用 `folder`，语义不准确。
2. 修正：
   - 在设备侧栏 `List` 上设置 `.transaction { animation = nil }`，关闭该区域的插入动画。
   - 新增 `DeviceTreeNodeStyle.symbolName(for:)`，按节点语义映射图标：
     - 设备节点：`gamecontroller.fill`
     - 轴分组：`slider.horizontal.3`
     - 按键分组：`square.grid.2x2`
     - 叶子节点：`circle.fill`
3. 测试：
   - 新增 `DeviceTreeNodeStyleTests`（4 条），覆盖上述图标映射规则。
4. 验证：
   - `swift test --filter DeviceTreeNodeStyleTests` 通过。
   - `swift test` 通过（46 tests, 0 failed）。

## 2026-03-21（十二次迭代：按 Apple HIG 侧栏规范重构）
1. 输入依据：
   - 参考 Apple HIG Sidebar 页面：`https://developer.apple.com/design/human-interface-guidelines/sidebars`
   - 使用文档数据接口校验规则：`/tutorials/data/design/human-interface-guidelines/sidebars.json`
2. 设计约束落地：
   - 设备树展示层级压缩为两级（设备 -> 控件），避免侧栏出现多级深层嵌套。
   - 运行控制（模拟事件与权限提示）放入 Sidebar 列表上部 Section，不再固定到底部工具区。
   - 保持系统 `List(.sidebar)` 交互语义与系统图标体系。
3. 实现细节：
   - 新增 `DeviceRuntimeSidebarHierarchy.project(_:)`，将任意深度树投影为两级，并为叶子节点补充分组上下文文案（示例：`Buttons · Button A`）。
   - `EunomiaDeviceRuntimeSidebarView` 重构为单一 `List`，包含：
     - `Runtime` section：`simulate_events` + AX 权限提示
     - `Devices` section：两级 `OutlineGroup` + 右键“按键详情”
   - 移除侧栏自定义背景包裹，减少与系统 Sidebar 语义冲突。
   - 根视图去除外层全局 padding，恢复更接近原生侧栏高度与边界行为。
4. TDD 与验证：
   - 红灯：新增 `SidebarHierarchyPresentationTests`（先失败，缺少 `DeviceRuntimeSidebarHierarchy`）。
   - 绿灯：实现后通过 `swift test --filter SidebarHierarchyPresentationTests`。
   - 全量验证：
     - `swift test` 通过（48 tests, 0 failed）。
     - `xcodebuild ... test -only-testing:EunomiaTests` 在默认部署目标下失败（工程目标版本不一致）。
     - 使用 `MACOSX_DEPLOYMENT_TARGET=26.2` 覆盖后，`xcodebuild ... test -only-testing:EunomiaTests` 通过。

## 2026-03-21（十三次迭代：辅助功能设置跳转按文档收敛）
1. 问题：
   - `openAccessibilitySettings()` 使用硬编码 URL Scheme（`x-apple.systempreferences:...`），兼容性与文档一致性弱。
2. 文档依据（XCDocs）：
   - `AXIsProcessTrustedWithOptions(_:)` + `kAXTrustedCheckOptionPrompt`
   - 文档说明：传入 prompt 选项可异步提示用户前往系统辅助功能授权。
3. 实现：
   - 新增 `AccessibilityPermissionNavigator`：
     - `promptOptions`：`[kAXTrustedCheckOptionPrompt: true]`
     - `openAccessibilitySettingsPrompt()`：调用 `AXIsProcessTrustedWithOptions(...)`
   - `EunomiaStore.openAccessibilitySettings()` 改为调用上述导航器，并在调用后刷新权限状态。
4. 测试：
   - 新增 `AccessibilityPermissionNavigatorTests`，校验 prompt 配置字典含正确 key/value。
5. 验证：
   - `swift test --filter AccessibilityPermissionNavigatorTests` 通过。
   - `swift test` 全量通过（49 tests, 0 failed）。
   - `xcodebuild ... MACOSX_DEPLOYMENT_TARGET=26.2 test -only-testing:EunomiaTests` 通过。

## 2026-03-21（十四次迭代：侧栏权限提示与图标样式收敛）
1. 问题：
   - 侧栏“辅助功能权限”提示视觉样式偏弱，不像系统侧栏中的告警/行动提示。
   - 设备树图标偏“填充重视觉”，与 Apple Sidebar 语义图标风格不一致。
2. 实现：
   - `EunomiaDeviceRuntimeSidebarView` 中权限提示改为：
     - 告警行图标：`exclamationmark.triangle.fill`（黄色语义）
     - 行动按钮：`Label + .bordered + .small`（`arrow.up.right.square`）
   - 设备树图标改为更轻量系统语义：
     - 设备分组：`gamecontroller`
     - 轴分组：`dial.horizontal`
     - 按键分组：`button.horizontal`
     - 叶子节点：`smallcircle.filled.circle`
   - 侧栏预览高度统一为完整侧栏比例（`760`），避免预览误判为“非侧栏”高度。
3. TDD：
   - 更新 `DeviceTreeNodeStyleTests` 期望值，先红灯后转绿。
4. 验证：
   - `swift test --filter DeviceTreeNodeStyleTests` 通过。
   - `swift test` 全量通过（49 tests, 0 failed）。
