# Tests for `debug` skill

每个 case 是一份 markdown checklist。开新 Claude 会话, 粘 Trigger Prompt, 对照 expected 打勾。

## Cases

- `examples/01-basic.md` — 基础触发: 测试失败时是否走 4 阶段流程

## 跑全部

手动: 逐个开新会话跑各 example。

## 改 `debug` skill 后

**至少跑 `01-basic.md`**, 防止回归。

特别关注: Claude 是否在 Phase 1 完成前就提"试试改 X"——这是最常见的回归点。
