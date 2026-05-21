# claude-workflow 架构基线

> **本文档作用：** `claude-workflow` 的架构原点。后续新增、调整、删除任何 skill，都必须先对照本文。
>
> **参考来源：** `/Users/macos/WebProject/superpowers`、Claude Code 官方 skills / hooks / subagents 文档、用户个人工作流偏好。
>
> **修订规则：** 架构变更必须先显式确认；不能由某个 skill 实现细节反向修改整体架构。

---

## 0. 项目定位

`claude-workflow` 是个人使用的 Claude Code 工作流插件。目标不是做公开发布的 `superpowers` fork，而是借鉴 `superpowers` 的行为塑造方法，保留对个人开发最有价值的部分：

1. **流程边界清楚**：每个 skill 只负责一个阶段，不把设计、计划、执行、验证混在一起。
2. **证据优先**：完成、修复、通过测试这类声明必须有新鲜验证证据。
3. **少而完整**：可以比 `superpowers` 少很多 skill，但留下的 skill 必须能闭环。
4. **中文表达**：skill 主体用中文；工具名、路径、命令和通用技术术语保留英文。
5. **个人优先**：不承担多 harness、公开 marketplace、开源贡献规则等包袱。

---

## 1. 分层架构

```text
┌──────────────────────────────────────────────────────────────┐
│ 第 0 层：启动与元规则层                                      │
│   hooks/session-start.js                                     │
│   skills/using/SKILL.md                                      │
│   作用：先做入口路由，选择最小足够流程                       │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ 第 1 层：主流程层                                            │
│   think  ->  plan  ->  execute                             │
│      \->  debug                                              │
│   作用：覆盖分析、设计、计划、执行、排错这些高频路径          │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ 第 2 层：增强层                                              │
│   verify / finish / review / worktree / subagent             │
│   作用：完成前验证、分支收尾、评审、隔离工作区、子代理调度    │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ 第 3 层：未来完整子代理流程层                                │
│   agents/ + reviewer prompts + task handoff rules             │
│   作用：只有配套 agent 真实存在后，才启用完整子代理开发流程   │
└──────────────────────────────────────────────────────────────┘
```

### 层间约束

- `using` 负责入口路由和 skill 调用纪律，但不展开具体 skill 的内部流程。
- `think` 负责需求理解、设计判断和复杂任务对齐，但不能阻止分析类任务读取上下文。
- `plan` 只写可执行计划，不执行计划。
- `execute` 只按已批准计划执行；遇到计划错误或阻塞就停。
- `debug` 是 bug / 测试失败 / 异常行为入口，优先找根因，不走普通实现流程。
- `verify` 是完成声明前的证据门。
- `finish` 是提交、PR、保留、丢弃等收尾决策门。
- `review`、`worktree` 和 `subagent` 是增强能力，不应主动打断主流程。
- 当前 `subagent` 只提供调度规则；完整子代理开发流程必须等 `agents/` 和 reviewer prompt 真正存在后再启用。

---

## 2. Skill 映射

| 本项目 skill | 参考 `superpowers` | 当前定位 |
|---|---|---|
| `using` | `using-superpowers` | 入口路由和调用纪律；由 SessionStart hook 注入 |
| `think` | `brainstorming` | 分析、设计、需求澄清、方案判断 |
| `plan` | `writing-plans` | 写可执行实现计划 |
| `execute` | `executing-plans` | inline 执行已批准计划 |
| `debug` | `systematic-debugging` | 系统化排错 |
| `verify` | `verification-before-completion` | 完成声明前验证 |
| `finish` | `finishing-a-development-branch` | 分支 / 提交 / PR 收尾 |
| `review` | `requesting-code-review` / `receiving-code-review` | 代码评审和评审反馈处理 |
| `worktree` | `using-git-worktrees` | 隔离工作区 |
| `subagent` | `dispatching-parallel-agents` / `subagent-driven-development` | 子代理调度规则，不承担完整子代理开发流程 |

当前不做完整映射：

| `superpowers` skill | 本项目处理方式 |
|---|---|
| `subagent-driven-development` | 暂缓。等 `agents/` 和 reviewer prompts 存在后再做。 |
| `dispatching-parallel-agents` | 部分吸收到 `subagent` 调度规则；不在 `execute` 中假装完整支持。 |
| `test-driven-development` | 不单独做强制 skill；在 `plan` 和 `debug` 中按场景要求测试先行。 |
| `writing-skills` | 暂不引入。先稳定现有 skill。 |

