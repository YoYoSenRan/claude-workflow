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
npm run dev
```

适合改 skill 或 hook 后快速测试。插件内 skill 会以插件命名空间出现，例如 `claude-workflow:think`。

### 安装到本机

在本机测试完整安装流程：

```bash
npm run install:local
```

卸载：

```bash
npm run uninstall:local
```

### 安装到用户全局

从 GitHub marketplace 安装到 user scope：

```bash
npm run install:user
```

卸载：

```bash
npm run uninstall:user
```

查看安装状态：

```bash
npm run plugin:list
```

不要同时保留 local 和 user 两份同名 `yoyosenran-tools` marketplace。测试完 local 后先卸载，再安装 user scope。更细的调试命令见 [安装与调试](docs/install.md)。

### 手动命令

底层 `claude plugin ...` 命令见 [安装与调试](docs/install.md)。

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

运行完整验证：

```bash
npm run validate
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
