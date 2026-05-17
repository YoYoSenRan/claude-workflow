#!/usr/bin/env bash
# install.sh — symlink per-item from this repo into ~/.claude/
#
# 基于 obra/clank 模式:
# - 检测 .git/ 防止跑错位置
# - per-item symlink, 不整目录 (规避 #11344/#764/#14836/#50886 bug)
# - 已存在的真目录自动备份, 不覆盖
# - 已是本仓 symlink 跳过, 幂等
# - 永不动 settings.json / .credentials.json (用户私产)
#
# 用法:
#   bash scripts/install.sh             # 真跑
#   DRY_RUN=1 bash scripts/install.sh   # 干跑, 看会改啥
#   bash scripts/install.sh --unlink    # 卸载本仓所有 symlink

set -euo pipefail

# ---- 定位仓库根 ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  echo "✗ 仓库根缺 .git/ — 拒绝运行 (防错位置)" >&2
  exit 1
fi

USER_CLAUDE="$HOME/.claude"
DRY_RUN="${DRY_RUN:-0}"
MODE="install"

# ---- 解析参数 ----
for arg in "$@"; do
  case "$arg" in
    --unlink|--uninstall) MODE="unlink" ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      grep -E '^#' "$0" | head -20
      exit 0 ;;
    *) echo "✗ 未知参数: $arg" >&2; exit 1 ;;
  esac
done

# ---- 配置: 哪些目录要同步 ----
SYNC_KINDS=(skills agents commands)

# ---- 操作 ----
echo "Repo: $REPO_ROOT"
echo "Target: $USER_CLAUDE"
if [[ "$DRY_RUN" == "1" ]]; then
  echo "Mode: $MODE (DRY_RUN — 不真改文件)"
else
  echo "Mode: $MODE"
fi
echo

link_count=0
backup_count=0
skip_count=0
unlink_count=0

for kind in "${SYNC_KINDS[@]}"; do
  src_dir="$REPO_ROOT/$kind"
  dst_dir="$USER_CLAUDE/$kind"

  [[ -d "$src_dir" ]] || continue
  mkdir -p "$dst_dir"

  for item in "$src_dir"/*; do
    [[ -e "$item" ]] || continue
    name="$(basename "$item")"
    target="$dst_dir/$name"

    # ---- unlink 模式 ----
    if [[ "$MODE" == "unlink" ]]; then
      if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$item" ]]; then
        if [[ "$DRY_RUN" == "1" ]]; then
          echo "[dry] rm $target"
        else
          rm "$target"
          echo "✗ unlinked $kind/$name"
        fi
        ((unlink_count++))
      fi
      continue
    fi

    # ---- install 模式 ----
    # 已是本仓 symlink → 跳
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$item" ]]; then
      echo "✓ $kind/$name (already linked)"
      ((skip_count++))
      continue
    fi

    # 已存在但不是本仓链接 → 备份
    if [[ -e "$target" || -L "$target" ]]; then
      backup="$target.bak.$(date +%s)"
      if [[ "$DRY_RUN" == "1" ]]; then
        echo "[dry] mv $target $backup"
      else
        mv "$target" "$backup"
        echo "↻ backed up $kind/$name → $(basename "$backup")"
      fi
      ((backup_count++))
    fi

    # 建链接
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[dry] ln -sfn $item $target"
    else
      ln -sfn "$item" "$target"
      echo "→ linked $kind/$name"
    fi
    ((link_count++))
  done
done

echo
echo "summary: linked=$link_count skipped=$skip_count backed_up=$backup_count unlinked=$unlink_count"

# ---- 字符预算预警 (Task B 关键发现) ----
if [[ "$MODE" == "install" && "$DRY_RUN" == "0" ]]; then
  echo
  echo "提醒 — 检查字符预算:"
  echo "  Claude Code SKILL.md 字符预算默认 15000 (~4k tokens)"
  echo "  超了的 SKILL.md 会被 silent drop, 检测命令:"
  echo "    find $REPO_ROOT/skills -name SKILL.md -exec wc -c {} \\; | sort -n"
fi
