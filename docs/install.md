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
claude plugin marketplace add https://github.com/YoYoSenRan/claude-workflow.git
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

如果只想在本机测试完整安装流程，可以添加本地 marketplace：

```bash
claude plugin marketplace add /Users/macos/WebProject/claude-workflow
claude plugin install claude-workflow@yoyosenran-tools --scope local
```

也可以使用 npm scripts：

```bash
npm run plugin:add-local
npm run plugin:install-local
npm run plugin:list
npm run plugin:details
```

卸载本地测试安装：

```bash
claude plugin uninstall claude-workflow --scope local
claude plugin marketplace remove yoyosenran-tools
```

对应 npm scripts：

```bash
npm run plugin:uninstall-local
npm run plugin:remove-local-marketplace
```

全局 user scope 安装：

```bash
claude plugin marketplace add https://github.com/YoYoSenRan/claude-workflow.git --scope user
claude plugin install claude-workflow@yoyosenran-tools --scope user
```

对应 npm scripts：

```bash
npm run plugin:add-user
npm run plugin:install-user
```

如果要用当前本地仓库作为 user scope marketplace 源：

```bash
npm run plugin:add-user-local-source
npm run plugin:install-user
```

卸载全局 user scope 安装：

```bash
claude plugin uninstall claude-workflow --scope user
claude plugin marketplace remove yoyosenran-tools
```

对应 npm scripts：

```bash
npm run plugin:uninstall-user
npm run plugin:remove-user-marketplace
```

不要同时保留 local 和 user 两份同名 `yoyosenran-tools` marketplace。测试完 local 后先移除，再添加 user scope。

---

## 项目级软链接模式

当前仓库还保留 `.claude/` 目录，作为本仓开发时的项目级测试入口：

```text
.claude/settings.json
.claude/hooks/session-start.js -> ../../hooks/session-start.js
.claude/skills/* -> ../../skills/*
```

这个模式只用于本仓开发测试；跨项目复用优先使用 plugin 模式。
