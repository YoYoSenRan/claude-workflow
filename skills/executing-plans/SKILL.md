---
name: executing-plans
description: "已有 writing-plans 产出的计划文件时使用。Load → critical review → TodoWrite checkpoint → 逐任务执行 → 遇 blocker 就停不猜。不适用于: 无计划直接改、临时改动 <5min、跟 subagent-driven-development 平行使用 (二选一)。"
when_to_use: "执行计划, 开始实现, 按计划做, 跑计划, 实施 plan, execute plan, run plan, implement from plan"
metadata:
  version: "0.1.0"
---

# 执行实现计划

加载 `writing-plans` 产出的 plan 文件, 评审 → TodoWrite → 逐任务执行 → blockers 就停。

<HARD-GATE>
遇到 blocker (测试失败 / 依赖缺失 / 指令不清 / 实现跟 plan 不符) → **停**, 报告用户。

禁止: 跳 step / 自己改 plan / 猜测意图 / "差不多就行"。

plan 是契约, 不是建议。
</HARD-GATE>

## 反模式: "我看一眼 plan 就开干"

最常掉的坑。直接跳到 Task 1 = 漏掉 critical review = 带 bug 上路。

plan 写错的概率 > 0。先 review 再 commit checkbox。

## 清单

按顺序完成:

1. **Load** — 读 plan 全文 (Read 工具, 一次性)
2. **Critical Review** — 找 blockers (歧义 / 缺依赖 / 顺序倒挂)
3. **TodoWrite 建** — 每 task = 一项
4. **逐任务执行**:
   - mark in_progress
   - 按 step 走, 验证 expected
   - mark completed
5. **遇 blocker 停** — 不猜不试, 报告用户
6. **完工** — 全部 done → 提示后续 (finishing)

## 流程图

```
Load plan
   ↓
Critical Review ── 有 blocker ──→ 报告用户, 暂停
   ↓ 通过
TodoWrite 建项
   ↓
取下一 task
   ↓
mark in_progress
   ↓
按 step 执行 + 验证
   ↓
通过? ── 否 ──→ blocker? ── 是 → 停, 问
   ↓ 是                     └ 否 → 修, retry (最多 1 轮)
mark completed
   ↓
还有 task? ── 是 ──→ 取下一
   ↓ 否
提示后续 (finishing)
```

## Critical Review

加载 plan 后, 动手前, 静默问自己:

- [ ] task 顺序无依赖倒挂?
- [ ] 文件路径都存在? (Create 例外)
- [ ] 命令能跑? (依赖装了吗?)
- [ ] step 之间无遗漏?
- [ ] 我能理解每 step 干啥?

任一答"否" → blocker, 报告用户, 不动手。

## Blocker 类型 + 处理

| Blocker | 处理 |
|---|---|
| 测试失败超 1 轮 retry | 停, 报告: "Task N Step M 测试持续失败, 输出: ..." |
| 文件 / 命令未找到 | 停, 报告: "Task N 假设 X 存在, 实际不存在" |
| step 含糊不能落地 | 停, 报告: "Task N Step M 含糊, 候选解读: A / B" |
| 实现跟 spec 不符 | 停, 报告: "Task N 实现 X, 但 plan 写的是 Y" |
| 修改超出 plan 范围 | 停, 报告: "Task N 需改 file Z, 但 plan 没列" |

**不要做的**:

- ✗ 跳过失败 step 继续下一 task
- ✗ 自己改 plan
- ✗ 猜测用户意图
- ✗ 编 expected 输出

## TodoWrite 用法

加载 plan 后立刻建项:

```
TodoWrite([
  { content: "Task 1: <name>", status: "pending" },
  { content: "Task 2: <name>", status: "pending" },
  ...
])
```

每 task 开始 → mark `in_progress`; 完成 → mark `completed`。

step 级别**不**进 TodoWrite (粒度太细, 用 plan 自己的 checkbox)。

## TDD 处理

plan 怎么写, 你怎么执行。

- plan 第 1 step 是"写失败测试" → 老实写, 跑, 看到红
- plan 没 test step → 不要自己加 (违反 plan 即契约)

要问的: plan 该不该有 test? → 这是 writing-plans 阶段的事, 不归你。

## 前后衔接 (软引用, 不强制)

- **前序**: writing-plans 产出的 `docs/plans/*.md`
- **后续理想**: finishing-a-development-branch (superpowers 同款)

本仓 finishing 暂无, 自己 commit + PR 即可。

## 危险信号

| 内心戏 | 真相 |
|---|---|
| "Step 大概是这意思, 直接干" | 大概 ≠ 确定。停, 问 |
| "测试失败可能环境问题, 跳过" | 跳过 = 隐藏 bug |
| "这 step 没写代码, 我补一下" | 补 = 改 plan。停, 问 |
| "plan 漏了 X, 我顺手加" | 顺手 = 范围扩散。停, 问 |
| "我先把简单 task 全做了" | 顺序破坏 = 依赖倒挂风险 |
| "blocker 等会再处理" | 现在就停, 继续 = 累积错误 |
| "TodoWrite 太重, 不建了" | 建。进度可追踪 = 用户能审 |

## 核心原则

- **HARD-GATE 不可破** — blocker 必停
- **plan 即契约** — 不擅自改
- **不猜不试** — 模糊就问
- **TodoWrite 必建** — 进度可追踪
- **逐项验证** — 每 step expected 必跑
