#!/usr/bin/env bash
# Hook unit test — validates session-start.js output structure
# Requires: Node.js only (no claude CLI)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$PLUGIN_ROOT/hooks/session-start.js"

PASSED=0
FAILED=0

pass() { PASSED=$((PASSED + 1)); echo "  ✅ $1"; }
fail() { FAILED=$((FAILED + 1)); echo "  ❌ $1"; }

echo "=== Hook Unit Tests: session-start.js ==="
echo ""

OUTPUT=$(node "$HOOK" 2>&1) || { fail "hook exited non-zero"; exit 1; }

# 1. Valid JSON
if echo "$OUTPUT" | jq . >/dev/null 2>&1; then
    pass "outputs valid JSON"
else
    fail "output is not valid JSON"
    echo "  output: $OUTPUT"
    exit 1
fi

# 2. Has hookSpecificOutput
if echo "$OUTPUT" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
    pass "has hookSpecificOutput"
else
    fail "missing hookSpecificOutput"
fi

# 3. Has hookEventName = SessionStart
EVENT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.hookEventName' 2>/dev/null)
if [ "$EVENT" = "SessionStart" ]; then
    pass "hookEventName is SessionStart"
else
    fail "hookEventName is '$EVENT', expected 'SessionStart'"
fi

# 4. Has additionalContext
CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)
if [ -n "$CONTEXT" ] && [ "$CONTEXT" != "null" ]; then
    pass "has additionalContext"
else
    fail "missing additionalContext"
fi

# 5. Context contains workflow-routing wrapper
if echo "$CONTEXT" | grep -q '<workflow-routing>'; then
    pass "context contains <workflow-routing>"
else
    fail "context missing <workflow-routing>"
fi

# 6. Context contains HARD-GATE
if echo "$CONTEXT" | grep -q '<HARD-GATE>'; then
    pass "context contains <HARD-GATE>"
else
    fail "context missing <HARD-GATE>"
fi

# 7. Context contains using skill content (routing table)
if echo "$CONTEXT" | grep -q '技能入口'; then
    pass "context contains using skill content"
else
    fail "context missing using skill content"
fi

# 8. Context contains SUBAGENT-STOP
if echo "$CONTEXT" | grep -q '<SUBAGENT-STOP>'; then
    pass "context contains <SUBAGENT-STOP>"
else
    fail "context missing <SUBAGENT-STOP>"
fi

# 9. Context contains routing table entries
for keyword in "think" "debug" "review" "setup" "skill"; do
    if echo "$CONTEXT" | grep -q "$keyword"; then
        pass "routing table contains '$keyword'"
    else
        fail "routing table missing '$keyword'"
    fi
done

# 10. No frontmatter leaked
if echo "$CONTEXT" | grep -q '^---$'; then
    fail "YAML frontmatter leaked into context"
else
    pass "no YAML frontmatter in context"
fi

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

[ "$FAILED" -eq 0 ] || exit 1
