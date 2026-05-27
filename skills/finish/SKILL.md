---
name: finish
description: 当实现已完成、所有测试通过、需要决定如何整合工作成果时使用——通过呈现结构化的选项（合并、PR 或清理）来指导开发工作的收尾
---

# 收尾开发分支

<HARD-GATE>
测试没过不许给用户看选项。必须先确认测试通过了，才能往下走。
</HARD-GATE>

给用户列出清晰的收尾选项，然后执行用户选的那个。跑测试 → 看看环境 → 列选项 → 执行用户的选择 → 清理。

## 何时使用

- 所有实现任务完成并核验后
- 在 execute 或 subagent 技能完成所有任务后
- 需要决定如何整合工作成果时

## 流程

### 第 1 步：跑测试

**在给用户看选项之前，先确认测试通过：**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**如果测试失败：**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

停下。不要进入第 2 步。

**如果测试通过：** 继续到第 2 步。

### 第 2 步：看看环境

**在列选项之前先搞清楚工作区是什么情况：**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

这决定了要显示哪个菜单以及清理如何工作：

| 状态 | 菜单 | 清理 |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON`（普通仓库） | 标准 4 选项 | 没有工作树需要清理 |
| `GIT_DIR != GIT_COMMON`，具名分支 | 标准 4 选项 | 基于来源（参见第 6 步） |
| `GIT_DIR != GIT_COMMON`，游离 HEAD | 简化的 3 选项（无合并） | 不清理（外部管理） |

### 第 3 步：确定基线分支

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

或者询问："这个分支是从 main 分出来的——对吗？"

### 第 4 步：列选项

**普通仓库和具名分支的工作树——原样列出以下 4 个选项：**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**游离 HEAD——原样列出以下 3 个选项：**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**不要加额外解释** —— 选项列表保持简洁。

### 第 5 步：执行用户的选择

#### 选项 1：本地合并

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
```

然后：清理工作树（第 6 步），再删除分支：

```bash
git branch -d <feature-branch>
```

#### 选项 2：推送并创建 PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

**不要清理工作树** —— 用户需要它保留下来以便就 PR 反馈进行迭代。

#### 选项 3：保持原样

报告："Keeping branch <name>. Worktree preserved at <path>."

**不要清理工作树。**

#### 选项 4：丢弃

**先确认：**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

等待精确的确认输入。

如果确认：
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

然后：清理工作树（第 6 步），再强制删除分支：
```bash
git branch -D <feature-branch>
```

### 第 6 步：清理工作区

**只对选项 1 和选项 4 运行。** 选项 2 和选项 3 始终保留工作树。

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**如果 `GIT_DIR == GIT_COMMON`：** 普通仓库，没有工作树需要清理。完成。

**如果工作树路径位于 `.worktrees/`、`worktrees/` 或 `~/.config/claude-workflow/worktrees/` 之下：** Claude Workflow 创建了这个工作树——清理由我们负责。

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**否则：** 当前环境拥有这个工作区，不是我们创建的。不要移除。如果平台提供了退出工作区的工具就用它，否则保留在原处。

<constraints>
- 测试没过不许继续
- 合并之后没跑测试不许算完
- 没有用户确认不许删工作成果
- 没有用户明确要求不许强制推送
- 合并没确认成功不许移除工作树
- 不是你创建的工作树不许清理（先检查来源）
- 不许在工作树内部运行 `git worktree remove`
- 选项 2（PR）和选项 3（保持）不许清理工作树
</constraints>

## 警示信号

| 错误 | 问题 | 正确做法 |
|------|------|----------|
| 跳过跑测试 | 合并了有问题的代码，创建了失败的 PR | 列选项之前必须先跑测试 |
| 开放式提问 | "我接下来该做什么？" 含义模糊 | 直接列出 4 个选项（或游离 HEAD 下的 3 个） |
| 为选项 2 清理工作树 | 移除了用户做 PR 迭代需要的工作树 | 只对选项 1 和选项 4 清理 |
| 在移除工作树之前就删除分支 | `git branch -d` 失败，因为工作树仍引用着这个分支 | 先合并，再移除工作树，然后删除分支 |
| 在工作树内部运行 git worktree remove | 命令静默失败 | 在移除之前先 `cd` 到主仓库根目录 |
| 清理不是你创建的工作树 | 留下不可控的残留 | 只清理位于已知路径之下的工作树 |
| 丢弃时无确认 | 意外删除工作成果 | 要求输入 "discard" 进行确认 |

## 集成

- **claude-workflow:execute** / **claude-workflow:subagent** —— 完成所有任务后调用本技能
- **claude-workflow:verify** —— 验证测试通过（第 1 步）

## 快速参考

| 选项 | 合并 | 推送 | 保留工作树 | 清理分支 |
|--------|-------|------|---------------|----------------|
| 1. 本地合并 | yes | - | - | yes |
| 2. 创建 PR | - | yes | yes | - |
| 3. 保持原样 | - | - | yes | - |
| 4. 丢弃 | - | - | - | yes（强制） |

## 沟通规范
- 用户看不到工具调用和思考过程，只看到你的文字输出
- 回复中不要出现本文件里的流程术语（不说"门控"、"检查点"、"子代理"、"回写"、"评审循环"）
- 用日常口语描述你在做什么："我先看看代码" / "写好了，测试通过" / "有个问题需要你确认"
- 匹配用户的说话风格——用户简短你就简短，用户详细你就详细
