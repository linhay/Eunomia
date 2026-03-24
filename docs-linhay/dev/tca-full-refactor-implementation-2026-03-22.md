# Eunomia 全量 TCA 改造实现记录（2026-03-22）

## 关联文档
- Feature：`docs-linhay/features/tca-full-refactor-2026-03-22.md`

## 实施摘要
1. 新增根级 reducer：`EunomiaRootFeature`
   - 统一承载根页面状态（映射、设备树、输出草稿、编辑器弹窗等）。
   - 统一承载根页面交互动作（初始化、重命名、映射管理、输出编辑、快捷配置、弹窗保存/关闭）。
2. 新增运行时桥接：`EunomiaRuntimeClient` + `EunomiaRuntimeSnapshot`
   - 将原 `EunomiaStore` 的能力封装为 reducer 可调用接口。
   - 保留原运行时逻辑，避免一次性重写 `NJInputController` 相关实现。
3. 扩展运行时状态快照能力：
   - `EunomiaStore.snapshot()`
   - `EunomiaStore.snapshotStream()`
4. 根视图改造成 Store 驱动：
   - `EunomiaRootView` 从 `@StateObject EunomiaStore` 切换为 `StoreOf<EunomiaRootFeature>`。
   - 原有 UI 交互改为发送 reducer action。

## BDD 场景回写
1. 场景 1（根页面 Store 驱动）：完成。
2. 场景 2（映射名编辑提交）：完成。
3. 场景 3（输出编辑交互回归）：完成。
4. 场景 4（键位编辑 Sheet 闭环）：完成。
5. 场景 5（核心测试通过）：完成。

## 测试（红绿过程）
1. 红灯：先新增 `EunomiaRootFeatureTests`，验证缺失类型导致编译失败。
2. 绿灯：补齐 reducer/runtime 桥接后通过。
3. 回归：`swift test` 全量通过（90 tests, 0 failed）。

## 兼容性与风险说明
1. 对外 API 收敛：新增 TCA 类型保持模块内可见，避免不必要公开接口膨胀。
2. 并发隔离：`live runtime` 构造限定在 `@MainActor`，避免 actor 隔离违规。
3. 工具链：当前环境 `swift test` 已可稳定通过；仍建议团队统一 Xcode 工具链版本，降低历史工具链差异风险。

## 继续简化（2026-03-22 23:57）
1. reducer 副作用模板收敛：
   - 新增 `runAndRefresh`，替换多处重复的 `await runtime.xxx(); await send(.runtimeUpdated(...))`。
2. runtime client 精简：
   - 删除未使用的 `canConfigure` 注入字段与对应 live 实现，减少无效依赖面。
3. 测试可读性提升：
   - `EunomiaRootFeatureTests` 新增 `makeRuntime` 工厂，移除重复 mock 样板。
   - 新增用例：`testDismissKeyMappingEditorClearsEditorState`。
4. 并发安全细化：
   - `updateDraft` 中将持久化草稿改为 `let draftToPersist` 捕获，消除 Swift 6 并发捕获告警。

## 继续简化（2026-03-23 00:01）
1. 去掉 `onAppear` 的重复首刷：
   - `onAppear` 仅触发 `.observeRuntime`，不再额外 `refreshSnapshot`。
   - 首次状态由 runtime stream 的首帧快照统一提供，避免双路径初始化。
2. 测试工厂默认对齐生产语义：
   - `makeRuntime` 默认 `updates` 会先发出一次 `snapshot` 再结束。
   - 需要“无更新流”时在测试中显式覆盖 `updates`。

## 继续简化（2026-03-23 01:15）
1. 去掉 `EunomiaRuntimeClient` 的冗余显式构造器，改用成员初始化器，减少重复字段搬运。
2. `EunomiaRootFeature` 为 `OutputDraft` 的简单字段更新新增 keyPath 重载：
   - `updateDraft(_:keyPath:value:)`
   - 将 `mappingIndex / mouseAxis / mouseSpeed / mouseButton / scrollDirection / scrollSmooth / scrollSpeed / keyActivationThreshold` 等场景改为一行式更新。
3. 保持复杂变换（如 `setKeyCode`、序列步骤编辑）仍走 `mutate` 版本，避免过度抽象。

## 继续简化（2026-03-23 01:30）
1. `EunomiaRootView` 继续去样板化：
   - 新增 `sendView(_:)`，统一 `store.send(.view(...))` 入口。
   - 新增 `binding(get:set:)` 重载，索引型绑定（`keySequenceKeyBinding` / `keySequenceDelayBinding`）改为复用 helper。
   - 多处按钮回调与 `onAppear` 改为调用 `sendView`，减少重复模板代码。
