# claude-workflow 架构基线

> **本文档作用：** `claude-workflow` 的架构原点。后续新增、调整、删除任何 skill，都必须先对照本文。
>
> **参考来源：** Claude Code 官方 skills / hooks / subagents 文档、用户个人工作流偏好。
>
> **修订规则：** 架构变更必须先显式确认；不能由某个 skill 实现细节反向修改整体架构。

---

## 0. 项目定位

`claude-workflow` 是个人使用的 Claude Code 工作流插件。核心目标：

1. **流程边界清楚**：每个 skill 只负责一个阶段，不把设计、计划、执行、验证混在一起。
2. **证据优先**：完成、修复、通过测试这类声明必须有新鲜验证证据。
3. **少而完整**：保留的 skill 必须能闭环，不堆砌冗余流程。
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
│   test / verify / finish / review / worktree / subagent / skill / setup │
│   作用：测试策略、完成前验证、分支收尾、评审、隔离工作区、子代理调度、skill 维护、项目初始化 │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ 第 3 层：受限子代理扫描层                                    │
│   agents/setup-config, setup-conventions, setup-styling, setup-framework, setup-patterns, setup-domain, setup-rules │
│   作用：只读收集 setup 证据；主智能体仍负责合并和决策         │
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
- `review`、`worktree`、`subagent` 和 `setup` 是增强能力，不应主动打断主流程。
- 当前已有 setup 专用只读 agents；完整 subagent-driven-development 仍不启用。

---

## 2. Skill 映射

| 本项目 skill | 当前定位 |
|---|---|
| `using` | 入口路由和调用纪律；由 SessionStart hook 注入 |
| `think` | 分析、设计、需求澄清、方案判断 |
| `plan` | 写可执行实现计划 |
| `execute` | inline 执行已批准计划 |
| `debug` | 系统化排错 |
| `test` | 测试策略和回归用例，不强制所有任务 TDD |
| `verify` | 完成声明前验证 |
| `finish` | 分支 / 提交 / PR 收尾 |
| `review` | 代码评审和评审反馈处理 |
| `worktree` | 隔离工作区 |
| `subagent` | 子代理调度规则，不承担完整子代理开发流程 |
| `skill` | 创建、修改和评审 Claude Workflow skill |
| `setup` | 生成当前项目的 Claude Code rules、任务 skills 和 references |

当前暂缓事项：

- 完整 subagent-driven-development 流程暂缓。当前只提供 setup 专用只读扫描 agents，不承担完整开发流程。
- 并行子代理派发部分吸收到 `subagent` 调度规则；不在 `execute` 中假装完整支持。
- TDD 以轻量 `test` skill 吸收；不强制所有任务 TDD。

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

### 5.1 `test`

目标：为行为变更选择合适测试或替代验证。

规则：

- bug 修复优先补能复现失败的回归测试。
- 功能变更优先证明用户可见行为或 API 契约。
- 不强制纯文档、格式、小配置改动写测试。
- 没有测试条件时，必须说明原因并给替代验证。

### 5.2 `verify`

目标：禁止无证据完成声明。

规则：

- 声称“完成 / 修好 / 通过 / 可用”前，必须运行能证明该声明的命令或检查。
- 必须读取完整输出和退出码。
- 不能用历史输出、推测、子代理报告替代验证。

### 5.3 `finish`

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

### 5.4 `review`

目标：让评审回到工程风险，而不是总结式夸赞。

规则：

- Findings 先行。
- 优先级：bug、行为回归、安全风险、缺失测试。
- 没问题时明确说没有发现阻塞问题，同时说明剩余风险。

### 5.5 `worktree`

目标：在需要隔离开发时保护当前工作区。

规则：

- 只有功能开发、较大重构、并行任务需要隔离时才触发。
- 优先尊重当前 harness 的原生工作区机制。
- 使用 git worktree 前说明路径、分支、清理方式。

### 5.6 `subagent`

目标：让子代理只承担边界清晰的辅助任务。

规则：

- 只派发独立、具体、可回传证据的任务。
- 主智能体保留需求确认、计划批准、最终完成声明和收尾决策。
- 不递归派发子代理。
- 当前不启用完整 subagent-driven-development。

### 5.7 `skill`

目标：维护 Claude Workflow skill 体系。

规则：

- 新增 skill 前先判断是否跨项目复用，项目专属知识不做全局 skill。
- `description` 只写触发条件，不总结完整流程。
- 新增或修改 skill 必须同步架构、入口路由和确定性静态检查。
- 不把具体 skill 的内部流程塞进 `using`。

### 5.8 `setup`

目标：把当前项目的真实习惯沉淀成 Claude Code 支持的项目级 rules、任务 skills 和 references。

规则：

- 只生成 Claude Code 原生识别的内容：`CLAUDE.md`、`.claude/CLAUDE.md`、`.claude/rules/*.md`、`.claude/skills/<name>/SKILL.md`、`.claude/skills/<name>/references/*.md`。
- 不同路径加载方式不同，setup 必须按下表分配产物：

| 路径 | 加载方式 |
|---|---|
| `CLAUDE.md` / `.claude/CLAUDE.md` | 启动自动加载全文 |
| `.claude/rules/*.md` | 自动加载；`paths:` frontmatter 可按路径触发 |
| `.claude/skills/<name>/SKILL.md` | 描述自动注入；调用时加载全文 |
| `.claude/skills/<name>/references/*.md` | 不自动加载；对应 SKILL.md 主动 Read |

