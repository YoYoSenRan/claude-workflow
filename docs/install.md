# 安装与调试

本文档覆盖两种使用方式：本地开发调试和通过 GitHub marketplace 安装。

---

## 本地开发调试

在任意测试项目里运行：

```bash
claude --plugin-dir /Users/macos/WebProject/claude-workflow
```

这个方式不会安装插件，只在当前 Claude Code 会话加载当前仓库内容。适合改 skill、hook 后立即验证。

验证插件结构：

```bash
claude plugin validate /Users/macos/WebProject/claude-workflow/.claude-plugin/plugin.json
```

验证本地 marketplace：

```bash
claude plugin validate /Users/macos/WebProject/claude-workflow/.claude-plugin/marketplace.json
```

---

## GitHub marketplace 安装

先添加 marketplace：

```bash
claude plugin marketplace add YoYoSenRan/claude-workflow
```

再安装插件：

```bash
claude plugin install claude-workflow@yoyosenran-tools
```

查看安装状态：

```bash
claude plugin list
claude plugin details claude-workflow
```

更新 marketplace 和插件：

```bash
claude plugin marketplace update yoyosenran-tools
claude plugin update claude-workflow
```

---

## 项目级软链接模式

当前仓库还保留 `.claude/` 目录，作为本仓开发时的项目级测试入口：

```text
.claude/settings.json
.claude/hooks/session-start.js -> ../../hooks/session-start.js
.claude/skills/* -> ../../skills/*
```

这个模式只用于本仓开发测试；跨项目复用优先使用 plugin 模式。