2. 结果：
   - 仅重构代码结构，未改动 reducer 语义与业务流程。
3. 验证与阻塞：
   - 执行 `swift test --filter EunomiaRootFeatureTests` 与 `swift test --filter EunomiaStoreTests` 时，均在依赖 `ComposableArchitecture` 编译阶段触发 Swift 编译器断言：`LocalDiscriminator is set multiple times`。
   - 崩溃定位仍在 `.build/checkouts/swift-composable-architecture/Sources/ComposableArchitecture/SwiftUI/Alert.swift`，属于工具链层阻塞，不是业务用例断言失败。

## 继续简化（2026-03-23 01:40）
1. `EunomiaRootFeature` runtime 调用去样板：
   - 新增 `runAndRefresh(keyPath:)`（无参）和 `runAndRefresh(_:keyPath:)`（单参）两个 helper。
   - 将 `setSelectedInput / setSimulatingEvents / openAccessibilitySettings / activateMapping / add/remove/moveMapping / quickConfigureKeyPress / clearOutput / dismissKeyMappingEditor / saveKeyMappingEditor` 等分支改为 keyPath 调度。
2. `EunomiaRootView` 发送入口统一：
   - 新增 `send(_ action: EunomiaRootFeature.Action)`。
   - Sheet cancel/save、sheet binding 关闭分支改用统一发送入口。
3. 验证与阻塞：
   - `swift test --filter EunomiaRootFeatureTests` 仍在 TCA 依赖编译阶段触发 `LocalDiscriminator is set multiple times`（`Alert.swift`），未能完成本轮测试门禁。

## 继续简化（2026-03-23 01:50）
1. `EunomiaRootFeature` 分支风格进一步统一：
   - `openKeyMappingEditorForInput` 改为二参 keyPath helper 调度。
   - `commitRename` 的 runtime 调用改为一参 keyPath helper 调度。
2. 新增 helper：
   - `runAndRefresh(_:_:keyPath:)`，用于 runtime 双参数异步方法。
3. 结果：
   - reducer `switch` 中 runtime side effect 调用风格基本统一，保留业务分支判断不变。
4. 验证与阻塞：
   - `swift test --filter EunomiaRootFeatureTests` 仍在 TCA 依赖编译阶段崩溃：`LocalDiscriminator is set multiple times`（`Alert.swift`）。

## 继续简化（2026-03-23 02:00）
1. `updateDraft` 分支去重：
   - 新增 `updateDraftFloat(_:keyPath:value:)`，统一 `Double -> Float` 的草稿写入。
   - `setKeyThreshold / setMouseSpeed / setScrollSpeed` 改为复用该 helper。
2. 键序列步骤更新去重：
   - 新增 `updateKeySequenceStep(_:at:mutate:)`，统一索引越界保护与步骤读取。
   - `setKeySequenceKey / setKeySequenceDelay` 改为复用该 helper。
3. 验证与阻塞：
   - `swift test --filter EunomiaRootFeatureTests` 仍在 TCA 依赖编译阶段触发 `LocalDiscriminator is set multiple times`。
   - 本次堆栈定位到 `ComposableArchitecture/SwiftUI/Sheet.swift`（此前也出现过 `Alert.swift`），本质仍为同类编译器断言问题。

## 继续简化（2026-03-23 02:10）
1. `setKeyCode` 分支抽离：
   - 新增 `updateDraftForKeyCode(_:keyCode:)`，收敛“主键与序列首步联动”逻辑。
   - `switch` 中 `setKeyCode` 改为单行调用，行为保持不变。
2. 验证与阻塞：
   - `swift test --filter EunomiaRootFeatureTests` 仍在 TCA 依赖编译阶段触发 `LocalDiscriminator is set multiple times`。
   - 本次堆栈定位到 `ComposableArchitecture/SwiftUI/ConfirmationDialog.swift`；结合此前 `Alert.swift` / `Sheet.swift`，判断为同一类编译器断言问题。

## 继续简化（2026-03-23 02:20）
1. 键序列步骤写入再收敛：
   - 新增 `replaceKeySequenceStep(draft:index:keyCode:delayMilliseconds:)`。
   - `setKeySequenceKey / setKeySequenceDelay / updateDraftForKeyCode` 改为复用该 helper，减少 `NJKeySequenceStep(...)` 重复构造。
