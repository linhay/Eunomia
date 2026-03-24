# Stitch 设计落地：Advanced Mapping Editor + Modern SVG Controller Dashboard

- 日期：2026-03-20
- 设计来源：
  - `Advanced Mapping Editor`（screenId: `54c17659278f4325bf4c8af7c89b7f1f`）
  - `Modern SVG Controller Dashboard`（screenId: `9555591a85734f83a17d419971a8a3c1`）

## 背景
当前 `EunomiaRootView` 功能完整，但视觉层级与信息密度偏基础，未体现 Stitch 方案中的深色控制台风格、玻璃化卡片与“高级映射编辑”结构。

## 需求边界
1. 仅改造 macOS SwiftUI 界面与样式，不改 HID 输入核心逻辑。
2. 保留现有映射编辑能力（输出类型切换、阈值设置、清空/保存流程）。
3. 关键视觉 token 对齐设计稿：深色背景、PlayStation Blue（#0072CE）主色、浅蓝高亮（#a5c8ff）、玻璃/卡片层次。
4. 右侧 Inspector 与弹窗编辑器采用“高级编辑器”布局风格。

## BDD 验收场景

### 场景 1：控制台式主界面
- Given 用户打开应用主窗口
- When 查看主内容区
- Then 可以看到深色渐变背景、顶部状态栏、卡片化手柄区域与右侧上下文配置面板
- And 状态展示在 `输入停止/未检测到手柄/实时输入` 三态下语义正确

### 场景 2：SVG 仪表盘风格映射到现有手柄视图
- Given 存在可配置输入
- When 用户查看手柄区域
- Then 高亮控件和可配置控件有明显视觉反馈
- And 可看到延迟/漂移等诊断信息卡片（展示层，可先使用当前状态推导值）

### 场景 3：高级映射编辑器
- Given 用户打开按键详情编辑弹窗
- When 弹窗展示
- Then 使用双栏结构：左侧源输入与诊断，右侧操作配置
- And 保留原有保存与取消行为

### 场景 4：回归安全
- Given 已有映射逻辑与序列化逻辑
- When 运行单元测试
- Then 输出草稿与编辑状态的关键字段（含按键序列与阈值）保持正确

### 场景 5：手柄区无障碍语义
- Given 用户通过 VoiceOver 或其他辅助技术浏览手柄区
- When 焦点移动到任意手柄控件按钮
- Then 该按钮应提供可读的 `accessibilityLabel`（包含控件语义名）
- And 提供与操作结果对应的 `accessibilityHint`（进入按键详情配置）
- And 具备稳定 `accessibilityIdentifier` 便于 UI 自动化定位

### 场景 6：手柄区内容可见性
- Given 系统支持 Liquid Glass
- When 用户查看手柄区卡片
- Then 手柄布局主体不应被玻璃层覆盖导致可读性下降
- And 主工作区与右侧编辑相关卡片（手柄区/实时轴数据/映射管理/输出编辑）统一使用实体背景

## 非目标
1. 不实现 HTML 原型中的完整动画/脚本交互。
2. 不引入新的后端/网络接口。
3. 不在本次改造中新增复杂宏编辑持久化流程。
