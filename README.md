# claude-workflow

个人 Claude Code 工作流插件。一组 skill + hook，强制 Claude 在动手前先走流程，少做错方向、少漏纪律。

---

## 它解决什么

Claude 默认行为有两个常见坑：

1. **prompt 一来就动手** — 不复述、不澄清，做错方向白干
2. **该用的 skill 不用** — 觉得"问题简单"跳过流程

根因：Claude 默认追求"快速给答案"，跟"先走流程"天然冲突。靠用户每次提醒不现实，得让流程**自动注入到对话开头**，让 Claude 想偷懒都偷不掉。

---

## 原理：skill 怎么被触发

Claude Code 的 skill 触发是**三阶段**流程，理解这个才能理解本仓为什么这么设计：

```
阶段 1 (会话启动)
  Claude Code 扫所有 skill 位置，只读 frontmatter (name + description + when_to_use)
  形成"可用 skill 清单"注入 system 上下文
  ↓
阶段 2 (每次用户消息)
  Claude 用语义匹配判断：当前 prompt 跟哪个 skill 的 description / when_to_use 最贴
  ↓
阶段 3 (主动调用)
  Claude 调 Skill 工具读 SKILL.md 全文，按里面流程执行
```

**关键失败点**：阶段 2 是 Claude 主观判断，会漏触发。尤其 meta-skill（"使用 skill 的纪律"）—— Claude 自己不会想到要查"如何查 skill"。

**本仓的解法**：用 SessionStart hook 把 meta-skill 内容**强行注入**对话开头（绕过阶段 2 的语义匹配），保证每次会话都生效。

---

## 工作流

```
Claude Code 会话启动 (SessionStart hook 触发，匹配 startup/clear/compact)
        ↓
hooks/session-start.js 执行
读 skills/using-workflow/SKILL.md 全文
包装成 <EXTREMELY_IMPORTANT>...</EXTREMELY_IMPORTANT>
通过 additionalContext 注入到 system 上下文
        ↓
┌──────────────────────────────────────────────┐
│   using-workflow  [META 调度纪律，强注入]      │
│                                              │
│   每次用户消息到来，Claude 必须先做：           │
│   "有 skill 适用吗?(1% 阈值)"                 │
│                                              │
│   1% 阈值 = 只要觉得有 1% 可能某 skill 适用,   │
│   就必须调用 Skill 工具，不可走捷径            │
└──────┬───────────────────┬───────────────────┘
       │                   │
       │ prompt 模糊        │ 用户说"写/改 skill"
       │ (指代不明/范围模糊  │ ("加个 skill 干 X")
       │  /多解读/高代价)   │
       ▼                   ▼
┌─────────────────────┐  ┌──────────────────────┐
│  aligning-intent    │  │  writing-skills      │
│                     │  │                      │
│  <HARD-GATE>        │  │  <HARD-GATE>         │
│  禁止调任何工具      │  │  P0 三问不能跳        │
│                     │  │                      │
│  复述理解 (具体)     │  │  P0 痛点/激活/反向    │
│  → 提 2-3 个 W 问题  │  │  P1 脚手架            │
│    (带选项，非开放) │  │  P2 frontmatter       │
│  → 等用户确认        │  │  P3 正文              │
│  → 才能执行          │  │  P4 字符预算 ≤13KB    │
│                     │  │  P5 测试             │
│  目的: 30 秒对齐     │  │                      │
│  省 1 小时返工       │  │  目的: 防止写出       │
│                     │  │  silent drop / 不触发  │
│                     │  │  / 没测试的废 skill   │
└─────────────────────┘  └──────────────────────┘
```

---

## 三 skill 分工

| skill | 类型 | 触发方式 | 作用 |
|---|---|---|---|
| `using-workflow` | meta | hook 强注入 | 调度其他 skill 的纪律。1% 阈值 |
| `aligning-intent` | 流程门卫 | 语义匹配 + HARD-GATE | 模糊 prompt 暂停对齐 |
| `writing-skills` | 流程门卫 | 语义匹配 + HARD-GATE | 写 skill 走 P0-P5 |

**为什么 using-workflow 必须用 hook 注入，其他两个不用？**

`using-workflow` 是元规则（"如何使用 skill"）—— Claude 自己不会主动想"我要查查怎么查 skill"，必须强注入。

`aligning-intent` / `writing-skills` 是具体流程 —— description 写得够准，Claude 看见模糊 prompt 或"写 skill"请求时会自己匹配到。

---

## HARD-GATE 是什么

强制锁。skill 里写 `<HARD-GATE>...</HARD-GATE>` 块，Claude 读到后**必须**遵守，不能用"先快速看一下"绕过。

例：`aligning-intent` 的 HARD-GATE 禁止在对齐完成前调用任何工具（包括 Read / Bash / Skill）。Claude 想"我先 ls 看一眼" → 违规。

配合 `<EXTREMELY_IMPORTANT>` 和"反模式清单"（列出 Claude 最常用的偷懒借口 + 反驳），从行为层面把流程钉死。

---

## 1% 阈值原理

正常人判断"要不要查 skill"的阈值是 50%（觉得多半用得上才查）。这导致漏触发率高。

把阈值压到 1%（只要觉得 1% 可能就查）→ 漏触发率趋零 → 偶尔多查一次成本低，漏触发一次成本高（白干一小时）。

这是个不对称代价的工程取舍：宁可过度调用，不可漏调用。
