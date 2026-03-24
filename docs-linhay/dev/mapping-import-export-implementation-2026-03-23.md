# 键位映射导入导出实现说明（2026-03-23）

关联需求文档：`docs-linhay/features/mapping-import-export-2026-03-23.md`

## 实现范围
1. Runtime 能力层新增：整套映射导入、整套映射导出。
2. TCA Root Feature 新增 action 与 runtime 调用链。
3. Mapping 管理 UI 新增导入/导出入口。
4. 本次一并修复组合键录入问题：`Shift + Return` 被 `flagsChanged` 覆盖导致回车消失。

## 关键设计
### 1) 导入导出能力
- `EunomiaStore`：
  - `importMapping()`：通过 `NSOpenPanel` 选择 JSON，解析为整套 payload，写入 `UserDefaults(mappings/selected)` 后 `controller.load() + refreshAll()`。
  - `exportMapping()`：通过 `NSSavePanel` 选择路径，导出整套 payload：
    - `format: "enjoyable.mapping-suite"`
    - `version: 1`
    - `mappings: [[String: Any]]`
    - `selected: Int`
  - 导入兼容旧格式：若 JSON 根为 `[[String: Any]]`，按 `selected = 0` 处理。
  - 文件类型兼容：macOS 12+ 使用 `allowedContentTypes = [.json]`，旧系统回退 `allowedFileTypes = ["json"]`。

### 2) 单向数据流接入
- `EunomiaRuntimeClient` 新增：
  - `importMapping: () async -> Void`
  - `exportMapping: () async -> Void`
- `EunomiaRootFeature.View` 新增：
  - `.importMapping`
  - `.exportMapping`
- reducer 通过 `runAndRefresh` 接入，保证操作后统一刷新 snapshot。

### 3) UI 入口
- `EunomiaMappingSidebarView`：
  - 上下文菜单新增 `Import/Export`。
  - 非 sidebar list 模式按钮区新增 `Import/Export`。
- `EunomiaRootView` 传入闭包触发对应 view action。

### 4) Shift+Return 录入修复
- 新增 `KeyComboInputView.nextKeyCodesAfterFlagsChanged(...)`。
- 规则：
  - 有修饰键 flags 时，更新为修饰键集合；
  - 若当前已是完成组合键（包含非修饰键），忽略修饰键释放事件，不覆盖组合；
  - 仅修饰键场景保持原行为。

## 测试
1. `EunomiaRootFeatureTests`
   - 新增 `testImportMappingCallsRuntime`
   - 新增 `testExportMappingCallsRuntime`
2. `KeyComboFieldCaptureTests`（新增）
   - 覆盖 `flagsChanged` 在组合键完成后不覆盖键值
   - 覆盖仅修饰键场景仍可保持录入
3. 全量回归：`swift test` 通过（以本次执行结果为准）。
