---
name: plan
description: 当 think 判断为复杂任务时使用——编写设计 + 实现方案，保存到文件，用于跨会话追踪和子代理执行
---

# 编写设计与实现方案

<HARD-GATE>
一旦加载 plan，就必须先写完方案并获得用户确认，再进入任何实现动作。

给出方案后必须等待用户明确批准执行，除非用户在同一句里已经明确说"直接实现/按计划执行/继续写代码"。
</HARD-GATE>

编写包含设计和实现步骤的完整方案。假设做事的人对代码库零上下文——把他们需要知道的一切写清楚。

**方案保存至：** `docs/plans/YYYY-MM-DD-<feature-name>.md`（用户偏好会覆盖此默认值）

## 何时使用

仅当 think 判断为复杂任务时：
- 多个子任务、跨子系统
- 可能跨会话、需要进度追踪
- 需要拆成小任务分别完成、或别人接手

简单/中等任务不走 plan，由 think 确认后直接实现。

## 流程

### 范围检查

如果需求涵盖多个独立子系统，建议拆成独立方案——每个子系统一个。每个方案应能独立得到可运行、可测试的软件。

### 设计部分

在写任务之前，先回答"做什么"和"为什么这么做"：

- **目标** — 一句话说清要构建什么
- **架构** — 组件、数据流、关键技术选型
- **方案取舍** — 为什么选这个方案、放弃了什么（2-3 句话够了，不要写论文）
- **文件结构** — 梳理要创建或修改的文件和每个文件的职责

设计原则：
- 每个文件一个明确职责，通过定义良好的接口通信
- 一起变化的文件放在一起，按职责拆分而不是按技术分层
- 在已有代码库中遵循既有模式
- YAGNI——只设计需要的东西

### 任务拆解

基于文件结构把实现拆成一个个可以独立完成的任务。

步骤按自然顺序排列，靠位置表达依赖——上一步完成才做下一步。

### 方案文件格式

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Use claude-workflow:subagent (recommended) or claude-workflow:execute to implement this plan. Steps use checkbox syntax for tracking. **Executors must write back `[x]` to this file as steps complete — this file is the single source of truth for progress.**

## 设计

**Goal:** [One sentence]

**Architecture:** [Components, data flow, key decisions]

**Tech Stack:** [Key technologies/libraries]

**Tradeoffs:** [Why this approach, what was rejected]

**Files:**
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing`
- Test: `tests/exact/path/to/test`

---

## 任务

### Task 1: [Component Name]

**Files:**
- `exact/path/to/file`
- `tests/path/to/test`

- [ ] 先写测试（此时应该不通过）

  [code block with actual test code]

  Run: `test command` — expected FAIL

- [ ] 再写最少的代码让测试通过

  [code block with actual implementation]

  Run: `test command` — expected PASS

- [ ] 最后整理代码

  Run: `test command` — all PASS, no regressions

### Task 2: [Next Component]
...
```

### 自己检查一遍

写完方案后回看一遍：

1. **需求覆盖：** 每条需求都能指向一个任务吗？列出缺口。
2. **占位符扫描：** "TBD"、"TODO"、"implement later"、"add validation"、没有代码块的代码步骤——都是方案失败。修掉。
3. **一致性：** 后面任务用到的名称是否与前面任务定义的一致？

发现问题就地修复，修完就走。

### 方案写好后怎么执行

**"方案已保存到 `docs/plans/<filename>.md`。两种执行方式：**

**1. 拆成小任务分别完成（推荐）** — 每个任务单独完成，任务之间检查一下

**2. 在当前会话逐步做** — 在当前会话一步步执行

**选哪种？"**

**若选择拆成小任务分别完成：** 使用 claude-workflow:subagent

**若选择在当前会话逐步做：** 使用 claude-workflow:execute

**完成后把进度记到文件里：**
- 完成一步后，把 `- [ ]` 改为 `- [x]` 写回方案文件
- 失败时在步骤下追加 `  - ❌ failed: <错误信息>`
- 进度以方案文件为准，任务列表只是当前会话的辅助，文件里的记录才算数

<constraints>
不允许占位符——每一步都必须包含做事的人实际需要的内容。以下都是方案失败：
- "TBD"、"TODO"、"implement later"、"fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above"（没有实际测试代码）
- "Similar to Task N"（重复写出代码——做的人可能不按顺序读取任务）
- 描述了做什么却不展示怎么做的步骤（代码步骤必须有代码块）

其他禁止行为：
- 禁止在方案中默认写 `git commit`、push 或 PR 步骤（只有用户明确要求时才加入）
- 禁止用"通常不会发生"跳过资源释放/清理策略
</constraints>

## 警示信号

| 念头 | 现实 |
|---|---|
| "设计已确认，直接实现" | plan 批准不是执行批准，等用户确认 |
| "先写代码，再补方案" | 先计划，后执行 |
| "通常不会销毁，不用清理" | 写清释放/清理策略 |
| "这步差不多就行" | 每步必须有完整代码和验证命令 |

## 和其他技能的关系

- **claude-workflow:think** —— think 判断为复杂任务后调用本技能
- **claude-workflow:subagent**（推荐）—— 拆成小任务分别完成
- **claude-workflow:execute** —— 在当前会话逐步执行方案
- **claude-workflow:worktree** —— 开始执行前确保隔离工作区

## 记住

- 始终给出确切文件路径
- 每一步都包含完整代码——如果该步骤变更代码，就把代码写出来
- 给出确切命令与预期输出
- DRY、YAGNI、先写测试再写代码、每步都有明确的验证方式
- 如果本次触碰会持续占用资源、注册外部回调、打开连接或启动后台工作，释放/清理策略属于本次改动范围

## 沟通规范
- 用户看不到工具调用和思考过程，只看到你的文字输出
- 回复中不要出现本文件里的流程术语（不说"门控"、"检查点"、"子代理"、"回写"）
- 用日常口语描述你在做什么："我先看看代码" / "写好了，测试通过" / "有个问题需要你确认"
- 匹配用户的说话风格——用户简短你就简短，用户详细你就详细
