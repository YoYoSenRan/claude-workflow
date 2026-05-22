# Setup Overview

本参考定义 setup 的总体流程。setup 的目标不是补缺文件，而是给当前项目建立 Claude Code 可用的导航系统：rules 提供持续短规则，project skills 提供按需加载的任务入口。

## 推荐生成结构

```text
CLAUDE.md
.claude/
  rules/
    00-project.md
    commands.md
    code-style.md
    testing.md
    frontend.md
    api.md
    database.md
  skills/
    project-context/
      SKILL.md
      references/setup-report.md
    project-commands/
      SKILL.md
    project-style/
      SKILL.md
      references/examples.md
    project-testing/
      SKILL.md
      references/examples.md
    project-ui/
      SKILL.md
      references/examples.md
    project-api/
      SKILL.md
      references/examples.md
    project-data/
      SKILL.md
      references/examples.md
```

只生成有证据支撑的文件。没有 UI、API、数据库或测试模式时，不生成对应领域 skill。

`project-context` 是完整 setup 的基础产物，默认生成或刷新，用来保存项目画像、领域索引、覆盖矩阵和 setup report。已有 rules 可以作为它的证据来源，但不能替代它。

高频开发领域默认生成对应 project skill，即使已有 rules。已有 rules 越完整，越适合作为 project skill 的强证据和入口引用。

完整 setup 中，`project-context` 必须包含 references：

```text
.claude/skills/project-context/references/setup-report.md
.claude/skills/project-context/references/domains.md
```

`project-context/SKILL.md` 只放摘要和导航，不承载完整报告。

## 流程

1. 确认目标项目路径。
2. 读取已有 `.claude/`、`CLAUDE.md`、`AGENTS.md`、README、docs。
3. 扫描项目配置和目录，形成广度索引。
4. 按 `domains.md` 识别领域。
5. 每个领域抽取代表样例。
6. 按 `coverage.md` 形成覆盖矩阵。
7. 生成候选 rules 和 project skills。
8. 用户确认后写入。
9. 写入后验证结构。

## 已有项目内容

如果目标项目已有 `.claude/rules/`：

- 把 rules 当作项目显式规则和证据来源；
- 不重复生成同类 rule；
- 仍然生成或刷新 `project-context`；
- 高频领域生成 project skill 作为任务入口，引用现有 rules 和 examples；
- 不输出当前项目之外的 Claude 配置信息。

## 用户可读输出

输出重点是“分析了什么”和“建议生成什么”。不要把大量“不生成 project-*”作为主结果；已有 rules、代码样例和命令入口应整理为已分析内容或建议生成内容。

## CLAUDE.md

项目入口说明默认写入项目根 `CLAUDE.md`，只放项目级内容使用规则，不放长示例。

如果项目已经使用 `.claude/CLAUDE.md`，或用户明确要求把 Claude Code 记忆放在 `.claude/` 下，可以沿用 `.claude/CLAUDE.md`。不要同时新建两个入口文件。

模板：

```markdown
# Project Instructions

本项目使用 Claude Workflow 生成项目级 rules 和 project skills。

## 使用规则

- 开始代码任务前，遵守 `.claude/rules/` 中适用规则。
- 涉及实现、计划、调试、测试时，按任务领域加载最相关的 `project-*` skill。
- 不要一次性加载全部 project skills。
- 项目 rules 和本文件优先于通用 workflow 默认建议。
- 如果 project skill 与当前代码冲突，先读相似实现，以当前代码为准并说明冲突。

## 常用入口

- `project-context`：项目结构、技术栈和领域索引。
- `project-commands`：常用命令和验证方式。
- `project-style`：代码风格、命名、导入、错误处理、封装方式。
```

如果项目已有 `CLAUDE.md` 或 `.claude/CLAUDE.md`，优先追加“使用规则”小节；不要覆盖原内容。

## Setup Report

setup report 放在 `.claude/skills/project-context/references/setup-report.md`。

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

## 未生成

- ...：证据不足

## 证据来源

- ...

## 风险

- ...
```
