# Changelog

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/), 版本号遵循 SemVer。

## [Unreleased]

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
