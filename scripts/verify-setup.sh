#!/bin/bash
# Verify Relevance Builder Kit setup is working correctly.
# Run standalone:  bash scripts/verify-setup.sh
# Also called automatically by setup.sh at the end of setup.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SETTINGS="$HOME/.claude/settings.json"

MIN_CLAUDE="2.1.3"
MIN_PYTHON="3.10"

PASS=0
FAIL=0
WARN=0
WARN_FIXES=()

check_pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
check_fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
check_warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); [ -n "${2:-}" ] && WARN_FIXES+=("$2"); }

echo "Verifying setup..."
echo ""

# --- Prerequisites ---

if command -v python3 &>/dev/null; then
  PY_VERSION=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  OLDEST_PY=$(printf '%s\n%s\n' "$MIN_PYTHON" "$PY_VERSION" | sort -V | head -1)
  if [ "$OLDEST_PY" = "$MIN_PYTHON" ]; then
    check_pass "python3 installed ($PY_VERSION)"
  else
    check_warn "python3 $PY_VERSION is below recommended $MIN_PYTHON (still works, but consider upgrading)" \
      "Upgrade Python: brew install python@3.12  (macOS) or apt install python3.12  (Debian / Ubuntu)"
  fi
else
  check_fail "python3 not found"
fi

if command -v claude &>/dev/null; then
  CLAUDE_VERSION=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [ -n "$CLAUDE_VERSION" ]; then
    OLDEST_CL=$(printf '%s\n%s\n' "$MIN_CLAUDE" "$CLAUDE_VERSION" | sort -V | head -1)
    if [ "$OLDEST_CL" = "$MIN_CLAUDE" ]; then
      check_pass "claude CLI installed ($CLAUDE_VERSION)"
    else
      check_warn "claude CLI $CLAUDE_VERSION is below minimum $MIN_CLAUDE" \
        "Update Claude Code: claude update"
    fi
  else
    check_pass "claude CLI installed (version unknown)"
  fi
else
  check_fail "claude CLI not found (install from claude.ai/claude-code)"
fi

# --- .mcp.json ---

MCP_JSON="$REPO_DIR/.mcp.json"
if [ -f "$MCP_JSON" ]; then
  if python3 -c "import json; json.load(open('$MCP_JSON'))" 2>/dev/null; then
    check_pass ".mcp.json is valid JSON"

    if grep -q "mcp.relevanceai.com" "$MCP_JSON"; then
      check_pass ".mcp.json points to Relevance AI prod MCP (mcp.relevanceai.com)"
    else
      check_warn ".mcp.json does not point to mcp.relevanceai.com" \
        "Restore default URL: git checkout .mcp.json"
    fi
  else
    check_fail ".mcp.json is not valid JSON"
  fi
else
  check_fail ".mcp.json not found (run bash setup.sh from the kit root to restore it)"
fi

# --- Statusline ---

if [ -f "$SCRIPT_DIR/statusline.sh" ] && [ -x "$SCRIPT_DIR/statusline.sh" ]; then
  check_pass "statusline.sh exists and is executable"
else
  check_warn "statusline.sh missing or not executable" \
    "Make statusline executable: chmod +x scripts/statusline.sh"
fi

PROJECT_SETTINGS="$REPO_DIR/.claude/settings.json"
if [ -f "$PROJECT_SETTINGS" ]; then
  HAS_STATUSLINE=$(python3 -c "
import json
d = json.load(open('$PROJECT_SETTINGS'))
print('yes' if 'statusLine' in d else 'no')
" 2>/dev/null)

  if [ "$HAS_STATUSLINE" = "yes" ]; then
    check_pass "Statusline configured in project settings"
  else
    check_warn "Statusline not configured" \
      "Configure statusline: bash scripts/setup-statusline.sh"
  fi
else
  check_warn "Project settings file not found at $PROJECT_SETTINGS" \
    "Re-run setup: bash setup.sh"
fi

# --- Summary ---

echo ""
echo "Results: $PASS passed, $FAIL failed, $WARN warnings"

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "Fix the failures above before starting Claude Code."
  exit 1
fi

if [ $WARN -gt 0 ]; then
  echo ""
  echo "----------------------------------------------------"
  echo "Warnings are non-blocking but worth addressing."
  echo "----------------------------------------------------"
  for fix in "${WARN_FIXES[@]}"; do
    echo "  -> $fix"
  done
  echo ""
fi
