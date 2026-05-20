# Tests for `writing-skills` skill

每个 case 是一份 markdown checklist。开新 Claude 会话, 粘 Trigger Prompt, 对照 expected 打勾。

## Cases

- `examples/01-basic.md` — 基础触发: 用户说"写个新 skill" 时是否激活

## 跑全部

手动: 逐个开新会话跑各 example。

## 改 `writing-skills` skill 后

**至少跑 `01-basic.md`**, 防止回归。
