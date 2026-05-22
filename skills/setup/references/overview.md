# Setup Overview

本参考定义 setup 的总体流程。setup 的目标不是补缺文件，而是给当前项目建立 Claude Code 可用的导航系统：rules 提供持续短规则，skills 提供按需加载的任务能力，references 承载长证据和清单。

## 推荐生成结构

```text
CLAUDE.md
.claude/
  rules/
    00-project.md
    commands.md
    code-style.md
  references/
    setup-report.md
    domains.md
    habits.md
  skills/
    <task-or-domain>/
      SKILL.md
      references/examples.md
```

只生成有证据支撑且能改变模型行为的文件。skill 名称必须来自当前项目真实任务能力、核心框架、工作流程或高频领域，不加 `project-` 前缀，也不套固定后台 / 前端模板。

先把项目画像、领域索引、覆盖矩阵和 setup report 写成 references 候选；当它们具备明确“理解项目 / 路由任务 / 选择入口”的任务触发和执行顺序时，再生成对应 skill。

高频开发领域先进入深扫候选；当它能让模型知道何时加载、先读什么、怎么改、怎么验证、哪些边界不能碰时，再生成对应 skill。

完整 setup 中，必须形成这些 references 候选：

```text
.claude/references/setup-report.md
.claude/references/domains.md
.claude/references/habits.md
```

如果最终确实生成某个任务 skill，也可以把相关 references 放在该 skill 的 `references/` 下。`SKILL.md` 只放触发、执行顺序和导航，不承载完整报告、领域索引或习惯矩阵。

## 流程

1. 确认目标项目路径。
2. 建立文件索引：顶层目录、`.claude/`、docs、scripts、tests、CI、配置文件和主要源码目录。
3. 读取已有 `.claude/rules/`、`CLAUDE.md`、`AGENTS.md`、README、docs。
4. 读取项目配置和命令入口，形成广度索引。
5. 形成初步候选 rules / skills / references。
6. 对候选做深度扫描；必要时读取 `agents.md` 并发派只读子代理。
7. 按 `habits.md` 抽样编码习惯，形成习惯矩阵。
8. 按 `domains.md` 识别领域。
9. 每个领域抽取代表样例。
10. 形成扫描账本，记录已读取、仅发现路径、未检查 / 证据不足。
11. 按 `coverage.md` 形成覆盖矩阵。
12. 生成候选 rules、skills 和 references。
13. 用户确认后写入。
14. 写入后验证结构。

会话里已经注入的规则正文只能作为线索。setup 的证据必须来自目标项目文件系统：文件索引、实际读取的配置 / rules / docs、代表源码样例、编码习惯抽样和命令入口。没有实际读取的内容，不能写成“已分析”，只能写成“发现路径”或“未检查”。

## 已有项目内容

如果目标项目已有 `.claude/rules/`：

- 把 rules 当作项目显式规则和证据来源；
- 不重复生成同类 rule；
- 仍然生成或刷新 setup report、domains、habits 这类 references 候选；
- 高频领域只有在存在明确任务触发和执行顺序时才生成 skill；
- 不输出当前项目之外的 Claude 配置信息。

## 用户可读输出

输出重点是“分析了什么”和“建议生成什么”。用户默认只需要感知应该添加哪些内容；未采纳项只进入内部扫描账本，不作为用户可见主结果。已有 rules、代码样例、编码习惯和命令入口应整理为已分析内容或建议生成内容。

输出候选前必须先形成扫描账本。扫描账本用于内部判断、用户追问时核对，以及用户指出漏项后补扫；默认不要完整展示。

扫描账本必须区分三种状态：

- **已读取**：本轮实际读取了文件内容；
- **仅发现路径**：只通过文件索引发现，未读取内容；
- **未检查 / 证据不足**：因为范围、时间或缺少样例无法判断。默认只内部记录，不进入用户候选输出。

最终建议必须分组输出。不要把 rule、skill、reference 混在同一张表里；不要默认输出“依据”列，证据细节放入 setup report。

```markdown
建议生成 rules：
| 路径 | 使用场景 / 作用 | 内容概要 |
|---|---|---|

建议生成 skills：
| 路径 | 使用场景 / 作用 | 内容概要 |
|---|---|---|

建议生成 references：
| 路径 | 承载内容 | 用途 |
|---|---|---|
```

`使用场景 / 作用` 必须写成完整句，说明该文件帮助模型在什么任务中做什么判断；不要写成“API 层约束”“命令入口”这类短标签。

## CLAUDE.md

项目入口说明默认写入项目根 `CLAUDE.md`，只放项目级内容使用规则，不放长示例。

如果项目已经使用 `.claude/CLAUDE.md`，或用户明确要求把 Claude Code 记忆放在 `.claude/` 下，可以沿用 `.claude/CLAUDE.md`。不要同时新建两个入口文件。

模板：

```markdown
# Project Instructions

本项目使用 Claude Workflow 生成项目级 rules、skills 和 references。

## 使用规则

- 开始代码任务前，遵守 `.claude/rules/` 中适用规则。
- 涉及实现、计划、调试、测试时，按当前任务加载最相关的项目 skill。
- 不要一次性加载全部项目 skills。
- 项目 rules 和本文件优先于通用 workflow 默认建议。
- 如果项目 skill 与当前代码冲突，先读相似实现，以当前代码为准并说明冲突。

## 常用入口

- 项目画像和领域索引：见 `.claude/references/domains.md`。
- 命令和验证方式：见 `.claude/references/setup-report.md` 或独立命令 reference。
- 任务 skill 使用当前项目自己的名称，例如核心框架、装修、发布、组件等真实任务入口。
```

如果项目已有 `CLAUDE.md` 或 `.claude/CLAUDE.md`，优先追加“使用规则”小节；不要覆盖原内容。

## Setup Report

setup report 默认放在 `.claude/references/setup-report.md`。
习惯矩阵默认放在 `.claude/references/habits.md`；setup report 只摘要引用它。

模板：

```markdown
# Setup Report

## 已识别

- 项目类型：
- 技术栈：
- 包管理器：
- 测试工具：
- 构建工具：

## 已生成

- ...

## 习惯矩阵

- 详见 `habits.md`

## 证据来源

- ...

## 使用注意

- ...
```
