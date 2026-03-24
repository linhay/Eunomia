# 项目更名与上游链接断开实现记录（2026-03-23）

关联需求文档：`docs-linhay/features/project-rename-eunomia-and-detach-upstream-2026-03-23.md`

## 实现概览
1. 项目名统一为 `Eunomia`（小行星带命名）。
2. Swift Package 名统一为 `EunomiaKit`。
3. Xcode 工程、Target、测试 Target 与 bundle identifier 同步更名。
4. 设置页移除上游仓库跳转链接，改为“独立维护”说明。
5. Git 远端移除，断开原仓库关联。
6. 内部 `Enjoyable*` 类型与文件名一次性重构为 `Eunomia*`。

## 目录与工程重命名
- 目录：
  - `Enjoyable/` -> `Eunomia/`
  - `Sources/EnjoyableKit/` -> `Sources/EunomiaKit/`
  - `Tests/EnjoyableKitTests/` -> `Tests/EunomiaKitTests/`
- Xcode：
  - `Eunomia/Eunomia.xcodeproj`
  - Target：`Eunomia` / `EunomiaTests` / `EunomiaUITests`
  - App 产物：`Eunomia.app`

## 代码与配置调整
- `Package.swift`
  - package、library、target、testTarget 统一为 `EunomiaKit`。
- App 工程
  - `@main` 类型改为 `EunomiaApp`。
  - App/测试 target 导入模块改为 `EunomiaKit` / `Eunomia`。
  - `HomeRenderMode` 语义由 `enjoyableRoot` 调整为 `eunomiaRoot`。
- 内部 SwiftUI/TCA 命名
  - `EnjoyableRootView` -> `EunomiaRootView`
  - `EnjoyableRootFeature` -> `EunomiaRootFeature`
  - `EnjoyableRuntimeSnapshot` -> `EunomiaRuntimeSnapshot`
  - `EnjoyableRuntimeClient` -> `EunomiaRuntimeClient`
  - `EnjoyableStore` -> `EunomiaStore`
  - `EnjoyableSettingsView` -> `EunomiaSettingsView`
- 文件名重构
  - `Sources/EunomiaKit/SwiftUI/Eunomia*.swift` 全部迁移为 `Eunomia*.swift`
  - `Tests/EunomiaKitTests/EnjoyableRootFeatureTests.swift` -> `EunomiaRootFeatureTests.swift`
- 兼容性
  - 通知/映射相关常量字符串命名同步为 `com.yukkurigames.Eunomia.*`。
  - 映射文件解析错误域从 `Enjoyable` 改为 `Eunomia`。
- Bundle 标识：
  - `eunomia.overloaded.cn`
  - `eunomia.overloaded.cn.EunomiaTests`
  - `eunomia.overloaded.cn.EunomiaUITests`

## 上游链接断开
- 设置页中移除上游 URL 按钮（不再出现仓库外链）。
- 本地化文案改为“独立维护，保留历史版权声明”。
- git 远端执行：
  - `git remote remove origin`

## 验证
1. `swift test -q`：通过（131 tests, 0 failed）。
2. `xcodebuild -project Eunomia/Eunomia.xcodeproj -scheme Eunomia -destination 'platform=macOS' build`：`** BUILD SUCCEEDED **`。
3. `rg -n "Enjoyable" Sources Tests Eunomia`：无结果。
