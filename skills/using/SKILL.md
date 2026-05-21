---
name: using
description: "会话启动时使用：说明如何查找、调用和遵守本项目 skills；由 SessionStart hook 注入，不参与具体任务路由"
disable-model-invocation: true
user-invocable: false
---

<SUBAGENT-STOP>
如果你是作为子代理被派遣去执行某个具体任务，请跳过此 skill。
</SUBAGENT-STOP>

# 使用 claude-workflow skills

<EXTREMELY-IMPORTANT>
如果你认为某个 skill 哪怕只有 1% 的可能性适用于当前任务，必须先调用该 skill。
skill 适用时不是建议，而是执行规则。
</EXTREMELY-IMPORTANT>

## 指令优先级

1. **用户显式指令**（AGENTS.md、CLAUDE.md、直接请求）优先级最高。
2. **claude-workflow skills** 覆盖默认模型习惯。
3. **默认系统提示** 优先级最低。

如果用户明确要求跳过某个流程，以用户指令为准；但要简短说明风险。

## 如何调用

- 在 Claude Code 中使用 `Skill` 工具加载对应 skill。
- 调用后按 skill 原文执行，不凭记忆执行。
- 不要用普通文件读取代替 `Skill` 工具。

## 基本流程

收到用户消息后：

1. 判断是否有相关 skill。
2. 如果有，先调用 `Skill` 工具。
3. 公开说明：`正在使用 <skill> 来 <目的>`。
4. 如果 skill 有清单，用 TodoWrite 建任务。
5. 严格按 skill 执行。

## 边界

- `using` 只说明如何使用 skill，不判断具体任务该走哪个 skill。
- 具体路由由相关 skill 自己决定，常见入口是 `think` 或 `debug`。
- 子代理只执行被派遣的具体任务，不递归加载完整主流程。

## 警示信号

| 念头 | 现实 |
|---|---|
| "先看一眼文件再说" | 先判断是否有 skill。 |
| "我记得这个 skill" | skill 会变，必须加载当前版本。 |
| "这只是个小回复" | 回复也是任务，仍要检查是否有 skill。 |
| "用了 skill 不必说" | 必须公开说明正在使用哪个 skill。 |
| "清单我记得住" | 有清单就用 TodoWrite。 |

## 用户指令

用户指令定义要做什么；skill 定义怎么做。两者冲突时，遵循用户指令，并说明被跳过的流程风险。
