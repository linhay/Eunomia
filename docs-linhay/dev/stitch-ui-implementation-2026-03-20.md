# Stitch UI 落地技术说明（2026-03-20）

关联需求文档：`docs-linhay/features/stitch-advanced-editor-and-svg-dashboard-2026-03-20.md`

## 实施范围
1. `Sources/EunomiaKit/SwiftUI/EunomiaRuntime.swift`
2. `Tests/EunomiaKitTests/DashboardThemeTests.swift`

## 关键实现点
1. 新增 `StitchPalette`，将设计稿主色与深色表面 token 统一到 SwiftUI 层。
2. 新增 `DashboardStatusKind` 与 `dashboardStatusKind(hidRunning:hasDevices:)`，把状态文案/图标/色彩从视图逻辑抽离为可测试模型。
3. 主界面重构为控制台风格：
   - 深色渐变背景
   - 品牌化侧边栏
   - 顶部状态栏
   - 手柄区域诊断卡片（Latency/Stick Drift）
   - 右侧上下文配置面板
4. `KeyMappingEditorSheet` 重构为高级双栏结构，保留原有保存/取消行为。
5. 补齐 `OutputDraft` 与 `KeyMappingEditorState` 的 `keySequenceSteps` 字段链路，修复已有测试预期。

## 风险与折中
1. 设计稿中的 HTML 动画与 hover 细节未一比一迁移，优先保留 macOS 原生可用性与性能。
2. 诊断卡片中的指标（Latency/Drift）使用现有状态推导值，属于展示层近似值。
3. 为兼容 `Package.swift` 目标 `macOS 11`，避免使用仅 `macOS 12+/13+` 可用的 API 形态。

## 验证
1. `swift test` 全量通过（33 tests, 0 failed）。
