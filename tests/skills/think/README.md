# `think` skill 测试

每个用例是一份 markdown 清单。开一个新的 Claude 会话，粘贴触发提示词，对照预期逐项打勾。

## 用例

- `examples/01-basic.md` — 基础触发：模糊 prompt「帮我看一下这个项目」是否触发对齐

## 跑全部

手动：逐个开新会话跑各 example。

## 改完 `think` skill 后

**至少跑 `01-basic.md`**，防止回归。

特别注意反向测试：清晰 prompt **不应**触发该 skill，避免误触发浪费一轮。
