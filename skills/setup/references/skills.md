# Domain Skill Generation

本参考用于生成 `.claude/skills/<domain>`。领域 skill 是按需加载的项目任务入口，负责告诉模型在某类任务中加载哪些 rules、阅读哪些代表文件、按什么顺序处理、用什么命令验证。

## 基本规则

- `SKILL.md` 保持短，写触发条件、执行规则和 references 入口。
- `description` 只写何时触发，不写完整流程。
- 长示例、证据、文件清单、扫描报告放 `references/`。
- 每个领域 skill 必须说明适用场景、执行规则、不要做、验证方式。
- 每个生成项必须有证据来源；证据不足的候选只进入内部账本，默认不向用户解释该项。
- 已有 rules 可以被领域 skill 引用，但不能替代领域 skill。领域 skill 的价值是按需加载领域入口、操作顺序、证据索引和验证选择。
- 高频开发领域即使已有完整 rules，也默认生成领域 skill；不要因为 rules 足够短或足够稳定就跳过领域入口。
- 除 `context` 和 `commands` 外，不预设固定 skill 清单。领域 skill 名称应来自当前项目的目录、rules 文件名、技术栈和业务词汇。
- 不要在 SKILL.md 大段复写已有 rules。SKILL.md 应像导航页，详细规则和证据放 references。

## 领域 Skill 模板

```markdown
---
name: <domain>
description: "处理当前项目 <domain> 相关任务时使用；加载对应 rules、代表文件、验证命令和常见风险。"
---

# <Domain>

## 使用场景

- ...

## 执行规则

1. 先读相关 rule：`.claude/rules/<domain>.md`。
2. 再读目标文件和 `references/examples.md` 中列出的代表文件。
3. 按本领域执行顺序处理。
4. 修改后按 `commands` 选择验证命令。

## 不要做

- 不复制 rules 正文到本 skill。
- 不新增与项目现有模式冲突的抽象。

## 验证方式

- ...

## 证据

详见：
- `references/examples.md`
- `references/risks.md`（如存在）
```

## 基础领域 skills

| Skill | 生成条件 | 作用 |
|---|---|---|
| `context` | 完整 setup 默认生成或刷新 | 项目画像、技术栈、目录职责、领域索引、覆盖矩阵、setup report |
| `commands` | 有 package scripts、CI 或常用命令 | 选择验证命令、开发命令、发布命令 |

## 领域 skills

领域 skill 没有固定清单。按项目实际领域生成，例如：

- uniapp 项目可能是 `platform`、`components`、`store`、`brand`、`decoration`；
- 组件库可能是 `components`、`styling`、`docs`、`release`；
- CLI / 工具库可能是 `cli`、`config`、`commands`；
- 后台或 API 服务才可能需要 `api`、`data`、`jobs`。

不要因为示例里出现某个名字，就在不相关项目中生成它。

## references/examples.md 模板

```markdown
# Evidence

## <领域或模式>

来源：
- ...

观察：
- ...

规则强度：
- 强规则 / 稳定习惯 / 观察模式
```

不要把 examples 当作强规则。只有来自项目文档或多个一致实现的内容才能写成规则。

## context references

完整 setup 必须生成：

```text
.claude/skills/context/references/setup-report.md
.claude/skills/context/references/domains.md
.claude/skills/context/references/habits.md
```

`context/SKILL.md` 只保留项目画像摘要和导航；完整覆盖矩阵、证据等级、领域索引和编码习惯矩阵放 references。
