# Delete 键映射修复（2026-03-23）

## 背景
用户反馈：将某个输入映射为 `Delete` 后，触发时不是逐字回删，而是出现“整句删除”行为。

## 目标
修复键盘事件发送时可能携带错误修饰键的问题，确保：
1. 单独映射 `Delete` 时不附带额外修饰键。
2. 组合键（如 `⌘ + Delete`）仍可按预期触发。
3. `Fn + Delete` 仅在 keyDown 注入 `SecondaryFn`，避免 keyUp 残留。

## BDD 场景
### 场景 1：单键 Delete
- Given 用户将输入映射为单键 `Delete`
- When 用户触发该输入
- Then 发送的键盘事件 flags 为空（不包含 `⌘/⌥/Fn` 等修饰位）

### 场景 2：Command + Delete
- Given 用户将输入映射为组合键 `⌘ + Delete`
- When 用户触发该输入
- Then 发送的非修饰键事件携带 `maskCommand`

### 场景 3：Fn + Delete
- Given 用户将输入映射为组合键 `Fn + Delete`
- When 用户触发该输入
- Then keyDown 包含 `maskSecondaryFn`，且 keyUp 不包含 `maskSecondaryFn`

## 验收标准
1. `KeyPressThresholdTests` 新增上述 3 个场景测试并通过。
2. 全量测试通过，无回归。
