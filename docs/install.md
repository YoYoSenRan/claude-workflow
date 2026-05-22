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
claude plugin install claude-workflow@claude-workflow --scope user
claude plugin uninstall claude-workflow@claude-workflow --scope user
claude plugin marketplace remove claude-workflow
```

这个方式会把当前仓库快照复制到 Claude Code 插件缓存；修改本仓代码后需要重新安装，或用 `npm run dev` 直接加载当前仓库。

插件安装后不会把 skills、agents、hooks 展开到 `~/.claude/skills`、`~/.claude/agents` 或全局 `settings.json` 的 hooks 里。Claude Code 会把插件内容放在 `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`，并在运行时从插件系统加载。

确认安装内容：

```bash
claude plugin list
claude plugin details claude-workflow@claude-workflow
```

如果本地仓库内容改了，重新运行 `npm run install:dev`。该命令会先卸载 user scope 中旧的 `claude-workflow`，再按当前仓库重新安装，避免旧缓存继续生效。

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
claude plugin install claude-workflow@claude-workflow --scope user
claude plugin uninstall claude-workflow@claude-workflow --scope user
claude plugin marketplace remove claude-workflow
```

更新：

```bash
npm run update
```

底层命令：

```bash
claude plugin marketplace update claude-workflow
claude plugin update claude-workflow@claude-workflow --scope user
```

查看安装状态：

```bash
npm run plugin:list
claude plugin details claude-workflow@claude-workflow
```

当前插件故意不写 `.claude-plugin/plugin.json` 或 `.claude-plugin/marketplace.json` 的 `version`。GitHub 安装时，Claude Code 会使用 Git commit SHA 作为版本判断依据；只要 GitHub 仓库有新 commit，执行上面的更新命令就能检测到变化。

如果以后在 manifest 里写入 semver `version`，更新判断会优先使用该字段。那时每次发布都必须同步提升版本号，否则即使 GitHub 有新 commit，插件也可能被判定为已是最新版。

更新后需要重启 Claude Code，或在会话内执行 `/reload-plugins`，让新的 skills、agents、hooks 生效。

不要同时注册本地路径和 GitHub 两份同名 `claude-workflow` marketplace。切换来源前先卸载，再安装另一种来源。

---

## 验证

一键验证：

```bash
npm run validate
```

底层命令：

```bash
claude plugin validate .claude-plugin/plugin.json
claude plugin validate .claude-plugin/marketplace.json
node hooks/session-start.js
node scripts/session-start.js
```
