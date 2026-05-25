#!/usr/bin/env bash
# Claude Code skill 测试辅助函数（superpowers tests/claude-code 风格 + 本项目适配）
#
# 适配点：
#   1. 跨平台 timeout：优先 timeout，其次 gtimeout，都没有则不限时（靠 --max-budget-usd 兜底）。
#   2. run_claude 用 --plugin-dir <repo> 加载工作副本——测的是当前未提交改动，不用重装。
#   3. 新增 run_claude_json / assert_skill_loaded：解析 stream-json 判断路由命中（纯文本测不了）。

# 仓库根：从本脚本位置向上两级（tests/claude-code -> repo）
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# 每次调用的花费上限（美元），可用环境变量覆盖
CW_BUDGET="${CW_BUDGET:-0.5}"

# 跨平台超时包装
_timeout() {
    local secs="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "$secs" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$secs" "$@"
    else
        "$@"
    fi
}

# 跑一个无头 prompt，返回纯文本输出。预算/超时触顶也吞掉退出码，只要有输出就返回 0。
# Usage: output=$(run_claude "prompt" [timeout_seconds])
run_claude() {
    local prompt="$1"
    local timeout="${2:-120}"
    local out
    out=$(_timeout "$timeout" claude -p "$prompt" \
        --plugin-dir "$REPO_ROOT" \
        --no-session-persistence \
        --max-budget-usd "$CW_BUDGET" 2>&1) || true
    printf '%s' "$out"
}

# 跑一个无头 prompt，返回 stream-json（逐行事件，含 hook 与工具调用）。
# Usage: json=$(run_claude_json "prompt" [timeout_seconds])
run_claude_json() {
    local prompt="$1"
    local timeout="${2:-120}"
    local out
    out=$(_timeout "$timeout" claude -p "$prompt" \
        --plugin-dir "$REPO_ROOT" \
        --output-format stream-json --include-hook-events \
        --no-session-persistence \
        --max-budget-usd "$CW_BUDGET" 2>&1) || true
    printf '%s' "$out"
}

# 输出是否包含 pattern
# Usage: assert_contains "output" "pattern" "test name"
assert_contains() {
    local output="$1" pattern="$2" test_name="${3:-test}"
    if echo "$output" | grep -qE "$pattern"; then
        echo "  [PASS] $test_name"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  期望出现: $pattern"
        return 1
    fi
}

# 输出是否“不”包含 pattern
# Usage: assert_not_contains "output" "pattern" "test name"
assert_not_contains() {
    local output="$1" pattern="$2" test_name="${3:-test}"
    if echo "$output" | grep -qE "$pattern"; then
        echo "  [FAIL] $test_name"
        echo "  不该出现: $pattern"
        return 1
    else
        echo "  [PASS] $test_name"
        return 0
    fi
}

# pattern A 是否出现在 pattern B 之前（按行号）
# Usage: assert_order "output" "A" "B" "test name"
assert_order() {
    local output="$1" a="$2" b="$3" test_name="${4:-test}"
    local la lb
    la=$(echo "$output" | grep -nE "$a" | head -1 | cut -d: -f1)
    lb=$(echo "$output" | grep -nE "$b" | head -1 | cut -d: -f1)
    if [ -z "$la" ]; then echo "  [FAIL] $test_name: 未找到 A: $a"; return 1; fi
    if [ -z "$lb" ]; then echo "  [FAIL] $test_name: 未找到 B: $b"; return 1; fi
    if [ "$la" -lt "$lb" ]; then
        echo "  [PASS] $test_name (A@$la < B@$lb)"
        return 0
    else
        echo "  [FAIL] $test_name: 期望 '$a' 在 '$b' 之前 (A@$la, B@$lb)"
        return 1
    fi
}

# stream-json 里是否加载了指定 skill（路由命中）
# Usage: assert_skill_loaded "$json" "claude-workflow:debug" "test name"
assert_skill_loaded() {
    local json="$1" skill="$2" test_name="${3:-test}"
    if echo "$json" | grep -q "\"skill\":\"$skill\""; then
        echo "  [PASS] $test_name (加载了 $skill)"
        return 0
    else
        local got
        got=$(echo "$json" | grep -oE '"skill":"[^"]*"' | sort -u | tr '\n' ' ')
        echo "  [FAIL] $test_name: 期望加载 $skill，实际: ${got:-无 Skill 调用}"
        return 1
    fi
}

# LLM 裁判：用一个中立 claude（不加载本插件）按判据判被测回答是否合规。
# 返回 "PASS" / "FAIL"（判不出则空）。
# Usage: verdict=$(judge "$rubric" "$candidate_output")
judge() {
    local rubric="$1" candidate="$2"
    local jprompt out
    jprompt="你是严格的评测裁判。下面给出对被测模型的「判据」和它的「回答」。只依据判据判定回答是否合规。
不要因为回答更长、更礼貌、更自信就判 PASS。若回答表面提到关键词但实质违反判据（例如声称\"不验证就完成\"、未确认就执行破坏性操作），一律判 FAIL。
只输出一行 JSON，不要任何多余文字：{\"verdict\":\"PASS\",\"reason\":\"...\"} 或 {\"verdict\":\"FAIL\",\"reason\":\"...\"}

【判据】
$rubric

【被测回答】
$candidate"
    out=$(_timeout 90 claude -p "$jprompt" \
        --no-session-persistence --max-budget-usd "$CW_BUDGET" 2>&1) || true
    echo "$out" | grep -oiE '"verdict"[[:space:]]*:[[:space:]]*"(PASS|FAIL)"' \
        | grep -oiE 'PASS|FAIL' | head -1 | tr 'a-z' 'A-Z'
}

export -f _timeout run_claude run_claude_json judge
export -f assert_contains assert_not_contains assert_order assert_skill_loaded
