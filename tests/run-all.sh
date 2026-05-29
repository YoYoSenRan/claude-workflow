#!/usr/bin/env bash
# Master test runner for claude-workflow
# Usage: ./tests/run-all.sh [--skip-triggering]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKIP_TRIGGERING=false

for arg in "$@"; do
    case "$arg" in
        --skip-triggering) SKIP_TRIGGERING=true ;;
    esac
done

TOTAL_PASSED=0
TOTAL_FAILED=0
SUITES=()

run_suite() {
    local name="$1"
    local script="$2"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if bash "$script"; then
        SUITES+=("✅ $name")
    else
        SUITES+=("❌ $name")
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
}

echo "=== claude-workflow test suite ==="

run_suite "Hook Tests" "$SCRIPT_DIR/hooks/test-session-start.sh"
run_suite "Plugin Validation" "$SCRIPT_DIR/plugin/test-validate.sh"

if [ "$SKIP_TRIGGERING" = "false" ]; then
    run_suite "Skill Triggering" "$SCRIPT_DIR/skill-triggering/run-all.sh"
else
    echo ""
    echo "⚠️  Skipped: Skill Triggering (--skip-triggering)"
    SUITES+=("⏭ Skill Triggering (skipped)")
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Final Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
for suite in "${SUITES[@]}"; do
    echo "  $suite"
done
echo ""

[ "$TOTAL_FAILED" -eq 0 ] || exit 1
