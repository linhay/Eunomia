# 项目更名与上游链接断开（2026-03-23）

## 背景
- 当前工程内仍大量使用 `Enjoyable` / `EnjoyableKit` 命名。
- 设置页仍包含上游项目直链，不满足“断开上游链接”的要求。
- 项目名需改为小行星带命名，本次采用：`Eunomia`（15 Eunomia）。

## 目标
1. 将工程对外项目名统一为 `Eunomia`（含 App / Xcode 工程 / Swift Package）。
2. 断开运行时 UI 中的上游项目跳转与上游直链文案。
3. 将内部 `Enjoyable*` 类型、文件名与测试名一次性重构为 `Eunomia*`。
4. 保证现有功能不回归，工程可继续编译与测试。

## BDD 验收场景
1. 场景：工程命名统一  
Given 仓库当前名称仍为 Enjoyable 体系  
When 完成本次重命名迁移  
Then `Package.swift`、Xcode target/scheme、目录结构统一为 `Eunomia` 体系。

2. 场景：上游链接断开  
Given 用户打开设置页  
When 查看开源声明区域  
Then 不再出现上游项目链接按钮，也不再暴露上游仓库 URL。

3. 场景：可回归验证  
Given 重命名与文案调整已完成  
When 运行现有测试/构建命令  
Then 构建与测试结果维持可用，且无新增命名导致的编译错误。

4. 场景：内部符号统一  
Given 代码层仍存在 `Enjoyable*` 前缀类型/文件名  
When 执行一次性重构  
Then 代码目录（`Sources/Tests/Eunomia`）不再包含 `Enjoyable` 标识。
