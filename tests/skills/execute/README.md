# `execute` skill 测试

每个用例是一份 markdown 清单。开一个新的 Claude 会话，粘贴触发提示词，对照预期逐项打勾。

## 用例

- `examples/01-basic.md` — 基础触发：「按 plan 文件实现」是否触发，并走完 critical review → TodoWrite → 逐任务执行

## 跑全部

手动：逐个开新会话跑各 example。

## 前置条件：需要 plan 文件

测试前先用 `plan` skill 产一份 plan，或手写一份 mock plan 放在 `docs/plans/`。

## 改完 `execute` skill 后

**至少跑 `01-basic.md`**，防止回归。

特别注意：
- 反向测试（无 plan / 临时一行改动）：**不应**触发
- 阻塞点测试：故意在 plan 埋错，验证**停而不猜**
- TodoWrite 必建：看 Claude Code UI 进度条
