# Changelog

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/), 版本号遵循 SemVer。

## [Unreleased]

## [0.2.0] — 2026-05-17

### 重构 — 改用"项目级 + sync 拷贝"双轨, 弃 symlink
- 目录: `skills/` `agents/` `commands/` → `.claude/skills/` `.claude/agents/` `.claude/commands/`
- 开发期: cd 进仓库, Claude 项目级自动加载 .claude/, hot-reload 实时
- 完成期: `scripts/sync.sh` 拷贝到 `~/.claude/`, 全局可用, 副本独立于仓库
- `.synced_from` 标记来源, `sync.sh --uninstall` 据此识别清除

### 删
- `scripts/install.sh` (symlink 模式) — 仓库被删全局也死, 已被 sync 替代

### 加
- `scripts/sync.sh` — rsync 增量拷贝, 含 DRY_RUN 和 --uninstall

### 调
- `scripts/validate-skill.py` 扫 `.claude/skills/` 而非 `skills/`
- `scripts/new-skill.sh` 输出到 `.claude/skills/<name>/`

## [0.1.0] — 2026-05-17

### 新增
- 仓库骨架: `skills/` `agents/` `commands/` `mcps/` `tools/` `scripts/` `docs/`
- `scripts/install.sh` — per-item symlink, obra/clank 模式, 幂等, 含 DRY_RUN 和 `--unlink`
- `scripts/validate-skill.py` — frontmatter / name / 字符预算 / 链接 / PII / examples 校验
- `scripts/new-skill.sh` — 从模板初始化新 skill
- `skills/search` — 迁入, v1.1.0
  - 通用深度调研 P0-P5 流程
  - 技术调研专项 TR-1 至 TR-7
  - 3 个 tests/examples cases
- `docs/conventions.md` — frontmatter / 命名 / 字符预算约定
- `docs/testing-guide.md` — examples 怎么写, 验收逻辑
- `docs/debugging.md` — hot-reload / 字符预算 / 不触发诊断 / symlink bug 警示
- `.gitignore` — 排除 credentials, 会话历史, 缓存等用户私产
