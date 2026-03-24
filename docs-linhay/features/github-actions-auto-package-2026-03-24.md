# GitHub Actions 自动打包（2026-03-24）

## 背景
- 仓库已迁移到公开地址 `linhay/Eunomia`。
- 当前缺少标准化 CI 打包流程，无法稳定产出可下载的构建产物。

## 目标
1. 在 GitHub Actions 中自动执行基础测试。
2. 自动构建 `Eunomia.app` 并产出 zip 包作为 artifacts。
3. 当推送 tag（`v*`）时，自动把 zip 作为 Release 资产发布。
4. 当在 GitHub UI 手动发布 Release 时，也能自动补充上传 zip 资产。

## BDD 验收场景
1. 场景：代码推送触发打包  
Given 开发者 push 任意分支  
When workflow 运行完成  
Then Actions 中可下载 `Eunomia-macOS-<sha>.zip` 工件。

2. 场景：PR 校验  
Given 提交 pull request  
When workflow 执行  
Then 先通过 `swift test`，再执行 App 构建打包。

3. 场景：标签发布  
Given 推送标签 `vX.Y.Z`  
When workflow 运行  
Then 自动创建/更新 GitHub Release，并附带打包 zip 资产。

4. 场景：手动发布 Release  
Given 在 GitHub 页面发布一个已存在 tag 的 Release  
When release `published` 事件触发 workflow  
Then 对应 Release 自动附加 `Eunomia-macOS-<sha>.zip` 资产。
