---
name: setup
description: 为当前 Claude Code 项目生成或刷新项目级 rules、skills、references 时使用
allowed-tools: Read Grep Glob Agent
---

# 项目工作流初始化

读取当前项目的真实文件、文档、配置和已有规则，给出项目级的 Claude Code 工作流建议。只把会影响后续做事方式的内容写入配置。项目概况、一次性观察、没有用武之地的长文，不生成。

setup 只在初始化时用，不是日常开发流程。普通任务仍回到 `using`，再按需要进入 `think`、`plan`、`execute`、`debug`、`verify` 等技能。

## 何时使用

- 为新项目生成 Claude Code 工作流配置时
- 刷新已有项目的 rules、skills、references 时
- 用户明确要求初始化工作流时

## 流程

### 能生成什么

只生成 Claude Code 认识的路径：

| 路径 | 用途 |
|---|---|
| `CLAUDE.md` / `.claude/CLAUDE.md` | 项目入口说明、稳定全局指令 |
| `.claude/rules/*.md` | 短、稳定、持续生效的规则 |
| `.claude/skills/<name>/SKILL.md` | 按需加载的项目任务能力 |
| `.claude/skills/<name>/references/*.md` | 只由对应 skill 主动读取的长参考 |

不要生成 `.claude/references/`。reference 必须归属某个 skill。

### 步骤

1. **确认目标项目** —— 确认当前目录就是要初始化的项目。
2. **读取本技能参考** —— 先读下面"参考加载"列出的文件，再开始判断。
3. **只读扫描** —— 查看顶层目录、源码、docs、tests、CI、脚本、配置、已有 `CLAUDE.md` / `.claude/rules`。
4. **总结规律** —— 记录真实命令、验证方式、编码习惯、目录约定、重复任务流程和容易出错的地方。
5. **生成建议** —— 分成 rules、skills、references 三类；说明每项为什么值得生成。
6. **等待确认** —— 未经用户确认，不写入 `.claude/` 或 `CLAUDE.md`。
7. **写入并检查** —— 写入后确认 skill 有 `SKILL.md`、`name`、`description`，reference 被对应 skill 引用。

### 要读哪些参考文件

这些 reference 是 setup 自己用来判断的依据，不是要复制到目标项目。

- 开始扫描前读 `references/workflow.md` 和 `references/coverage.md`，确定整体流程与覆盖面。
- 需要生成或刷新 rules 时，读 `references/rules.md`。
- 需要生成或刷新项目 skills 时，读 `references/skills.md`。
- 需要提取项目习惯、业务域或长参考时，读 `references/habits.md`、`references/domains.md`。
- 需要深扫配置、框架、样式、领域或既有规则时，读 `references/agents.md`，并按其中要求实际使用 `Agent`。

### 什么时候生成什么

生成 rule：内容短、稳定、经常用到、全局生效或跟路径相关。

生成 skill：有明确的触发时机、固定的做事顺序、项目特有的操作步骤或验证方式。

生成 reference：内容太长放不进 rule 或 SKILL.md，而且有明确的 skill 会去读它。

### 输出格式

```text
项目类型：...

已分析内容：
- ...

建议生成 rules：
| 路径 | 作用 | 内容概要 |
|---|---|---|

建议生成 skills：
| 路径 | 触发场景 | 内容概要 |
|---|---|---|

建议生成 references：
| 路径 | 保存内容 | 读取入口 |
|---|---|---|

需要确认：
- 是否写入
- 已存在文件如何处理
```

<constraints>
- 禁止生成只见过一次的东西
- 禁止生成以后用不上的东西
- 禁止生成只是"项目里有什么"的流水账
- 禁止生成没有根据的猜测
- 禁止生成与用户现有规则冲突的内容
- 禁止生成 `.claude/references/`（reference 必须归属某个 skill）
- 禁止未经用户确认就写入 `.claude/` 或 `CLAUDE.md`
</constraints>

## 警示信号

| 念头 | 现实 |
|---|---|
| "多生成一点以后总会用到" | 无触发条件就是噪音 |
| "把扫描报告放进 reference" | reference 必须被某个 skill 读取 |
| "直接覆盖旧规则" | 先读旧内容，说明保留、追加或替换策略 |
| "只看 README 就够了" | setup 必须读真实配置和代表文件 |

## 沟通规范
- 用户看不到工具调用和思考过程，只看到你的文字输出
- 回复中不要出现本文件里的流程术语
- 用日常口语描述你在做什么："我先看看代码" / "写好了，测试通过" / "有个问题需要你确认"
- 匹配用户的说话风格——用户简短你就简短，用户详细你就详细
