---
name: setup
description: "为当前 Claude Code 项目生成项目级 rules 和领域 skills 时使用；用于扫描项目规范、代码模式、命令和验证方式，生成或刷新待确认的项目专属工作流内容。"
---

## 子代理辅助模式

如果你是作为子代理被派遣做 setup 扫描，只能返回只读发现、证据文件、强度判断和建议落点；不得写入 `.claude/`、覆盖规则或宣布项目已完成初始化。

# 项目工作流初始化

setup 用来把当前项目的真实习惯沉淀成 Claude Code 支持的项目级内容。它只生成当前项目内的 rules 和领域 skills，不处理任何用户级或跨项目配置。

## 目标

- 用 `.claude/rules/*.md` 承载短、稳定、高频的项目规则；
- 用 `.claude/skills/<domain>/SKILL.md` 承载按需加载的项目任务入口、领域导航、证据索引和操作流程；
- 用 `references/` 保存证据、示例、编码习惯画像和扫描报告；
- 让 `think`、`plan`、`execute`、`debug`、`test` 能按当前项目习惯工作。

## 何时使用

使用本 skill：

- 用户要求初始化当前项目的 Claude Code 工作流；
- 用户要求生成项目专属 rules、skills、规范或上下文；
- 项目代码风格、API、UI、测试、命令等需要沉淀成可复用规则；
- 已有项目 rules / 领域 skills 需要刷新，但必须先评估 diff。

不使用本 skill：

- 只是修改本仓库全局 workflow skill，应该用 `skill`；
- 单次代码改动，直接按 `using` 路由到对应流程；
- 没有用户确认就自动写入目标项目；
- 为了“覆盖全”而生成没有证据支撑的领域 skill。

---

## Claude Code 支持边界

只能生成 Claude Code 会识别或能按需读取的内容：

```text
CLAUDE.md
.claude/CLAUDE.md
.claude/rules/*.md
.claude/skills/<name>/SKILL.md
.claude/skills/<name>/references/*.md
```

项目入口说明默认优先写入项目根 `CLAUDE.md`。只有目标项目已经使用 `.claude/CLAUDE.md`，或用户明确要求时，才沿用 `.claude/CLAUDE.md`。

setup 不读取、生成或修改当前项目之外的 Claude 配置。

不要依赖 Claude Code 不会自动识别的自定义主文件作为核心入口。报告和证据可以放在 skill 的 `references/` 下。

<HARD-GATE>
setup 的输出不得引用、评价或依赖当前项目之外的 Claude 配置。

已有 `.claude/rules/` 是输入证据，不是跳过领域 skills 的理由。rules 和领域 skills 分工不同：rules 放持续短规则，领域 skills 放按需加载的领域入口、证据索引和操作流程。

只要执行完整 setup，`context` 默认必须作为候选生成或刷新，用来保存项目画像、领域索引、覆盖矩阵和 setup report。除非用户明确只生成某个单项，不要因为已有 structure/rules 文档就跳过 `context`。

高频开发领域如果有明确 rules 或多个一致样例，默认应生成对应领域 skill。已有 rules 只说明证据充足，不说明 skill 冗余。领域 skill 不复制 rules，而是告诉模型何时加载哪些 rules、读哪些代表文件、按什么顺序处理、用什么命令验证。

不要预设后台、全栈或前端模板。除 `context` 和 `commands` 这类基础入口外，领域 skill 名称必须来自当前项目自己的目录、规则文件、业务词汇和高频任务，而不是套用固定清单。

领域 skill 的 `SKILL.md` 不能成为 rules 的复印件。SKILL.md 只写入口、触发、执行顺序、验证选择和 references 导航；详细规则、覆盖矩阵、证据、示例和长清单必须放到 `references/`。

完整 setup 中，`context` 必须生成 `references/setup-report.md`、`references/domains.md` 和 `references/habits.md`，除非用户明确只生成极小范围。

生成 proposal 前必须先形成扫描账本。没有扫描账本，不允许说“扫描完成”，也不允许给最终候选。扫描账本用于内部判断和用户追问时核对；默认用户输出只呈现已分析范围和建议添加项，未采纳项只进入内部扫描账本。
</HARD-GATE>

---

## 工作流

### 1. 确认目标项目

先确认当前工作目录就是要初始化的项目。不要把项目专属内容写回 `claude-workflow` 插件仓库，除非用户明确是在初始化本仓。

### 2. 只读扫描

先按 `references/overview.md` 和 `references/coverage.md` 做广度索引，再按 `references/habits.md` 分析编码习惯，最后按 `references/domains.md` 判断领域。不要因为先读到某个领域样例就提前生成结论。

扫描必须以目标项目文件系统为证据。会话里已经注入的 CLAUDE / rules 内容只能当作线索，不能替代实际读取或文件索引；如果为了节省上下文没有读取某个文件，必须在扫描账本里标为“未读取 / 仅发现路径”。

按顺序执行：

