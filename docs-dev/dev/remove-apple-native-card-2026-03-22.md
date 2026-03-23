# 移除 AppleNativeCard（2026-03-22）

## 目标
1. 从代码中移除 `AppleNativeCard` 依赖。
2. 保持卡片区标题、图标、内容与表面样式能力不变。

## BDD 场景
1. Given 主界面展示手柄布局、实时轴数据、输出编辑三块卡片，When 页面渲染，Then 三块内容仍显示标题+图标+主体内容。
2. Given 卡片样式策略为 `.solid`，When 页面渲染，Then 三块卡片仍应用统一的实体卡片表面样式。

## TDD
1. 红灯基线：当前分支存在 `AppleNativeCard` 符号缺失，`swift test` 编译失败。
2. 绿灯实现：替换为 `NativePanelCard` 后通过测试。
3. 新增测试：`AppleNativeDesignTests.testNativePanelCardCanBeConstructedWithSolidSurface`。

## 实施
1. 新增 `NativePanelCard`（通用卡片容器）：
   - 结构：`Label(title, symbol)` + `content`
   - 样式：复用 `.nativeCardSurface(surfaceStyle)`
2. 替换调用：
   - `EnjoyableRootView.controllerCard`
   - `EnjoyableRootView.outputEditorCard`
   - `EnjoyableLiveAxisCardView.body`
3. 全仓检索确认：`AppleNativeCard` 引用为 0。

## 验证
1. `swift test --filter AppleNativeDesignTests -q` 通过。
2. `swift test -q` 全量通过（77 tests, 0 failed）。