2. 验证与阻塞：
   - `swift test --filter EunomiaRootFeatureTests` 仍触发 `LocalDiscriminator is set multiple times`。
   - 本次堆栈定位到 `ComposableArchitecture/SwiftUI/Popover.swift`，与此前 `Alert/Sheet/ConfirmationDialog` 一致，仍为同类工具链断言。

## 继续简化（2026-03-23 02:30）
1. 按 TDD 补充 `EunomiaRootFeatureTests`：
   - `testSetKeySequenceDelayClampsToZero`
   - `testSetKeyCodeSyncsFirstSequenceStep`
   - `testSetKeyCodeCreatesFirstSequenceStepWhenMissing`
2. 代码收敛：
   - `setKeySequenceKey / setKeySequenceDelay / updateDraftForKeyCode` 已复用 `replaceKeySequenceStep`。
3. 验证与阻塞：
   - `swift test --filter EunomiaRootFeatureTests` 仍在 TCA 依赖编译阶段断言失败（`LocalDiscriminator is set multiple times`）。
   - 本次堆栈再次定位到 `ComposableArchitecture/SwiftUI/ConfirmationDialog.swift`，与此前 `Alert/Sheet/Popover` 一致。

## 继续简化（2026-03-23 02:40）
1. 测试样板收敛：
   - 新增 `makeStoreWithDraftSnapshot(_:)`，统一 `snapshot + updates finish + updateDraft writeback` 测试搭建。
2. 边界测试补充（TDD）：
   - `testSetKeySequenceDelayOutOfBoundsKeepsDraftUnchanged`
   - `testSetEmptyKeyCodeDoesNotCreateFirstSequenceStep`
3. 验证与阻塞：
   - `swift test --filter EunomiaRootFeatureTests` 仍触发 `LocalDiscriminator is set multiple times`。
   - 本次堆栈再次指向 `ComposableArchitecture/SwiftUI/Popover.swift`（同类断言反复出现在多个 SwiftUI 文件）。

## 继续简化（2026-03-23 02:55）
1. `AppleKeyMappingEditorSheet` 文件结构收敛为 3 个文件：
   - 保留：`AppleKeyMappingEditorSheet.swift`（主视图）
   - 新增：`AppleKeyMappingEditorSheet+Logic.swift`（原 State/Actions/Subviews 合并）
   - 保留：`AppleKeyMappingEditorSheet+Preview.swift`（预览）
2. 删除冗余拆分文件：
   - `AppleKeyMappingEditorSheet+Actions.swift`
   - `AppleKeyMappingEditorSheet+State.swift`
   - `AppleKeyMappingEditorSheet+Subviews.swift`
3. 修复问题：
   - `AppleKeyMappingEditorSheet.swift` 中确认弹窗 message key 被污染，已恢复为 `discard_changes_message`。
4. 验证与阻塞：
   - `swift test --filter EunomiaRootFeatureTests` 仍在 TCA 依赖编译阶段触发 `LocalDiscriminator is set multiple times`。
   - 本次堆栈定位到 `ComposableArchitecture/SwiftUI/Popover.swift`。

## 继续简化（2026-03-23 03:35）
- Trigger Events 表格每行改为单个 `KeyComboField`，直接监听并写入整组组合键（modifiers + 主键）。
- 移除行内多输入框与 `+/-` 键位数量操作，避免“先拆键位再组合”的认知负担。
- 组合键显示改为同一输入框内容（空格分隔），不再显示 `+` 分隔符。
- 新增 `KeyComboField`（`NSViewRepresentable`）用于按键组合捕获；保留原 `KeyCodeField` 以兼容其他位置。

## 快速修复（2026-03-23 03:55）
- 修复 `KeyComboField` 编译错误：
  - `EunomiaRuntime.swift` 增加 `import Carbon` 以提供 `kVK_*` 常量。
  - 组合键采集路径统一为 `UInt16`，移除 `CGKeyCode/UInt16` 混用导致的 `Ambiguous use of init`。
  - `isModifierKey` 拆为 `Set<UInt16>` 判断，规避类型检查超时。
- 验证：`swift build` 不再出现上述符号/歧义错误，但仍受 Swift 6.2 + TCA 编译器断言阻塞。

## 行为修复（2026-03-23 04:20）
- 修复 Key Mapping Editor 点击保存后不关闭的问题：`applyKeyMappingEditorState` 应用成功后立即 `keyMappingEditorState = nil`。
- 现象对应：日志出现 "Saving mappings to defaults." 但 sheet 未收起；本次改动使保存动作闭环为“写入 + 关闭”。
