# claude-workflow 架构基线

> **本文档作用**：claude-workflow 项目的架构原点。所有 skill 开发、调整、新增必须对照本文。任何与本文冲突的实现都视为偏离方向。
>
> **参考来源**：`/Users/macos/WebProject/superpowers` 架构 + 用户个人调整。
>
> **修订规则**：本文档变更必须经用户显式确认，不可由 skill 实现侧反向修改架构。

---

## 0. 设计哲学

claude-workflow 是个人开发工作流的行为塑造插件。核心信念：

1. **流程纪律 > 临场判断**。结构化流程能在长会话中持续生效，临场判断会因压力、疲劳、token 紧张而塌陷。
2. **HARD-GATE 是载荷不是装饰**。带强压力词的指令块是 superpowers 经 94% PR 拒收率压力测试后沉淀下来的行为塑造手段，不可弱化为"建议"。
3. **职责单一**。每个 skill 只承担一件事，跨职责必须拆分。
4. **终态明确**。每个主流程 skill 必须明确"只能跳到下一个 X"，禁止横跳。
5. **文档为执行而存在**。spec / plan 文档不是产物，是执行输入；不可执行的文档视为失败。

---

## 1. 三层 skill 体系

```
┌─────────────────────────────────────────────────────────────────┐
│ 第 0 层：元规则层（session-start 自动注入）                     │
│   skills/using/SKILL.md                                         │
│   告诉 Claude "skill 体系怎么用"，不参与具体任务路由            │
└─────────────────────────────────────────────────────────────────┘
                              │ 注入到 <EXTREMELY_IMPORTANT> 标签
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 第 1 层：主流程层（4 个 skill，全部 HARD-GATE）                 │
│   think → plan → executing                                      │
│            ↘ debug（独立入口，bug 类任务）                      │
│   严格顺序，不可跳步，终态固定指向下一 skill                    │
└─────────────────────────────────────────────────────────────────┘
                              │ 按需叠加
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 第 2 层：增强层（弱触发，按 prompt 关键词条件性加载）           │
│   worktree / research / verification / finishing-branch /       │
│   code-review / 未来按需追加                                    │
│   由主流程 skill 触发或并行注入，不打断主流程                   │
└─────────────────────────────────────────────────────────────────┘
```

### 1.1 层间约束

- **第 0 层 → 第 1 层**：using 不路由具体任务，仅告知 Claude "存在 skill 体系，遵守 1% 法则"。所有路由权下放到第 1 层的 think。
- **第 1 层 内部**：think 是唯一入口，决定路由到 plan/debug/executing/直接执行。plan 终态固定指向 executing。executing/debug 终态自包含。
- **第 1 层 → 第 2 层**：主流程 skill 在必要时调用增强 skill（如 plan 提示用 worktree、executing 调 verification）。增强 skill 不可反向打断主流程。

---

## 2. 第 0 层：元规则层

### 2.1 skills/using/SKILL.md

**唯一文件**：`skills/using/SKILL.md`，约 80 行。

**职责清单**（保留）：
- 1% 法则——哪怕 1% 可能某 skill 适用就必须 Skill 工具调用
- SUBAGENT-STOP——子代理派遣时跳过 skill 加载
- 指令优先级——用户指令 > skill > 默认系统提示
- 如何调用 Skill 工具
- 宣告义务——使用 skill 前必须公开宣告"正在使用 X skill 来 Y"
- TodoWrite 义务——skill 内含 checklist 时为每项落 todo

**禁止职责**（删除）：
- ❌ PlanMode 前置 think 拦截（路由权归 think）
- ❌ skill 优先级排序（"Process 先于 Implementation"，归 think）
- ❌ 入口违规对照表（归 think）
- ❌ Red Flags 表（归 think 的反模式段）

### 2.2 session-start 注入机制

`hooks/session-start.js` 在 SessionStart 事件触发时把 `skills/using/SKILL.md` 全文读出，包进 `<EXTREMELY_IMPORTANT>` 标签注入到 Claude 上下文。

机制对标 superpowers `hooks/session-start`，差异：
- 用 Node.js 实现（superpowers 是 bash）
- 仅 Claude Code 单一 harness（superpowers 多 harness 适配）

---

## 3. 第 1 层：主流程层

### 3.1 skill 一览

| skill | 对标 superpowers | 入口条件 | HARD-GATE 锁什么 | 终态指向 |
|---|---|---|---|---|
| think | brainstorming | 所有用户 prompt 第一站 | 模糊 prompt 不动工具 | plan / debug / executing / 直接执行 |
| plan | writing-plans | think 路由（多步骤实现） | 禁 placeholder + 步骤必须可执行 | executing |
| executing | executing-plans + subagent-driven-development | think 路由 / 已有 plan 文件 | 遇阻即停不拼猜 | 完成或调用增强 skill |
| debug | systematic-debugging | think 路由（bug 类任务） | 未查根因不动修（Iron Law） | 完成或转 plan（需写修复计划时） |

### 3.2 think skill