---

## 3. 启动机制

`hooks/session-start.js` 在 `SessionStart` 事件触发时读取 `skills/using/SKILL.md`，并通过 `hookSpecificOutput.additionalContext` 注入会话。

约束：

- `using` 必须短小，因为它会进入每个会话上下文。
- 具体流程细节必须放在对应 skill 中，不塞进 `using`。
- plugin 安装由 Claude Code 读取 `hooks/hooks.json` 和 `skills/`；本仓不再维护全局拷贝脚本。
- hook 失败时可以降级继续，不应阻断会话。

---

## 4. 主流程定义

### 4.1 `using`

职责：

- 收到用户请求后，先判断请求类型、明确程度和风险。
- 选择能安全完成任务的最小流程。
- 明确适用的 skill 必须调用；清晰低风险小改不升级成完整流程。
- 保留指令优先级、主流程 skill 公开宣告、TodoWrite 规则。
- 说明如何访问 skill。

禁止：

- 不写 `think / debug / plan` 的详细流程。
- 不承载长篇 red flags 或 checklist。

### 4.2 `think`

职责：

- 分析类任务：允许先做只读项目探索，再给判断。
- 实现类模糊任务：先澄清目的、范围、边界，再进入计划或执行。
- 复杂实现任务：必要时产出 spec，供 `plan` 使用。
- 方案判断：给推荐方案、取舍、风险，而不是只列选项。

两种模式：

```text
分析模式：
  触发：分析、审查、理解、解释、对比、调研当前项目。
  允许：读取文件、文档、git 历史、参考项目。
  禁止：用户未要求实现前编辑文件。

实现意图模式：
  触发：构建、重构、优化、修改行为、实现功能。
  范围不清时：先问，不编辑。
  范围清晰时：可交给 plan 或直接执行小改。
```

### 4.3 `plan`

职责：

- 将已确认需求写成可执行计划。
- 计划必须包含明确文件、步骤、命令和预期输出。
- 代码细节按风险分级：关键接口、类型、配置、迁移必须完整；普通内部实现写清约束和验证即可。
- 禁止占位符和“参考上面”。
- 输出路径默认仍为 `docs/plans/YYYY-MM-DD-<name>.md`。

注意：

- `docs/roadmaps/` 用于项目路线图；`docs/plans/` 用于可执行任务计划。
- TDD 对代码行为变化是推荐路径；文档、配置、说明类改动可以不写失败测试，但计划必须说明原因。
- 没有真实 plan-reviewer agent 前，不强制 subagent 评审。

### 4.4 `execute`

职责：

- 读取已批准计划。
- 执行前做 critical review。
- 为每个任务建立 TodoWrite。
- 按计划逐步执行和验证。
- 遇阻即停，不猜、不改计划、不跳过验证。

当前不承担：

- 不承担完整 subagent-driven-development。
- 不派不存在的 reviewer agent。
- 不在没有配套 prompts 的情况下承诺子代理评审。

终态：

- 任务完成 -> 进入 `verify`。
- 计划有问题 -> 返回 `plan` 或报告用户。
- 执行阻塞 -> 报告 blocker。

### 4.5 `debug`

职责：

- 处理 bug、测试失败、报错、异常行为。
- 先根因调查，再模式分析，再最小假设验证，再修复。
- 没有根因证据前不提修复方案。
- 修复后必须进入 `verify` 或执行等价的新鲜验证。

---

## 5. 增强层定义

### 5.1 `verify`

目标：禁止无证据完成声明。

规则：

- 声称“完成 / 修好 / 通过 / 可用”前，必须运行能证明该声明的命令或检查。
- 必须读取完整输出和退出码。
- 不能用历史输出、推测、子代理报告替代验证。

### 5.2 `finish`

目标：安全地结束一段开发工作。

默认选项：

```text
1. 提交当前工作
2. 推送 / 创建 PR
3. 保留当前分支
4. 丢弃当前工作
```

约束：

- 丢弃工作必须要求用户明确确认。
- 不主动执行破坏性 git 命令。
- 不在测试失败时建议合并或 PR。

### 5.3 `review`

目标：让评审回到工程风险，而不是总结式夸赞。

规则：

- Findings 先行。
- 优先级：bug、行为回归、安全风险、缺失测试。
- 没问题时明确说没有发现阻塞问题，同时说明剩余风险。

### 5.4 `worktree`

