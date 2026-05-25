---
name: setup
description: "为当前 Claude Code 项目生成项目级 rules、任务 skills 和 references 时使用；用于扫描项目规范、代码模式、命令和验证方式，生成或刷新待确认的项目专属工作流内容。"
allowed-tools: Read Grep Glob
---

## 子代理辅助模式

被派遣做 setup 扫描时，只返回只读发现、证据文件、强度判断和建议落点；不写入 `.claude/`、不覆盖规则、不宣布项目已初始化。

# 项目工作流初始化

把当前项目的真实习惯沉淀成 Claude Code 支持的项目级内容：rules（持续短规则）、任务 skills（按需加载的能力）、references（证据与清单）。只生成当前项目内的内容，不碰用户级或跨项目配置。

## 何时使用

- 用户要求初始化当前项目的 Claude Code 工作流；
- 生成项目专属 rules / skills / 规范 / 上下文；
- 已有项目 rules / skills / references 需刷新（必须先评估 diff）。

不使用：只改本插件全局 skill（用 `skill`）；单次代码改动（按 `using` 路由）；未经确认就写入；为“覆盖全”生成无证据的 skill。

## Claude Code 支持边界

只生成 Claude Code 原生识别的路径，按加载方式区分：

| 路径 | 加载方式 | 适用 |
|---|---|---|
| `CLAUDE.md` / `.claude/CLAUDE.md` | 启动时自动加载全文 | 项目入口说明、稳定全局指令 |
| `.claude/rules/*.md` | 启动时自动加载；带 `paths:` 则按路径触发 | 短、稳定、持续生效的规则 |
| `.claude/skills/<name>/SKILL.md` | 描述自动注入；调用时加载全文 | 任务能力、执行顺序、验证方式 |
| `.claude/skills/<name>/references/*.md` | 不自动加载；由对应 SKILL.md 主动 Read | skill 私有长样例、矩阵、证据 |

`.claude/references/` 不是原生路径，本项目不使用——所有 reference 必须归属某个 skill。项目入口说明默认写项目根 `CLAUDE.md`，仅当项目已用 `.claude/CLAUDE.md` 或用户要求时才沿用。

<HARD-GATE>
1. setup 输出不得引用、评价或依赖当前项目之外的 Claude 配置。
2. reference 必须归属某个 skill 并被该 SKILL.md 显式 Read，否则不生成；无 skill 归属的长内容重判为 rule、CLAUDE.md 内容或降级 internal。
3. 生成 proposal 前必须先形成扫描账本；没有账本不许说“扫描完成”或给最终候选。账本用于内部判断和用户追问；默认只向用户呈现已分析范围和建议添加项。
4. 深度扫描必须实际调用 `Agent` 工具，不许主线程内联代替（除非项目无源码、无配置入口、无已有 `.claude/rules/` 三条全中）。强制派发规则见工作流第 4 步。
5. 用户可见输出必须含“已派发 agents”段，列出实际调用的 `subagent_type`、范围和状态；任何缺席必须说明原因和补扫方式。
6. skill 必须有明确任务触发、执行顺序、验证方式和风险边界；高频领域或已有 rules 只说明值得深扫，不等于必须生成 skill。skill 名从项目真实任务能力提取，不套后台 / 前端模板。
7. SKILL.md 只写入口、触发、执行顺序、验证选择和 references 导航；详细规则、矩阵、证据、长清单放 references。setup report、domains、habits 必须归属对应任务 skill 的 references，无归属则降级 internal。
</HARD-GATE>

## 工作流

### 1. 确认目标项目

确认当前工作目录就是要初始化的项目。不要把项目专属内容写回 `claude-workflow` 插件仓库，除非用户明确要初始化本仓。

### 2. 只读扫描

按 `references/overview.md`、`references/coverage.md` 做广度索引，按 `references/habits.md` 分析编码习惯，按 `references/domains.md` 判断领域。证据必须来自目标项目文件系统；已注入的 CLAUDE / rules 只是线索，未实际读取的标为“仅发现路径”。

顺序：文件索引（顶层目录、`.claude/`、docs、scripts、tests、CI、配置、主要源码）→ 读已有显式规则（CLAUDE.md / AGENTS.md / README / CONTRIBUTING / docs / `.claude/rules/`）→ 读项目配置（package / workspace / tsconfig / lint / format / test / build / CI）→ 整理命令入口 → 列初步候选。

### 3. 初步候选

轻量扫描后形成候选清单（只代表“值得深挖”，不是最终建议）：

```markdown
| 类型 | 候选名称 | 初步依据 | 需要深扫什么 |
|---|---|---|---|
```

### 4. 深度扫描和子代理

读 `references/agents.md`，按其分工、提示模板和 plugin 命名空间说明，通过 `Agent` 工具并发派只读子代理。子代理只扫描，不决策、不写入。

