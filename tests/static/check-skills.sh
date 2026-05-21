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
done

implemented_skills=()
for file in "${skill_files[@]}"; do
  implemented_skills+=("$(basename "$(dirname "$file")")")
done

for skill in using think plan execute debug verify finish review worktree; do
  [[ -d "skills/$skill" ]] || fail "expected skill missing: skills/$skill"
  if ! grep -q "| \`$skill\` |" docs/architecture.md; then
    fail "docs/architecture.md does not list skill '$skill' in mapping table"
  fi
done

if grep -q 'SYNC_SKIP=("using")' scripts/sync.sh; then
  ok "using is excluded from sync"
else
  fail "scripts/sync.sh must exclude using from normal skill sync"
fi

if grep -q 'META_SKILL' hooks/session-start.js && grep -q "'skills', 'using', 'SKILL.md'" hooks/session-start.js; then
  ok "SessionStart hook references using skill"
else
  fail "hooks/session-start.js must inject skills/using/SKILL.md"
fi

if [[ "$failures" -gt 0 ]]; then
  echo
  echo "summary: failed=$failures"
  exit 1
fi

echo
echo "summary: ok"
