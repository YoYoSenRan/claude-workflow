---
name: review
description: 在完成任务、实现重要功能或合并前用于验证工作是否满足需求
---

# 申请代码评审

派发一个代码评审员子代理，在问题级联放大之前抓住它们。评审员获取的是为评估精心构造的上下文——绝不是你会话的历史。这让评审员聚焦于工作产物本身，而不是你的思考过程，也保留了你自己的上下文以便继续工作。

**核心原则：** 早评审、多评审。

如果用户给的是已经收到的代码评审反馈，而不是要求你发起评审，先阅读 `references/receiving-feedback.md`。

## 何时使用

**强制：**
- 子代理驱动开发中每个任务之后
- 完成重要功能之后
- 合并到 main 之前

**可选但有价值：**
- 卡住时（新视角）
- 重构之前（基线检查）
- 修复复杂 bug 之后

## 流程

### 1. 获取 git SHA

```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

### 2. 派发代码评审员子代理

使用 Claude Code 的 `Agent` 工具，填写 `code-reviewer.md` 中的模板。

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

## 集成

**与工作流集成：**
- **子代理驱动开发：** 每个任务后评审，在问题叠加前抓住它们
- **执行方案：** 在每个任务后或自然检查点处评审
- **临时开发：** 合并前评审，卡住时评审

**模板：** `review/code-reviewer.md`
