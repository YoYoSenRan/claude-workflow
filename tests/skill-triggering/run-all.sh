#!/usr/bin/env bash
# Run all skill triggering tests
# Usage: ./run-all.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

if ! command -v claude >/dev/null 2>&1; then
    echo "⚠️  SKIP: claude CLI not found"
    exit 0
fi

SKILLS=(
    "think"
    "debug"
    "review"
    "setup"
    "skill"
)

echo "=== Skill Triggering Tests ==="
echo ""

PASSED=0
FAILED=0
RESULTS=()

for skill in "${SKILLS[@]}"; do
    prompt_file="$PROMPTS_DIR/${skill}.txt"

    if [ ! -f "$prompt_file" ]; then
        echo "⚠️  SKIP: No prompt file for $skill"
        continue
    fi

    echo "--- Testing: $skill ---"

    if "$SCRIPT_DIR/run-test.sh" "$skill" "$prompt_file" 3 2>&1 | tee "/tmp/claude-workflow-test-$skill.log"; then
        PASSED=$((PASSED + 1))
        RESULTS+=("✅ $skill")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("❌ $skill")
    fi

    echo ""
done

echo "=== Summary ==="
for result in "${RESULTS[@]}"; do
    echo "  $result"
done
echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"

[ "$FAILED" -eq 0 ] || exit 1
