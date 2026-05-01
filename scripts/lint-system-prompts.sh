#!/usr/bin/env bash
# CLI lint: scan deployable agent prompt files for formatting violations.
#
# Walks builds/ for system-prompt files (system-prompt*.md or anything inside
# a system-prompts/ directory). For each, flags:
#   - Markdown table separator rows (rule: no tables in deployed prompts)
#   - Em or en dash characters
#
# Run before deploying:    bash scripts/lint-system-prompts.sh
# CI:                      use the same exit code (0 clean, 1 violations).
#
# This complements scripts/pre-tool-system-prompt-check.sh which fires at
# deploy time. The lint catches violations earlier (in the file, before any
# MCP call).

set -uo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$REPO_ROOT" || exit 2

if [ ! -d builds ]; then
  echo "lint-system-prompts: no builds/ directory at $REPO_ROOT, nothing to scan"
  exit 0
fi

# Bash 3.2 compatible (macOS default has no mapfile/readarray).
FILES=()
while IFS= read -r line; do
  FILES+=("$line")
done < <(find builds -type f \( -name 'system-prompt*.md' -o -path '*/system-prompts/*.md' \) 2>/dev/null | sort)

FILE_COUNT=${#FILES[@]}

if [ "$FILE_COUNT" -eq 0 ]; then
  echo "lint-system-prompts: no system-prompt files found under builds/"
  exit 0
fi

TOTAL_VIOLATIONS=0
FILES_WITH_VIOLATIONS=0

# Patterns
TABLE_RE='^[[:space:]]*\|[[:space:]]*:?-+:?[[:space:]]*(\|[[:space:]]*:?-+:?[[:space:]]*)+\|[[:space:]]*$'
DASH_RE=$'\xe2\x80\x94|\xe2\x80\x93'

for f in "${FILES[@]}"; do
  FILE_VIOLATIONS=0

  # Only scan content between BEGIN PROMPT / END PROMPT markers if present.
  # Otherwise scan the whole file. This lets prompt files use markdown tables
  # in their "Notes before deploying" preamble without false-positives.
  HAS_MARKERS=0
  if grep -q '^BEGIN PROMPT' "$f" 2>/dev/null && grep -q '^END PROMPT' "$f" 2>/dev/null; then
    HAS_MARKERS=1
    CONTENT=$(awk '/^BEGIN PROMPT/{flag=1; next} /^END PROMPT/{flag=0} flag' "$f")
  else
    CONTENT=$(cat "$f")
  fi

  # Markdown table check
  TABLE_HITS=$(printf '%s\n' "$CONTENT" | grep -nE "$TABLE_RE" || true)
  if [ -n "$TABLE_HITS" ]; then
    if [ $FILE_VIOLATIONS -eq 0 ]; then
      echo ""
      echo "FAIL $f"
    fi
    echo "   Markdown table separator row(s):"
    printf '%s\n' "$TABLE_HITS" | sed 's/^/     /'
    echo "   Rule: BUILD_PRACTICES.md > 'System Prompts > No Markdown Tables'"
    echo "   Fix:  convert to bullet list."
    FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
    TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + 1))
  fi

  # Em / en dash check. Strip backtick-quoted spans first so docs that
  # legitimately reference the character don't false-positive.
  STRIPPED_CONTENT=$(printf '%s' "$CONTENT" | sed 's/`[^`]*`//g')
  DASH_HITS=$(printf '%s\n' "$STRIPPED_CONTENT" | grep -nE "$DASH_RE" || true)
  if [ -n "$DASH_HITS" ]; then
    if [ $FILE_VIOLATIONS -eq 0 ]; then
      echo ""
      echo "FAIL $f"
    fi
    echo "   Em or en dash character(s):"
    printf '%s\n' "$DASH_HITS" | sed 's/^/     /'
    echo "   Rule: CLAUDE.md > 'Hard Rules -- Never use em dashes'"
    echo "   Fix:  replace with comma, full stop, parentheses, or '--'."
    FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
    TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + 1))
  fi

  if [ $FILE_VIOLATIONS -gt 0 ]; then
    FILES_WITH_VIOLATIONS=$((FILES_WITH_VIOLATIONS + 1))
    if [ "$HAS_MARKERS" -eq 0 ]; then
      echo "   NOTE: this file has no BEGIN PROMPT / END PROMPT markers, so the"
      echo "         lint scanned the whole file (preamble + deployable body)."
      echo "         Consider wrapping the deployable text in markers so future"
      echo "         lint runs only check what gets shipped."
    fi
  fi
done

echo ""
if [ $TOTAL_VIOLATIONS -eq 0 ]; then
  echo "OK lint-system-prompts: $FILE_COUNT file(s) scanned, all clean"
  exit 0
else
  echo "FAIL lint-system-prompts: $TOTAL_VIOLATIONS violation(s) across $FILES_WITH_VIOLATIONS file(s) ($FILE_COUNT scanned)"
  exit 1
fi
