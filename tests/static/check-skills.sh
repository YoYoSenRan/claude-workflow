#!/usr/bin/env bash
# Static checks for claude-workflow skills.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

failures=0

fail() {
  echo "✗ $*"
  failures=$((failures + 1))
}

ok() {
  echo "✓ $*"
}

cd "$REPO_ROOT"

[[ -d skills ]] || fail "skills/ directory is missing"
[[ -f docs/architecture.md ]] || fail "docs/architecture.md is missing"

skill_files=()
while IFS= read -r file; do
  skill_files+=("$file")
done < <(find skills -mindepth 2 -maxdepth 2 -name SKILL.md | sort)

if [[ "${#skill_files[@]}" -eq 0 ]]; then
  fail "no skills/*/SKILL.md files found"
fi

for file in "${skill_files[@]}"; do
  dir_name="$(basename "$(dirname "$file")")"
  line_count="$(wc -l < "$file" | tr -d ' ')"

  if ! sed -n '1p' "$file" | grep -qx -- '---'; then
    fail "$file missing opening frontmatter delimiter"
    continue
  fi

  frontmatter_end="$(awk 'NR > 1 && $0 == "---" { print NR; exit }' "$file")"
  if [[ -z "$frontmatter_end" ]]; then
    fail "$file missing closing frontmatter delimiter"
    continue
  fi

  name="$(awk -F': *' 'NR > 1 && /^name:/ { print $2; exit }' "$file" | tr -d '"')"
  description="$(awk -F': *' 'NR > 1 && /^description:/ { print $2; exit }' "$file" | tr -d '"')"

  [[ -n "$name" ]] || fail "$file missing frontmatter name"
  [[ -n "$description" ]] || fail "$file missing frontmatter description"
  [[ "$name" == "$dir_name" ]] || fail "$file name '$name' does not match directory '$dir_name'"
  [[ "$line_count" -gt 20 ]] || fail "$file looks like an empty shell skill ($line_count lines)"
  if ! grep -Eq '<SUBAGENT-STOP>|^## 子代理辅助模式$' "$file"; then
    fail "$file missing SUBAGENT-STOP boundary or 子代理辅助模式 section"
  fi
done

implemented_skills=()
for file in "${skill_files[@]}"; do
  implemented_skills+=("$(basename "$(dirname "$file")")")
done

for skill in using think plan execute debug verify finish review worktree subagent; do
  [[ -d "skills/$skill" ]] || fail "expected skill missing: skills/$skill"
  if [[ -L ".claude/skills/$skill" ]] && [[ "$(readlink ".claude/skills/$skill")" == "../../skills/$skill" ]]; then
    ok "project skill link exists: $skill"
  else
    fail ".claude/skills/$skill must link to ../../skills/$skill"
  fi
  [[ -f "tests/skills/$skill/README.md" ]] || fail "tests/skills/$skill/README.md is missing"
  if ! find "tests/skills/$skill/examples" -mindepth 1 -maxdepth 1 -type f -name '*.md' | grep -q .; then
    fail "tests/skills/$skill/examples must contain at least one markdown example"
  fi
  if ! grep -q "| \`$skill\` |" docs/architecture.md; then
    fail "docs/architecture.md does not list skill '$skill' in mapping table"
  fi
done

if grep -q 'SYNC_KINDS=(skills agents commands hooks)' scripts/sync.sh && grep -q 'SYNC_SKIP=("hooks:hooks.json")' scripts/sync.sh; then
  ok "sync includes skills and hooks"
else
  fail "scripts/sync.sh must sync skills and global hook while skipping plugin hooks.json"
fi

if grep -q 'META_SKILL' hooks/session-start.js && grep -q "'skills', 'using', 'SKILL.md'" hooks/session-start.js; then
  ok "SessionStart hook references using skill"
else
  fail "hooks/session-start.js must inject skills/using/SKILL.md"
fi

if [[ -L ".claude/hooks/session-start.js" ]] && [[ "$(readlink .claude/hooks/session-start.js)" == "../../hooks/session-start.js" ]]; then
  ok "project hook is linked from .claude/hooks"
else
  fail ".claude/hooks/session-start.js must link to ../../hooks/session-start.js"
fi

if grep -q '\${CLAUDE_PROJECT_DIR}/.claude/hooks/session-start.js' .claude/settings.json; then
  ok "project settings use .claude hook path"
else
  fail ".claude/settings.json must call \${CLAUDE_PROJECT_DIR}/.claude/hooks/session-start.js"
fi

[[ -f ".claude-plugin/plugin.json" ]] || fail ".claude-plugin/plugin.json is missing"
[[ -f ".claude-plugin/marketplace.json" ]] || fail ".claude-plugin/marketplace.json is missing"
if [[ -f "hooks/hooks.json" ]]; then
  ok "plugin hook config exists at default path"
else
  fail "hooks/hooks.json is missing"
fi

if grep -q '\${CLAUDE_PLUGIN_ROOT}/scripts/session-start.js' hooks/hooks.json; then
  ok "plugin hooks use CLAUDE_PLUGIN_ROOT scripts path"
else
  fail "hooks/hooks.json must call \${CLAUDE_PLUGIN_ROOT}/scripts/session-start.js"
fi

if [[ -L "scripts/session-start.js" ]] && [[ "$(readlink scripts/session-start.js)" == "../hooks/session-start.js" ]]; then
  ok "plugin session-start script links to root hook"
else
  fail "scripts/session-start.js must link to ../hooks/session-start.js"
fi

if grep -q '"name": "yoyosenran-tools"' .claude-plugin/marketplace.json && grep -q '"source": "./"' .claude-plugin/marketplace.json; then
  ok "marketplace manifest points to local plugin source"
else
  fail ".claude-plugin/marketplace.json must expose claude-workflow from the marketplace repository root"
fi

if [[ "$failures" -gt 0 ]]; then
  echo
  echo "summary: failed=$failures"
  exit 1
fi

echo
echo "summary: ok"