强制派发（满足即必须派；短名失败时重试 `claude-workflow:<name>`）：

- 存在 package / workspace / CI / scripts / build / env 任一配置 → `setup-config`
- 存在源码目录 → `setup-conventions`
- 存在 CSS/SCSS/LESS/Sass/Stylus、组件 style、CSS Modules、utility CSS 或 design tokens → `setup-styling`
- 存在自研框架 / CRUD / table / form / DSL / 装修引擎 / API factory → `setup-framework`
- 存在 `CLAUDE.md` / `.claude/CLAUDE.md` / `.claude/rules/*.md` → `setup-rules`
- 反复出现的页面骨架 / 业务流程 / 文件组织 → `setup-patterns`
- 高频且项目特有流程或风险的业务领域 → `setup-domain`

agent 不可用、报错或返回空时主线程补扫，并在用户可见输出说明缺席原因。

### 5. 形成扫描账本

生成最终建议前先形成账本，具体到文件或目录，区分“已读取 / 仅发现路径 / 未检查”。不写“已全量扫描”这类无法核对的话。默认不贴给用户，用户追问或指出漏项时再展开并补扫。

### 6. 生成候选设计

先输出计划，不直接写文件。按产物决策协议判定落点：

| 条件 | 最终落点 | 加载方式 |
|---|---|---|
| 强规则 + 全项目 / 某技术层 + 高频踩坑或硬边界 | `.claude/rules/<name>.md` | 自动加载 |
| 强规则但只对部分路径生效 | `.claude/rules/<name>.md` + `paths:` | 触发匹配文件时加载 |
| 稳定习惯 + 明确任务触发 + 需要执行步骤 | `.claude/skills/<name>/SKILL.md` | 按需加载 |
| skill 私有长样例、矩阵、证据 | `.claude/skills/<name>/references/<file>.md` | 对应 SKILL.md 主动 Read |
| 跨 skill 共享但无 skill 归属的长内容 | 重判：rule / CLAUDE.md / 降级 | — |
| 单点观察、冲突项、低频业务、无任务触发 | internal（仅进账本） | 不写入 |

每个进入用户可见建议的候选必须至少满足一条生成价值：防止模型改错、少问路、写得像项目、正确验证、降低重复扫描成本。只能描述“项目里有什么”的候选放 reference 或 internal。

生成前读对应 reference：rules 读 `references/rules.md`，skills 读 `references/skills.md`，习惯按 `references/habits.md`，覆盖矩阵按 `references/coverage.md`。已有 rules 作为证据读取、可被 skill 引用、避免重复生成同类 rule。

用户可见建议分组输出（不混表，默认不输出“依据”列）：

```markdown
建议生成 rules：
| 路径 | 使用场景 / 作用 | 内容概要 |
|---|---|---|

建议生成 skills：
| 路径 | 使用场景 / 作用 | 内容概要 |
|---|---|---|

建议生成 references：
| 路径 | 承载内容 | 消费入口 |
|---|---|---|
```

`使用场景 / 作用` 必须写成完整句，说明该文件帮模型在什么任务中做什么判断，不写“API 层约束”这类短标签。默认不输出未采纳项。

### 7. 等用户确认

确认后才写入 `.claude/`。目标文件已存在时：先读现有内容，说明保留 / 追加 / 替换策略，不无提示覆盖用户已有规则。

### 8. 验证结构

写入后检查：每个 skill 有 `SKILL.md` / `name` / `description`，`name` 与目录名一致；rules 简短无长示例；所有 reference 落在 `.claude/skills/<name>/references/` 且被对应 SKILL.md 显式引用；没有 `.claude/references/*.md`；setup report / domains / habits 已落到建议位置；SKILL.md 没有大段复写 rules；没有空壳 skill。

## 输出格式

只读扫描后输出：

```text
项目类型：...

已派发 agents：
| subagent_type | 扫描范围 | 返回状态 |
|---|---|---|

未派发 / 失败的 agent：
- <名称>：<原因>（主线程如何补扫）

已分析内容：
- 项目类型 / 技术栈、已有规则、关键代码领域、编码习惯、命令和验证入口

建议生成 rules / skills / references：（分三张表，见上）

需要确认：
- 是否写入；已存在文件的处理方式；冲突或过期文档处理方式
```

写入完成后输出已生成项、验证结果、使用注意。

## 与其他 skill 的关系

| 场景 | 使用 |
|---|---|
| 设计 setup 生成内容 | 本 skill |
| 维护 Claude Workflow 插件 skill | `skill` |
| 生成后执行代码任务 | `using` 路由到 `think` / `plan` / `execute` |
| 项目规则影响测试策略 | `test` 读取相关项目 skill 或 reference |
| 完成声明 | `verify` |
