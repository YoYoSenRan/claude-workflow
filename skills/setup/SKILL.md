---
name: setup
description: 为当前 Claude Code 项目生成或刷新项目级 rules、skills、references 时使用
allowed-tools: Read Grep Glob Agent
---

# 项目工作流初始化

扫描项目，发现已有的代码规律和模式，通过分步交互让用户选择要生成哪些规范。只生成用户确认的内容，只写有实际证据支持的规则。

setup 只在初始化或刷新时用，不是日常开发流程。

## 何时使用

- 为新项目生成 Claude Code 工作流配置时
- 刷新已有项目的 rules、skills、references 时
- 用户明确要求初始化工作流时

## 流程

### 第 1 步：快速扫描，识别项目

自动完成，不用问用户。

1. 看项目根目录的标志文件（package.json、Cargo.toml、go.mod、pyproject.toml 等）→ 确定技术栈
2. 看目录结构 → 了解项目组织方式
3. 看已有 `.claude/`（rules、skills）→ 是不是已经初始化过
4. 读 `references/workflow.md` 和 `references/coverage.md` 了解整体流程

**向用户报告：**

> "这是一个 [技术栈] 项目。[简要描述项目结构]。
> [已有 N 个 rules、M 个 skills / 还没初始化过。]"

如果已有配置，说明后续是"刷新"模式——会保留已有内容，只补充或更新。

### 第 2 步：发现领域，让用户选

按 `references/domains.md` 的方法识别项目中的领域。不预判"该看什么"，而是"看到了什么"。

**怎么发现领域：**
- 看目录结构（src/components → UI 组件、src/services → API 层）
- 看配置文件（路由配置、状态管理配置）
- 看重复模式（多个相似结构的文件 → 框架约定）
- 看已有文档或注释

**用 AskUserQuestion 工具列出发现，让用户多选：**

> "我发现以下领域，选择你想生成规范的：
> □ [领域 1]（发现了什么，几个样本）
> □ [领域 2]（发现了什么，几个样本）
> □ [领域 3]（发现了什么，几个样本）
> ..."

用户没选的就不管。用户可以补充 setup 没发现的领域。

### 第 3 步：逐个领域深扫 + 确认

对用户选的每个领域：

1. **深扫** — 按 `references/habits.md` 的方法采样 2-5 个文件，提取模式
2. **判断强度** — 按 `references/coverage.md` 判断证据是否充分
   - 有文档或 3+ 个一致样本 → 可以写 rule
   - 2-5 个一致样本但没文档 → 可以写 rule 或 reference
   - 只有 1 个样本或样本不一致 → 只做记录，不生成
3. **展示发现，问用户确认：**

> "[领域名] 分析完毕，发现：
> - [规律 1]
> - [规律 2]
> - [规律 3]
>
> 建议生成：
> - rules/[name].md（[什么内容]）
> - skills/[name]/references/[name].md（[什么内容]）
>
> 要生成吗？要调整吗？"

用户说要调整就改，说不要就跳过，说好就记下来。

**领域多时可以派子代理并行扫描**（按 `references/agents.md` 的规则判断是否需要）。

### 第 4 步：统一写入

所有领域确认完毕后：

1. 一次性写入所有用户确认的文件
2. 写完后检查：
   - skill 有 `SKILL.md`、`name`、`description`
   - reference 被对应 skill 明确引用
   - rules 够短、够稳定
   - 没有 `.claude/references/`（reference 必须在 skill 下）
3. 向用户报告写了什么

**已有文件的处理：**

如果项目已有 `.claude/` 配置，先读 `references/refresh.md`，按刷新策略处理：
- 手动创建的 rule：不自动覆盖，展示差异让用户决定
- 自动生成的 rule：展示变化，用户确认后更新
- 引用已不存在的 rule：建议删除
- 新发现：按正常流程建议新增

## 能生成什么

只生成 Claude Code 认识的路径：

| 路径 | 用途 | 加载方式 |
|---|---|---|
| `CLAUDE.md` | 项目全局指令 | 每次自动加载 |
| `.claude/rules/*.md` | 短规则 | 每次自动加载 |
| `.claude/skills/<name>/SKILL.md` | 按需加载的能力 | 调用时加载 |
| `.claude/skills/<name>/references/*.md` | 长参考 | skill 内手动读取 |

不生成 `.claude/references/`。reference 必须归属某个 skill。

## 什么时候生成什么

**生成 rule** — 内容短、证据充分（3+ 样本或有文档）、跨文件通用、防止常见错误
- 例：命名约定、import 顺序、组件使用规范、错误处理模式

**生成 skill** — 有明确的触发场景、有固定的操作步骤、项目特有的做事方式
- 例：CRUD 页面怎么写、部署怎么做、特定框架怎么用
- 按 `references/skills.md` 的 6 个问题判断是否值得生成

**生成 reference** — 内容太长放不进 rule，但有明确的 skill 会读它
- 例：组件清单、API 索引、页面对照表

**不生成** — 只见过一次、以后用不上、只是项目概况、没有证据

## 要读哪些参考文件

这些是 setup 自己用来判断的依据，不是要复制到目标项目。

| 参考文件 | 什么时候读 |
|---|---|
| `references/workflow.md` + `references/coverage.md` | 第 1 步开始前 |
| `references/domains.md` | 第 2 步识别领域时 |
| `references/habits.md` | 第 3 步深扫时 |
| `references/rules.md` | 判断是否该生成 rule 时 |
| `references/skills.md` | 判断是否该生成 skill 时 |
| `references/agents.md` | 判断是否需要派子代理深扫时 |
| `references/refresh.md` | 项目已有 `.claude/` 配置时（刷新模式） |

<constraints>
- 没有用户确认不许写入任何文件
- 没有实际证据（采样文件）不许生成 rule
- 不许生成只见过一次的东西
- 不许生成 `.claude/references/`
- 不许一锅端——每个领域单独展示、单独确认
- 已有文件不许直接覆盖——展示差异让用户决定
</constraints>

## 警示信号

| 念头 | 现实 |
|---|---|
| "多生成一点以后总会用到" | 没有触发场景就是噪音 |
| "一次全展示给用户选效率更高" | 信息太多用户没法判断，逐个确认更准确 |
| "只看了目录结构就知道该生成什么" | 必须读实际文件，目录名不是证据 |
| "直接覆盖旧规则" | 先看旧内容，让用户决定 |

## 沟通规范
- 用户看不到工具调用和思考过程，只看到你的文字输出
- 每一步用自然的对话展示发现，不要堆技术术语
- 用 AskUserQuestion 工具做选择题，不要让用户自己写
- 匹配用户的说话风格
