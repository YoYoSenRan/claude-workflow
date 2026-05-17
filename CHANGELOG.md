# Changelog

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/), 版本号遵循 SemVer。

## [Unreleased]

## [0.4.0] — 2026-05-17

### 重构 — tests 抽顶级, 镜像根结构
- `skills/<name>/tests/` → `tests/skills/<name>/` (顶级 tests/ 目录)
- 同时建 `tests/agents/` `tests/mcps/` `tests/tools/` 占位, 未来加测都进顶级 tests/
- skills 包内只剩功能内容 (SKILL.md + references/), 不再混测试

### 调
- `scripts/validate-skill.py` 检查路径改为 `tests/skills/<name>/examples/`
- `scripts/new-skill.sh` 同时建真目录 + tests 同名目录 + symlink, 三件套

### 改动
- 文档全部反映 tests 新位置

## [0.3.0] — 2026-05-17

### 重构 — `skills/` 回根目录 + `.claude/skills/` 相对 symlink
- 跟主流仓 (obra/superpowers, daymade/claude-code-skills, anthropics/claude-plugins-official) 结构对齐
- `skills/<name>/` 真源 — git 跟踪, 编辑这里
- `.claude/skills/<name> → ../../skills/<name>` 相对 symlink, 项目级激活点
- 跨机 clone 后路径仍然解析 (相对路径不写死绝对位置)
- 未来发 marketplace plugin 友好 (skills/ 在根是默认期望)

### 调
- `scripts/sync.sh` SRC 改 `$REPO_ROOT` (从根读 skills/), 不走 .claude/ symlink
- `scripts/new-skill.sh` 同时建真目录 + 相对 symlink
- `scripts/validate-skill.py` 扫 `skills/` 而非 `.claude/skills/`
- 文档全部反映新分工

### 加
- 各空目录 (`agents/` `commands/` `mcps/` `tools/` `.claude/agents/` `.claude/commands/`) 加 `.gitkeep` 占位

### 已知问题 (#25367 调研已知)
- per-item symlink 在 slash-command init 阶段报 `Unknown skill` 噪声, 不影响功能, 等 Anthropic 修

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
