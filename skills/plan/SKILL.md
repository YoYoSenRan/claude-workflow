---
name: plan
description: 当你已有一份规格说明或多步任务的需求时，在动手写代码之前使用
---

# 编写方案

## 概述

编写全面的实现方案，假设工程师对我们的代码库零上下文且品味存疑。把他们需要知道的一切都写清楚：每个任务要改哪些文件、代码、测试、他们可能要看的文档、如何测试。把整个方案拆成口大小的任务给他们。DRY、YAGNI、TDD、清晰检查点。

假设他们是熟练的开发者，但对我们的工具链或问题领域几乎一无所知。假设他们对良好的测试设计也不太熟悉。

<HARD-GATE>
一旦加载 plan，就必须先产出计划，再进入任何写文件、跑实现命令或修改代码的动作。

"单文件"、"纯 UI"、"不值得写 docs/plans" 只能决定计划形式更轻，不能成为跳过 plan 的理由。

用户只确认了 think 的设计方向，不等于批准你执行实现。plan 产出后必须等待用户明确批准执行，除非用户在同一句里已经明确说"直接实现/按计划执行/继续写代码"。
</HARD-GATE>

**上下文：** 如果在隔离的工作树中工作，该工作树应已在执行时通过 `claude-workflow:worktree` 技能创建。

**方案保存至：** `docs/plans/YYYY-MM-DD-<feature-name>.md`
- （用户对方案位置的偏好会覆盖此默认值）

## 计划形式

根据任务规模选择计划形式，但都必须先计划后执行。

**轻量内联计划**适用于同时满足：
- 只改 1 个文件或少量样式/文案；
- 不改公共 API、数据结构、权限、路由、构建配置；
- 验证命令明确；
- 用户没有要求可交接文档。

轻量内联计划不落盘，直接在回复中给出：

```text
轻量实现计划：
1. 文件：`path/to/file`
2. 改动：
   - ...
3. 验证：
   - `command`，预期 ...
4. 风险：
   - ...

确认后我再执行。
```

**文档计划**适用于任一情况：
- 跨多个文件或模块；
- 有任务依赖、多人交接或后续恢复需求；
- 涉及公共 API、数据结构、迁移、权限、部署；
- 用户要求写计划文档。

文档计划保存到 `docs/plans/YYYY-MM-DD-<feature-name>.md`。

## 范围检查

如果规格涵盖多个独立子系统，本应在头脑风暴阶段拆分成子项目规格。如果没有拆，建议将其拆成独立方案——每个子系统一个方案。每个方案都应能独立产出可运行、可测试的软件。

## 文件结构

在定义任务之前，先梳理将要创建或修改的文件以及每个文件的职责。这是拆解决策被锁定的环节。

- 设计具有清晰边界和良好定义接口的单元。每个文件应承担一个明确职责。
- 你对能一次容纳在上下文里的代码推理最佳，且当文件聚焦时你的编辑更可靠。优先采用更小、聚焦的文件，而不是承担过多的大文件。
- 一起变化的文件应放在一起。按职责拆分，而不是按技术分层。
- 在已有代码库中遵循既有模式。若代码库使用大文件，不要单方面重组——但如果你正在修改的文件已经变得难以维护，把拆分纳入方案是合理的。

这种结构指导任务拆解。每个任务都应产出自包含、独立可理解的变更。

## 口大小的任务粒度

**每一步是一个动作（2-5 分钟）：**
- "写失败的测试" - 一步
- "运行确认它失败" - 一步
- "实现使测试通过的最小代码" - 一步
- "运行测试确认通过" - 一步
- "更新任务状态并汇报验证结果" - 一步

## 方案文档头

**每个方案必须以此头开始：**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use claude-workflow:subagent (recommended) or claude-workflow:execute to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## 任务结构

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Update task status**

Report files changed, tests run, and whether the task is ready for review.
````

## 不允许占位符

每一步都必须包含工程师实际需要的内容。以下都是**方案失败**——永远不要这样写：
- "TBD"、"TODO"、"implement later"、"fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above"（没有实际测试代码）
- "Similar to Task N"（重复写出代码——工程师可能不按顺序读取任务）
- 描述了做什么却不展示怎么做的步骤（代码步骤必须有代码块）
- 引用了任何任务中均未定义的类型、函数或方法

## 记住
- 始终给出确切文件路径
- 每一步都包含完整代码——如果该步骤变更代码，就把代码写出来
- 给出确切命令与预期输出
- DRY、YAGNI、TDD、清晰检查点
- 不要在方案中默认写 `git commit`、push 或 PR 步骤；只有用户明确要求提交时才加入。
- 如果本次触碰会持续占用资源、注册外部回调、打开连接、持有句柄或启动后台工作的逻辑，释放/清理策略属于本次改动范围；不要用"通常不会发生"或"保持改动最小"当作跳过理由。

## 自评审

在写完整个方案后，以新的眼光看一遍规格并核对方案。这是你自己跑的清单——不是派发子代理。

**1. 规格覆盖：** 浏览规格中的每一节/每一项需求。你能指出哪个任务实现了它吗？列出所有缺口。

**2. 占位符扫描：** 在你的方案中搜索警示信号——上文"不允许占位符"一节里的任何模式。修复它们。

**3. 类型一致性：** 你在后面任务里用到的类型、方法签名和属性名是否与你在前面任务里定义的一致？Task 3 里叫 `clearLayers()` 而 Task 7 里叫 `clearFullLayers()` 是 bug。

如果你发现问题，就地修复。无需重新评审——修了就走。如果发现某条规格需求没有对应任务，加上该任务。

## 执行交接

保存方案后，提供执行选择：

如果是轻量内联计划：

```text
轻量计划已给出。确认后我再执行。
```

等待用户确认。不要在同一条回复里直接写文件。

如果是文档计划：

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using execute, batch execution with checkpoints

**Which approach?"**

**若选择子代理驱动：**
- **必需的子技能：** 使用 claude-workflow:subagent
- 每个任务派发新子代理 + 两阶段评审

**若选择内联执行：**
- **必需的子技能：** 使用 claude-workflow:execute
- 带评审检查点的批量执行

## 常见违规

| 说法 | 问题 | 正确做法 |
|---|---|---|
| "这是单文件，不写 plan 文档，直接落地" | 把轻量计划误解成跳过计划 | 给轻量内联计划，等确认 |
| "设计已确认，所以我直接实现" | think 批准不是执行批准 | plan 后等执行确认 |
| "我加载了 plan，但按项目习惯跳过" | 二次解释 skill | 改用轻量内联计划 |
| "先写代码，再补说明" | 顺序倒置 | 先计划，后执行 |
| "通常不会销毁，不用清理" | 用假设保留资源问题 | 写清释放/清理策略 |