1. **文件索引**：先列出顶层目录、`.claude/`、docs、scripts、tests、CI、配置文件和主要源码目录；
2. **显式规则**：读取存在的 `CLAUDE.md`、`AGENTS.md`、README、CONTRIBUTING、docs、`.claude/rules/*.md`；
3. **项目配置**：读取 package / workspace / tsconfig / lint / format / test / build / CI 入口；
4. **命令入口**：整理 scripts、CI job、常用开发 / 构建 / 验证命令；
5. **初步候选**：先根据索引、rules、docs、scripts 和目录名列出可能需要的 rules / skills，不做最终判断；
6. **深度扫描**：按候选范围执行本地抽样；中大型项目或用户要求深入时，先读 `references/agents.md`，再并发派只读子代理扫描；
7. **编码习惯抽样**：打开 `references/habits.md`，按其中步骤选样例、提取字段、判断强度和落点；
8. **合并决策**：合并本地扫描和子代理返回，去重、降级弱观察、决定最终建议；
9. **内部缺口登记**：把未读取的高风险目录或入口记入扫描账本，例如 hooks、hybrid、plugins、tests、CI、生成脚本、关键 runtime 入口；默认不展示给用户，除非它会影响建议生成或用户追问扫描过程。

不要只用 `ls` 和已注入上下文完成 setup。至少要有文件索引、配置读取、规则读取、编码习惯抽样和代表实现抽样；除非项目本身没有对应文件。

### 3. 初步候选

轻量扫描后，先形成初步候选清单。候选只代表“值得深挖”，不是最终建议。

```markdown
| 类型 | 候选名称 | 初步依据 | 需要深扫什么 |
|---|---|---|---|
| rule | <name> | <rules/docs/scripts/目录证据> | <要验证的习惯或命令> |
| skill | <name> | <高频领域/目录/rule> | <代表文件和写法习惯> |
| reference | <path> | <证据或长清单需要承载> | <需要收集的证据> |
```

不要把初步候选直接输出成最终建议。先进入深度扫描。

### 4. 深度扫描和子代理

默认由主线程完成深度扫描。遇到以下情况，必须使用 Claude Code 的 `Agent` 工具并发派只读子代理：

- 项目目录较大，候选领域超过 3 个；
- 已有 `.claude/rules/` 较多，需要核对真实代码；
- 需要同时分析配置命令、编码习惯、多个业务领域；
- 用户明确要求深入 setup 或使用 agent。

子代理只扫描，不决策、不写入。每个子代理必须拿到明确范围和固定输出格式。

派发前读取 `references/agents.md`，按其中推荐分工和提示模板组织任务。不要只在正文里说“需要 agent”；必须实际调用 `Agent` 工具。

调用规则：

- `setup-config`：只要项目存在 package / workspace / CI / scripts / build / env 任一类配置，就必须派发；
- `setup-style`：只要项目存在源码目录，就必须派发；
- `setup-rules`：只要项目存在 `CLAUDE.md`、`.claude/CLAUDE.md` 或 `.claude/rules/*.md`，就必须派发；
- `setup-domain`：每个高频候选领域可以单独派发；候选超过 3 个时至少派发 2 个不同领域；
- 如果某个 agent 无法调用，必须在用户可见输出中说明：未能调用哪个 agent、原因是什么、主线程如何补扫。

Agent 工具调用时显式指定 `subagent_type`：

```text
subagent_type: setup-config
subagent_type: setup-style
subagent_type: setup-rules
subagent_type: setup-domain
```

不要使用旧称 `Task tool` 描述调度。Claude Code 当前用于派发 subagent 的工具名是 `Agent`。

子代理任务模板：

```text
你是 setup 深度扫描子代理。只读扫描，不修改文件，不生成 .claude 内容，不做最终决策。

扫描范围：<路径 / 领域 / 候选项>
目标：验证这些候选 rules / skills 是否有足够证据，并提取编码习惯。

请读取代表文件，返回表格：

| 类型 | 候选名称 | 观察结果 | 证据文件 | 强度 | 建议落点 |
|---|---|---|---|---|---|

强度只能是：强规则 / 稳定习惯 / 内部观察 / 不采用。

边界：
- 不输出最终“应该生成什么”的结论。
- 不写文件。
- 不展示无关目录树。
- 证据文件必须是实际读取过的文件。
```

主线程收到结果后：

1. 合并同名候选；
2. 去掉不采用项；
3. 将内部观察只留在扫描账本；
4. 将强规则 / 稳定习惯映射到 rules、skills 或 references；
5. 决定最终用户可见建议。

### 5. 形成扫描账本

生成最终建议前，先形成本轮扫描账本。账本必须具体到文件或目录，不写“已全量扫描”这类无法核对的话。默认不要把完整账本贴给用户；用户指出漏项或追问扫描过程时，再按账本回答并补扫漏项。

### 6. 生成候选设计

先输出计划，不直接写文件。候选内容必须区分：

- **rules**：持续生效的短规则；
- **领域 skills**：按需加载的详细项目模式；
- **references**：证据、示例、习惯矩阵、setup report。

