#!/usr/bin/env bash
# sync.sh — 把本仓库的 Claude Code 插件源内容**拷贝**到 ~/.claude/ 全局
#
# 与 symlink 区别 — 这是真拷贝, 仓库被删后 ~/.claude/ 副本仍在
#
# 工作流:
#   开发期: 以插件源结构维护根目录 skills/ agents/ commands/
#   完成期: bash scripts/sync.sh 拷贝到 ~/.claude/skills、~/.claude/agents、~/.claude/commands、~/.claude/hooks
#
# 用法:
#   bash scripts/sync.sh                # 真同步
#   DRY_RUN=1 bash scripts/sync.sh      # 干跑
#   bash scripts/sync.sh --uninstall    # 移除本仓 sync 过去的内容

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

[[ -d "$REPO_ROOT/.git" ]] || { echo "✗ 须在仓库根目录运行"; exit 1; }

# 从根目录的真源同步 (skills/ agents/ commands/), 不走 .claude/ symlink
SRC="$REPO_ROOT"
DST="$HOME/.claude"
DRY_RUN="${DRY_RUN:-0}"
MODE="sync"

for arg in "$@"; do
  case "$arg" in
    --uninstall|--unsync) MODE="uninstall" ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      grep -E '^#' "$0" | head -20
      exit 0 ;;
    *) echo "✗ 未知参数: $arg"; exit 1 ;;
  esac
done

[[ -d "$SRC" ]] || { echo "✗ $SRC 不存在"; exit 1; }
# 至少要有一个 sync 目标
has_content=0
for k in skills agents commands hooks; do
  [[ -d "$SRC/$k" ]] && [[ -n "$(ls -A "$SRC/$k" 2>/dev/null)" ]] && has_content=1 && break
done
[[ "$has_content" == "1" ]] || { echo "✗ skills/agents/commands/hooks 都为空, 无内容可 sync"; exit 1; }

SYNC_KINDS=(skills agents commands hooks)
SYNC_SKIP=("hooks:hooks.json")

should_skip() {
  local kind="$1"
  local name="$2"
  local s
  for s in "${SYNC_SKIP[@]:-}"; do
    [[ "$name" == "$s" || "$kind:$name" == "$s" ]] && return 0
  done
  return 1
}

echo "Src: $SRC"
echo "Dst: $DST"
echo "Mode: $MODE$([ "$DRY_RUN" = "1" ] && echo " (DRY_RUN)")"
echo

sync_count=0
skip_count=0
backup_count=0
unsync_count=0

for kind in "${SYNC_KINDS[@]}"; do
  src_dir="$SRC/$kind"
  dst_dir="$DST/$kind"

  [[ -d "$src_dir" ]] || continue
  mkdir -p "$dst_dir"

  for item in "$src_dir"/*; do
    [[ -e "$item" ]] || continue
    name="$(basename "$item")"
    item_dst="$dst_dir/$name"
    if [[ -d "$item" ]]; then
      marker="$item_dst/.synced_from"
    else
      marker="$item_dst.synced_from"
    fi

    # 跳过 SYNC_SKIP 名单
    if should_skip "$kind" "$name"; then
      echo "- $kind/$name (跳过, 见 SYNC_SKIP)"
      ((skip_count++))
      continue
    fi

    # ---- uninstall 模式 ----
    if [[ "$MODE" == "uninstall" ]]; then
      if [[ -f "$marker" ]] && [[ "$(cat "$marker")" == "$REPO_ROOT" ]]; then
        if [[ "$DRY_RUN" == "1" ]]; then
          echo "[dry] rm -rf $item_dst"
        else
          rm -rf "$item_dst" "$marker"
          echo "✗ unsynced $kind/$name"
        fi
        ((unsync_count++))
      else
        echo "- $kind/$name (非本仓 sync, 不动)"
      fi
      continue
    fi

    # ---- sync 模式 ----
    # 目标已存在但不是本仓 sync 过去的 → 备份
    if [[ -e "$item_dst" && ! -f "$marker" ]]; then
      backup="$item_dst.bak.$(date +%s)"
      if [[ "$DRY_RUN" == "1" ]]; then
        echo "[dry] mv $item_dst → $backup"
      else
        mv "$item_dst" "$backup"
        echo "↻ backed up $kind/$name"
      fi
      ((backup_count++))
    fi

    if [[ -d "$item" ]]; then
      # rsync 增量拷贝 (源加 / = 同步内容, 不含父目录)
      if [[ "$DRY_RUN" == "1" ]]; then
        echo "[dry] rsync -a --delete $item/ $item_dst/"
      else
        mkdir -p "$item_dst"
        rsync -a --delete \
          --exclude='.synced_from' \
          "$item/" "$item_dst/"
        echo "$REPO_ROOT" > "$marker"
        echo "→ synced $kind/$name"
      fi
    else
      if [[ "$DRY_RUN" == "1" ]]; then
        echo "[dry] cp $item $item_dst"
      else
        cp "$item" "$item_dst"
        echo "$REPO_ROOT" > "$marker"
        echo "→ synced $kind/$name"
      fi
    fi
    ((sync_count++))
  done
done

echo
if [[ "$MODE" == "uninstall" ]]; then
  echo "summary: unsynced=$unsync_count"
else
  echo "summary: synced=$sync_count backed_up=$backup_count"
  echo
  echo "提醒:"
  echo "  开发期维护 $REPO_ROOT 下的插件源目录: skills/ agents/ commands/"
  echo "  只在 skill 改稳定后才需要 sync 到全局"
fi
