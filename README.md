# Claude Workflow

面向 Claude Code 的中文工作流插件。它提供一组轻量但有边界的 skills，用来约束常见开发流程：先判断任务类型，再选择最小足够流程，避免小任务被流程化、模糊需求被盲改、完成声明缺少验证。

这个仓库借鉴 `superpowers` 的行为约束思路，但目标不是做完整 fork，而是保留个人开发中最常用的路径，并针对 Claude Code 使用方式简化。

## 包含的 skills

| Skill | 作用 |
|---|---|
| `using` | 会话入口路由规则；由 SessionStart hook 注入，也作为项目级 skill 暴露 |
| `think` | 只读分析、方案判断、模糊需求澄清 |
| `plan` | 将已确认需求写成可执行计划 |
| `execute` | 按已批准计划逐步执行，不擅自改计划 |
| `debug` | 报错、测试失败、异常行为的根因调查与修复 |
| `verify` | 完成声明前的新鲜证据检查 |
| `finish` | 提交、PR、保留、丢弃等收尾决策 |
| `review` | 代码评审和评审反馈处理，Findings 先行 |
| `worktree` | 隔离工作区规则 |
| `subagent` | Claude Code subagent 调度边界和提示模板 |

## 安装方式

### 本地开发调试

不安装插件，只在当前 Claude Code 会话加载本仓库：

```bash
claude --plugin-dir /Users/macos/WebProject/claude-workflow
```

适合改 skill 或 hook 后快速测试。插件内 skill 会以插件命名空间出现，例如 `claude-workflow:think`。

### GitHub marketplace 安装

添加 marketplace：

```bash
claude plugin marketplace add https://github.com/YoYoSenRan/claude-workflow.git
```

安装插件：

```bash
claude plugin install claude-workflow@yoyosenran-tools
```

查看安装状态：

```bash
claude plugin list
claude plugin details claude-workflow
```

更新：

```bash
claude plugin marketplace update yoyosenran-tools
claude plugin update claude-workflow
```

本机测试完整安装流程：

```bash
claude plugin marketplace add /Users/macos/WebProject/claude-workflow
claude plugin install claude-workflow@yoyosenran-tools --scope local
```

或者使用 npm scripts：

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

### 全局拷贝模式

如果不走 plugin 安装，也可以把当前仓库内容同步到 `~/.claude`：

```bash
DRY_RUN=1 bash scripts/sync.sh
bash scripts/sync.sh
```

`sync.sh` 会同步 `skills/` 和全局需要的 `hooks/session-start.js`。插件专用的 `hooks/hooks.json` 不会同步到全局 hooks 目录。

## 本仓开发入口

仓库内保留 `.claude/` 项目级软链接结构，用于开发本仓时直接测试：

```text
.claude/settings.json
.claude/hooks/session-start.js -> ../../hooks/session-start.js
.claude/skills/* -> ../../skills/*
```

跨项目复用优先使用 plugin 模式；`.claude/` 主要是本仓开发便利层。

## 目录结构

```text
.claude-plugin/
  plugin.json
  marketplace.json
.claude/
  settings.json
  hooks/
  skills/
hooks/
  hooks.json
  session-start.js
scripts/
  session-start.js -> ../hooks/session-start.js
  sync.sh
skills/
  using/
  think/
  plan/
  execute/
  debug/
  verify/
  finish/
  review/
  worktree/
  subagent/
docs/
  architecture.md
  install.md
  testing.md
tests/
  static/
  skills/
```

## 验证

验证插件 manifest：

```bash
claude plugin validate /Users/macos/WebProject/claude-workflow/.claude-plugin/plugin.json
```

验证 marketplace manifest：

```bash
claude plugin validate /Users/macos/WebProject/claude-workflow/.claude-plugin/marketplace.json
```

验证 hook 输出：

```bash
node hooks/session-start.js
node scripts/session-start.js
node .claude/hooks/session-start.js
```

运行静态检查：

```bash
bash tests/static/check-skills.sh
```

同步前预演：

```bash
DRY_RUN=1 bash scripts/sync.sh
```

## 设计原则

- 小任务不要强制进入完整流程。
- 模糊需求先澄清，不盲改。
- 已批准计划才进入 `execute`。
- bug 和测试失败先找根因。
- 完成、修好、通过必须有新鲜验证证据。
- 子代理只做边界清晰的辅助任务，不替主智能体做最终决策。

## 相关文档

- [架构基线](docs/architecture.md)
- [安装与调试](docs/install.md)
- [测试策略](docs/testing.md)
- [Changelog](CHANGELOG.md)
- [中文更新日志](CHANGELOG.zh-CN.md)
