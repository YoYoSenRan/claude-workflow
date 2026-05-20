# Tests for `think` skill

每个 case 是一份 markdown checklist。开新 Claude 会话, 粘 Trigger Prompt, 对照 expected 打勾。

## Cases

- `examples/01-basic.md` — 基础触发: 模糊 prompt "帮我看一下这个项目" 是否触发对齐

## 跑全部

手动: 逐个开新会话跑各 example。

## 改 `think` skill 后

**至少跑 `01-basic.md`**, 防止回归。

特别注意反向测试: 清晰 prompt **不应**触发该 skill, 避免误触发浪费一轮。
