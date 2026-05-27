---
name: worktree
description: 当开始一项需要与当前工作区隔离的功能开发时，或在执行实施方案之前使用 —— 通过原生工具或 git 工作树兜底，确保存在一个隔离的工作区
---

# 使用 Git 工作树

确保工作发生在一个隔离的工作区中。优先使用你所在平台的原生工作树工具。仅在没有原生工具可用时，再回退到手动 git 工作树。先检测已存在的隔离。然后使用原生工具。再回退到 git。绝不与宿主环境对抗。

## 何时使用

- 开始一项需要与当前工作区隔离的功能开发时
- 在执行实施方案之前
- 用户明确要求创建工作树时

## 流程

### 步骤 0：检测已存在的隔离

**在创建任何东西之前，检查你是否已经处于一个隔离的工作区中。**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**子模块防护：** `GIT_DIR != GIT_COMMON` 在 git 子模块内部同样成立。在断定"已经在工作树中"之前，先确认你不在子模块中：

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**如果 `GIT_DIR != GIT_COMMON`（且不在子模块中）：** 你已经在一个关联工作树中。跳到步骤 3（项目初始化）。不要再创建另一个工作树。

附带分支状态一起汇报：
- 在分支上："已位于隔离工作区 `<path>`，分支 `<name>`。"
- 处于分离 HEAD："已位于隔离工作区 `<path>`（分离 HEAD，由外部管理）。完成时需要创建分支。"

**如果 `GIT_DIR == GIT_COMMON`（或处于子模块中）：** 你在一个普通的仓库 checkout 中。

用户是否已在指令中表达过工作树偏好？如果没有，请先征求同意再创建工作树：

> "需要我搭建一个隔离的工作树吗？它能保护你当前分支不被改动。"

如果已有声明的偏好，遵循它，不再询问。如果用户拒绝授权，原地工作，跳到步骤 3。

### 步骤 1：创建隔离工作区

**你有两种机制。按以下顺序尝试。**

#### 1a. 原生工作树工具（首选）

用户已要求一个隔离工作区（步骤 0 已同意）。你是否已经有创建工作树的途径？它可能是一个名为 `EnterWorktree`、`WorktreeCreate` 的工具，一条 `/worktree` 命令，或一个 `--worktree` 选项。如果有，使用它并跳到步骤 3。

原生工具会自动处理目录放置、分支创建与清理。在你拥有原生工具时仍调用 `git worktree add`，会产生宿主环境看不见也管不到的幽灵状态。

仅在没有可用的原生工作树工具时，才进入步骤 1b。

#### 1b. Git 工作树兜底

**仅在步骤 1a 不适用时使用** —— 你没有可用的原生工作树工具。手动用 git 创建工作树。

**目录选择**

按以下优先级。用户的明确偏好始终高于观察到的文件系统状态。

1. **检查指令中是否有声明的工作树目录偏好。** 如果用户已指定，无需询问，直接使用。

2. **检查是否存在项目级工作树目录：**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   如有，使用之。两者都存在时，`.worktrees` 胜出。

3. **检查是否存在全局目录：**
   ```bash
   project=$(basename "$(git rev-parse --show-toplevel)")
   ls -d ~/.config/claude-workflow/worktrees/$project 2>/dev/null
   ```
   如有，使用之（与旧全局路径向后兼容）。

4. **若无其他指引可用**，默认使用项目根下的 `.worktrees/`。

**安全核验（仅项目级目录）**

**创建工作树前必须确认该目录已被忽略：**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**如果未被忽略：** 先建议把对应目录加入 `.gitignore`，并获得用户确认后再编辑。不要自动提交该变更。

**为何关键：** 防止把工作树内容意外提交进仓库。

全局目录（`~/.config/claude-workflow/worktrees/`）无需核验。

**创建工作树**

```bash
project=$(basename "$(git rev-parse --show-toplevel)")

# Determine path based on chosen location
# For project-local: path="$LOCATION/$BRANCH_NAME"
# For global: path="~/.config/claude-workflow/worktrees/$project/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**沙箱兜底：** 如果 `git worktree add` 因权限错误（沙箱拒绝）失败，告诉用户沙箱阻止了工作树创建，你将改为在当前目录工作。然后在原地执行 setup 与基线测试。

### 步骤 3：项目初始化

自动识别并运行合适的初始化命令：

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 步骤 4：核验干净的基线

运行测试以确保工作区起始状态干净：

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**如果测试失败：** 汇报失败情况，询问是继续还是先调查。

**如果测试通过：** 汇报准备就绪。

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

<constraints>
- 禁止在步骤 0 检测到已有隔离时还去创建工作树
- 禁止拥有原生工作树工具（例如 `EnterWorktree`）时仍使用 `git worktree add`
- 禁止跳过步骤 1a 直接跳到步骤 1b 的 git 命令
- 禁止没核验目录被忽略就创建项目级工作树
- 禁止跳过基线测试核验
- 禁止不询问就在测试失败时继续
</constraints>

## 警示信号

| 错误 | 问题 | 正确做法 |
|------|------|----------|
| 与宿主环境对抗 | 平台已提供隔离时仍使用 `git worktree add` | 步骤 0 检测已有隔离，步骤 1a 优先原生工具 |
| 跳过检测 | 在已有工作树中又嵌套创建工作树 | 在创建之前始终运行步骤 0 |
| 跳过忽略核验 | 工作树内容被纳入版本控制，污染 git status | 创建项目级工作树前始终 `git check-ignore` |
| 想当然地选目录 | 不一致，违反项目约定 | 遵循优先级：已存在 > 全局遗留 > 指令文件 > 默认 |
| 在测试失败时继续 | 无法区分新引入的 bug 与既有问题 | 汇报失败，获得明确授权再继续 |

## 快速参考

| 情况 | 行动 |
|-----------|--------|
| 已在关联工作树中 | 跳过创建（步骤 0） |
| 在子模块中 | 视为普通仓库（步骤 0 的防护） |
| 有可用的原生工作树工具 | 使用它（步骤 1a） |
| 无原生工具 | git 工作树兜底（步骤 1b） |
| `.worktrees/` 存在 | 使用之（确认被忽略） |
| `worktrees/` 存在 | 使用之（确认被忽略） |
| 两者都存在 | 使用 `.worktrees/` |
| 都不存在 | 查阅指令文件，再默认 `.worktrees/` |
| 全局路径存在 | 使用之（向后兼容） |
| 目录未被忽略 | 征求确认后加入 .gitignore；不要自动提交 |
| 创建时遇到权限错误 | 沙箱兜底，原地工作 |
| 基线测试失败 | 汇报失败 + 询问 |
| 没有 package.json/Cargo.toml | 跳过依赖安装 |
