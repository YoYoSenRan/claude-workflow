# `plan` skill 测试

每个用例是一份 markdown 清单。开一个新的 Claude 会话，粘贴触发提示词，对照预期逐项打勾。

## 用例

- `examples/01-basic.md` — 基础触发：应用代码需求「写个登录功能 plan」是否触发，且产物符合模板

## 跑全部

手动：逐个开新会话跑各 example。

## 改完 `plan` skill 后

**至少跑 `01-basic.md`**，防止回归。

特别注意：
- 反向测试（清晰一行改动 / 需求模糊未定 / 已有 plan）：**不应**触发
- 产物路径必须是 `docs/plans/YYYY-MM-DD-<name>.md`
- 占位符零容忍（产物 grep `TBD\|TODO\|FIXME` 应为空）
