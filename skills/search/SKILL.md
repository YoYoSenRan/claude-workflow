---
name: search
description: "并行子代理 + 引文锁源的深度调研 skill, 回答具体研究问题、产出可追溯低幻觉报告。与 /learn 区分: /learn 是收集材料→写成文章, /search 是回答研究问题→出调研报告。不适合单次问答或单页阅读。"
when_to_use: "深度调研, 调研一下, 综述, 技术选型, 库对比, 框架对比, SDK 选型, 性能 benchmark, 竞品分析, 行业报告, 市场调研, 政策分析, deep research, survey, landscape, library comparison, framework selection, SDK choice, benchmark, market research, competitive analysis, write a report on"
metadata:
  version: "1.1.0"
---

# Search: 深度调研工作流

并行派出多个子代理搜资料 → 主代理只读蒸馏笔记 → 锁定引文后起草 → 反向自审 → 交付。

核心承诺 — **每条事实必带 `[n]` 引用, 主代理不读 raw search 结果, 引文 P3 后锁死不可加新源**。

## 适用 / 不适用

| 适用 | 不适用 |
|---|---|
| 多源对比、技术选型、竞品/行业分析、政策综述 | 单页问答 — 直接 `/read` |
| 用户要求"可追溯"、"无幻觉"、"带出处" | 已知答案的快速核对 |
| 主题跨 2 个以上子领域 | 单文件理解 — 直接 Read |
| 需要写成报告交付 | 写文章 (走 `/learn` 收集 → 写作流水) |

判断不准 — 默认 Standard 模式 (见 P0)。单实体/单概念查询 (问题 <30 字, 无对比) 走 Lightweight。

## 架构

```
主代理 (协调器, 上下文轻)
  │
  P0: 范围 + AS_OF 设定
  │
  P1: 任务板分解 (3-5 任务)
  │
  P2: 并行派子代理 ──→ 子代理 A → task-a 笔记 ─┐
                    ──→ 子代理 B → task-b 笔记 ─┤
                    ──→ 子代理 C → task-c 笔记 ─┘
  │                                            │
  │     主代理只读笔记 ←───────────────────────┘
  │     (子代理的 raw search 结果留在它自己上下文, 用完即弃)
  │
  P3: 合并去重 → 引文注册表 [n] (锁源)
  │
  P4: 大纲 + 起草 (每事实带 [n] + 信心度)
  │
  P5: 反向自审 (≥3 issue) + 核验 + 交付
```

**省 context 关键** — 子代理把搜来的几十 KB 网页蒸馏成 ≤15 条 findings, 主代理上下文减负 60-70%。

## 技术调研专项 (Tech Research Mode)

**自动叠加** — 问题涉及以下任一时, 在常规 P0-P5 流程上叠加本节规则:

触发关键词: library, framework, SDK, API, npm, pip, crate, gem, 技术选型, 库对比, 框架对比, benchmark, 性能对比, 工具对比, GitHub repo, 开源项目, 维护活跃度

### TR-1: 数据源优先级 (覆盖默认)

```
1. context7 MCP (官方文档)        ← 第一手, 必试
2. 目标库的 GitHub repo            ← star/commits/issues/releases
3. 官方 blog / changelog           ← 版本演进与破坏性变更
4. 标准媒体 (InfoQ/Hacker News 等) ← 行业反馈
5. 通用 web_search                 ← 兜底
```

不要直接跳过 1-2 用 web_search 拿二手 blog。

### TR-2: 子代理强制采集字段

每个候选 (库/框架/工具) 至少收齐:

| 字段 | 标签 | 时效红线 |
|---|---|---|
| GitHub stars | `stars: N` | — |
| Last commit 日期 | `last_commit: YYYY-MM-DD` | **>12 月标"维护风险"** |
| Latest release | `latest_release: vX.Y.Z @ YYYY-MM-DD` | >6 月留意 |
| Open issues / closed ratio | `issues: open/total` | — |
| License | `license: MIT/AGPL/...` | 标注病毒式 license 风险 |
| Bundle size / 安装大小 | `size: KB or MB` | 前端必收 |
| 主要 maintainer | `maintainer: 公司/个人/基金会` | 单点风险 |

### TR-3: 笔记加 Code Snippets 段

子代理在三段 (Sources/Findings/Gaps) 基础上多加一段:

```
## Code Snippets
### [Xn] {库名} 基础调用
```{lang}
{≤15 行核心调用示例, 从官方文档抠}
```

### [Xm] {库名} 进阶/配置
{另一关键示例}
```

每候选 1-3 段, 整任务 ≤5 段。**只抠官方/作者写的代码**, 不抓二手教程的。

### TR-4: 报告必须含决策矩阵

`report_template.md` 的核心章节加表:

