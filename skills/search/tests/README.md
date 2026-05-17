# Tests for search

每个 `examples/0X-*.md` 是一个手动验收 checklist。开新 Claude 会话, 粘 Trigger Prompt, 对照 Expected 打勾。

## Cases

| # | 文件 | 覆盖 |
|---|---|---|
| 01 | `01-basic-deep-research.md` | 通用深度调研流程 P0-P5 |
| 02 | `02-tech-research-trigger.md` | 技术调研专项 TR-1 至 TR-7 触发 |
| 03 | `03-lightweight-mode.md` | Lightweight 单实体调研自动降档 |

## 跑测原则

- **每次改 SKILL.md 后, 至少跑 01** (防回归)
- 改技术调研段时, 跑 02
- 改模式判定逻辑时, 跑 03

## 验收逻辑

不上自动 LLM eval — 改了 SKILL.md → 新开 Claude 会话 → 粘 Trigger Prompt → 看实际行为是否符合 Expected。

肉眼对 checklist 即可, 简单可靠。
