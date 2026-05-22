---
name: setup
description: "为当前 Claude Code 项目生成项目级 rules 和 project-* skills 时使用；用于扫描项目规范、代码模式、命令和验证方式，生成或刷新待确认的项目专属工作流内容。"
---

## 子代理辅助模式

如果你是作为子代理被派遣做 setup 扫描，只能返回只读发现、证据文件和建议生成项；不得写入 `.claude/`、覆盖规则或宣布项目已完成初始化。

# 项目工作流初始化

setup 用来把当前项目的真实习惯沉淀成 Claude Code 支持的项目级内容。它只生成当前项目内的 rules 和 project skills，不处理任何用户级或跨项目配置。

## 目标

- 用 `.claude/rules/*.md` 承载短、稳定、高频的项目规则；
- 用 `.claude/skills/project-*/SKILL.md` 承载按需加载的项目任务入口、领域导航、证据索引和操作流程；
- 用 `references/` 保存证据、示例和扫描报告；
- 让 `think`、`plan`、`execute`、`debug`、`test` 能按当前项目习惯工作。

## 何时使用

使用本 skill：

- 用户要求初始化当前项目的 Claude Code 工作流；
- 用户要求生成项目专属 rules、skills、规范或上下文；
- 项目代码风格、API、UI、测试、命令等需要沉淀成可复用规则；
- 已有项目 rules / project skills 需要刷新，但必须先评估 diff。

不使用本 skill：

- 只是修改本仓库全局 workflow skill，应该用 `skill`；
- 单次代码改动，直接按 `using` 路由到对应流程；
- 没有用户确认就自动写入目标项目；
- 为了“覆盖全”而生成没有证据支撑的 project skill。

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

已有 `.claude/rules/` 是输入证据，不是跳过 project skills 的理由。rules 和 project skills 分工不同：rules 放持续短规则，project skills 放按需加载的领域入口、证据索引和操作流程。

只要执行完整 setup，`project-context` 默认必须作为候选生成或刷新，用来保存项目画像、领域索引、覆盖矩阵和 setup report。除非用户明确只生成某个单项，不要因为已有 structure/rules 文档就跳过 `project-context`。

高频开发领域如果有明确 rules 或多个一致样例，默认应生成对应 `project-*` skill。已有 rules 只说明证据充足，不说明 skill 冗余。project skill 不复制 rules，而是告诉模型何时加载哪些 rules、读哪些代表文件、按什么顺序处理、用什么命令验证。

不要预设后台、全栈或前端模板。除 `project-context` 和 `project-commands` 这类基础入口外，领域 skill 名称必须来自当前项目自己的目录、规则文件、业务词汇和高频任务，而不是套用固定清单。

`project-* / SKILL.md` 不能成为 rules 的复印件。SKILL.md 只写入口、触发、执行顺序、验证选择和 references 导航；详细规则、覆盖矩阵、证据、示例和长清单必须放到 `references/`。

完整 setup 中，`project-context` 必须生成 `references/setup-report.md` 和 `references/domains.md`，除非用户明确只生成极小范围。
</HARD-GATE>

---

## 工作流

### 1. 确认目标项目

先确认当前工作目录就是要初始化的项目。不要把项目专属内容写回 `claude-workflow` 插件仓库，除非用户明确是在初始化本仓。

### 2. 只读扫描

先按 `references/overview.md` 和 `references/coverage.md` 做广度索引，再按 `references/domains.md` 判断领域。不要因为先读到某个领域样例就提前生成结论。

按顺序读取：

1. 显式规则：`CLAUDE.md`、`AGENTS.md`、README、CONTRIBUTING、docs；
2. 项目配置：package、workspace、tsconfig、lint、format、test、build、CI；
3. 目录结构：apps、packages、src、docs、scripts、tests、.claude；
4. 代表实现：每个领域找 2-5 个相似文件，不全量总结；
5. 验证入口：scripts、CI、已有测试命令和常用开发命令。

### 3. 生成候选设计

先输出计划，不直接写文件。候选内容必须区分：

- **rules**：持续生效的短规则；
- **project skills**：按需加载的详细项目模式；
- **references**：证据、示例、setup report。

生成 rules 前读 `references/rules.md`。生成 project skills 前读 `references/skills.md`。覆盖矩阵和证据等级必须按 `references/coverage.md` 输出。

已有项目 rules 的处理方式：

- 作为证据来源读取；
- 可在 project skill 中引用；
- 可避免重复生成同类 rule；
- 不能作为“不生成 project-context / project-commands / 高频领域 skill”的理由。
- 高频领域必须按项目实际技术栈、目录和已有 rules 命名；不要套用固定领域列表。

### 4. 等用户确认

用户确认后才写入 `.claude/`。如果目标文件已存在：

- 先读取现有内容；
- 说明保留、追加或替换策略；
- 不无提示覆盖用户已有规则。

### 5. 验证结构

写入后检查：

- 每个 project skill 都有 `SKILL.md`、`name`、`description`；
- `name` 和目录名一致；
- rules 简短，不包含长示例；
- references 路径存在；
- `project-context/references/setup-report.md` 存在；
- `project-context/references/domains.md` 存在；
- project skill 正文没有大段复写 rules；详细内容已经放到 references；
- 没有生成空壳 skill。

---

## 生成原则

- 有证据才生成，没有证据就写入 setup report 的“未覆盖”。
- 明确区分强规则和观察模式：文档规则优先，代码样例只是证据。
- 不把偶然写法总结成规范；至少需要多个相似样例，或来自明确文档。
- 不一次性生成所有领域；只生成当前项目确实存在的领域。
- 不自动修改用户已有 `CLAUDE.md`、`.claude/CLAUDE.md` 或 rules，除非用户确认合并策略。
- `SKILL.md` 保持短；长示例、文件清单、扫描报告放 references。
- 若某领域已有 rule，project skill 应引用该 rule，并把补充证据放 references；不要复制 rule 正文。

## 输出格式

只读扫描后输出：

```text
项目类型：
- ...

已分析内容：
- 项目类型 / 技术栈：...
- 已有项目规则：...
- 关键代码领域：...
- 命令和验证入口：...

建议生成：
- 文件：...
- 原因：...
- 内容概要：...

证据：
- ...

需要确认：
- 是否写入这些文件
- 已存在文件的处理方式
```

写入完成后输出：

```text
已生成：
- ...

未生成：
- ...

验证：
- ...

剩余风险：
- ...
```

## 与其他 skill 的关系

| 场景 | 使用 |
|---|---|
| 设计 setup 生成内容 | 本 skill |
| 维护 Claude Workflow 插件 skill | `skill` |
| 生成后执行代码任务 | `using` 路由到 `think` / `plan` / `execute` |
| 项目规则影响测试策略 | `test` 读取相关 project skill |
| 完成声明 | `verify` |
