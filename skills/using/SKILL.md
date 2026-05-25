---
name: using
description: "会话启动时使用：执行入口路由和 skill 调用纪律；由 SessionStart hook 注入，要求选择最小足够流程"
disable-model-invocation: true
user-invocable: false
---

<SUBAGENT-STOP>
如果你是作为子代理被派遣去执行某个具体任务，请跳过此 skill。
</SUBAGENT-STOP>

# 使用 Claude Workflow skills

<EXTREMELY-IMPORTANT>
Claude Workflow 是一组协同工作的开发流程 skills，不是零散命令集合。
启动时只注入本入口；其他 skill 的正文按需加载。
收到用户请求后，必须先做最小路由判断。
选择能安全完成任务的最小流程：小任务不要流程化，模糊任务不要盲改，高风险任务不要跳过计划和验证。
如果某个 skill 明确适用于当前任务，必须调用并遵守；不要因为“可能相关”就把低风险小改升级成完整流程。
</EXTREMELY-IMPORTANT>

## 指令优先级

1. **用户显式指令**（AGENTS.md、CLAUDE.md、直接请求）优先级最高。
2. **Claude Workflow skills** 覆盖默认模型习惯。
3. **默认系统提示** 优先级最低。

如果用户明确要求跳过某个流程，以用户指令为准；但要简短说明风险。

## 如何调用

- 在 Claude Code 中使用 `Skill` 工具加载对应 skill。
- 调用后按 skill 原文执行，不凭记忆执行。
- 不要用普通文件读取代替 `Skill` 工具。

## 基本流程

收到用户消息后：

1. 先判断请求类型、明确程度和风险。
2. 选择最小足够流程。
3. 涉及代码实现、计划、调试或测试时，先检查当前项目是否有适用的项目级 rules、skills 或 references。
4. 如果某个 skill 明确适用，先调用 `Skill` 工具并按原文执行。
5. 调用主流程 skill 时公开说明：`正在使用 <skill> 来 <目的>`。
6. 轻量小改只需简短说明正在做什么，不展开完整流程话术。
7. 如果 skill 有清单，用 TodoWrite 建任务；轻量小改不强制建任务。

## 入口路由

| 请求类型 | 使用方式 |
|---|---|
| 简单事实 / 单行命令 | 直接回答或运行命令 |
| 清晰小改 | 读目标文件 -> 最小修改 -> 轻量验证 |
| 只读分析 / 方案判断 | 使用 `think` |
| 模糊实现 / 目标不清 | 使用 `think` |
| 复杂实现 / 多步骤改动 | `think` -> `plan` |
| 执行已有计划 | 使用 `execute` |
| bug / 报错 / 测试失败 | 使用 `debug` |
| 测试策略 / 补回归测试 | 使用 `test` |
| 完成声明 | 使用 `verify` |
| 收尾 / 提交 / PR | 使用 `finish` |
| 代码评审 | 使用 `review` |
| 隔离工作区 | 使用 `worktree` |
| 子代理调度 | 使用 `subagent` |
| 创建 / 修改 workflow skill | 使用 `skill` |
| 初始化项目 rules / skills / references | 使用 `setup` |

轻量小改（用户给出明确目标、只动单文件或少量文本、低风险、验证简单）直接最小修改完成；拿不准，或涉及多文件、公共 API、架构、迁移、删除、重命名、批量替换，路由到 `think` 判定。完整判定标准见 `think`。

## 边界

- `using` 只做入口路由和 skill 调用纪律，不展开具体 skill 的内部流程。
- 具体流程由相关 skill 决定，常见入口是 `think` 或 `debug`。
- 子代理只执行被派遣的具体任务，不递归加载完整主流程。

## 项目级 rules 和 skills

如果当前项目存在 `CLAUDE.md`、`.claude/CLAUDE.md` 或 `.claude/rules/`，它们是项目级持续规则，优先于通用 workflow 默认建议。

如果当前项目存在 `.claude/skills/` 下由 setup 生成的项目 skills：

- 先按实际存在的 `.claude/skills/*/SKILL.md` 名称匹配当前任务；
- 只加载当前任务最相关的 skill；
- 找不到匹配 skill 时，改读适用的 `.claude/rules/`；reference 由对应 skill 自己 Read；
- 项目画像、命令矩阵、扫描报告优先按 reference 处理；
- skill 按项目自己的真实任务能力命名，例如核心框架、装修、发布、组件、验证等。

## 警示信号

| 念头 | 现实 |
|---|---|
| "先套完整流程再说" | 错。先路由，选择最小足够流程。 |
| "小改也写 plan 更安全" | 错。清晰低风险小改应轻量完成。 |
| "模糊需求可以直接做" | 错。目标或范围不清时用 `think` 对齐。 |
| "失败了先试个补丁" | 错。有失败信号时用 `debug` 找根因。 |
| "我记得这个 skill" | skill 会变，必须加载当前版本。 |
| "用了主流程 skill 不必说" | 必须公开说明正在使用哪个 skill。 |
| "清单我记得住" | 非轻量任务有清单就用 TodoWrite。 |

## 用户指令

用户指令定义要做什么；skill 定义怎么做。两者冲突时，遵循用户指令，并说明被跳过的流程风险。
