# claude-workflow

个人 Claude Code 工作流插件。一组 skill + hook，强制 Claude 动手前先走流程，少做错方向、少漏纪律。

---

## 定位与范围

**做核心闭环 5 件套，对齐 Anthropic 官方四阶段 (Explore → Plan → Implement → Commit)。**

| 项 | 状态 | 覆盖阶段 | 说明 |
|---|---|---|---|
| 入口纪律 (`using`) | ✅ 实现 | meta | hook 强注入，所有会话生效 |
| 模糊对齐 (`think`) | ✅ 实现 | Explore 前置 | HARD-GATE 暂停 + 复述 + W 问 |
| 写计划 (`plan`) | ✅ 实现 | Plan | 把任务拆到细碎粒度，落到 docs/plans/ |
| 跑计划 (`executing`) | ✅ 实现 | Implement | TodoWrite + 逐个任务 + 遇阻塞点就停 |
| 系统排错 (`debug`) | ✅ 实现 | Implement 排错支路 | 4 阶段强制 + 3 次失败质疑架构 |
| `.claude/agents/`, `commands/`, `mcps/`, `tools/` | ⬜ 占位 | — | 目前空目录，按需后续接入 |

**适合谁**：单人项目、需要"Claude 别乱开干"纪律、追求轻量 skill 集 (5 个核心 skill) 而非大而全工作流的人。

**不适合谁**：团队协作场景、需要完整头脑风暴 / TDD / 子代理驱动 / 代码评审 / 收尾流程的项目——本仓**不覆盖**这些, 请另寻方案。

---

## 安装

**作为 Claude Code 插件（推荐，热重载）**：

```bash
git clone <this-repo> ~/projects/claude-workflow
# Claude Code 会自动识别 .claude-plugin/plugin.json
# 在该目录下开 claude，hook 自动激活
```

**同步到全局 ~/.claude/（稳定后用）**：

```bash
cd ~/projects/claude-workflow
bash scripts/sync.sh          # 真同步
DRY_RUN=1 bash scripts/sync.sh # 干跑
bash scripts/sync.sh --uninstall # 卸载
```

注意：`using` 在全局同步时**自动跳过**（见 `scripts/sync.sh` 的 `SYNC_SKIP`）—— 它只走 hook 注入路径，不应在 skill 清单里二次出现。

---

## 它解决什么

Claude 默认行为有两个常见坑：

1. **prompt 一来就动手** —— 不复述、不澄清，做错方向白干
2. **该用的 skill 不用** —— 觉得"问题简单"就跳过流程

根本原因：Claude 默认追求"快速给答案"，跟"先走流程"天然冲突。靠用户每次提醒不现实，得让流程**自动注入到对话开头**，让 Claude 想偷懒都偷不掉。

---

## 原理：skill 怎么被触发

Claude Code 的 skill 触发是**三阶段**流程，理解这个才能理解本仓为什么这么设计：

```
阶段 1（会话启动）
  Claude Code 扫所有 skill 位置，只读前置元数据 (name + description + when_to_use)
  形成"可用 skill 清单"注入 system 上下文
  ↓
阶段 2（每次用户消息）
  Claude 用语义匹配判断：当前 prompt 跟哪个 skill 的 description / when_to_use 最贴
  ↓
阶段 3（主动调用）
  Claude 调 Skill 工具读 SKILL.md 全文，按里面流程执行
```

**关键失败点**：阶段 2 是 Claude 主观判断，会漏触发。尤其 meta-skill（"使用 skill 的纪律"）—— Claude 自己不会想到要查"如何查 skill"。

**本仓的解法（双轨）**：

1. **`using` 走 hook 强注入** —— `hooks/session-start.js` 把全文塞进 system 上下文，绕开阶段 2 的语义匹配。
2. **`using` 加 `disable-model-invocation: true` + `user-invocable: false`** —— Claude 不会主动调用（hook 已经塞了），用户也不能 `/using`（菜单隐藏）。**避免双重激活**。
3. 其他三个 skill 走正常阶段 1-3 —— description 写得够准，Claude 看见对应触发场景会自己匹配。

**官方字段速查**（`code.claude.com/docs/en/skills`）：