**职责**：
1. 收所有用户 prompt 作为第一站
2. 扫歧义信号 → 命中即 HARD-GATE 锁住，复述 + W 问题 + 等确认
3. 不命中 → 直接路由（不进 HARD-GATE）
4. 复杂任务对齐完成 → 落 spec 到 `docs/specs/YYYY-MM-DD-<topic>.md`
5. 简单任务对齐完成 → 仅口头对齐，不落盘
6. 按任务类型路由到下一 skill

**HARD-GATE 内容**：
```
检测到 prompt 模糊时，禁止调用任何工具（Read / Edit / Bash / Skill 等），
禁止做任何"先看一下""先试一下"的探索性动作。
必须先完成：复述理解 → 提 W 问题 → 等用户确认。
```

**路由表**（终态）：

| 任务类型 | 下一步 skill | spec 是否落盘 |
|---|---|---|
| 多步骤实现 / 改多个文件 / 改架构 | plan | ✅ 落 docs/specs/ |
| 排查 bug / 失败原因 | debug | 视复杂度（一般不落） |
| 已有计划，本次执行 | executing | 不落 |
| 单步小改动（1 个文件、几行） | 直接执行 | 不落 |

**spec 落盘判定**：think 自决"复杂度"——跨多文件 / 跨多步骤 / 会动架构 = 复杂 → 落 spec。单文件单动作 = 简单 → 不落。

### 3.3 plan skill

**职责**：
1. 读 think 的 spec 文件或当面对齐结果作为输入
2. 写实现计划，落 `docs/plans/YYYY-MM-DD-<feature>.md`
3. 自我审查（placeholder 扫描 / 类型一致性 / spec 覆盖）
4. 可选派遣子代理评审（用 `skills/plan/plan-document-reviewer-prompt.md`）
5. 终态指向 executing

**HARD-GATE 内容**：
```
计划文档中禁止出现 TBD / TODO / "fill in later" / "implement appropriate X" 
等占位符。每个步骤必须含可执行的代码块或精确命令。
```

**plan 文档模板**（约束）：
- 文件结构段（先列出会改/会创建的所有文件）
- 任务分解（每任务含 Files / Steps / 验证 / Commit）
- 步骤粒度：2-5 分钟一步（"写失败测试" / "运行验证失败" / "实现" / "运行验证通过" / "提交"）
- 自审章节

### 3.4 executing skill

**职责**：
1. 加载 plan 文档
2. 严格按计划执行
3. **内嵌子代理决策逻辑**：单文件包含"任务判别 → 简单自做 / 复杂拆子代理 / 多任务并行派遣"
4. 遇阻即停报告，不拼猜推进
5. 终态：完成 / 调用增强 skill（verification / finishing-branch）

**HARD-GATE 内容**：
```
执行遇到 blocker（依赖缺失 / 测试挂 / 指令不清 / 验证反复失败）时，
必须停下报告。禁止跳过验证步骤，禁止猜测推进。
```

**子代理决策表**（内嵌）：

| 任务特征 | 执行方式 |
|---|---|
| 单文件 / 单步骤 / 简单替换 | 主智能体自做 |
| 跨多文件 / 需独立验证 / 可并行 | 拆给子代理（每任务一个新 agent） |
| 多个互不依赖任务 | 并行派遣多子代理 |
| 含 review / audit 性质 | 派遣 reviewer 类子代理 |

### 3.5 debug skill

**职责**：
1. 收 bug / 测试挂 / 异常行为类任务
2. 强制 4 phases：根因调查 → 假设验证 → 修复 → 防回归
3. Iron Law 锁——未完成 Phase 1 不可提任何修复

**HARD-GATE 内容**：
```
未完成 Phase 1（根因调查 + 证据采集），禁止提出任何修复方案。
症状修复 = 失败。
```

---

## 4. 第 2 层：增强层

### 4.1 已存在 / 已计划

| skill | 状态 | 对标 superpowers | 触发条件 | 与主流程关系 |
|---|---|---|---|---|
| research | ✅ 已存在 | 无（自定） | "搜索 / 调研 / 查文档" 类 prompt | 可被任何主流程 skill 调用 |
| worktree | 📋 已计划 | using-git-worktrees | "新功能 / 隔离开发 / git worktree" | executing 前置生效 |

### 4.2 路线图（按用户优先级）

| skill | 对标 superpowers | 触发条件 | 与主流程关系 |
|---|---|---|---|
| verification-before-completion | 同名 | executing 完成后 | executing 调用，作为完成前必经步骤 |
| finishing-branch | finishing-a-development-branch | verification 通过后 | PR / merge / cleanup 选项 |
| code-review | requesting-code-review + receiving-code-review | PR 前后 | 双向评审，PR 前自检 / PR 后接评审 |

### 4.3 增强 skill 约束

- 默认**无 HARD-GATE**（弱触发，错触发代价低）
- 单独例外：涉及安全/不可逆动作的增强 skill 可加 HARD-GATE（如 worktree 防误改主分支）
- 必须含 SUBAGENT-STOP 块
- 触发条件写 description 字段，不写流程摘要

---

## 5. 文档落盘约定