```
## 决策矩阵

| 维度 | {候选 A} | {候选 B} | {候选 C} |
|---|---|---|---|
| 维护活跃度 (last commit) | 2026-04 ✅ | 2024-11 ⚠️ | 2026-05 ✅ |
| Stars / 生态 | 45k | 12k | 88k |
| License | MIT ✅ | AGPL-3.0 ⚠️ | Apache 2.0 ✅ |
| Bundle size | 12KB | 45KB | 8KB |
| 学习曲线 | 低 | 中 | 高 |
| 团队栈契合 | {依据本地 codebase} | ... | ... |
| 性能 (benchmark) | {数字 + 源} | ... | ... |
| 主要风险 | 单点 maintainer | license 病毒 | 学习成本 |

**推荐**: {候选} — {一句话理由 + 引用}
```

### TR-5: 加"实测建议"段

报告末尾 (在引文注册表前) 加:

```
## 实测建议 (Minimum PoC)

最小验证命令:
```bash
{npm/pip/cargo install ...}
{最小 hello-world 代码或 cli 调用}
```

观察点:
- {点 1, 如"启动时间"}
- {点 2, 如"内存占用"}
- {点 3, 如"错误信息可读性"}

预计耗时: {N 分钟}
```

调研只是文献综述, 真正决策前必须有 PoC — 本段告诉用户怎么花 30 分钟验证。

### TR-6: 本地代码库约束感知

起草前快速扫:
- `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` 看现有栈
- 主要框架版本 (React 17 vs 19 限制 lib 选择)
- 现有 ORM/HTTP client/test runner

报告"决策矩阵"的"团队栈契合"行据此填。**不要推荐与现有栈冲突的方案**, 即使技术更优。如必须推荐, 在风险列写明迁移成本。

### TR-7: 反模式 (技术调研特有)

- ✗ 用 web_search 拿 Medium/dev.to 二手 blog 当主源 (应去 context7 + GitHub)
- ✗ 推荐库不报 last commit 日期
- ✗ 只看 star 不看 issue 健康度 (50k star 但 3k open issue = 维护塌方)
- ✗ 忽视 license (AGPL 进商业代码会引爆)
- ✗ 不收代码片段, 只给文字描述 (开发者要看 API 长啥样)
- ✗ 不读本地 codebase 就推荐方案 (推 React lib 给 Vue 项目)

---

## 状态回执约定

每阶段结束输出一行 `[Pn] ...` 形式回执给用户。用户随时可打断、改方向、跳过某阶段。失败 (web_search 不可用、子代理无回应、Quality Gates 不达标) — 停下报告并等用户决定, 不要静默重试。

## P0: 范围 + 模式

回问用户三件事 (一次提问) —

1. **深度** — Lightweight (3 任务, 2-4K 字) / Standard (4-5 任务, 4-7K 字)
2. **视角** — 调研立场 (如: 用户/开发者/采购方/学术综述)
3. **输出语言** — 中/英/双语对照

**默认值**: 未明确时走 Standard。问题 <30 字且只问单一实体/单一概念 (无对比、无"对比/技术选型"字样) 自动走 Lightweight。

设定 —
- `AS_OF` = 今天日期 (YYYY-MM-DD), 用于时效性核查
- `MODE` = Standard / Lightweight
- 检查能力: web_search 必须可用 (不可用→停下问用户); 无子代理派遣能力则进入**降级顺序模式** (见 P2)

报告: `[P0] mode={MODE}, AS_OF={日期}, 子代理={yes/no}`

## P1: 任务板

把研究问题拆 3-5 个任务, 每个由专家角色独立调查 —

```
Task A — 角色: {如 "TLS 指纹研究员"}
         目标: 一句话调查目标
         查询: 2-3 个预设 search query
         深度: DEEP (fetch 2-3 篇全文) / SCAN (snippet 够用)
         输出: task-a 笔记

Task B — ...
```

规则 —
- 任务彼此独立 + 来源多样
- **派遣分批**: 同时并发 ≤3, 超过 3 任务时分 2 批 (先 3, 等回完再剩余)
- 标记时效敏感声明
- 每任务必有"专家角色", 不写"通用搜索"

报告: `[P1] N 任务, 第 1 批 K 个派遣中`

## P2: 派遣 + 收笔记

并行派子代理, 加载 [references/subagent_prompt.md](references/subagent_prompt.md) 作为派遣模板。

子代理交付物按 [references/notes_format.md](references/notes_format.md) 格式 — 三段:
- **Sources** — URL + 类型 + 日期 + Authority 1-10
  - **每任务源数**: Standard 4-8 条 / Lightweight 3-5 条 (聚合后达到 P3 全局阈值即可)
- **Findings** — ≤15 条单句事实, 每条带源号 [An]
- **Gaps** — 搜了但没找到的、可能的反向解释

**铁律** —
- 主代理在起草阶段**只读笔记**, 不把子代理或自己的 raw search 结果作为起草直接素材
- 子代理不许编 URL, 只用实际访问过的链接
- 不确定数字标 `[unverified]`

### 降级顺序模式 (无子代理派遣能力时)

主代理串行扮演每个角色, 流程严格分段:

1. **调研窗口**: 当前任务的 web_search + WebFetch 全部执行
2. **蒸馏窗口**: 立刻写出 `task-{id}` 笔记 (格式同上)
3. **关闭原始素材**: 笔记写完后**不回头查搜索结果**, 进入下一任务

