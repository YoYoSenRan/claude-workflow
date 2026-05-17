# Debugging

调试 skill 的常见坑 + 诊断步骤。基于 Task B / D 的调研结果。

## 三种 skill 作用域

本仓采用 **项目级开发 + 全局拷贝** 双轨:

```
1. ~/项目/.claude/skills/X/SKILL.md    项目级 (cd 进项目自动加载)
2. ~/.claude/skills/X/SKILL.md         全局 (任何项目都能用)
3. plugin 装的                          通过 /plugin install
```

优先级: 项目级 > 全局 > plugin

**本仓**:
- `~/WebProject/claude-workflow/skills/X/` ← 真源, 编辑这里
- `~/WebProject/claude-workflow/.claude/skills/X` → `../../skills/X` ← 相对 symlink, 项目级激活点
- `~/.claude/skills/X/` ← `sync.sh` 拷贝来的副本, 全局生效

**已知噪声 (#25367)** — symlink 的 skill 在 slash-command init 阶段报 `Unknown skill`, 但执行 OK。等 Anthropic 修, 不影响使用。

## Hot Reload

**Claude Code 2.1.0+ (2026-01-07 发布) 已内置 hot-reload** —

```
改 skills/X/SKILL.md  →  下一条 prompt 即生效 (cd 在仓库内, 项目级激活)
```

不需要重启会话, 不需要 `/reload`。Claude Code 下次发 prompt 时自动 pick up。

**编辑铁律** — 改根目录 `skills/X/` 真源, 不要改:
- `.claude/skills/X/` (是 symlink, 改了等于改根 skills/, 无差; 但概念混乱)
- `~/.claude/skills/X/` (是 sync 来的拷贝, 下次 sync 会覆盖)

**例外**: 通过 `/plugin install` 装的 plugin **不享受 hot-reload** (bug #35641 — 必须全重启)。

## 字符预算 (Silent Drop)

**头号杀手** — `SLASH_COMMAND_TOOL_CHAR_BUDGET` 默认 **15000** 字符 (~4k tokens)。

SKILL.md 超了 → **silent drop**, Claude 完全看不到这个 skill, 不报错。

诊断 —

```bash
# 看每个 SKILL.md 字节数
find ~/.claude/skills -name SKILL.md -exec wc -c {} \; | sort -n

# 本仓 (跟着 symlink)
find /Users/macos/WebProject/claude-workflow/skills -name SKILL.md -exec wc -c {} \; | sort -n
```

本仓 `validate-skill.py` 软上限设 13000 (留余量, 强制)。

临时提预算 —
```bash
SLASH_COMMAND_TOOL_CHAR_BUDGET=30000 claude
```

但治本是**把细节推到 references/**, 不靠加预算。

## "Skill 装了但不触发" 4 种原因

按出现频率排:

### ① description / when_to_use 不够"推力"
最常见。Claude 倾向 undertrigger。

修法 — frontmatter 描述要"推力强" + 写明何时用 + 写明何时不用:
```yaml
description: "{做什么}. Use when {场景 X}. 与 /{相邻 skill} 区分: ... Not for {不适用}."
when_to_use: "触发词1, 触发词2, ..."
```

### ② 字符预算超了 (见上)
诊断: `wc -c` SKILL.md, 看是不是 > 15000。

### ③ Symlink 整目录 (踩 bug)
若 `~/.claude` **整个目录**是 symlink (而不是各 item 是 symlink), 触发 4 个 bug:
- #11344: slash 命令重复
- #764 / #14836: skill 静默丢失 (扫描器没用 `find -L`)
- #50886: Windows OneDrive EEXIST 崩溃

**修法** — 永远 per-item symlink (本仓 `install.sh` 就是这样做)。

### ④ Plugin 装了但没 enabled
`/plugin install` 装的可能落在 `installed_plugins.json` 但没进 `enabledPlugins` (bug #17832)。

诊断:
```bash
jq '.installedPlugins, .enabledPlugins' ~/.claude.json
```

## "改了不生效" 诊断

```bash
# ① 看是否项目级生效 (cd 进仓库内开会话)
ls .claude/skills/<name>/SKILL.md

# ② 看全局副本是否最新 (sync 后)
cat ~/.claude/skills/<name>/.synced_from
# 应输出: /Users/.../claude-workflow

diff -q .claude/skills/<name>/SKILL.md ~/.claude/skills/<name>/SKILL.md
# 没输出 = 已同步; 有 diff = 需要 bash scripts/sync.sh

# ③ 字符预算
wc -c .claude/skills/<name>/SKILL.md

# ④ frontmatter 合法
python3 scripts/validate-skill.py .claude/skills/<name>

# ⑤ 2.1.0+ hot-reload 是否启用
claude --version    # 看版本
```

## "Unknown skill: X" Init 噪声

bug #25367 — symlink 的 skill 在 slash-command init 阶段会报 `Unknown skill: <name>`, 但执行阶段正常。

**当前** — 噪声, 忽略即可。Claude 仍能用 skill。

## 不要做的诊断

- ❌ 重复 `claude plugin reload` — bug #35641, 新 plugin 必须全重启
- ❌ 整目录 symlink `~/.claude` 想省事 — 4 个 bug 等着
- ❌ 把 settings.json 入库 — 含 OAuth token, 安全 + 同步冲突
- ❌ chezmoi 管 `~/.claude` 而你手改 settings.json — 下次 apply 冲突

## 工具速查

| 工具 | 干啥 |
|---|---|
| `wc -c SKILL.md` | 字符预算检测 |
| `cat ~/.claude/skills/X/.synced_from` | 看全局副本是哪个仓库 sync 来的 |
| `diff -q .claude/skills/X/SKILL.md ~/.claude/skills/X/SKILL.md` | 看仓库 vs 全局是否同步 |
| `validate-skill.py` | 静态校验 |
| `sync.sh --uninstall` | 移除本仓 sync 过去的副本 |
| `DRY_RUN=1 sync.sh` | 看会改啥不真改 |
| `tests/examples/*.md` 手动跑 | 行为回归 |
