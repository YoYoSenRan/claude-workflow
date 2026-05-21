# claude-workflow 测试策略

本文档定义修改 skill 后如何验证没有破坏工作流。目标不是复制 `superpowers` 的完整测试矩阵，而是建立个人项目可维护的最小验收线。

---

## 1. 测试分层

```text
静态检查
  ↓
hook 冒烟测试
  ↓
skill 触发测试
  ↓
人工行为回归
```

### 1.1 静态检查

目的：不用启动 Claude，也能发现明显结构错误。

应检查：

- 每个 `skills/*/SKILL.md` 都有 frontmatter。
- frontmatter 至少包含 `name` 和 `description`。
- `name` 必须和目录名一致。
- 不允许 3 行空壳 skill。
- 不允许引用不存在的本地 skill。
- `using` 如果通过 hook 注入，就不能作为普通全局 skill 同步。
- `docs/architecture.md` 中列出的 skill 必须和实际文件一致，未实现的必须明确标注。

建议脚本：

```bash
bash tests/static/check-skills.sh
```

### 1.2 hook 冒烟测试

目的：确认 SessionStart hook 能输出 Claude Code 期望的 JSON，并注入 `using` 内容。

应检查：

- `node hooks/session-start.js` 退出码为 0。
- 输出是合法 JSON。
- 输出包含 `hookSpecificOutput.additionalContext`。
- 输出包含 `skills/using/SKILL.md` 的关键内容。

建议脚本：

```bash
node hooks/session-start.js
```

### 1.3 skill 触发测试

目的：验证自然语言 prompt 是否会触发正确 skill，并且没有先执行无关工具。

参考 `superpowers/tests/skill-triggering` 的形状，但本项目只保留最小集：

| 场景 | Prompt | 预期 |
|---|---|---|
| 清晰小改 | `把 README 标题改短一点` | 不触发 `plan` / `execute` / `debug` / `worktree`，读目标文件后最小修改 |
| 分析项目 | `先分析一下当前项目` | 触发 `think`，允许只读探索，不编辑文件 |
| 模糊重构 | `帮我重构一下这个模块` | 触发 `think`，先澄清范围，不编辑 |
| 写计划 | `按刚才确认的方案写一个实现计划` | 触发 `plan` |
| 执行计划 | `按 docs/plans/example.md 开始执行` | 触发 `execute`，先读计划并 critical review |
| 测试失败 | 带 stack trace 的测试失败 prompt | 触发 `debug`，先根因调查 |
| 完成声明 | `现在可以说完成了吗` | 触发 `verify`，要求新鲜证据 |
| 子代理调度 | `派个子代理 review 这个 diff` | 触发 `subagent`，限定子代理边界和输出格式 |

建议脚本：

```bash
bash tests/skill-triggering/run-test.sh
```

如果本机没有 `claude` CLI，脚本应跳过并说明原因，不应失败。

### 1.4 显式 skill 请求测试

目的：用户明确说“用 X skill”时，agent 必须先调用对应 skill，不能先动手。

测试项：

- `用 think 分析这个项目`
- `用 debug 排查这个报错`
- `用 plan 写实现计划`
- `用 execute 执行这个 plan`
- `用 verify 检查是否完成`

建议脚本：

```bash
bash tests/explicit-skill-requests/run-test.sh
```

---

## 2. 修改不同文件后的最低验证

| 修改范围 | 最低验证 |
|---|---|
| `hooks/session-start.js` | `node hooks/session-start.js`，检查 JSON 和 using 注入 |
| `skills/using/SKILL.md` | hook 冒烟测试 + 清晰小改反过度流程测试 + 显式 skill 请求测试 |
| `skills/think/SKILL.md` | 分析项目 prompt + 模糊实现 prompt |
| `skills/plan/SKILL.md` | 写计划 prompt + 静态 placeholder 检查 |
| `skills/execute/SKILL.md` | 有效 plan、缺失 plan、含糊 plan 三类 prompt |
| `skills/debug/SKILL.md` | stack trace prompt + 修复后验证 prompt |
| `skills/verify/SKILL.md` | 完成声明 prompt，确认要求新鲜验证 |
| `skills/finish/SKILL.md` | 收尾 prompt，确认出现安全选项且丢弃需确认 |
| `skills/review/SKILL.md` | review prompt，确认 Findings 先行 |
| `skills/worktree/SKILL.md` | worktree prompt，确认说明路径、分支、状态和清理方式 |
| `skills/subagent/SKILL.md` | subagent prompt，确认不交出用户确认、收尾和最终完成声明 |
| `scripts/sync.sh` | `DRY_RUN=1 bash scripts/sync.sh` |
| `docs/architecture.md` | 静态检查 skill 列表和实际文件一致 |

---

## 3. 人工回归清单

自动化测试不能完全证明 agent 行为稳定。每次大改主流程 skill 后，至少人工跑以下会话：

### 3.1 分析类

Prompt：

```text
先分析一下当前项目
```

预期：

- 可以读取文件和 git 历史。
- 不要求用户先回答一堆问题。
- 不编辑文件。
- 输出结构化判断。

### 3.2 模糊实现类

Prompt：

```text
帮我优化一下这个模块
```

预期：

- 先指出范围不清。
- 给选项或追问。
- 不直接编辑。

### 3.3 明确小改

Prompt：

```text
把 skills/using/SKILL.md 第 3 行描述改短
```

预期：

- 读取目标文件。
- 只做指定小改。
- 不强行进入完整 plan 流程。

### 3.4 debug 类

Prompt：

```text
我的测试挂了：
FAIL src/parser.test.ts
TypeError: Cannot read property 'value' of undefined
  at parse src/parser.ts:42
```

预期：

- 读错误和相关代码。
- 复现或说明无法复现需要更多信息。
- 不先给“加个空值判断”这类症状修复。

---

## 4. 不通过时怎么处理

| 失败类型 | 处理 |
|---|---|
| 静态检查失败 | 先修结构，不跑行为测试 |
| hook 输出非法 JSON | 先修 hook，不同步 |
| skill 没触发 | 调整 frontmatter `description`，不要依赖非官方触发字段 |
| 触发后先动工具 | 调整 `using` 或对应 skill 的 hard gate |
| 分析类任务被迫先提问 | 调整 `think` 的分析模式 |
| `execute` 猜测计划含糊步骤 | 强化 blocker 规则 |
| 完成声明没有验证 | 强化 `verify` 触发和接入点 |

---

## 5. 发布 / 同步前检查

同步到全局前至少运行：

```bash
node hooks/session-start.js
bash tests/static/check-skills.sh
DRY_RUN=1 bash scripts/sync.sh
```

如果存在 Claude CLI，再运行：

```bash
bash tests/run-all.sh
```

只有以上检查通过后，才执行真实同步：

```bash
bash scripts/sync.sh
```
