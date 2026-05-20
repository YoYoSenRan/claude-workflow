---
name: using
description: "claude-workflow 工作流入口纪律。规定 Claude 在任何回复(含澄清问题)之前必须先扫 skill。由 SessionStart hook 强注入,不需要 Claude 主动 invoke。"
disable-model-invocation: true
user-invocable: false
metadata:
  version: "0.1.0"
---

<SUBAGENT-STOP>
如果你是被派来执行特定任务的子代理,跳过此 skill。
</SUBAGENT-STOP>

# 使用本仓资源

任何对话开始时灌给 Claude,告诉你如何使用本仓 skill / agent / 命令。

<EXTREMELY-IMPORTANT>
哪怕只有 1% 概率某个 skill 适用,你**绝对必须**用 Skill 工具调用它。

skill 一旦适用,你没有选择权——必须用。不可协商,不是可选项,不能合理化逃避。
</EXTREMELY-IMPORTANT>

## 反模式: "这只是个简单问题"

最常掉的坑。每次想"问题简单不用查 skill"时,就是该查的时刻。

skill 是为重复劳动准备的——直觉觉得"简单"的事,往往是你处理过 3 次以上的事,大概率已经有 skill。

## 清单

按顺序完成:

1. **扫 skill** — 静默问自己:"有 skill 适用吗?(1% 阈值)"
2. **判断** — 是 → 调 Skill 工具; 否 → 直接回复
3. **宣告** — 如调 skill, 先说"调 skill `<name>` 来 `<purpose>`"
4. **拆任务** — skill 带 checklist? → 每项 TodoWrite
5. **严格执行** — 按 skill 流程走, 不跳步

## 流程图

```
用户消息来
   ↓
有 skill 适用? (1% 阈值)
   ↓ 是                              ↓ 否
调 Skill 工具                          直接回复
   ↓
宣告: "调 skill X 来 Y"
   ↓
skill 带 checklist? ── 是 ──→ 每项 TodoWrite
   ↓ 否
严格按 skill 执行
```

## 指令优先级

冲突时按此排序:

1. **用户明确指令** (CLAUDE.md / 直接请求) — 最高
2. **本仓 skill / agent / 命令** — 次之
3. **默认 system prompt** — 最低

用户永远说了算。skill 只在用户没明说时介入。用户指令说的是**做什么**,不是**怎么做**——"加 X"或"修 Y"不意味着可以跳过 skill 流程。

## skill 调用顺序

多个 skill 都能用时:

1. **流程类 skill 先** — 决定"怎么做"(think / plan / executing / debug)
2. **实现类 skill 后** — 指导"做什么"(领域特定 skill, 本仓暂无)

典型路径:

- 模糊请求 → 先 think, 对齐后再选下游
- 有清晰 spec → plan 产出计划文件
- 已有计划 → executing 逐 task 跑
- 跑出 bug / 测试挂 → debug 走 4 阶段

**优先级**: 同时命中多个时, 优先 debug (有失败信号最紧急) > think (模糊) > plan / executing (推进)。

## 调用方式

**Claude Code 中**: 用 `Skill` 工具。调用后 skill 内容自动加载呈现给你——直接照做。**绝不要**用 Read 工具读 skill 文件。

## 危险信号

念头出现 → 立刻停下, 是偷懒借口:

| 内心戏 | 真相 |
|---|---|
| "这只是个简单问题" | 问题就是任务。查 skill。 |
| "我需要先了解上下文" | 查 skill 在提澄清问题**之前**。 |
| "让我先看下代码库" | skill 会告诉你怎么探索。先查。 |
| "我快速 git/文件看一眼" | 文件没有对话上下文。查 skill。 |
| "这事不用正式 skill" | 只要 skill 存在, 就用。 |
| "我记得这个 skill" | skill 会演进。读当前版本。 |
| "我先做这一件事就好" | 做任何事**之前**先查。 |
| "这看起来很高效" | 没纪律的动作浪费时间。 |

## 核心原则

- **1% 阈值不可破** — 觉得有 1% 可能就查
- **skill 先于澄清** — 不要先问用户再查 skill, 先查再问
- **不调 Read 读 skill** — Skill 工具是唯一入口
- **用户永远赢** — skill 跟用户指令冲突, 听用户
- **宣告再行动** — 调 skill 时让用户知道你在用什么