生成 rules 前读 `references/rules.md`。生成领域 skills 前读 `references/skills.md`。编码习惯必须按 `references/habits.md` 的步骤提取并判断落点。覆盖矩阵和证据等级必须按 `references/coverage.md` 输出。

已有项目 rules 的处理方式：

- 作为证据来源读取；
- 可在领域 skill 中引用；
- 可避免重复生成同类 rule；
- 不能作为跳过 `context` / `commands` / 高频领域 skill 的理由。
- 高频领域必须按项目实际技术栈、目录和已有 rules 命名；不要套用固定领域列表。

如果证据不足会影响生成结果，不硬生成；默认从建议中省略该项。只有缺口会阻塞用户目标时才说明。

用户可见建议必须分组输出，不要把 rule、skill、reference 混在同一张表里。默认不要输出“依据”列；证据细节写入 setup report，用户追问时再展开。

`作用 / 使用场景` 不能写成“路由规则约束”“项目画像入口”这类短标签，必须说明它帮助模型在什么任务中做什么判断。

默认不要输出未采纳项区块。未采纳项只进内部扫描账本。只有会影响用户确认或需要用户决策的内容，才放到“需要确认”中。

用户可见建议格式：

```markdown
建议生成 rules：
| 路径 | 使用场景 / 作用 | 内容概要 |
|---|---|---|
| `.claude/rules/<name>.md` | <模型在什么任务中必须持续遵守什么边界> | <短规则包含哪些约束，不写长样例> |

建议生成 skills：
| 路径 | 使用场景 / 作用 | 内容概要 |
|---|---|---|
| `.claude/skills/<name>/SKILL.md` | <遇到什么任务时加载；加载后帮助模型按什么顺序工作> | <触发条件、执行顺序、需要读取的 references、验证选择> |

建议生成 references：
| 路径 | 承载内容 | 用途 |
|---|---|---|
| `.claude/skills/<name>/references/<file>.md` | <样例、习惯矩阵、命令表、setup report 等长内容> | <哪个 skill 会读取它；解决什么查找或证据问题> |
```

### 7. 等用户确认

用户确认后才写入 `.claude/`。如果目标文件已存在：

- 先读取现有内容；
- 说明保留、追加或替换策略；
- 不无提示覆盖用户已有规则。

### 8. 验证结构

写入后检查：

- 每个领域 skill 都有 `SKILL.md`、`name`、`description`；
- `name` 和目录名一致；
- rules 简短，不包含长示例；
- references 路径存在；
- `context/references/setup-report.md` 存在；
- `context/references/domains.md` 存在；
- `context/references/habits.md` 存在；
- 领域 skill 正文没有大段复写 rules；详细内容已经放到 references；
- 没有生成空壳 skill。

---

## 生成原则

- 有证据才生成；证据不足的候选只进入内部扫描账本，默认不向用户列出。
- 明确区分强规则和观察模式：文档规则优先，代码样例只是证据。
- 不把偶然写法总结成规范；至少需要多个相似样例，或来自明确文档。
- 习惯扫描必须覆盖写法风格、代码顺序、命名、类型、核心写法、抽象边界、注释、数据流和验证方式；无法落地的维度只保留在内部扫描账本，不进入默认候选输出。
- 不一次性生成所有领域；只生成当前项目确实存在的领域。
- 不自动修改用户已有 `CLAUDE.md`、`.claude/CLAUDE.md` 或 rules，除非用户确认合并策略。
- `SKILL.md` 保持短；长示例、文件清单、扫描报告放 references。
- 若某领域已有 rule，领域 skill 应引用该 rule，并把补充证据放 references；不要复制 rule 正文。

## 输出格式

只读扫描后输出：

```text
项目类型：
- ...

已分析内容：
- 项目类型 / 技术栈：...
- 已有项目规则：...
- 关键代码领域：...
- 编码习惯：写法风格 / 代码顺序 / 命名 / 类型 / 注释 / 抽象 / 数据流 / 验证方式
- 命令和验证入口：...

建议生成 rules：
| 路径 | 使用场景 / 作用 | 内容概要 |
|---|---|---|
| ... | ... | ... |

建议生成 skills：
| 路径 | 使用场景 / 作用 | 内容概要 |
|---|---|---|
| ... | ... | ... |

建议生成 references：
| 路径 | 承载内容 | 用途 |
|---|---|---|
| ... | ... | ... |

需要确认：
- 是否写入这些文件
- 已存在文件的处理方式
- 需要用户决策的冲突或过期文档处理方式
```

写入完成后输出：

```text
已生成：
- ...

验证：
- ...

使用注意：
- ...
```

## 与其他 skill 的关系

| 场景 | 使用 |
|---|---|
| 设计 setup 生成内容 | 本 skill |
| 维护 Claude Workflow 插件 skill | `skill` |
| 生成后执行代码任务 | `using` 路由到 `think` / `plan` / `execute` |
| 项目规则影响测试策略 | `test` 读取相关领域 skill |
| 完成声明 | `verify` |
