# Simulate Events 开关持久化（2026-03-23）

## 需求
- `simulate events` 开关状态需要持久化，应用重启后恢复上次选择。

## 实现
1. 在 `NJInputController` 增加持久化 key：`simulatingEventsDefaultsKey`。
2. 当 `simulatingEvents` 发生变化时，写入 `UserDefaults`。
3. 在 `load()` 中读取持久化值并恢复到 `simulatingEvents`。

## BDD 验收场景
1. Given 用户将开关设为开启
   When 关闭并重新打开应用
   Then 开关仍保持开启。
2. Given 用户将开关设为关闭
   When 关闭并重新打开应用
   Then 开关仍保持关闭。

## 测试
- 新增 `NJInputControllerPersistenceTests`：
  - `testLoadRestoresSimulatingEventsFromDefaults`
  - `testSettingSimulatingEventsPersistsToDefaults`