| 字段 | 用法 | 本仓哪里用 |
|---|---|---|
| `name` | 显示名，限小写 + 连字符 | 全部 |
| `description` | **触发条件**（不是流程摘要！） | 全部 |
| `when_to_use` | 拼到 description 后面，触发短语例子 | 三个非 meta skill |
| `disable-model-invocation` | 禁止 Claude 主动调用 | `using` |
| `user-invocable` | 是否出现在 `/` 菜单 | `using` 设 false |
| metadata.version | 自定义槽，本仓存版本号 | 全部 |

**陷阱**：`description` 不要写工作流摘要。Claude 看见摘要会觉得"我懂了"，跳过读 skill 正文 → 漏掉 HARD-GATE。本仓 skill 的 description 都只写**触发场景 + 不适用场景**，流程留在正文。

---

## 工作流

```
Claude Code 会话启动 (SessionStart hook 触发，匹配 startup/clear/compact)
        ↓
hooks/session-start.js 执行
读 skills/using/SKILL.md 全文
包装成 <EXTREMELY_IMPORTANT>...</EXTREMELY_IMPORTANT>
通过 additionalContext 注入到 system 上下文
        ↓
┌──────────────────────────────────────────────┐
│   using  [META 调度纪律，强注入]                │
│                                              │
│   每次用户消息到来，Claude 必须先做：           │
│   "有 skill 适用吗?(1% 阈值)"                 │
│                                              │
│   1% 阈值 = 只要觉得有 1% 可能某 skill 适用,   │
│   就必须调用 Skill 工具，不可走捷径            │
└──────┬───────────┬───────────┬───────────────┘
       │           │           │
   prompt 模糊   有规格   bug/失败 / 测试挂
       ▼           ▼           ▼
  ┌─────────┐ ┌──────────┐ ┌──────────┐
  │  think  │ │  plan    │ │  debug   │
  │         │ │          │ │          │
  │HARD-GATE│ │HARD-GATE │ │HARD-GATE │
  │禁止工具  │ │占位符零 │ │4 阶段强制 │
  │复述+W 问 │ │任务 2-5 │ │根因>症状  │
  │等确认    │ │min/步    │ │3 次失败质│
  │          │ │交付 plan │ │疑架构    │
  │30 秒对齐 │ │          │ │          │
  │省 1 小时 │ │ ↓        │ │ ↓        │
  └─────────┘ │executing │ │ Phase 4  │
              │TodoWrite │ │ 内嵌跑测  │
              │+ 阻塞点  │ │ 看新鲜证  │
              │  停      │ │ 据       │
              └──────────┘ └──────────┘
```

**走通的完整链路** (理想路径):

```
think (对齐) → plan (拆) → executing (跑) → 中途挂?
                                              ↓ 挂
                              debug (4 阶段) → 修完跑测试看新鲜证据 → 完工
```

---

## skill 分工

| skill | 类型 | 触发方式 | 作用 |
|---|---|---|---|
| `using` | meta | hook 强注入 | 调度其他 skill 的纪律。1% 阈值 |
| `think` | 流程门卫 | 语义匹配 + HARD-GATE | 模糊 prompt 暂停对齐 |
| `plan` | 流程门卫 | 语义匹配 + HARD-GATE | 把规格拆成细碎计划 |
| `executing` | 流程门卫 | 语义匹配 + HARD-GATE | 按计划逐个任务执行，遇阻塞点就停 |
| `debug` | 流程门卫 | 语义匹配 + HARD-GATE | bug/失败时走 4 阶段排错，3 次失败质疑架构 |

**为什么 using 必须用 hook 注入，其他不用？**

`using` 是元规则（"如何使用 skill"）—— Claude 自己不会主动想"我要查查怎么查 skill"，必须强注入。

其他 skill 是具体流程 —— description 写得够准，Claude 看见对应触发场景时会自己匹配到。

---

## HARD-GATE 是什么

强制锁。skill 里写 `<HARD-GATE>...</HARD-GATE>` 块，Claude 读到后**必须**遵守，不能用"先快速看一下"绕过。

例：`think` 的 HARD-GATE 禁止对齐完成前调用任何工具（包括 Read / Bash / Skill）。Claude 想"我先 ls 看一眼" → 违规。

配合 `<EXTREMELY_IMPORTANT>` 和"反模式清单"（列出 Claude 最常用的偷懒借口 + 反驳），从行为层面把流程钉死。

---

## 1% 阈值原理

正常人判断"要不要查 skill"的阈值是 50%（觉得多半用得上才查）。这导致漏触发率高。

