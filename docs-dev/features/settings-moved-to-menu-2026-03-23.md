# Settings 从 Inspector 迁移到菜单栏（2026-03-23）

## 变更目标
- 设置模块不再占用主界面右侧 Inspector。
- 设置入口迁移到 macOS 菜单栏 `Settings…`。

## 实现
1. `RootPanelLayout.current.inspectorRoles` 移除 `settings`。
2. `EnjoyableInspectorPanelView` 恢复为 3 模块（Status / Mappings / Output Editor）。
3. 新增 `public EnjoyableSettingsView` 供 App 场景调用。
4. 在 `EnjoyableApp` 增加 `Settings { EnjoyableSettingsView() }`。

## BDD 验收
1. Given 用户打开主界面
   When 查看右侧 Inspector
   Then 不再看到 Settings 模块。
2. Given 用户点击菜单栏 `Settings…`
   When 弹出设置窗口
   Then 可看到原设置内容（应用名、开源声明、许可证、上游链接）。
