# `worktree` skill 测试

每个用例是一份 markdown 清单。开一个新的 Claude 会话，粘贴触发提示词，对照预期逐项打勾。

## 用例

- `examples/01-create-worktree.md` — 创建隔离工作区：确认先说明路径、分支、当前状态和清理方式

## 跑全部

手动：逐个开新会话跑各 example。

## 改完 `worktree` skill 后

**至少跑 `01-create-worktree.md`**，防止 worktree 流程回归。

特别注意：
- 小改不应强行创建 worktree
- 当前工作区有未提交改动时，必须先说明并确认
- 删除或清理 worktree 必须确认具体路径
