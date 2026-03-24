# 设置页与上游协议声明（2026-03-23）

## 背景
- 产品名已确定为 `Eunomia`。
- 需要在应用内新增设置页，展示上游项目署名与许可证信息。

## 需求变更
1. 在右侧 Inspector 导航中新增 `Settings` 页面入口。
2. 设置页中展示：
   - 应用名称：`Eunomia`
   - 开源声明：基于 Eunomia 开发并保留上游署名
   - 许可证：MIT
   - 上游项目链接

## BDD 验收场景
1. Given 用户打开主界面右侧 Inspector
   When 查看导航列表
   Then 可以看到 `Settings/设置` 入口。
2. Given 用户进入 `Settings/设置` 页面
   When 查看内容
   Then 能看到 `Eunomia`、开源声明、`MIT` 信息与上游链接。
3. Given 本地化语言为中文或英文
   When 进入设置页
   Then 标题与文案按对应语言展示。

## 测试策略
- 更新布局与描述符单元测试：
  - `RootPanelLayoutTests`
  - `InspectorPanelSectionDescriptorTests`
- 增加 `.settings` 角色与 `settings_title` 映射断言。
