# Enjoyable 全量 TCA 改造（2026-03-22）

## 背景
当前仓库仅完成 TCA 最小接入（单个示例 reducer），核心根页面仍由 `EnjoyableStore (ObservableObject)` 直接驱动。为满足可组合、可测试和可维护目标，需要将根 UI 交互改造成 TCA reducer 驱动。

## 需求边界
1. 将 `EnjoyableRootView` 的核心状态与交互迁移到 `StoreOf<Feature>`。
2. 新增根级 `EnjoyableRootFeature`，覆盖：页面初始化、映射管理、输入选择、输出草稿编辑、快捷配置、键位编辑 Sheet 的打开/关闭/保存。
3. 保留现有运行时能力（`NJInputController` 等）和现有 UI 行为，不引入破坏性功能删减。
4. 新增/更新 TCA 单元测试，验证关键状态演进与运行时调用。

## BDD 验收场景

### 场景 1：根页面由 TCA Store 驱动
- Given 应用进入主页面
- When `EnjoyableRootView` 渲染
- Then 通过 `StoreOf<EnjoyableRootFeature>` 渲染并触发初始化动作

### 场景 2：映射名编辑与提交
- Given 当前映射名为 `Default`
- When 用户输入新名称并提交
- Then reducer 调用运行时重命名，并将 state 同步为最新映射名

### 场景 3：输出编辑交互可回归
- Given 当前已选中输入项
- When 用户修改输出草稿（类型、按键、阈值、宏步骤）
- Then reducer 将草稿更新指令下发运行时，并同步回 state

### 场景 4：键位编辑 Sheet 闭环
- Given 用户打开键位编辑器
- When 用户取消或保存
- Then reducer 正确关闭 sheet；保存时将编辑状态应用到运行时

### 场景 5：核心测试可通过
- Given 新增根级 TCA 测试
- When 执行测试
- Then 关键场景通过且不破坏现有测试

## 非目标
1. 本次不对底层 `NJInputController` 进行重写。
2. 本次不做 UI 视觉重设计。
3. 本次不引入与 TCA 无关的新依赖。

## 完成回写（2026-03-22 23:43）
1. 已新增 `EnjoyableRootFeature` 并接管根页面状态与交互。
2. 已新增 `EnjoyableRuntimeClient` / `EnjoyableRuntimeSnapshot`，实现 reducer 与原 runtime 的桥接。
3. `EnjoyableRootView` 已切换为 Store 驱动。
4. 已新增 `EnjoyableRootFeatureTests`，并完成红灯到绿灯。
5. 全量验证：`swift test` 通过（90 tests, 0 failed）。
