# Tests for `executing-plans` skill

每个 case 是一份 markdown checklist。开新 Claude 会话, 粘 Trigger Prompt, 对照 expected 打勾。

## Cases

- `examples/01-basic.md` — 基础触发: "按 plan 文件实现" 是否触发 + 走完 critical review → TodoWrite → 逐任务执行

## 跑全部

手动: 逐个开新会话跑各 example。

## Pre-condition: 需要 plan 文件

测试前先用 `writing-plans` skill 产一份 plan, 或手写一份 mock plan 放在 `docs/plans/`。

## 改 `executing-plans` skill 后

**至少跑 `01-basic.md`**, 防止回归。

特别注意:
- 反向测试 (无 plan / 临时一行改动): **不应**触发
- Blocker 测试: 故意在 plan 埋错, 验证**停而不猜**
- TodoWrite 必建: 看 Claude Code UI 进度条
