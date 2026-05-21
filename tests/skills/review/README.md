# `review` skill 测试

每个用例是一份 markdown 清单。开一个新的 Claude 会话，粘贴触发提示词，对照预期逐项打勾。

## 用例

- `examples/01-code-review.md` — 代码评审：确认 Findings 先行，优先报告真实风险
- `examples/02-review-feedback.md` — 评审反馈处理：确认先判断反馈是否成立，不盲目执行
- `examples/03-subagent-review-negative.md` — 子代理评审请求：确认显式派发请求不会直接触发 review

## 跑全部

手动：逐个开新会话跑各 example。

## 改完 `review` skill 后

**至少跑 `01-code-review.md`、`02-review-feedback.md` 和 `03-subagent-review-negative.md`**，防止 review 回到总结式输出、盲目执行反馈，或抢走 subagent 调度请求。

特别注意：
- Findings 必须先行
- 没证据的问题不能列为 finding
- 反馈处理不是直接改代码
