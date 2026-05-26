---
name: setup
description: 为当前 Claude Code 项目生成或刷新项目级 rules、skills、references 时使用
allowed-tools: Read Grep Glob Agent
---

# 项目工作流初始化

## 概述

读取当前项目的真实文件、文档、配置和已有规则，生成一份项目级 Claude Code 工作流建议。

**核心原则：** 只把会改变未来行动的内容写入项目配置。普通项目概况、单点观察、没有使用场景的长文，不生成。

setup 是显式初始化工具，不是日常开发流程。普通任务仍回到 `using`，再按请求进入 `think`、`plan`、`execute`、`debug`、`verify` 等技能。

## 支持的产物

只生成 Claude Code 原生识别的路径：

| 路径 | 用途 |
|---|---|
| `CLAUDE.md` / `.claude/CLAUDE.md` | 项目入口说明、稳定全局指令 |
| `.claude/rules/*.md` | 短、稳定、持续生效的规则 |
| `.claude/skills/<name>/SKILL.md` | 按需加载的项目任务能力 |
| `.claude/skills/<name>/references/*.md` | 只由对应 skill 主动读取的长参考 |

不要生成 `.claude/references/`。reference 必须归属某个 skill。

## 流程

1. **确认目标项目** —— 确认当前目录就是要初始化的项目。
2. **读取本技能参考** —— 先读下面“参考加载”列出的文件，再开始判断。
3. **只读扫描** —— 查看顶层目录、源码、docs、tests、CI、脚本、配置、已有 `CLAUDE.md` / `.claude/rules`。
4. **提取模式** —— 记录真实命令、验证方式、编码习惯、目录约定、重复任务流程和高风险边界。
5. **生成建议** —— 分成 rules、skills、references 三类；说明每项为什么值得生成。
6. **等待确认** —— 未经用户确认，不写入 `.claude/` 或 `CLAUDE.md`。
7. **写入并检查** —— 写入后确认 skill 有 `SKILL.md`、`name`、`description`，reference 被对应 skill 引用。

## 参考加载

这些 reference 是 setup 自己的判断依据，不是要复制到目标项目。

- 开始扫描前读 `references/workflow.md` 和 `references/coverage.md`，确定整体流程与覆盖面。
- 需要生成或刷新 rules 时，读 `references/rules.md`。
- 需要生成或刷新项目 skills 时，读 `references/skills.md`。
- 需要提取项目习惯、业务域或长参考时，读 `references/habits.md`、`references/domains.md`。
- 需要深扫配置、框架、样式、领域或既有规则时，读 `references/agents.md`，并按其中要求实际使用 `Agent`。

## 生成规则

生成 rule，当它是短规则、稳定、高频、全局或路径相关。

生成 skill，当它有明确任务触发、固定读取顺序、项目特有操作步骤或验证方式。

生成 reference，当内容太长，不适合放在 rule 或 SKILL.md 内容里，并且有明确读取它的 skill。

不生成：
- 只有一次观察；
- 没有未来触发场景；
- 只是“项目里有什么”的概况；
- 没有证据支持的推测；
- 与用户现有规则冲突的内容。

## 输出格式

```text
项目类型：...

已分析内容：
- ...

建议生成 rules：
| 路径 | 作用 | 内容概要 |
|---|---|---|

建议生成 skills：
| 路径 | 触发场景 | 内容概要 |
|---|---|---|

建议生成 references：
| 路径 | 保存内容 | 读取入口 |
|---|---|---|

需要确认：
- 是否写入
- 已存在文件如何处理
```

## 红旗

| 念头 | 现实 |
|---|---|
| "多生成一点以后总会用到" | 无触发条件就是噪音。 |
| "把扫描报告放进 reference" | reference 必须被某个 skill 读取。 |
| "直接覆盖旧规则" | 先读旧内容，说明保留、追加或替换策略。 |
| "只看 README 就够了" | setup 必须读真实配置和代表文件。 |
