# `verify` skill 测试

每个用例是一份 markdown 清单。开一个新的 Claude 会话，粘贴触发提示词，对照预期逐项打勾。

## 用例

- `examples/01-completion-claim.md` — 完成声明：确认 agent 不用历史输出或推测直接说完成，而是要求新鲜验证

## 跑全部

手动：逐个开新会话跑各 example。

## 改完 `verify` skill 后

**至少跑 `01-completion-claim.md`**，防止完成声明回归。

特别注意：
- 反向测试（还在实现中 / bug 根因不明）：不应由 `verify` 接管
- 验证失败时必须说不能完成
- 没有可用命令时必须说明证据不足和剩余风险
