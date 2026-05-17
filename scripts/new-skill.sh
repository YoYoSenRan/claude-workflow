#!/usr/bin/env bash
# new-skill.sh — 从模板初始化新 skill
#
# 用法:
#   bash scripts/new-skill.sh <skill-name>
#   bash scripts/new-skill.sh search-news

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "用法: $0 <skill-name>"
  echo "  名字须 kebab-case, 不含 'anthropic'/'claude'"
  exit 1
fi

NAME="$1"

# 校验名字
if ! [[ "$NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "✗ 名字须 kebab-case (小写+数字+连字符): $NAME"
  exit 1
fi
if [[ "$NAME" == *anthropic* || "$NAME" == *claude* ]]; then
  echo "✗ 名字不可含 'anthropic' / 'claude'"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/$NAME"

if [[ -d "$SKILL_DIR" ]]; then
  echo "✗ 已存在: $SKILL_DIR"
  exit 1
fi

mkdir -p "$SKILL_DIR/references" "$SKILL_DIR/tests/examples"

cat > "$SKILL_DIR/SKILL.md" <<EOF
---
name: $NAME
description: "TODO: 一句话说明做什么, 何时触发, 不适合什么场景"
when_to_use: "TODO: 触发词, 中英混合 comma 分隔"
metadata:
  version: "0.1.0"
---

# ${NAME^}: TODO 标题

TODO: 简短描述

## 适用 / 不适用

| 适用 | 不适用 |
|---|---|
| TODO | TODO |

## 流程

TODO: 列出 phases

## 反模式

- ✗ TODO

## 文件清单

| 文件 | 何时加载 |
|---|---|
| references/TODO.md | TODO |
EOF

cat > "$SKILL_DIR/tests/examples/01-basic.md" <<EOF
# 01 — 基础触发

## Trigger Prompt
"TODO: 一句典型触发 prompt"

## Pre-conditions
- TODO

## Expected Behavior Checklist
- [ ] Claude 自动 invoke /$NAME
- [ ] TODO

## Anti-Patterns (不应出现)
- TODO

## 跑法
开新 Claude 会话 → 粘 Trigger Prompt → 对照 checklist 打勾
EOF

cat > "$SKILL_DIR/tests/README.md" <<EOF
# Tests for $NAME

每个 case 是一份 markdown checklist。开新 Claude 会话, 粘 Trigger Prompt, 对照 expected 打勾。

## Cases
- 01-basic.md — 基础触发

## 跑全部
手动: 逐个开会话跑

## 改 skill 后
**至少跑 01-basic.md**, 防止回归。
EOF

echo "✓ created skills/$NAME/"
echo "  SKILL.md (TODO 待填)"
echo "  references/"
echo "  tests/examples/01-basic.md"
echo
echo "下一步:"
echo "  1. 填 SKILL.md frontmatter + 内容"
echo "  2. python3 scripts/validate-skill.py skills/$NAME"
echo "  3. bash scripts/install.sh    # 建 symlink"
