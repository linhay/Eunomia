# 离线映射可读可配实现说明（2026-03-23）

关联需求文档：`docs-linhay/features/offline-mapping-read-write-2026-03-23.md`

## 实现范围
1. Runtime 保留离线输入选择，不再因设备断开强制清空上下文。
2. Mapping 支持按输入 UID 直接读写输出条目，支持离线保存。
3. 新增离线输入路径格式化函数，便于 UI 展示当前离线输入来源。

## 关键实现
### 1) UID 维度映射读写
- `NJMapping` 新增：
  - `output(forUID:)`
  - `setOutput(_:forUID:)`
- 目的：当 `NJInput` 实例不可用（设备离线）时，仍可按 UID 更新 `entries`。

### 2) Runtime 离线选择上下文
- `EunomiaStore` 新增 `refreshSelectedInputContext()`：
  - 在线场景：按原逻辑从 `element(forUID:)` 解析输入并构建草稿。
  - 离线场景：保留 `selectedInputID`，使用 `currentMapping.output(forUID:)` 构建草稿。
- `setSelectedInput(id:)` 改为统一调用 `refreshSelectedInputContext()`。
- `refreshTree()` 不再在设备离线时清空选中，而是刷新离线上下文。
- `updateDraft(_:)` 改为：
  - 在线：`currentMapping[selectedInput] = ...`
  - 离线：`currentMapping.setOutput(..., forUID: selectedInputID)`

### 3) 离线路径展示
- 新增 `offlineInputPath(for:)`，将 UID 格式化为可读路径：
  - 例如：`111:222:1~Axis 1~Low` → `111:222:1 ▸ Axis 1 ▸ Low`

## 测试
1. `NJMappingOfflineAccessTests`
   - `testSetAndGetOutputByUID`
   - `testSetNilOutputByUIDRemovesEntry`
2. `OfflineSelectionPathTests`
   - `testOfflineInputPathUsesUIDSegments`
   - `testOfflineInputPathFallsBackToUIDWhenNoSegments`
3. 全量回归：`swift test` 通过（131 tests, 0 failed）。
