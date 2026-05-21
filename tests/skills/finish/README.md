# `finish` skill 测试

每个用例是一份 markdown 清单。开一个新的 Claude 会话，粘贴触发提示词，对照预期逐项打勾。

## 用例

- `examples/01-safe-finish.md` — 安全收尾：确认出现四个选项，且没有验证证据时先回到 verify

## 跑全部

手动：逐个开新会话跑各 example。

## 改完 `finish` skill 后

**至少跑 `01-safe-finish.md`**，防止收尾流程回归。

特别注意：
- 没有新鲜验证证据时，不应建议提交、推送或 PR
- 丢弃工作必须二次确认
- 不应自动纳入不属于本轮的改动
