---
name: review
description: 在完成任务、实现重要功能或合并前用于验证工作是否满足需求
---

# 申请代码评审

让另一个代理来帮你检查代码，趁问题还小的时候发现它们。评审员拿到的是专门为检查准备的信息——不是你的对话记录。这样评审员只看产出，不受你思路干扰，你自己也不会丢失上下文。

**核心原则：** 早评审、多评审。

如果用户给的是已经收到的代码评审反馈，而不是要求你发起评审，先阅读 `references/receiving-feedback.md`。

## 何时使用

**建议使用：**
- 中等任务实现完成后、verify 之前
- execute 执行完所有任务后、finish 之前
- 合并到 main 之前

**可选但有价值：**
- 卡住时（换个视角看问题）
- 重构之前（先确认当前状态）
- 修复复杂 bug 之后

**不需要使用：**
- subagent 流程（已内置两轮检查，不需要再调 review）
- 简单任务（verify 够了）

## 流程

### 1. 获取 git SHA

```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

### 2. 启动代码评审员

使用 Claude Code 的 `Agent` 工具，填写 `references/code-reviewer.md` 中的模板。

**占位符：**
- `{DESCRIPTION}` - 简要总结你构建了什么
- `{PLAN_OR_REQUIREMENTS}` - 它应当做什么
- `{BASE_SHA}` - 起始提交
- `{HEAD_SHA}` - 结束提交

### 3. 根据反馈行动

- 立即修复关键问题
- 在继续之前修复重要问题
- 把次要问题记下来留到以后
- 评审员错了就回推（带理由）

### 示例

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

<constraints>
- 禁止因为"简单"而跳过评审
- 禁止忽视关键问题
- 禁止带着未修复的重要问题继续
- 禁止与有效的技术反馈争辩（应该用技术推理回推）
- 禁止在 review 过程中直接修改代码（评审员只读）
</constraints>

## 警示信号

| 念头 | 现实 |
|------|------|
| "这次改动太小，不用评审" | 小改动也会有 bug |
| "评审员不懂我的设计" | 用技术推理回推，不要忽视 |
| "重要问题以后再修" | 在继续之前修复 |

## 在流程中的位置

```
实现完成 → review（检查质量）→ verify（跑验证）→ finish（交付）
```

review 在 verify 之前、finish 之前。verify 验证"能不能跑"，review 验证"写得好不好"。

**触发方式：**
- execute 完成所有任务后，显式调用 review 再进 finish
- 中等任务直接实现后，think 在路径中建议走 review
- 用户主动要求"帮我看看代码"

**模板：** `references/code-reviewer.md`

## 沟通规范
- 用户看不到工具调用和思考过程，只看到你的文字输出
- 回复中不要出现本文件里的流程术语
- 用日常口语描述你在做什么："我先看看代码" / "写好了，测试通过" / "有个问题需要你确认"
- 匹配用户的说话风格——用户简短你就简短，用户详细你就详细
