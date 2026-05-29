---
name: plan
description: 为复杂任务编写设计与分步实现方案，包含场景定义、文件结构、任务进度和验证步骤
---

# 编写设计与实现方案

<HARD-GATE>
写完方案并获得用户确认前，不得实现。
</HARD-GATE>

## 触发

think 判断为复杂任务：跨子系统、多任务、需要追踪进度，或需要拆给别人执行。简单/中等任务不走 plan。

## 输出位置

默认保存到 `docs/plans/YYYY-MM-DD-<feature-name>/`，用户指定路径时按用户要求。

```
docs/plans/YYYY-MM-DD-<feature-name>/
├── README.md           # 索引：目标、设计、任务清单（标题+状态）
└── tasks/
    ├── 01-<task-name>.md   # 单个任务的完整 spec
    ├── 02-<task-name>.md
    └── ...
```

## 执行

1. 检查范围；多个独立子系统建议拆成多个方案。
2. 列出能力变更。
3. 写设计：架构、关键决策、文件结构。
4. 拆任务；每个任务能独立执行、验证、审查。
5. 给每个任务写场景、步骤、验证方式。
6. 自检占位符、能力覆盖、场景覆盖、一致性。
7. 保存方案后，让用户选择执行方式。

## README.md 模板

````markdown
# [Feature Name]

> **For agentic workers:** Use claude-workflow:subagent (recommended) or claude-workflow:execute to implement this plan. **README.md is the single source of truth for progress.** Task specs are in `tasks/` directory.

## 概览

**目标：** [一句话]

## 能力变更

| 能力 | 类型 | 说明 |
|---|---|---|
| [能力名] | 新增/修改/删除 | 一句话说明行为变化 |

## 设计

**架构：** [组件、数据流]

**决策：**
- [决策点]: [选择] — [理由和取舍]

**文件：**
- 新建: `exact/path/to/file`
- 修改: `exact/path/to/existing`
- 测试: `tests/exact/path/to/test`

## 任务

| # | 任务 | 能力 | 确定性 | 状态 |
|---|---|---|---|---|
| 1 | [任务标题] | [能力名] | 高/中/低 | ⬚ |
| 2 | [任务标题] | [能力名] | 高/中/低 | ⬚ |

状态标记：⬚ 待做 · ▶ 进行中 · ✅ 完成 · ⚠️ 需要判断 · ❌ 阻塞 · ⏭ 跳过
````

确定性：
- **高** — 改什么一目了然，无歧义（Markdown、配置、单文件明确改动）
- **中** — 多文件代码、有逻辑判断
- **低** — 架构、跨系统、新设计

## Task 模板

````markdown
# Task N: [任务标题]

**文件：**
- `exact/path/to/file`
- `tests/path/to/test`

**场景：**
- 当 [前置条件/操作] 则 [预期行为/结果]
- 当 [边界条件] 则 [预期行为]
- 当 [异常输入] 则 [错误处理]

**验证策略：**
- 行为逻辑改动：优先先写会失败的测试，再实现到通过
- 文档、配置、workflow、迁移：写清可执行校验或人工核对项
- UI：包含构建/类型检查，以及必要的页面或截图检查

**步骤：**

- [ ] 先建立验证证据

  行为逻辑任务写具体测试代码；非代码任务写具体校验命令或人工检查项。

  Run: `验证命令` — expected: [预期失败/预期输出/人工检查标准]

- [ ] 再写最少的实现或文档变更

  [code block with actual implementation]

  Run: `验证命令` — expected PASS / expected: [预期输出]

- [ ] 最后整理代码

  Run: `test command` — all PASS, no regressions
````

场景数量控制在 3-7 个，覆盖正常路径、关键边界、错误路径。

## 非代码任务模板

````markdown
# Task N: [配置/迁移/文档任务名]

**文件：**
- `exact/path/to/file`

**场景：**
- 当 [执行变更后] 则 [可观测的预期状态]
- 当 [验证命令] 则 [预期输出]

**步骤：**

- [ ] 执行变更

  [具体的文件内容或命令]

- [ ] 验证变更生效

  Run: `验证命令` — expected: [预期输出]

  无法用命令验证时，写明人工检查项：
  > 人工确认：[具体检查什么、怎么检查]
````

## 自检

保存前逐项检查：

1. 能力变更表每项都有任务。
2. 每个任务都能追溯到能力。
3. 每个任务都有场景、文件、步骤、验证方式。
4. 没有 TBD、TODO、implement later、add validation、handle edge cases。
5. 后续任务使用的名称和前面定义一致。

## 输出

方案写完后只输出：

```text
方案已保存到 `docs/plans/<name>/`。

执行方式：
1. 拆成小任务分别完成
2. 在当前会话逐步做

选哪种？
```

## 禁止

- 禁止占位符。
- 禁止只有“写测试/加校验”但没有具体内容。
- 禁止用“Similar to Task N”替代完整步骤。
- 禁止在方案中默认写 `git commit`、push 或 PR 步骤（只有用户明确要求时才加入）
- 禁止用"通常不会发生"跳过资源释放/清理策略
