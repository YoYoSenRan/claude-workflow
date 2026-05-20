# `debug` skill 测试

每个用例是一份 markdown 清单。开一个新的 Claude 会话，粘贴触发提示词，对照预期逐项打勾。

## 用例

- `examples/01-basic.md` — 基础触发：测试失败时是否走 4 阶段流程

## 跑全部

手动：逐个开新会话跑各 example。

## 改完 `debug` skill 后

**至少跑 `01-basic.md`**，防止回归。

特别关注：Claude 是否在 Phase 1 完成前就提「试试改 X」——这是最常见的回归点。