目标：在需要隔离开发时保护当前工作区。

规则：

- 只有功能开发、较大重构、并行任务需要隔离时才触发。
- 优先尊重当前 harness 的原生工作区机制。
- 使用 git worktree 前说明路径、分支、清理方式。

### 5.5 `subagent`

目标：让子代理只承担边界清晰的辅助任务。

规则：

- 只派发独立、具体、可回传证据的任务。
- 主智能体保留需求确认、计划批准、最终完成声明和收尾决策。
- 不递归派发子代理。
- 当前不启用完整 subagent-driven-development。

---

## 6. 文档约定

| 文档 | 作用 | 路径 |
|---|---|---|
| 架构基线 | 定义 skill 体系和边界 | `docs/architecture.md` |
| 测试策略 | 定义如何验证 skill 行为 | `docs/testing.md` |
| 路线图 | 阶段性改造方案 | `docs/roadmaps/*.md` |
| spec | 复杂实现任务的需求边界 | `docs/specs/*.md` |
| plan | 具体实施计划 | `docs/plans/*.md` |

本仓库是工作流项目，实际 `docs/plans/` 通常出现在被处理的业务仓库中。

---

## 7. SKILL.md 标准

每个 `SKILL.md` 至少包含：

```markdown
---
name: <skill-name>
description: "<触发条件>"
---

# <中文标题>

<职责说明>

## 何时使用

## 流程

## 停止条件

## 验证方式
```

子代理边界二选一：

```markdown
<SUBAGENT-STOP>
如果你是作为子代理被派遣去执行某个具体任务，请跳过此 skill。
</SUBAGENT-STOP>
```

或：

```markdown
## 子代理辅助模式

如果你是作为子代理被派遣执行本 skill 对应的辅助任务，可以使用本 skill 的受限模式。
说明允许做什么，以及禁止替主智能体完成哪些决策或动作。
```

主流程 skill 还必须包含：

- hard gate；
- 反模式；
- 明确终态；
- 何时不激活。

增强层 skill 可以更短，但不能是空壳。

子代理规则：

- `using`、`execute`、`finish`、`worktree`、`subagent` 使用 `SUBAGENT-STOP`。
- `think`、`plan`、`debug`、`verify`、`review` 可以写普通的“子代理辅助模式”章节，但必须限制为只读、草案、评审或验证输出。
- 不自造新的 XML 标签；目前只有 `SUBAGENT-STOP` 继承自 `superpowers` 的 prompt 约定。
- 子代理不得替主智能体确认需求、批准计划、执行收尾、提交、推送、切换工作区或宣布最终完成。

---

## 8. 不变式

1. `using` 只做入口路由，不承载具体 skill 的内部流程。
2. `think` 不阻止分析类任务读取上下文。
3. `plan` 不执行计划。
4. `execute` 不擅自改计划。
5. `debug` 没有根因前不修复。
6. `verify` 是完成声明前的证据门。
7. `finish` 不在未确认时执行破坏性动作。
8. 空壳 skill 不允许同步或发布。
9. `subagent` 只负责调度规则；没有 `agents/` 和 reviewer prompts 时，不声明支持完整 subagent-driven-development。
10. 架构调整必须先更新本文档。

---

## 9. 与 `superpowers` 的关键差异

| 维度 | `superpowers` | `claude-workflow` |
|---|---|---|
| 使用范围 | 公开插件，多 harness | 个人 Claude Code 工作流 |
| 语言 | 英文 | 中文为主 |
| skill 数量 | 完整方法论库 | 小集合，逐步补齐 |
| subagent | 完整子代理开发流程 | 暂缓，等配套 agent 存在 |
| 测试 | 多层 CLI / 集成测试 | 先做最小静态 + 触发测试 |
| 发布 | marketplace / release | 本地同步为主 |

---

## 10. 当前改造顺序

1. 恢复本文档和 `docs/testing.md`。
2. 修正 `using` 和 `think`。
3. 稳定 `plan`。
4. 收窄 `execute`。
5. 调整 `debug`，接入 `verify`。
6. 加最小自动化测试。
7. 清理 `scripts/sync.sh` 和 README。

---

## 11. 变更记录

| 日期 | 变更 | 原因 |
|---|---|---|
| 2026-05-21 | 重建架构基线，明确个人版边界、分析模式、增强层和 subagent 暂缓策略 | 按 `superpowers` 调研和当前仓库问题重新校准 |
