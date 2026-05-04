#!/usr/bin/env bash
# PreToolUse hook: block agent-write tool calls whose system_prompt violates
# the deployable-prompt formatting rules.
#
# Triggered by .claude/settings.json on:
#   - relevance_upsert_agent
#   - relevance_patch_agent
#   - relevance_save_agent_draft
#
# Reads the tool call JSON on stdin. Pulls the system_prompt out of either
# .tool_input.system_prompt or .tool_input.config.system_prompt (save_draft
# nests under config). If the prompt contains a markdown-table separator row
# or any em / en dash, exits 2 to block the deploy with a rule citation.
#
# Skip silently when no system_prompt is in the payload (e.g. attaching tools
# only). Skip silently when jq isn't available. Never break the dev loop.

set -uo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "pre-tool-system-prompt-check: jq not installed, skipping prompt validation." >&2
  echo "  Install jq to enable pre-deploy checks for markdown tables and em / en dashes." >&2
  echo "  macOS: brew install jq    Linux: apt install jq    or see https://stedolan.github.io/jq/" >&2
  exit 0
fi

SYSTEM_PROMPT=$(printf '%s' "$INPUT" | jq -r '
  .tool_input.system_prompt //
  .tool_input.patch.system_prompt //
  .tool_input.config.system_prompt //
  empty
' 2>/dev/null)

if [ -z "$SYSTEM_PROMPT" ] || [ "$SYSTEM_PROMPT" = "null" ]; then
  exit 0
fi

VIOLATIONS=()

# Markdown-table separator rows: pipe + dashes / colons / spaces + at least one
# more pipe + dashes / colons / spaces + final pipe. Catches |---|---|, | --- | --- |,
# |:---|---:|, etc. Won't false-positive on prose pipes (no separator dashes).
if printf '%s\n' "$SYSTEM_PROMPT" | grep -Eq '^[[:space:]]*\|[[:space:]]*:?-+:?[[:space:]]*(\|[[:space:]]*:?-+:?[[:space:]]*)+\|[[:space:]]*$'; then
  VIOLATIONS+=("markdown_table")
fi

# Em dash (U+2014) or en dash (U+2013). Strip backtick-quoted spans first so
# a self-check rule like `Replace every X` (documenting the character) doesn't
# false-positive. Real em dashes in body prose still trigger.
STRIPPED=$(printf '%s' "$SYSTEM_PROMPT" | sed 's/`[^`]*`//g')
if printf '%s' "$STRIPPED" | grep -Eq $'\xe2\x80\x94|\xe2\x80\x93'; then
  VIOLATIONS+=("em_dash")
fi

if [ ${#VIOLATIONS[@]} -eq 0 ]; then
  exit 0
fi

{
  echo ""
  echo "System prompt formatting check failed."
  echo ""
  echo "The system_prompt you're about to deploy violates one or more rules"
  echo "from .claude/rules/. Fix and retry."
  echo ""

  for v in "${VIOLATIONS[@]}"; do
    case "$v" in
      markdown_table)
        echo "  - Markdown table detected in system_prompt."
        echo "    Rule: BUILD_PRACTICES.md > 'System Prompts > No Markdown Tables'"
        echo "    Fix: convert to a bullet list. Example:"
        echo ""
        echo "      | Pattern | Use for |     ->   - **Pattern A** -- 3-column icon cards. Use for"
        echo "      |---|---|                       3 parallel benefits. Cap: 3 cards."
        echo "      | A | 3-column |                - **Pattern B** -- stacked text cards. Short list"
        echo "      | B | stacked |                   of ideas (2-4)."
        echo ""
        echo "    Markdown tables flatten to pipe-noise inside the agent UI's"
        echo "    prompt editor and are harder for the LLM to parse than bullets."
        echo "    Tables are fine in agent.md (human docs). Not in the deployed"
        echo "    system_prompt."
        echo ""
        ;;
      em_dash)
        echo "  - Em dash or en dash detected in system_prompt."
        echo "    Rule: CLAUDE.md > 'Hard Rules -- Never use em dashes'"
        echo "    Fix: replace with a comma, full stop, or parentheses. Use the"
        echo "         double-hyphen '--' if you want a long-dash effect."
        echo ""
        ;;
    esac
  done

  echo "See:"
  echo "  - .claude/rules/DOC_RULES.md > 'system-prompt.md formatting'"
  echo "  - .claude/rules/BUILD_PRACTICES.md > 'System Prompts'"
  echo ""
  echo "If this block is wrong (rare), edit scripts/pre-tool-system-prompt-check.sh"
  echo "or temporarily disable in .claude/settings.json. Don't bypass the rule"
  echo "silently."
} >&2

exit 2