- **不使用** `.claude/references/*.md` 全局路径。所有 reference 必须归属某个 skill，放在该 skill 的 `references/` 子目录。
- 项目入口说明默认优先使用项目根 `CLAUDE.md`；只有项目已有 `.claude/CLAUDE.md` 或用户明确要求时才沿用。
- 只处理当前项目下的文件，不读取、生成或修改当前项目之外的 Claude 配置。
- 先只读扫描，再生成候选设计；用户确认后才写入目标项目。
- rules 只放短、稳定、高频规则；详细示例、证据和报告放 `.claude/skills/<skill>/references/` 下。
- 有证据、明确任务触发和执行顺序才生成 skill；没有生成价值的内容只写入扫描账本。
- 没有 skill 归属的长内容，重新判断是 rule、CLAUDE.md 内容还是降级 internal，不允许写入任何 `.claude/references/*` 全局路径。
- 不把目标项目专属知识写回本插件仓库，除非用户明确初始化本仓。

---

## 6. 文档约定

| 文档 | 作用 | 路径 |
|---|---|---|
| 架构基线 | 定义 skill 体系和边界 | `docs/architecture.md` |
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

### 7.1 可选 frontmatter 字段

Claude Code 官方 frontmatter 字段除 `name` 和 `description` 外还有 `allowed-tools`、`paths`、`when_to_use`、`disable-model-invocation`、`user-invocable`、`model`、`effort`、`context`、`agent`、`hooks`、`argument-hint`、`arguments` 等。本项目刻意未使用的字段：

| 字段 | 不使用的原因 |
|---|---|
| `paths` | workflow skill 按用户意图触发，非按文件路径；只允许 `setup` 等明确项目操作的 skill 在需要时启用 |
| `when_to_use` | 与中文 `description` 表达力重叠，刻意只用 `description` 一处 |
| `disable-model-invocation` / `user-invocable` | 仅 `using` skill 使用（与 SessionStart hook 配套，防止重复加载） |
| `context: fork` / `agent` | 当前不启用 skill 内联派出子代理；与 `subagent` skill 调度规则分离 |
| `model` / `effort` | 不在 skill 层固定模型；用户在会话层选择 |
| `allowed-tools` | 仅在风险低、调用频繁的 read-only skill 启用（当前 `setup`） |

### 7.2 子代理边界

二选一：

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

**重要提示**：`<SUBAGENT-STOP>` 和 `## 子代理辅助模式` 是写给**主智能体**读的护栏（主智能体决定是否把 skill 内容拼到子代理 prompt 里），而**不是**子代理启动时自动读取的开关。Claude Code 官方 subagent 启动时只接收自己的系统提示和初始 prompt，不会自动加载主会话的 workflow skill。这两个章节属于纪律性约定，不是平台 enforcement。

要真正硬强制，需要用 [hooks](https://code.claude.com/docs/en/hooks)（`PreToolUse` / `SubagentStart` 等）在工具调用前后拦截，本项目目前未启用。

主流程 skill 还必须包含：

- hard gate；
- 反模式；
- 明确终态；
- 何时不激活。

增强层 skill 可以更短，但不能是空壳。

子代理规则：

- `using`、`execute`、`finish`、`worktree`、`subagent` 使用 `SUBAGENT-STOP`。
- `think`、`plan`、`debug`、`test`、`verify`、`review`、`skill` 可以写普通的“子代理辅助模式”章节，但必须限制为只读、草案、评审或验证输出。
- 不自造新的 XML 标签；目前只允许使用 `SUBAGENT-STOP`。
- 子代理不得替主智能体确认需求、批准计划、执行收尾、提交、推送、切换工作区或宣布最终完成。

---

## 8. 不变式

1. `using` 只做入口路由，不承载具体 skill 的内部流程。
2. `think` 不阻止分析类任务读取上下文。
3. `plan` 不执行计划。
4. `execute` 不擅自改计划。
5. `debug` 没有根因前不修复。
6. `test` 不强制所有任务 TDD，但行为变化必须有测试或替代验证判断。
7. `verify` 是完成声明前的证据门。
8. `finish` 不在未确认时执行破坏性动作。
9. 空壳 skill 不允许同步或发布。
10. `subagent` 只负责调度规则；setup agents 只能只读扫描，不声明支持完整 subagent-driven-development。
11. `skill` 维护 skill 体系，不替代普通开发流程。
12. `setup` 生成项目级 rules、任务 skills 和 references，不替代通用 workflow。
13. 架构调整必须先更新本文档。

---

## 9. 项目边界

- 使用范围：个人 Claude Code 工作流，不做公开插件。
- 语言：中文为主；工具名、命令、路径保留英文。
- skill 数量：小集合，逐步补齐；不堆砌方法论。
- subagent：setup 只读扫描 agents 已存在；完整子代理开发流程仍暂缓。
- 验证：只保留 plugin validate + hook 冒烟。
- 发布：本地同步为主。

---

## 10. 变更记录

| 日期 | 变更 | 原因 |
|---|---|---|
| 2026-05-21 | 重建架构基线，明确个人版边界、分析模式、增强层和 subagent 暂缓策略 | 按当前仓库问题重新校准 |
