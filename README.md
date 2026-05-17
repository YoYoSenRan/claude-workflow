# claude-workflow

我的 Claude Code skills / agents / MCP servers / CLI 工具仓库。

## 工作流: 项目级开发 → 同步到全局

```
开发期: cd 进仓库 → Claude 自动加载 .claude/ 项目级 → hot-reload 实时调试
完成期: bash scripts/sync.sh → 拷贝到 ~/.claude/ 全局, 任何项目都能用
```

**关键** — 全局是真拷贝, 不是 symlink。仓库被删 → 全局副本不受影响。

## 目录结构

```
claude-workflow/
├── skills/                     ✦ 真源 (跟主流仓 obra/daymade 一致)
│   └── search/                 SKILL.md + references/ + tests/
├── agents/                     真源 (暂空)
├── commands/                   真源 (暂空)
│
├── .claude/                    项目级激活点, 内容是相对 symlink 指向真源
│   ├── skills/
│   │   └── search → ../../skills/search
│   ├── agents/                 (暂空)
│   └── commands/               (暂空)
│
├── mcps/                       自写 MCP server (暂空)
├── tools/                      CLI 辅助 (暂空)
│
├── scripts/                    仓库管理
│   ├── sync.sh                 skills/agents/commands → ~/.claude/ 拷贝
│   ├── validate-skill.py       静态校验
│   └── new-skill.sh            建真目录 + .claude/ 相对 symlink
│
└── docs/                       项目文档
    ├── conventions.md
    ├── testing-guide.md
    └── debugging.md
```

**两个目录的分工** —
- **根目录 `skills/ agents/ commands/`** = 真源, git 跟踪, 编辑这里
- **`.claude/skills/...`** = 相对 symlink, 让 Claude Code 进入仓库时项目级加载到真源

## 开发流程

```bash
# 1. cd 进仓库, Claude Code 会自动加载本仓 .claude/skills/ (symlink 透明到 skills/)
cd ~/WebProject/claude-workflow

# 2. 改真源 (不要改 .claude/skills/, 那是 symlink 入口, 改谁都一样)
vim skills/search/SKILL.md   # hot-reload 实时生效 (Claude Code 2.1.0+)

# 3. 校验
python3 scripts/validate-skill.py

# 4. 跑测 (开新 Claude 会话, 粘 tests/examples/0X.md 的 Trigger Prompt)

# 5. 稳定后, sync 到全局
bash scripts/sync.sh
```

## 同步命令

```bash
bash scripts/sync.sh                # 真拷贝 .claude/* → ~/.claude/*
DRY_RUN=1 bash scripts/sync.sh      # 干跑, 看会改啥
bash scripts/sync.sh --uninstall    # 移除本仓 sync 过去的内容 (识别 .synced_from 标记)
```

## 加新 skill

```bash
bash scripts/new-skill.sh my-skill
# 自动建:
#   skills/my-skill/{SKILL.md, references/, tests/examples/}   ← 真源
#   .claude/skills/my-skill → ../../skills/my-skill            ← 相对 symlink
# 填 SKILL.md
python3 scripts/validate-skill.py skills/my-skill
# 开发期: cd 进仓库测; 稳定后 bash scripts/sync.sh
```

## 校验

```bash
python3 scripts/validate-skill.py                # 全部
python3 scripts/validate-skill.py skills/search  # 单个
```

校验项: frontmatter / name 规范 / 字符预算 (<13K) / references 死链 / PII / tests/examples 非空。

## 调试

详见 `docs/debugging.md` — hot-reload / 字符预算 / 不触发的 4 种原因。

## 现有内容

| 类型 | 名字 | 版本 |
|---|---|---|
| skill | search | 1.1.0 |

## 设计原则

- **拷贝, 不 symlink** — 仓库被删, 全局不死
- **项目级 + 全局** 双轨 — 开发期项目级 (cd 触发, hot-reload), 完成期全局 (sync 拷贝)
- **per-item 操作**, 永不整目录 (规避 #11344/#764/#14836/#50886)
- **永不动 `~/.claude/settings.json`** (用户私产)
- 凭证 / 会话历史 / 缓存 永不入库 (见 `.gitignore`)
