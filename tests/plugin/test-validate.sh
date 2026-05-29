#!/usr/bin/env bash
# Plugin validation test — validates plugin.json and marketplace.json
# Requires: claude CLI
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASSED=0
FAILED=0

pass() { PASSED=$((PASSED + 1)); echo "  ✅ $1"; }
fail() { FAILED=$((FAILED + 1)); echo "  ❌ $1"; }

echo "=== Plugin Validation Tests ==="
echo ""

# Check claude CLI exists
if ! command -v claude >/dev/null 2>&1; then
    echo "⚠️  SKIP: claude CLI not found"
    exit 0
fi

# 1. plugin.json validates
if claude plugin validate "$PLUGIN_ROOT/.claude-plugin/plugin.json" >/dev/null 2>&1; then
    pass "plugin.json validates"
else
    fail "plugin.json validation failed"
fi

# 2. marketplace.json validates
if claude plugin validate "$PLUGIN_ROOT/.claude-plugin/marketplace.json" >/dev/null 2>&1; then
    pass "marketplace.json validates"
else
    fail "marketplace.json validation failed"
fi

# 3. All skills have SKILL.md
MISSING_SKILLS=()
for skill_dir in "$PLUGIN_ROOT"/skills/*/; do
    skill_name=$(basename "$skill_dir")
    if [ ! -f "$skill_dir/SKILL.md" ]; then
        MISSING_SKILLS+=("$skill_name")
    fi
done
if [ ${#MISSING_SKILLS[@]} -eq 0 ]; then
    pass "all skill directories have SKILL.md"
else
    fail "missing SKILL.md in: ${MISSING_SKILLS[*]}"
fi

# 4. All skills have name in frontmatter
BAD_NAMES=()
for skill_file in "$PLUGIN_ROOT"/skills/*/SKILL.md; do
    skill_name=$(basename "$(dirname "$skill_file")")
    if ! head -10 "$skill_file" | grep -q "^name:"; then
        BAD_NAMES+=("$skill_name")
    fi
done
if [ ${#BAD_NAMES[@]} -eq 0 ]; then
    pass "all skills have name in frontmatter"
else
    fail "missing name in frontmatter: ${BAD_NAMES[*]}"
fi

# 5. All skills have description in frontmatter
BAD_DESC=()
for skill_file in "$PLUGIN_ROOT"/skills/*/SKILL.md; do
    skill_name=$(basename "$(dirname "$skill_file")")
    if ! head -10 "$skill_file" | grep -q "^description:"; then
        BAD_DESC+=("$skill_name")
    fi
done
if [ ${#BAD_DESC[@]} -eq 0 ]; then
    pass "all skills have description in frontmatter"
else
    fail "missing description in frontmatter: ${BAD_DESC[*]}"
fi

# 6. Skill name matches directory name
MISMATCH=()
for skill_file in "$PLUGIN_ROOT"/skills/*/SKILL.md; do
    dir_name=$(basename "$(dirname "$skill_file")")
    yaml_name=$(head -10 "$skill_file" | grep "^name:" | sed 's/^name: *//')
    if [ -n "$yaml_name" ] && [ "$yaml_name" != "$dir_name" ]; then
        MISMATCH+=("$dir_name (yaml: $yaml_name)")
    fi
done
if [ ${#MISMATCH[@]} -eq 0 ]; then
    pass "all skill names match directory names"
else
    fail "name mismatch: ${MISMATCH[*]}"
fi

# 7. All agents have required frontmatter
if [ -d "$PLUGIN_ROOT/agents" ]; then
    BAD_AGENTS=()
    for agent_file in "$PLUGIN_ROOT"/agents/*.md; do
        agent_name=$(basename "$agent_file" .md)
        if ! head -10 "$agent_file" | grep -q "^name:"; then
            BAD_AGENTS+=("$agent_name")
        fi
    done
    if [ ${#BAD_AGENTS[@]} -eq 0 ]; then
        pass "all agents have name in frontmatter"
    else
        fail "missing name in agent frontmatter: ${BAD_AGENTS[*]}"
    fi
fi

# 8. hooks.json is valid JSON
if jq . "$PLUGIN_ROOT/hooks/hooks.json" >/dev/null 2>&1; then
    pass "hooks.json is valid JSON"
else
    fail "hooks.json is not valid JSON"
fi

# 9. No orphan references (references not under a skill)
if [ -d "$PLUGIN_ROOT/.claude/references" ]; then
    fail "found .claude/references/ — references must be under skills/"
else
    pass "no orphan references directory"
fi

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

[ "$FAILED" -eq 0 ] || exit 1
