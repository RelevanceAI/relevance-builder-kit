#!/usr/bin/env bash
# PreToolUse hook: block agent-write tool calls whose system_prompt or emoji
# violate the deployable-config rules.
#
# Triggered by .claude/settings.json on:
#   - relevance_upsert_agent
#   - relevance_patch_agent
#   - relevance_save_agent_draft
#
# Reads the tool call JSON on stdin. Two independent checks:
#   1. system_prompt formatting (markdown tables, em / en dashes)
#   2. emoji must be a CDN URL, not a unicode character (BUILD_PRACTICES § Avatars)
#
# Pulls fields from .tool_input.<field>, .tool_input.config.<field> (save_draft),
# or .tool_input.patch.<field> (patch_agent). Each check runs only when its
# field is in the payload. Skip silently when jq isn't available. Never break
# the dev loop.

set -uo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "pre-tool-system-prompt-check: jq not installed, skipping prompt + avatar validation." >&2
  echo "  Install jq to enable pre-deploy checks for markdown tables, em / en dashes, and avatar URLs." >&2
  echo "  macOS: brew install jq    Linux: apt install jq    or see https://stedolan.github.io/jq/" >&2
  exit 0
fi

SYSTEM_PROMPT=$(printf '%s' "$INPUT" | jq -r '
  .tool_input.system_prompt //
  .tool_input.patch.system_prompt //
  .tool_input.config.system_prompt //
  .tool_input.patch.system_prompt //
  empty
' 2>/dev/null)

EMOJI=$(printf '%s' "$INPUT" | jq -r '
  .tool_input.emoji //
  .tool_input.config.emoji //
  .tool_input.patch.emoji //
  empty
' 2>/dev/null)

VIOLATIONS=()

if [ -n "$SYSTEM_PROMPT" ] && [ "$SYSTEM_PROMPT" != "null" ]; then
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
fi

if [ -n "$EMOJI" ] && [ "$EMOJI" != "null" ]; then
  # Agent avatars must be CDN SVG URLs, not unicode emojis (BUILD_PRACTICES § Avatars).
  # Check: the value must start with http:// or https://. Unicode emoji, plain text,
  # or empty-but-set values fail.
  if ! printf '%s' "$EMOJI" | grep -Eq '^https?://'; then
    VIOLATIONS+=("unicode_avatar")
  fi
fi

if [ ${#VIOLATIONS[@]} -eq 0 ]; then
  exit 0
fi

{
  echo ""
  echo "Agent-write check failed."
  echo ""
  echo "The agent config you're about to deploy violates one or more rules"
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
      unicode_avatar)
        echo "  - Agent emoji is set to a unicode character, not a CDN URL."
        echo "    Rule: BUILD_PRACTICES.md > 'Agent Config > Avatars'"
        echo "    Fix: use a Relevance CDN avatar URL. Pattern:"
        echo ""
        echo "      https://cdn.jsdelivr.net/gh/RelevanceAI/content-cdn@latest/agents/agent_avatars/agent_avatar_{N}.svg"
        echo "      (range: 10-24 for default agents)"
        echo ""
        echo "      Phone agents: phone_agent_avatar_{N}.svg (range: 08-12)"
        echo ""
        echo "    Unicode emoji avatars do not match the kit's deployment standard."
        echo "    Pick an N from the documented range, or browse the CDN directory:"
        echo "    https://github.com/RelevanceAI/content-cdn/tree/main/agents/agent_avatars"
        echo ""
        ;;
    esac
  done

  echo "See:"
  echo "  - .claude/rules/DOC_RULES.md > 'system-prompt.md formatting'"
  echo "  - .claude/rules/BUILD_PRACTICES.md > 'System Prompts' / 'Agent Config > Avatars'"
  echo ""
  echo "If this block is wrong (rare), edit scripts/pre-tool-system-prompt-check.sh"
  echo "or temporarily disable in .claude/settings.json. Don't bypass the rule"
  echo "silently."
} >&2

exit 2
