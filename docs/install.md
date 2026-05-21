# 安装与调试

本文档覆盖 npm scripts 快捷入口和底层 Claude Code plugin 命令。

---

## 本地开发调试

在仓库根目录运行：

```bash
npm run dev
```

这个方式不会安装插件，只在当前 Claude Code 会话加载当前仓库内容。适合改 skill、hook 后立即验证。

底层命令：

```bash
claude --plugin-dir .
```

---

## 本地安装

安装：

```bash
npm run install:local
```

卸载：

```bash
npm run uninstall:local
```

底层命令：

```bash
claude plugin marketplace add . --scope local
claude plugin install claude-workflow@yoyosenran-tools --scope local
claude plugin uninstall claude-workflow --scope local
claude plugin marketplace remove yoyosenran-tools
```

## GitHub marketplace 安装

安装到 user scope：

```bash
npm run install:user
```

卸载：

```bash
npm run uninstall:user
```

如果要用当前本地仓库作为 user scope marketplace 源：

```bash
claude plugin marketplace add . --scope user
claude plugin install claude-workflow@yoyosenran-tools --scope user
```

这个方式只适合调试 user scope 行为；日常本地调试优先用 `npm run dev` 或 `npm run install:local`。

底层命令：

```bash
claude plugin marketplace add https://github.com/YoYoSenRan/claude-workflow.git --scope user
claude plugin install claude-workflow@yoyosenran-tools --scope user
claude plugin uninstall claude-workflow --scope user
claude plugin marketplace remove yoyosenran-tools
```

更新：

```bash
claude plugin marketplace update yoyosenran-tools
claude plugin update claude-workflow
```

查看安装状态：

```bash
npm run plugin:list
claude plugin details claude-workflow
```

不要同时保留 local 和 user 两份同名 `yoyosenran-tools` marketplace。测试完 local 后先卸载，再安装 user scope。

---

## 验证

一键验证：

```bash
npm run validate
```

底层命令：

```bash
npm run check
claude plugin validate .claude-plugin/plugin.json
claude plugin validate .claude-plugin/marketplace.json
node hooks/session-start.js
node scripts/session-start.js
node .claude/hooks/session-start.js
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
