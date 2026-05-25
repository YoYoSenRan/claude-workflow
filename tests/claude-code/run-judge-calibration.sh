#!/usr/bin/env bash
# judge 裁判校准 runner —— 拿金标准样本验证「裁判本身」判得准不准。
#
# 为什么单独一套：scenarios.tsv 的 judge 场景测的是「被测模型」合不合规，
# 但裁判自己也是 LLM、有过度通过偏见。这套反过来测裁判：喂已知 PASS/FAIL 的样本，
# 看 judge 还原得对不对。judge 判错 = 判据太松或裁判漂移，必须先修裁判再信 judge 场景。
#
# 判据不在此复制 —— 按 id 从 scenarios.tsv 取（单一真相源，改判据只改一处）。
#
# 用法:
#   bash run-judge-calibration.sh              # 每条样本判 1 次
#   bash run-judge-calibration.sh -n 5         # 每条判 5 次看裁判稳定度
#   bash run-judge-calibration.sh -t G4        # 只校准 G4 的样本
#   CW_BUDGET=1 bash run-judge-calibration.sh  # 调高每次花费上限

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
FIXTURES="$SCRIPT_DIR/judge-fixtures.tsv"
SCENARIOS="$SCRIPT_DIR/scenarios.tsv"

RUNS=1; ONLY_ID=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--runs) RUNS="$2"; shift 2 ;;
        -t|--id)   ONLY_ID="$2"; shift 2 ;;
        -h|--help) echo "用法: $0 [-n RUNS] [-t ID]"; exit 0 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

command -v claude >/dev/null 2>&1 || { echo "ERROR: 未找到 claude CLI"; exit 1; }

# 从 scenarios.tsv 按 id 取 judge 判据（field: 1=id 3=assert 4=expect/rubric）
get_rubric() {
    awk -F'\t' -v id="$1" '$1==id && $3=="judge" {print $4; exit}' "$SCENARIOS"
}

echo "========================================"
echo " judge 裁判校准"
echo " claude: $(claude --version 2>/dev/null || echo 未知)  RUNS=$RUNS  budget=$CW_BUDGET"
[ -n "$ONLY_ID" ] && echo " 过滤: $ONLY_ID"
echo "========================================"

total=0; failed=0
while IFS=$'\t' read -r id expect label answer; do
    [[ -z "${id:-}" || "$id" == \#* ]] && continue
    [ -n "$ONLY_ID" ] && [ "$id" != "$ONLY_ID" ] && continue

    rubric=$(get_rubric "$id")
    if [ -z "$rubric" ]; then
        printf "  [FAIL] %-3s %-32s scenarios.tsv 里找不到 id=%s 的 judge 判据\n" "$id" "$label" "$id"
        total=$((total + 1)); failed=$((failed + 1)); continue
    fi

    total=$((total + 1))
    match=0
    for i in $(seq 1 "$RUNS"); do
        verdict=$(judge "$rubric" "$answer")
        [ "$verdict" = "$expect" ] && match=$((match + 1))
    done

    rate=$((match * 100 / RUNS))
    if [ "$match" -eq "$RUNS" ]; then
        printf "  [PASS] %-3s 期望 %-4s  %d/%d  %s\n" "$id" "$expect" "$match" "$RUNS" "$label"
    else
        printf "  [FAIL] %-3s 期望 %-4s  %d/%d (%d%%)  %s\n" "$id" "$expect" "$match" "$RUNS" "$rate" "$label"
        failed=$((failed + 1))
    fi
done < "$FIXTURES"

echo ""
echo "========================================"
echo " 样本 $total  裁判判错 $failed"
echo "========================================"
if [ "$failed" -eq 0 ]; then
    echo "STATUS: 裁判已校准（全部样本判对）"; exit 0
else
    echo "STATUS: 裁判失准 —— 收紧 scenarios.tsv 对应判据措辞，或在样本集补负例后重测"; exit 1
fi
