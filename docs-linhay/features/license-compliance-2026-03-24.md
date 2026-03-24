# 许可整理与合规落位（2026-03-24）

## 背景
- 仓库已有 MIT 声明但缺少标准化主许可证文件与第三方许可清单落位。
- 已确认存在上游 MIT 署名与图标 public domain 声明，且 SwiftPM 依赖含 MIT 与 Apache-2.0。

## 需求变更
1. 在仓库根目录新增主许可证文件 `LICENSE`（MIT）。
2. 在仓库根目录维护 `THIRD_PARTY_NOTICES`，统一记录：
   - 上游署名与许可文本
   - 图标来源声明
   - SwiftPM 依赖许可清单
3. 在 `README.md` 的 License 章节明确指向 `LICENSE` 与 `THIRD_PARTY_NOTICES`。

## BDD 验收场景
1. Given 任何开发者或审计方访问仓库根目录
   When 查看许可证相关文件
   Then 能直接看到 `LICENSE` 与 `THIRD_PARTY_NOTICES`。
2. Given 需要核查第三方依赖许可
   When 阅读 `THIRD_PARTY_NOTICES`
   Then 能看到依赖名称、仓库链接与许可类型（MIT/Apache-2.0）。
3. Given 需要确认项目许可入口
   When 查看 `README.md` 的 License 章节
   Then 能找到主许可证和第三方声明的明确链接。

## 测试策略
- 文档与声明文件改动，不涉及可执行逻辑。
- 通过文件存在性与内容核对完成验证。
