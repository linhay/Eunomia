# TCA 集成阻塞记录（2026-03-22）

## 背景
- 目标：在当前仓库集成 `pointfreeco/swift-composable-architecture`，并落地最小 `Feature + TestStore` 闭环。
- 参考：`onevcat/Prowl` 已使用 TCA（其 `Package.resolved` 锁定 `1.23.1`）。

## 复现结论
在当前环境（`Apple Swift version 6.2 (swift-6.2-RELEASE)`）下，只要某个 target 实际依赖并编译 `ComposableArchitecture`，就会触发编译器断言崩溃：

- 典型报错：`Assertion failed: LocalDiscriminator is set multiple times`
- 崩溃位置：TCA 的 SwiftUI/Deprecations 相关源码（如 `Alert.swift`、`Popover.swift`、`Internal/Deprecations.swift`）

已验证以下版本均可复现：
1. `1.25.2`
2. `1.23.1`（与 Prowl 一致）
3. `0.59.0`
4. `main`

附加验证（最小包实验）：
1. 在临时 SwiftPM 最小工程中，仅引入 TCA 并声明一个最小 `@Reducer`，同样复现。
2. 即便 package 设置 `swiftLanguageVersions: [.v5]`，实际依赖编译仍走 Swift 6 前端并崩溃。
3. 崩溃定位稳定落在 `SwiftUI/Popover.swift` 相关闭包语义分析阶段。

## BDD 验收结果回写
1. 场景「依赖可用」：已完成（带工具链前提）  
   `EunomiaKit` 与 `EunomiaKitTests` 已引用 `ComposableArchitecture`，并在 Xcode 默认工具链可成功编译。
2. 场景「Reducer 状态演进可验证」：已完成（带工具链前提）  
   已新增 `KeyMappingEditorTCAFeature` 与 `TCAIntegrationTests`，`TestStore` 断言通过。
3. 场景「最小集成不破坏现有行为」：已满足  
   `XcodeDefault Swift 6.2.4` 下全量测试通过（88 tests, 0 failed）。

## 当前仓库策略
1. 维持真实 TCA 集成状态（target 已依赖、最小 Feature + 测试已落地）。
2. 保留“工具链差异”显式说明：
   - `XcodeDefault Swift 6.2.4`：可构建可测试
   - `swift-6.2-RELEASE (+assertions)`：编译 TCA 时仍触发断言崩溃
3. 已清理实验残留 `Sources/TCAIntegrationSpike/`，避免悬空代码。

## 与 Prowl 的对齐说明
1. `Prowl` 使用 Xcode 工程并锁定 TCA `1.23.1`，说明“项目形态可行”。
2. 但在本地当前 Swift 6.2 工具链中，即便对齐到 `1.23.1` 仍复现同类崩溃。
3. 推断：当前阻塞更接近“本地工具链编译器问题”，而非单纯 TCA 版本选型。

## 下一步建议
1. 团队统一改用 Xcode 默认工具链执行本仓库 SwiftPM 测试（或在 CI 明确 `DEVELOPER_DIR`）。
2. 持续关注 `swift-6.2-RELEASE` 的编译器问题；若修复后可去掉额外工具链约束。
3. 下一步按业务拆分，把 `AppleKeyMappingEditorSheet` 的编辑状态逐段迁移到 TCA reducer。
