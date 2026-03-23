# 按键详情页“两张语义卡 + 组合键双轨”实现（2026-03-22）

## 目标
1. `AppleKeyMappingEditorSheet` 右侧改为两张语义卡：按钮状态卡、触发事件卡。
2. 触发步骤模型升级为 `keys + delay`，支持单键/组合键双轨。
3. 完成旧格式到新格式的一次性迁移：兼容读取旧 `key/sequence`，统一写新 `steps`。

## BDD 到实现映射
1. 按钮状态卡：
   - 启用开关、触发模式（按下触发）、阈值调节、不可编辑原因提示。
2. 触发事件卡：
   - 步骤类型切换（单键/组合键）
   - 组合键字段增删
   - 步骤延时编辑、新增/删除、上移/下移
   - 以“每步骤一个编辑分组”的方式展示，分组头部承载步骤号、类型标签、摘要与顺序操作
   - 分组内容承载类型切换、延时设置与按键编辑，强调“配置任务”而不是“数据表浏览”
3. 门禁不变：
   - 不可解析/禁用状态下控件禁用
   - 保存可用性由有效绑定推导

## 数据模型与迁移
1. `NJKeySequenceStep` 升级为：
   - `keys: [CGKeyCode]`
   - `delayMilliseconds: Int`
2. 兼容层：
   - 保留 `init(keyCode:delayMilliseconds:)`
   - 保留 `keyCode` 兼容访问器（映射到 `keys.first`）
3. `NJOutputKeyPress`：
   - 序列化仅写 `steps`
   - 反序列化优先读 `steps`，回退兼容旧 `key/sequence`
   - 读取后统一转换为新步骤模型
4. 触发行为：
   - 单步且无延时使用“长按语义”：触发时按下，解除触发时抬起
   - 上述长按语义同时覆盖单键与组合键（组合键按下顺序触发、抬起时反向释放）
   - 其他步骤（含存在延时的步骤）按步骤延时触发并发送按下/抬起

## 交互设计重构
1. 设计动机：
   - `trigger events` 本质是逐步配置的编辑任务，不是高密度数据对比场景。
   - 纯 table 样式在组合键、多控件编辑和可访问操作上信息密度过高，可读性不足。
2. 设计依据：
   - `xcdocs`：
     - `/documentation/SwiftUI/GroupBox`
     - `/documentation/SwiftUI/Picking-Container-Views-for-Your-Content#Group-views-and-controls-for-data-entry`
   - 结论：对数据录入型界面，应优先使用能表达分组语义的容器组织相关控件。
3. 最终落地：
   - 每个步骤使用 `GroupBox`，在标签区展示步骤编号、单键/组合键标签、摘要文本、上下移动按钮。
   - 分组内部按“类型 -> 延时 -> 按键”顺序组织输入，降低扫描与编辑切换成本。
   - Trigger Events 表格增加“方式”列，直接展示当前步骤属于“长按”或“点按”语义，避免用户误判实际触发行为。
   - 顺序按钮继续使用 `.bordered` 小按钮，并保留无障碍标签，兼顾键盘与 VoiceOver 可达性。
   - 步骤摘要升级为真实按键名摘要，直接显示如 `↩，延时 80 ms` 或 `Q + W，延时 120 ms`，降低“需要点开才能理解步骤内容”的成本。
   - 长序列场景增加步骤折叠/展开，支持一键“展开全部 / 折叠全部”；头部摘要对多键组合做截断，避免头部横向膨胀。
   - 头部摘要进一步拆成 badge：按键 token、隐藏数量 `+N`、延时 badge，组合键编辑区也提供 token 预览，提升扫描感与完成度。
   - badge 视觉按语义分层，单键编辑区与组合键编辑区统一为 token editor 风格。
   - 第一个有效 key 作为 primary action 视觉锚点，次级 key 与隐藏数量退居次要层级。
   - 展开内容改为 inspector 两栏布局，并增加当前步骤选中高亮。

## TDD 与验证
1. `KeyPressThresholdTests`：
   - 覆盖新结构 round-trip、旧结构兼容读取、组合键步骤 round-trip。
2. `KeyMappingEditorStateTests`：
   - 覆盖仅组合键步骤时保存可用与主键推导。
   - 覆盖步骤摘要使用真实按键显示名，且测试跟随本地化模板断言。
   - 覆盖长组合键摘要在限制可见键名数量时的截断行为。
   - 覆盖可见键名 token 与隐藏数量推导。
3. `OutputDraftTests`：
   - 覆盖组合键步骤构建输出。
4. 回归：
   - `swift test -q` 全量通过（81 tests, 0 failed）。
