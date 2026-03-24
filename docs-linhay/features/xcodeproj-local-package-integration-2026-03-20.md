# Eunomia.xcodeproj 接入本地包与权限补齐（2026-03-20）

## 背景
- 工程已重建为 `Eunomia/Eunomia.xcodeproj`。
- 现有业务能力在根目录 `Package.swift`（产品名 `EunomiaKit`）中。
- 需要在新工程中恢复依赖接入，并在首页直接展示 `EunomiaKit` 的 SwiftUI 主视图。

## 目标
- 在 `Eunomia` App Target 中接入本地 Swift Package：`../Package.swift`。
- 首页 UI 由占位内容切换为 `EunomiaRootView`。
- 权限配置满足手柄/HID 输入与事件模拟场景可运行。

## 验收标准（BDD）
1. 场景：App 依赖接入
   - Given 新建的 `Eunomia.xcodeproj`
   - When 以 Debug 配置构建 App
   - Then 工程可解析本地包并成功编译（`import EunomiaKit` 可用）

2. 场景：首页显示
   - Given App 启动到主窗口
   - When 展示首页
   - Then 页面显示 `EunomiaKit` 的根视图（非默认 `Hello, world!` 占位页）

3. 场景：权限补齐
   - Given 用户开启事件模拟或连接 HID 设备
   - When App 运行在本地开发环境
   - Then 不因沙盒限制阻断核心输入映射能力
   - And 辅助功能权限由系统授权，应用内可引导跳转系统设置页

## 测试策略
- 先增加首页视图接入测试并验证失败（红灯）。
- 完成包接入与首页替换后，执行单元测试与构建验证（绿灯）。