铁律仍成立: 起草 (P4) 时只引用笔记, 不引用任何 raw search。这是工作流分段而非物理隔离 — 关键是起草那一步只看蒸馏后的笔记, 防止主代理凭印象编内容。

报告每个任务: `[P2 task-{id}] {N} sources, {M} findings`

## P3: 引文注册表 (锁源)

读完所有任务笔记 → 合并去重 → 统一编号 —

```
注册表

Approved:
[1] 作者/机构 — 标题 | URL | type: official | date: YYYY-MM-DD | auth: 8 | task-a
[2] ...

Dropped:
× 来源 | URL | reason: 单源 + auth<5 / 时效过期 / 重复

Stats: approved={n}/{total}, 域名数={k}, official 占比={pct}%
```

**质量阀** (Quality Gates) — 全部针对**聚合后的 Approved 注册表**, 非单任务:

| 指标 | Standard | Lightweight |
|---|---|---|
| Approved 源数 (去重后) | ≥10 | ≥6 |
| 唯一域名数 | ≥5 | ≥3 |
| official+academic 占比 | ≥30% | ≥20% |
| 单源最大占比 | ≤25% | ≤30% |
| community 占比上限 | ≤30% | ≤40% |

不达标 — 停下报告给用户, 提议: ① 补 1-2 个针对性任务再跑 P2 / ② 降级到 Lightweight / ③ 接受当前数据起草并标注信心度低。

**来源类型标签** — `official` / `academic` / `secondary-industry` / `journalism` / `community` / `other`

**P3 之后注册表锁死** — P4 起草不可加新源, 想到新事实没源就标 `[unverified]` 或删。

报告: `[P3] {approved}/{total} sources, {k} 域名, official {pct}%`

## P4: 大纲 + 起草

先建大纲 (主题先于任务序) —

```
## 章节 N
来源: [1][3][7] (跨 task-a, task-b)
核心论断: ...
反向声明候选: ...
时效核查: 源日期 vs AS_OF
缺口: 哪些数据缺官方源
```

再按 [references/report_template.md](references/report_template.md) 起草。

**起草规则** —
- 每条事实带 `[n]`
- 数字/百分比必须有源, 否则 `[unverified]` 或删
- 每节末标**信心度**: 高/中/低 + 一句理由
- 冲突证据处插**反向声明** ("亦有 X 认为...")
- 主代理永不编 URL — 全从注册表取

报告: `[P4] {n}/{m} 章节, ~{words} 字`

## P5: 反向自审 + 核验 + 交付

自审 5 题 —
1. 结论可能错吗? 错在哪?
2. 哪些高影响声明只有 1 个源?
3. 哪些声明缺 official/academic 背书?
4. 时效敏感声明的源日期 vs AS_OF?
5. 哪些主张对立解释成立?

**强制找 ≥3 个 issue** — 找不到就重审 (大概率自欺)。

**Issue 处置分流** (issue ≠ 报告中的"核心争议") —
- 类型 A: 缺源/单源/时效过期 → 回头补源、降信心度、或删该声明
- 类型 B: 存在实质对立证据/解释 → 写入报告"核心争议"段保留
- 类型 C: 内部不一致/数字矛盾 → 修正文

只有类型 B 进入报告"核心争议"。A/C 是 silent fix。**不要为凑"核心争议 ≥3 条"硬塞类型 A 的问题**。

核验 —
- [ ] 每个 `[n]` 都在 Approved 注册表里
- [ ] 抽 5+ 关键声明溯源到任务笔记
- [ ] 删/标无源声明
- [ ] Dropped 源没复活
- [ ] 关键论点不靠单源

报告: `[P5] {n} issues 发现, {m} 处修正, 报告 ready`

交付时附 —
- 引文注册表 (放报告末尾或单独文件)
- 信心度概览
- 反向争议小节
- AS_OF 日期

## 反模式

- ✗ 主代理直接读 raw search 结果 (应只读子代理笔记)
- ✗ 编造 URL / 凭印象写数字
- ✗ Dropped 源在起草时偷偷复活
- ✗ 时效敏感声明缺日期
- ✗ 跳过 P5 自审或自审找 0 issue
- ✗ 用单源支撑高影响声明
- ✗ 子代理把任务搜索结果原样塞回主代理
- ✗ 模式选错 — 简单核对走 Lightweight 即可, 不要事事 Standard

## 文件清单

| 文件 | 何时加载 |
|---|---|
| [references/subagent_prompt.md](references/subagent_prompt.md) | P2 派遣子代理时 |
| [references/notes_format.md](references/notes_format.md) | P2 校验子代理交付格式 |
| [references/report_template.md](references/report_template.md) | P4 起草章节骨架 |

## 完成后

报告交付后, 建议用户:
- A) 跑 `/read` 进一步核查某个具体 URL
- B) 跑 `/write` 把报告去 AI 味润色
- C) 转 PDF / PPT (走外部工具)
- D) 直接收下
