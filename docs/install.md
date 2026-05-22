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

## 本地仓库安装

从当前仓库安装到 user scope，所有 Claude Code 项目都会生效：

```bash
npm run install:dev
```

卸载：

```bash
npm run uninstall
```

底层命令：

```bash
claude plugin marketplace add ./ --scope user
claude plugin install claude-workflow@yoyosenran-tools --scope user
claude plugin uninstall claude-workflow --scope user
claude plugin marketplace remove yoyosenran-tools
```

这个方式会把当前仓库快照复制到 Claude Code 插件缓存；修改本仓代码后需要重新安装，或用 `npm run dev` 直接加载当前仓库。

## GitHub marketplace 安装

安装到 user scope：

```bash
npm run install:github
```

卸载：

```bash
npm run uninstall
```

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

不要同时注册本地路径和 GitHub 两份同名 `yoyosenran-tools` marketplace。切换来源前先卸载，再安装另一种来源。

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
