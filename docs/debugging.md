# Debugging

调试 skill 的常见坑 + 诊断步骤。基于 Task B / D 的调研结果。

## Hot Reload

**Claude Code 2.1.0+ (2026-01-07 发布) 已内置 hot-reload** —

```
改 ~/.claude/skills/X/SKILL.md  →  下一条 prompt 即生效
```

不需要重启会话, 不需要 `/reload`。只要 `~/.claude/skills/X/` 的内容变了 (含 symlink 指向的源文件), Claude Code 下次发 prompt 时自动 pick up。

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
# ① 确认 symlink 指对地方
ls -la ~/.claude/skills/<name>
# 应输出: -> /Users/.../claude-workflow/skills/<name>

# ② 确认改的是源不是副本
realpath ~/.claude/skills/<name>/SKILL.md
# 应指向仓库, 不是本地

# ③ 字符预算
wc -c ~/.claude/skills/<name>/SKILL.md

# ④ frontmatter 合法
python3 /Users/macos/WebProject/claude-workflow/scripts/validate-skill.py \
  /Users/macos/WebProject/claude-workflow/skills/<name>

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
| `realpath ~/.claude/skills/X/SKILL.md` | 找真源文件 |
| `validate-skill.py` | 静态校验 |
| `install.sh --unlink` | 干净卸载本仓 symlink |
| `DRY_RUN=1 install.sh` | 看会改啥不真改 |
| `tests/examples/*.md` 手动跑 | 行为回归 |
