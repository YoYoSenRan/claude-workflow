#!/usr/bin/env bash
# Claude Workflow skill 行为测试 — 数据驱动 runner（superpowers tests/claude-code 风格）。
# 读 scenarios.tsv，每条在隔离 sandbox 里跑，断言，统计通过率。全过才 exit 0。
#
# 安全：每条场景都在临时 sandbox 目录（cwd）里跑，插件经 --plugin-dir 从真仓库加载。
#       破坏性 prompt（丢弃/提交）只会作用于 throwaway 目录，不碰真仓库。
#
# 用法:
#   bash run-skill-tests.sh                 # 全部场景，每条 1 次
#   bash run-skill-tests.sh -n 5            # 每条跑 5 次看通过率
#   bash run-skill-tests.sh --tier 1        # 只跑 Tier 1
#   bash run-skill-tests.sh -t G4           # 只跑某条
#   CW_BUDGET=1 bash run-skill-tests.sh     # 调高每次花费上限

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
TSV="$SCRIPT_DIR/scenarios.tsv"

RUNS=1; ONLY_TIER=""; ONLY_ID=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--runs) RUNS="$2"; shift 2 ;;
        --tier) ONLY_TIER="$2"; shift 2 ;;
        -t|--test) ONLY_ID="$2"; shift 2 ;;
        -h|--help) echo "用法: $0 [-n RUNS] [--tier N] [-t ID]"; exit 0 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

command -v claude >/dev/null 2>&1 || { echo "ERROR: 未找到 claude CLI"; exit 1; }

echo "========================================"
echo " Claude Workflow Skill 行为测试"
echo " 仓库: $REPO_ROOT"
echo " claude: $(claude --version 2>/dev/null || echo 未知)  RUNS=$RUNS  budget=$CW_BUDGET"
[ -n "$ONLY_TIER" ] && echo " 过滤: Tier $ONLY_TIER"
[ -n "$ONLY_ID" ] && echo " 过滤: 场景 $ONLY_ID"
echo "========================================"

# 预置一个隔离 sandbox 目录，返回路径
seed_sandbox() {
    local seed="$1" sb
    sb=$(mktemp -d)
    case "$seed" in
        git)
            ( cd "$sb" && git init -q && git config user.email t@t && git config user.name t \
              && printf '# Demo\n' > README.md && git add . && git commit -qm init \
              && printf 'dirty\n' >> README.md && printf 'console.log(1)\n' > app.js ) ;;
        readme)
            ( cd "$sb" && git init -q && git config user.email t@t && git config user.name t \
              && printf '# Hello\n\nbody\n' > README.md && git add . && git commit -qm init ) ;;
        plan)
            ( cd "$sb" && git init -q && git config user.email t@t && git config user.name t \
              && mkdir -p docs/plans \
              && cat > docs/plans/2026-01-01-demo.md <<'EOF'
# Demo 实现计划

**状态：** 已批准
**创建日期：** 2026-01-01

## 目标
新增一个 add 函数。

## 验证方式
- `node -e "require('./src/math').add"` — 不报错。

## 任务清单

### 任务 1：新增 add 函数

**状态：** 待执行
**涉及文件：**
- 新建：`src/math.js`

**步骤：**
- [ ] 步骤 1.1：创建 `src/math.js`，导出 `add(a,b){return a+b}`。
  运行：`node -e "console.log(require('./src/math').add(1,2))"`
  预期：输出 3

**完成标准：**
- 上述命令输出 3。
EOF
              git add . && git commit -qm init ) ;;
        *) : ;;
    esac
    echo "$sb"
}

# 判断单条断言是否通过（输出在 $3）
check_assert() {
    local assert="$1" expect="$2" out="$3"
    case "$assert" in
        skill)        echo "$out" | grep -qE "\"skill\":\"$expect\"" ;;
        not_skill)    ! echo "$out" | grep -qE "\"skill\":\"$expect\"" ;;
        no_skill)     ! echo "$out" | grep -q '"name":"Skill"' ;;
        contains)     echo "$out" | grep -qE "$expect" ;;
        not_contains) ! echo "$out" | grep -qE "$expect" ;;
        judge)        [ "$(judge "$expect" "$out")" = PASS ] ;;
        *) echo "  未知断言: $assert" >&2; return 1 ;;
    esac
}

total=0; failed=0; info_lines=()
while IFS=$'\t' read -r id tier assert expect seed flags prompt; do
    [[ -z "${id:-}" || "$id" == \#* ]] && continue
    [ -n "$ONLY_TIER" ] && [ "$tier" != "$ONLY_TIER" ] && continue
    [ -n "$ONLY_ID" ] && [ "$id" != "$ONLY_ID" ] && continue

    total=$((total + 1))
    # 断言类型决定取 json 还是纯文本
    local_mode=text
    case "$assert" in skill|not_skill|no_skill) local_mode=json ;; esac

    pass=0
    for i in $(seq 1 "$RUNS"); do
        sb=$(seed_sandbox "$seed")
        if [ "$local_mode" = json ]; then
            out=$( cd "$sb" && run_claude_json "$prompt" 150 )
        else
            out=$( cd "$sb" && run_claude "$prompt" 150 )
        fi
        rm -rf "$sb"
        check_assert "$assert" "$expect" "$out" && pass=$((pass + 1))
    done

    rate=$((pass * 100 / RUNS))
    tag="[T$tier]"
    [ "$flags" = info ] && tag="$tag(info)"
    if [ "$pass" -gt 0 ]; then
        printf "  [PASS] %-4s %s  %d/%d (%d%%)  %s\n" "$id" "$tag" "$pass" "$RUNS" "$rate" "$assert:$expect"
    else
        if [ "$flags" = info ]; then
            printf "  [info] %-4s %s  0/%d  %s (信息项,不计失败)\n" "$id" "$tag" "$RUNS" "$assert:$expect"
            info_lines+=("$id 通过率 0%")
        else
            printf "  [FAIL] %-4s %s  0/%d  %s\n" "$id" "$tag" "$RUNS" "$assert:$expect"
            failed=$((failed + 1))
        fi
    fi
done < "$TSV"

echo ""
echo "========================================"
echo " 场景 $total  失败 $failed"
[ "${#info_lines[@]}" -gt 0 ] && printf " 信息项: %s\n" "${info_lines[*]}"
echo "========================================"
[ "$failed" -eq 0 ] && { echo "STATUS: PASSED"; exit 0; } || { echo "STATUS: FAILED"; exit 1; }
