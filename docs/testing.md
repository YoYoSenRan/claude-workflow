# claude-workflow 测试策略

本文档只定义确定性测试。模型行为受上下文、模型版本、插件状态和当前工作区影响，不把 prompt 行为样例作为测试。

---

## 1. 静态检查

目的：不用启动 Claude，也能发现明显结构错误。

应检查：

- 每个 `skills/*/SKILL.md` 都有 frontmatter。
- frontmatter 至少包含 `name` 和 `description`。
- `name` 必须和目录名一致。
- 不允许 3 行空壳 skill。
- 不允许引用不存在的本地 skill。
- `docs/architecture.md` 中列出的 skill 必须和实际文件一致。
- `.claude/skills/*` 项目级软链接必须指向根目录 `skills/*`。
- plugin manifest、marketplace manifest、hook config 必须存在。
- plugin hook 必须使用 `${CLAUDE_PLUGIN_ROOT}`。

运行：

```bash
bash tests/static/check-skills.sh
```

---

## 2. Hook 冒烟测试

目的：确认 SessionStart hook 能输出 Claude Code 期望的 JSON，并注入 `using` 内容。

应检查：

- `node hooks/session-start.js` 退出码为 0。
- 输出是合法 JSON。
- 输出包含 `hookSpecificOutput.additionalContext`。
- 输出包含 `skills/using/SKILL.md` 的关键内容。

运行：

```bash
node hooks/session-start.js
node scripts/session-start.js
node .claude/hooks/session-start.js
```

---

## 3. Plugin Manifest 验证

运行：

```bash
claude plugin validate .claude-plugin/plugin.json
claude plugin validate .claude-plugin/marketplace.json
```

---

## 4. 一键验证

发布或安装前运行：

```bash
npm run validate
```

当前不维护 prompt 行为测试。需要判断 skill 是否好用时，按人工使用结果调整 `description`、`using` 路由或对应 skill 正文。
