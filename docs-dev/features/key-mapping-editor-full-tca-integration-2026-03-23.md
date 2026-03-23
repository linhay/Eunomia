# Key Mapping Editor 完整 TCA 接入（2026-03-23）

## 目标
- `AppleKeyMappingEditorSheet` 从本地 `@State` 迁移为 `Store` 驱动。
- 将编辑过程中的状态变更统一放入 reducer，避免视图层直接写业务状态。

## 实现
1. 新增 reducer：`AppleKeyMappingEditorFeature`。
   - State：`initialState`、`draft`、`selectedStepIndex`、`showsDiscardConfirmation`
   - Action：启用开关、阈值、步骤 keys/delay、追加/删除/移动步骤、选中步骤、放弃确认弹窗
2. `AppleKeyMappingEditorSheet` 改为持有 `StoreOf<AppleKeyMappingEditorFeature>`。
3. `AppleKeyMappingEditorSheet+Logic` 中所有写操作改为 `store.send(...)`。
4. 保留外部回调：`onCancel` / `onSave`，保证上层调用协议不变。

## BDD 验收
1. Given 用户编辑 key sequence
   When 增删改步骤
   Then 变更通过 reducer 更新并反映在 UI。
2. Given 用户设置重复按键
   When 写入某步骤 keys
   Then reducer 自动去重并同步主键码。
3. Given 用户删除步骤
   When 当前选中步骤越界
   Then 选中索引会被归一化到有效范围。

## 测试
- 新增：`AppleKeyMappingEditorFeatureTests`
  - `testSetKeySequenceKeysDeduplicatesAndSyncsPrimaryKey`
  - `testRemoveStepNormalizesSelection`
- 兼容性：保留 `AppleKeyMappingEditorSheet.normalizedSelectedStepIndex` 供现有测试继续使用。

## 第二阶段（Root 组合化）
1. 移除 sheet 的 `onCancel/onSave` 闭包，改为 `AppleKeyMappingEditorFeature.Action.delegate` 上行事件。
2. `AppleKeyMappingEditorFeature` 新增：
   - `.cancelTapped` / `.discardConfirmed` / `.saveTapped`
   - `.delegate(.cancel | .save(KeyMappingEditorState))`
3. `EnjoyableRootFeature` 接入子 reducer 组合：
   - State 从 `keyMappingEditorState` 升级为 `keyMappingEditor: AppleKeyMappingEditorFeature.State?`
   - Action 新增 `.keyMappingEditor(AppleKeyMappingEditorFeature.Action)`
   - 通过 `.ifLet(\.keyMappingEditor, action: \.keyMappingEditor)` 组合
4. Root 统一处理 delegate：
   - `.delegate(.cancel)` -> `.dismissKeyMappingEditor`
   - `.delegate(.save(...))` -> `runtime.applyKeyMappingEditorState(...)`
5. `EnjoyableRootView` 的 sheet 改为直接承载 scoped child store。

## 新增验收场景
1. Given 编辑器已打开
   When 用户点击 Save
   Then 通过子 reducer delegate 上行到 Root，并持久化后关闭。
2. Given 编辑器有未保存改动
   When 用户点击 Cancel 并确认放弃
   Then 子 reducer 发出 `.delegate(.cancel)`，Root 关闭 editor。

## 回归验证
- `swift test` 全量通过（112 tests, 0 failed）。
