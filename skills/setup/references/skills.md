# Skill Generation

本参考用于生成 `.claude/skills/<name>`。skill 是按需加载的项目任务能力，负责告诉模型在某类任务中加载哪些 rules、阅读哪些代表文件、按什么顺序处理、用什么命令验证。

## 基本规则

- `SKILL.md` 保持短，写触发条件、执行规则和 references 入口。
- `description` 只写何时触发，不写完整流程。
- 长示例、证据、文件清单、扫描报告放 `references/`。
- 每个 skill 必须说明适用场景、执行规则、不要做、验证方式。
- skill 必须能改变模型下一步行为：知道何时加载、先读什么、怎么改、怎么验证、哪些边界不能碰。
- 每个生成项必须有证据来源；证据不足的候选只进入内部账本，默认不向用户解释该项。
- 已有 rules 可以被 skill 引用，但不能替代 skill。skill 的价值是按需加载任务入口、操作顺序、证据索引和验证选择。
- 高频开发领域不等于必须生成 skill。只有该领域有明确任务触发、重复执行步骤、项目特有风险或核心框架协议时，才生成 skill。
- 从当前项目真实任务能力、核心框架、工作流程或高频领域中提取 skill 名称。
- 不要在 SKILL.md 大段复写已有 rules。SKILL.md 应像导航页，详细规则和证据放 references。
- 候选进入 skill 前，必须写清它如何帮助模型防止改错、少问路、写得像项目、正确验证或降低重复扫描成本。

## Skill 模板

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
4. 修改后按项目验证 reference 或验证类 skill 选择命令。

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

## Reference 优先项

先按 reference 处理项目画像和命令清单；只有它们具备明确任务触发和执行步骤时，才升级为 skill。

| 候选 | 什么时候才生成 skill | 否则放哪里 |
|---|---|---|
| 项目上下文 / 项目画像 | 用户有明确“理解项目 / 任务路由 / 新人导航”触发，且它定义了加载顺序和决策步骤 | `.claude/references/setup-report.md`、`.claude/references/domains.md`、`.claude/references/habits.md` |
| 命令 / 验证方式 | 它不只是命令清单，而能根据改动类型选择验证策略、构建端、品牌、风险检查 | `.claude/references/commands.md` 或 `commands.md` rule |

## 生成价值过滤

生成 skill 前逐项检查：

| 问题 | 必须能回答 |
|---|---|
| 任务触发 | 用户说什么任务时应该加载它 |
| 执行顺序 | 加载后模型按什么顺序工作 |
| 项目差异 | 这个项目和通用做法哪里不同 |
| 验证方式 | 改完后应该如何验证 |
| 失败风险 | 不加载它时模型最可能改错什么 |

答不出来时，不生成 skill；相关证据只放 reference 或 internal。

## 项目 skills

skill 没有固定清单。按项目真实任务能力、核心框架、工作流程或高频领域生成，例如：

- uniapp 项目可能是 `platform`、`components`、`store`、`brand`、`decoration`；
- 组件库可能是 `components`、`styling`、`docs`、`release`；
- CLI / 工具库可能是 `cli`、`config`、`release`、`verification`；
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

## setup references

完整 setup 必须形成这些 references 候选：

```text
.claude/references/setup-report.md
.claude/references/domains.md
.claude/references/habits.md
```

如果最终生成了某个相关 skill，可以把 references 放入 `.claude/skills/<name>/references/`。没有任务触发和执行步骤的资料，直接放 `.claude/references/`。