把阈值压到 1%（只要觉得 1% 可能就查）→ 漏触发率趋零 → 偶尔多查一次成本低，漏触发一次成本高（白干一小时）。

这是个不对称代价的工程取舍：宁可过度调用，不可漏调用。

---

## 设计参考与取舍

本仓设计期参考了 [superpowers](https://github.com/obra/superpowers) 这个工作流项目, 借鉴了它的 `<HARD-GATE>` / `<SUBAGENT-STOP>` / 反模式表 / 警示信号表 / 1% 阈值等机制。但本仓**不是 superpowers 的发行版 / fork / 子集**, 是独立项目, 范围有意收窄。

下表展示本仓**有意**做了哪些取舍 (左列是参考做法, 右列是本仓选择):

| 维度 | 参考做法 (superpowers) | 本仓选择 |
|---|---|---|
| skill 数量 | 14 (含 TDD / debug / worktree / finishing 等) | 5 (入口 + 对齐 + 计划双件套 + 排错) |
| 平台覆盖 | Claude Code / Cursor / Codex / Copilot / OpenCode | 仅 Claude Code |
| hook 实现 | bash + 多语言通用 `.cmd` 跨 Windows | Node.js 单文件, 跨平台等价 |
| plan 输出路径 | `docs/<plugin>/plans/` (插件命名空间) | `docs/plans/` (去命名空间) |
| TDD 强制度 | 独立 skill, 按需激活 | plan 模板软推荐, 不适用场景自删 |
| 测试自动化 | `claude -p` 跑 stream-json 自动断言 | 目前手动 markdown 清单 (P2 待补) |

**核心取舍**: 本仓只做"对齐意图 + 写计划 + 跑计划 + 系统排错"这条主干, 头脑风暴 / TDD 强制 / 子代理驱动开发 / 收尾 skill / 代码评审 / 完工验证等**有意不补**(见 ROADMAP "不计划做"段)。需要这些场景请自行扩展或另寻方案。

---

## ROADMAP

**已完成（核心闭环 5 件套）**：

- [x] using（meta 强注入）
- [x] think（Explore 前置）
- [x] plan（Plan）
- [x] executing（Implement 单线）
- [x] debug（Implement 排错支路）

**P1（增量，看需要）**：

- [ ] subagent-driven-development：Claude Code 主推的 Task 工具 + 隔离上下文模式，executing 的平行选项
- [ ] finishing-a-development-branch 极简版：跑测试 + 提交 + PR 提示三步

**P2（基建，按需补）**：

- [ ] 测试自动化：抄 superpowers `run-test.sh`，把 `tests/skills/<name>/examples/01-basic.md` 的 Trigger Prompt 接 `claude -p` + stream-json 自动断言
- [ ] `.claude/agents/` 接入个人常用子代理（评审者 / 调试者 / 文档 / linter 等）
- [ ] `.claude/commands/` 自定义短命令
- [ ] LICENSE / CHANGELOG / version-bump 脚本（个人仓优先级低）

**不计划做**：

- ❌ 跨平台支持（Cursor / Codex / Copilot） — 本仓仅 Claude Code
- ❌ TDD / worktree / dispatching-parallel-agents → plan 已带 TDD 模板；个人单线不开 worktree
- ❌ code-review skill → 派评审者子代理走 Task 工具
- ❌ brainstorming → think 已兜底"需求未定"场景
- ❌ 团队治理 / PR 模板 / CI 集成 → 个人仓不需要

---

## 目录速查

```
.claude-plugin/plugin.json     插件入口，指向 hooks/hooks.json
.claude/settings.json          项目级配置，hook 注册（与 plugin.json hooks 字段双轨等价）
.claude/skills/                项目级 skill 扫描位（symlink 指向根 skills/）
hooks/
  hooks.json                   SessionStart 匹配器: startup|clear|compact
  session-start.js             Node 注入器：读 using 全文 → additionalContext
skills/
  using/SKILL.md               meta，hook 强注入，不暴露 / 菜单
  think/SKILL.md               模糊 prompt 暂停门卫
  plan/SKILL.md                拆任务到 docs/plans/
  executing/SKILL.md           按计划逐个任务跑
  debug/SKILL.md               4 阶段排错门卫
tests/skills/<name>/
  README.md                    测试用法
  examples/01-basic.md         Trigger Prompt + Expected Checklist
scripts/sync.sh                同步到全局 ~/.claude/（using 自动跳过）
```
