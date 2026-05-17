# claude-workflow

我自己的 Claude Code skills / agents / MCP servers / CLI 工具的源代码仓库。本地通过 symlink 接入 `~/.claude/`, 改即生效。

## 目录结构

```
claude-workflow/
├── skills/         个人 skill (SKILL.md + references/ + tests/)
├── agents/         自定义子代理
├── commands/       slash 命令 (Anthropic 已标 legacy, 优先用 skill)
├── mcps/           自写 MCP server (TypeScript/Python)
├── tools/          CLI 辅助 (跟 Claude 解耦)
├── scripts/        仓库管理 (install/uninstall/validate/new-skill)
├── docs/           项目级文档
└── .claude-plugin/ (可选) marketplace.json 用于公开发布
```

## 安装

```bash
# clone 后
bash scripts/install.sh

# 看会改啥不真改
DRY_RUN=1 bash scripts/install.sh

# 卸载 (只清本仓建的 symlink)
bash scripts/install.sh --unlink
```

`install.sh` 行为 —
- per-item symlink 到 `~/.claude/{skills,agents,commands}/<name>`
- 已存在的真目录 → 时间戳备份, 不覆盖
- 已是本仓 symlink → 跳过 (幂等)
- **永不动 `settings.json` / `.credentials.json`** (用户私产)

## 开发新 skill

```bash
bash scripts/new-skill.sh my-skill
# 填 skills/my-skill/SKILL.md
python3 scripts/validate-skill.py skills/my-skill
bash scripts/install.sh    # 建 symlink
# Claude Code 2.1.0+ 自动 hot-reload, 改 SKILL.md 即生效
```

## 校验

```bash
# 全部 skill
python3 scripts/validate-skill.py

# 单个
python3 scripts/validate-skill.py skills/search
```

校验项: frontmatter 完整 / name 规范 / 字符预算 (<13K 软上限) / references 链接 / 无 PII / tests/examples 非空。

## 调试

详见 `docs/debugging.md` — 字符预算 / hot-reload / 不触发的 4 种原因 / symlink 已知 bug。

## 现有内容

| 类型 | 名字 | 版本 |
|---|---|---|
| skill | search | 1.1.0 |

## 写给自己的约定

- 改 SKILL.md 后, 至少跑该 skill 的 `tests/examples/01-*.md` 一遍
- 名字 kebab-case, 不含 `anthropic` / `claude`
- SKILL.md 控制在 ~13KB 内, 详细内容推 `references/`
- credentials / 会话历史 / 项目状态 永不入库 (见 `.gitignore`)
- 整目录 symlink `~/.claude` 是雷区 (#11344/#764/#14836/#50886), 永远 per-item
