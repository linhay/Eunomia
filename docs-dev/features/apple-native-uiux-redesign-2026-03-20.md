# Enjoyable Apple 原生 UI/UX 重设计（2026-03-20）

## 背景
- 当前主界面视觉风格偏“重装饰”，与 Apple Human Interface 风格不一致。
- 需要统一为 Apple 原生信息架构与交互语言，并引入 Liquid Glass（可用时）。

## 目标
- 重做 `EnjoyableRootView` 的整体信息架构与视觉语言。
- 采用 Apple 风格导航与分区：Sidebar + Detail（macOS 典型结构）。
- 在支持系统上使用 Liquid Glass；不支持时提供 Material 回退。
- 保留核心功能路径：映射选择、输入监控状态、手柄可视化、按键映射编辑入口。

## 验收标准（BDD）
1. 场景：整体结构符合 Apple 交互习惯
   - Given 用户启动应用
   - When 进入主界面
   - Then 看到 Sidebar/Detail 的双栏结构，信息分区清晰且可读

2. 场景：视觉系统一致
   - Given 用户在主界面浏览
   - When 查看不同功能卡片与按钮
   - Then 圆角、间距、层级与交互反馈保持一致，不再使用强烈非原生风格

3. 场景：Liquid Glass 与回退
   - Given 系统支持 Liquid Glass
   - When 显示主界面关键容器
   - Then 使用 Liquid Glass API 呈现
   - And 在不支持环境下回退到 Material，不影响功能

4. 场景：核心功能保持可用
   - Given 已连接手柄或开启输入监控
   - When 用户切换映射、查看状态、打开按键映射编辑
   - Then 功能路径可达，行为与原能力一致

5. 场景：侧边栏与检查器职责清晰
   - Given 用户进入主界面
   - When 浏览左侧 Sidebar 与右侧检查器
   - Then Sidebar 承载设备列表、模拟事件开关与权限引导
   - And 右侧检查器承载映射导航与映射工具

6. 场景：侧边栏符合 Apple HIG（Sidebars）
   - Given 用户在 macOS 侧边栏浏览设备与运行信息
   - When 展开层级并切换运行开关
   - Then 侧边栏层级不超过两级（设备 -> 控件）
   - And 运行控制与权限引导不固定在底部不可见区域
   - And 使用系统语义图标与系统 `List(.sidebar)` 交互表现

## 测试策略
- 先增加设计系统与系统能力门禁测试（红灯）。
- 再实现新 UI 结构与样式（绿灯）。
- 通过 `swift test` + `xcodebuild build` 回归验证。

## 执行结果
1. 已新增红灯测试 `Tests/EnjoyableKitTests/AppleNativeDesignTests.swift`，随后实现通过。
2. 已完成根视图重构：
   - 新增 `Sources/EnjoyableKit/SwiftUI/EnjoyableRootView.swift`
   - 顶层改为 `NavigationSplitView`（macOS 13+）并提供 `NavigationView` 回退（macOS 11/12）
   - Sidebar/Detail 信息架构重建，保留映射管理、状态、手柄布局、实时轴值、输出编辑路径
3. Liquid Glass 在编译器/系统满足条件时启用，其他环境回退到兼容背景样式。
4. 验证通过：
   - `swift test`（39 tests, 0 failed）
   - `xcodebuild ... build`（Debug，macOS）
   - `xcodebuild ... test -only-testing:EnjoyableTests`

## 分阶段落地进度（功能优先，先不追求最终视觉）
1. 阶段 1（已完成）：仅重排信息架构，不改业务行为
   - Detail 区由单列改为“主工作区 + 检查器”双栏。
   - 主工作区承载手柄布局与实时轴值；检查器承载状态、映射管理区与输出编辑。
   - 新增布局 token：`mainMinWidth`、`inspectorIdealWidth`、`inspectorMaxWidth`。
   - Sidebar 采用系统原生 `List(.sidebar)` 结构，移除自定义侧栏卡片容器。
   - App 默认入口已切换到 `EnjoyableRootView`，不再保留旧入口回退分支。
   - 已移除 Sidebar 内部重复标题头，导航层级由系统工具栏统一表达。
   - Sidebar 已应用独立背景色（含滚动底色隐藏处理），强化与主内容区的分栏视觉区隔。
   - 设备列表与模拟事件开关（含辅助功能权限引导）已定位到 Sidebar，形成“设备与运行”分区。
   - 映射导航与映射工具已定位到右侧检查器，作为映射管理分区。
   - 状态栏背景已与侧边栏统一（同色系、同透明度策略）。
2. 阶段 2（待执行）：统一控件密度与卡片层级（保持现有功能路径）
3. 阶段 3（待执行）：微交互、焦点态与可访问性细节打磨