| 阶段 | 产出 | 路径 | 必落性 |
|---|---|---|---|
| think（复杂任务） | spec | `docs/specs/YYYY-MM-DD-<topic>.md` | 默认落 |
| think（简单任务） | 仅口头对齐 | — | 不落 |
| plan | 实现计划 | `docs/plans/YYYY-MM-DD-<feature>.md` | 必落 |
| executing / debug | 不产文档 | — | — |
| 架构调整 | 本文档 | `docs/architecture.md` | 需用户确认 |

**目录约束**：
- `docs/specs/` — think 复杂任务输出
- `docs/plans/` — plan 唯一输出
- `docs/architecture.md` — 架构原点（本文档）
- 其他 docs 子目录按需创建，需在本文档补登记

---

## 6. SKILL.md 文件结构标准

每个 skill 的 SKILL.md 必须含以下段（按顺序）：

```markdown
---
name: <skill-name>
description: "<触发条件，不写流程摘要>"
[when_to_use: "<原话触发模式>"]              # 可选
[disable-model-invocation: true]              # 仅 using
[user-invocable: false]                        # 仅 using
---

<SUBAGENT-STOP>
如果你是作为子代理被派遣去执行某个具体任务，请跳过此 skill。
</SUBAGENT-STOP>

[<HARD-GATE>...</HARD-GATE>]                   # 第 1 层全部必有；第 2 层按需

# <skill 中文标题>

<一段总述>

## 反模式：<最常见借口>                       # 第 1 层必有；第 2 层按需

## 清单                                         # 必有
1. ...
2. ...

## 流程图                                       # 必有（dot 语法）
```dot
digraph skill {
  ...
}
```

## 详细流程                                     # 必有

## 关键原则                                     # 必有

## 警示信号                                     # 第 1 层必有
| 念头 | 现实 |

## 何时不激活                                   # 可选
```

**强约束**：
- 终态指向必须在流程图 doublecircle 或文末"过渡到下一 skill"段明示
- 不允许 placeholder
- 中文表达，技术术语保留英文
- 文件大小目标 100-250 行（超 250 行考虑拆 reference 文件）

---

## 7. 触发与调用约定

### 7.1 自动触发（1% 法则）

所有用户 prompt 默认走 think 入口。Claude 收到消息后：

1. 扫 prompt 是否命中任何 skill 触发条件（≥1% 即触发）
2. 命中 → 调用 Skill 工具加载对应 SKILL.md
3. 公开宣告"正在使用 X skill 来 Y"
4. 含 checklist 则 TodoWrite 落地
5. 严格按 skill 执行

### 7.2 用户显式触发

用户原话含 "用 think / 走 plan / 调 debug" 等明确指令 → 直接走对应 skill，跳过 think 路由判断。

### 7.3 子代理豁免

子代理被派遣执行具体任务时，session-start 注入的 using 内容里的 SUBAGENT-STOP 块生效，跳过所有 skill 加载。子代理只做被派遣的事，不递归走主流程。

---

## 8. 不变式（违反即视为偏离）

1. **using 不路由** — using 内不可出现"模糊时跳 think""bug 时跳 debug"等路由指令
2. **think 是唯一入口** — 所有用户 prompt 由 think 首接，不可绕过
3. **plan 终态必为 executing** — 不可指向其他 skill
4. **HARD-GATE 不可弱化** — 锁的措辞可中文化但不可改成"建议"
5. **文档必须可执行** — spec / plan 不含 placeholder
6. **单向链不可横跳** — 主流程 skill 不互调（如 plan 不直接调 debug）
7. **增强 skill 不打断主流程** — 仅在主流程内被调用，不主动抢入口
8. **subagent 决策内嵌于 executing** — 不拆独立 skill
9. **架构变更需用户确认** — 本文档变更不可由 skill 实现侧反向触发

---

## 9. 与 superpowers 的差异表

| 维度 | superpowers | claude-workflow | 差异理由 |
|---|---|---|---|
| 命名 | brainstorming/writing-plans/executing-plans/systematic-debugging | think/plan/executing/debug | 用户偏好简短中文友好 |
| 语言 | 英文 | 中文（技术术语保留英文） | 用户母语 |
| harness 支持 | Claude Code / Cursor / Gemini / Codex 多 | 仅 Claude Code | 个人使用 |
| using 职责 | 含 skill 优先级 + Red Flags 表（路由相关） | 仅元规则 | think 接管所有路由 |
| brainstorming 落 spec | 总是落 | 复杂任务才落 | 减少简单任务过度文档化 |
| subagent 派遣 | dispatching-parallel-agents + subagent-driven-development 两个独立 skill | 嵌入 executing 单文件 | 用户偏好简化 |
| Visual Companion | 有（浏览器辅助） | 暂无 | 不需要 |
| 多 harness 整合测试 | 必需 | 不需要 | 单 harness |

---

## 10. 变更日志

| 日期 | 变更 | 决策来源 |
|---|---|---|
| 2026-05-20 | 初稿创建，锁定三层 skill 体系、4 主流程 HARD-GATE、docs/specs+plans 双目录、subagent 嵌入 executing、未来增强路线图 | 用户对齐会话（本日） |
