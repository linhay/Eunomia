# Composable Architecture 集成（2026-03-22）

## 背景
当前工程尚未引入 `pointfreeco/swift-composable-architecture`，后续希望逐步把部分编辑器状态迁移到可组合、可测试的 reducer 架构，需要先完成依赖与最小落地闭环。

## 需求边界
1. 集成 `ComposableArchitecture` 依赖到 SwiftPM 工程。
2. 在 `EunomiaKit` 内新增一个最小可运行的 TCA Feature（State/Action/Reducer/Store）。
3. 新增对应单元测试，验证 reducer 行为可被 `TestStore` 驱动。
4. 不改变现有 UI 业务行为，不强制把现有页面一次性迁移到 TCA。

## BDD 验收场景

### 场景 1：依赖可用
- Given 工程已拉取依赖
- When 执行 `swift test`
- Then `ComposableArchitecture` 能被 `EunomiaKit` 与测试 target 正常编译引用

### 场景 2：Reducer 状态演进可验证
- Given 一个初始状态的 TCA Feature
- When 发送动作 `toggleEnabled` 与 `setThreshold`
- Then `enabled` 与 `threshold` 按预期变化

### 场景 3：最小集成不破坏现有行为
- Given 现有功能与测试集
- When 执行全量测试
- Then 现有测试仍通过

## 非目标
1. 本次不做大规模状态迁移。
2. 本次不重构现有 SwiftUI 页面绑定方式。
3. 本次不引入新的运行时依赖注入框架。

## 当前状态（2026-03-22 晚）
1. `Package.swift` 已接入 TCA package dependency（`1.23.1`）。
2. 已落地最小 TCA 集成闭环：
   - `EunomiaKit` target 正式依赖 `ComposableArchitecture`
   - 新增 `KeyMappingEditorTCAFeature`（State/Action/Reducer）
   - 新增 `TCAIntegrationTests`（`TestStore` 验证状态演进）
3. 工具链分歧：
   - `XcodeDefault Swift 6.2.4` 下 `swift test` 全量通过（88 tests, 0 failed）
   - 当前 shell 默认 `swift-6.2-RELEASE (+assertions)` 下仍会触发编译器断言崩溃
4. 详细阻塞与复现记录见：
   - `docs-linhay/dev/tca-integration-blocked-by-swift-toolchain-2026-03-22.md`
