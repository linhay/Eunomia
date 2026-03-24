# Eunomia

`Eunomia`（15 Eunomia）是一个 macOS 手柄映射工具：将游戏手柄/摇杆输入映射为键盘与鼠标事件，用于只支持键鼠输入的应用或游戏。

当前仓库已完成项目更名与上游断链迁移，公开仓库地址：<https://github.com/linhay/Eunomia>。

## 功能概览

- 手柄按键、轴、方向键映射到键盘/鼠标输出
- 基于 SwiftUI + TCA 的映射管理与编辑界面
- 映射导入导出、离线读写、运行时控制
- 中英文本地化（`en` / `zh-Hans`）

## 项目结构

- `Eunomia/`：macOS App（Xcode 工程）
- `Sources/EunomiaKit/`：核心逻辑与 UI 组件库（Swift Package Target）
- `Tests/EunomiaKitTests/`：单元测试
- `docs-linhay/`：项目文档系统（features/dev/plans/memory/references/screenshots/scripts）

## 开发环境

- Xcode 15.4+（建议）
- Swift 5.9+
- macOS 14+

## 本地运行

1. 打开 `Eunomia/Eunomia.xcodeproj`
2. 选择 `Eunomia` Scheme
3. 运行应用

## 测试

```bash
swift test
```

如需在 Xcode 内运行 UI 或集成测试，可使用对应 Test Plan / Scheme。

## License

- Project: [MIT](./LICENSE)
- Third-party notices: [THIRD_PARTY_NOTICES](./THIRD_PARTY_NOTICES)
- Dependency licenses: see `.build/checkouts/<package>/LICENSE*`
