---
name: skill
description: "创建、修改或评审 Claude Workflow skill 时使用；包括 SKILL.md、description 触发边界、上下文重量、using 路由、架构同步和发布前验证。"
---

## 子代理辅助模式

被派遣评审 skill 时，用本 skill 的只读评审模式。只返回问题、证据和建议；不修改文件、批准发布或宣布 workflow 已完成。

# Skill 写作

skill 维护 Claude Workflow 本身。只处理 skill 的创建、修改、评审和测试，不处理普通业务代码。

## 何时使用

新增 / 修改 / 重命名 / 删除 skill；检查 skill 是否好用或会误触发；改 `skills/*/SKILL.md`、`skills/using/SKILL.md` 或 references；调整 `description`、触发边界、子代理边界或 using 路由；发布前检查结构。

不使用：普通代码实现 / debug / review；项目专属编码规范（放项目级 `CLAUDE.md` 或项目 skill）；能用脚本强制检查的机械规则（优先自动化）。

## 核心原则

- **值得才新增**：只有跨项目复用、会反复影响 agent 行为、且非项目专属知识时，才做全局 skill。
- **description 只写触发条件**，不总结流程，否则模型可能只按 description 行动而跳过正文。
- **正文只写当前 skill 职责**；跨 skill 跳转写在“与其他 skill 的关系”。
- **using 只做入口路由**；新增主流程 skill 时才更新 using 路由表。
- **只验证确定性结构**，不把 prompt 行为样例当测试。

## 新增 skill 清单

- [ ] 这个能力不是已有 skill 的一小段规则；
- [ ] 不是项目专属知识；
- [ ] 名称短清晰，目录名和 frontmatter `name` 一致；
- [ ] `description` 只描述何时使用；
- [ ] 正文含何时使用 / 何时不使用 / 流程 / 停止条件或验证方式；
- [ ] 含 `SUBAGENT-STOP` 或 `子代理辅助模式`；
- [ ] 如需入口路由，更新 `skills/using/SKILL.md`；
- [ ] 更新静态检查中的 expected skill 列表；
- [ ] 运行 `npm run validate`。

## 修改 skill 清单

先读当前文件，不凭记忆改。重点检查：触发条件是否过宽导致小改被流程化；是否把技术栈 / 框架 / 项目习惯写进全局 skill；是否与 think / plan / execute / debug / verify 职责重叠；是否引入无法验证的承诺；是否要求不存在的 agent / hook / command / 工具；是否让子代理承担主智能体决策。

## 常见错误

| 错误 | 修正 |
|---|---|
| 新增 skill 只为一个项目 | 放项目级 `CLAUDE.md` 或项目 skill |
| description 写完整流程 | 改成触发条件 |
| using 里复制所有 skill 细节 | using 只保留路由和调用纪律 |
| 把 prompt 样例当测试 | 只保留确定性静态检查；行为问题靠实际使用反馈调整 |
| skill 要求“始终”执行 | 写清例外和轻量路径 |
| 修改 skill 后不验证 hook | 运行 `npm run validate` |

## 与其他 skill 的关系

| 场景 | 使用 |
|---|---|
| 判断是否该新增 skill | `skill` |
| 写复杂实现计划 | `plan` |
| 执行 skill 改造计划 | `execute` |
| skill 行为异常或不触发 | `debug` |
| 完成前验证 skill 结构 | `verify` |
| 评审 skill diff | `review` |
