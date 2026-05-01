#!/bin/bash
# Relevance Builder Kit -- one-time setup
# Run after cloning: bash setup.sh
#
# This script:
#   1. Checks prerequisites
#   2. Verifies .mcp.json points to the Relevance AI prod MCP server
#   3. Asks for a project name and renames the kit folder
#   4. Customizes .mcp.json with a project-specific server name
#   5. Configures the Claude Code statusline
#   6. Optionally adds a 'ccd' shell alias
#   7. Optionally creates your first build folder
#   8. Runs verification

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"

MIN_CLAUDE="2.1.3"
MIN_PYTHON="3.10"

echo "========================================="
echo "  Relevance Builder Kit Setup"
echo "========================================="
echo ""

# --- 1. Check prerequisites ---

echo "Checking prerequisites..."

MISSING=()

if ! command -v python3 &>/dev/null; then
  MISSING+=("python3")
fi

if ! command -v git &>/dev/null; then
  MISSING+=("git")
fi

if ! command -v claude &>/dev/null; then
  MISSING+=("claude CLI (install from claude.ai/claude-code)")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "ERROR: Missing required tools:"
  for m in "${MISSING[@]}"; do
    echo "  - $m"
  done
  echo ""
  echo "Install these and re-run setup."
  exit 1
fi

echo "  python3: $(python3 --version 2>&1 | head -1)"
echo "  git:     $(git --version)"
echo "  claude:  $(claude --version 2>/dev/null || echo 'unknown')"

CLAUDE_VERSION=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -n "$CLAUDE_VERSION" ]; then
  OLDEST=$(printf '%s\n%s\n' "$MIN_CLAUDE" "$CLAUDE_VERSION" | sort -V | head -1)
  if [ "$OLDEST" != "$MIN_CLAUDE" ]; then
    echo ""
    echo "WARNING: Claude CLI $CLAUDE_VERSION is below minimum $MIN_CLAUDE. Run: claude update"
  fi
fi

PY_VERSION=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
if [ -n "$PY_VERSION" ]; then
  OLDEST_PY=$(printf '%s\n%s\n' "$MIN_PYTHON" "$PY_VERSION" | sort -V | head -1)
  if [ "$OLDEST_PY" != "$MIN_PYTHON" ]; then
    echo ""
    echo "WARNING: Python $PY_VERSION is below recommended $MIN_PYTHON. Some scripts may not work correctly."
  fi
fi

echo ""

# --- 2. Verify MCP config ---

echo "Verifying MCP configuration..."
cd "$REPO_DIR"
MCP_JSON="$REPO_DIR/.mcp.json"
if [ ! -f "$MCP_JSON" ]; then
  echo "ERROR: .mcp.json missing. Restore it from the kit before continuing:"
  echo "       git checkout .mcp.json"
  exit 1
fi

MCP_URL=$(python3 -c "
import json, sys
try:
    d = json.load(open('$MCP_JSON'))
    servers = d.get('mcpServers', {})
    if not servers:
        sys.exit(2)
    print(next(iter(servers.values())).get('url', ''))
except Exception:
    sys.exit(2)
" 2>/dev/null)

if [ -z "$MCP_URL" ]; then
  echo "ERROR: .mcp.json is malformed or has no mcpServers entries."
  echo "       Restore it: git checkout .mcp.json"
  exit 1
fi

if [[ "$MCP_URL" != *"mcp.relevanceai.com"* ]]; then
  echo "WARNING: .mcp.json points to a non-default URL:"
  echo "         $MCP_URL"
  echo "         The kit ships pre-wired to https://mcp.relevanceai.com (Relevance AI prod)."
  echo "         If this was intentional, ignore. Otherwise restore: git checkout .mcp.json"
else
  echo "  MCP target: $MCP_URL"
fi
echo ""

# --- 3. Project naming ---

echo "Choose a name for your project."
echo "This will:"
echo "  - Rename this folder to relevance-builder-{name}"
echo "  - Set the MCP server name to relevance-ai-{name}"
echo ""
echo "Examples: personal, team, marketing"
echo ""
read -rp "Project name: " PROJECT_NAME

PROJECT_NAME_CLEAN=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')

if [ -z "$PROJECT_NAME_CLEAN" ]; then
  echo "ERROR: Invalid project name."
  exit 1
fi

MCP_SERVER_NAME="relevance-ai-${PROJECT_NAME_CLEAN}"
TARGET_DIR_NAME="relevance-builder-${PROJECT_NAME_CLEAN}"
CURRENT_DIR_NAME="$(basename "$REPO_DIR")"
PARENT_DIR="$(dirname "$REPO_DIR")"

if [ "$CURRENT_DIR_NAME" != "$TARGET_DIR_NAME" ]; then
  TARGET_PATH="$PARENT_DIR/$TARGET_DIR_NAME"

  if [ -d "$TARGET_PATH" ]; then
    echo "ERROR: $TARGET_PATH already exists. Pick a different name or remove the existing folder."
    exit 1
  fi

  echo "Renaming folder: $CURRENT_DIR_NAME -> $TARGET_DIR_NAME"
  echo ""
  echo "WARNING: about to rename this directory."
  echo "         If any other terminal has it open as CWD, that shell will be orphaned"
  echo "         (commands there will fail with 'No such file or directory')."
  echo "         Close those terminals before continuing."
  echo ""
  read -rp "Continue with rename? (y/n): " CONFIRM_RENAME
  if [[ ! "$CONFIRM_RENAME" =~ ^[Yy]$ ]]; then
    echo "Rename cancelled. Re-run setup.sh when ready."
    exit 0
  fi
  mv "$REPO_DIR" "$TARGET_PATH"
  REPO_DIR="$TARGET_PATH"
  SCRIPTS_DIR="$REPO_DIR/scripts"
  echo "  Done. Kit is now at: $REPO_DIR"
else
  echo "  Folder already named $TARGET_DIR_NAME, skipping rename."
fi

echo ""

# --- 4. Customize .mcp.json ---

MCP_JSON="$REPO_DIR/.mcp.json"

echo "Customizing .mcp.json with server name: $MCP_SERVER_NAME"

python3 -c "
import json
import sys

with open('$MCP_JSON') as f:
    data = json.load(f)

servers = data.get('mcpServers', {})
if not servers:
    print('ERROR: .mcp.json has no mcpServers entries. The file looks corrupted.', file=sys.stderr)
    print('       Restore it from the original kit or run: git checkout .mcp.json', file=sys.stderr)
    sys.exit(1)

old_key = next(iter(servers))
server_config = servers[old_key]

new_data = {'mcpServers': {'$MCP_SERVER_NAME': server_config}}
with open('$MCP_JSON', 'w') as f:
    json.dump(new_data, f, indent=2)
    f.write('\n')
"
echo "  .mcp.json updated."
echo ""

# --- 5. Configure statusline ---

if [ -f "$SCRIPTS_DIR/setup-statusline.sh" ]; then
  echo "Configuring statusline..."
  bash "$SCRIPTS_DIR/setup-statusline.sh"
fi

# --- 6. Offer ccd shell alias ---

echo ""
echo "Optional: 'ccd' shortcut for 'claude --dangerously-skip-permissions'."
echo "  This flag bypasses Claude Code's per-tool permission prompts."
echo "  It is faster, but Claude can run shell commands and edit files without asking."
echo "  Only enable if you understand and accept that tradeoff."
echo ""
read -rp "Add 'ccd' shell alias? (y/n): " ADD_ALIAS

if [[ "$ADD_ALIAS" =~ ^[Yy]$ ]]; then
  USER_SHELL="$(basename "${SHELL:-}")"

  case "$USER_SHELL" in
    fish)
      SHELL_RC="$HOME/.config/fish/config.fish"
      ALIAS_LINE='alias ccd "claude --dangerously-skip-permissions"'
      mkdir -p "$(dirname "$SHELL_RC")"
      ;;
    zsh)
      SHELL_RC="$HOME/.zshrc"
      ALIAS_LINE='alias ccd="claude --dangerously-skip-permissions"'
      ;;
    bash)
      SHELL_RC="$HOME/.bashrc"
      ALIAS_LINE='alias ccd="claude --dangerously-skip-permissions"'
      ;;
    *)
      # Fall back: pick whichever rc file exists, default to zshrc on macOS.
      if [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
      elif [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
      else
        SHELL_RC="$HOME/.zshrc"
      fi
      ALIAS_LINE='alias ccd="claude --dangerously-skip-permissions"'
      echo "  Could not detect shell ($USER_SHELL); defaulting to $SHELL_RC."
      echo "  If your shell uses different syntax, add this manually instead:"
      echo "    $ALIAS_LINE"
      ;;
  esac

  # Anchored grep so a comment containing 'alias ccd=' doesn't false-positive.
  if grep -qE '^\s*alias\s+ccd[= ]' "$SHELL_RC" 2>/dev/null; then
    echo "  ccd alias already exists in $SHELL_RC"
  else
    echo "" >> "$SHELL_RC"
    echo "# Claude Code shortcut (skip permissions)" >> "$SHELL_RC"
    echo "$ALIAS_LINE" >> "$SHELL_RC"
    echo "  Added ccd alias to $SHELL_RC (restart your shell or run: source $SHELL_RC)"
  fi
fi

# --- 7. Create first build folder ---

echo ""
read -rp "Create your first build folder in builds/? (y/n): " CREATE_BUILD

if [[ "$CREATE_BUILD" =~ ^[Yy]$ ]]; then
  read -rp "Build name (e.g. 'lead-research', 'phone-receptionist'): " BUILD_NAME
  BUILD_DIR_NAME=$(echo "$BUILD_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')

  if [ -n "$BUILD_DIR_NAME" ]; then
    BUILD_DIR="$REPO_DIR/builds/$BUILD_DIR_NAME"
    mkdir -p "$BUILD_DIR/tools"

    if [ ! -f "$BUILD_DIR/agent.md" ]; then
      cat > "$BUILD_DIR/agent.md" << 'AGENTEOF'
# Agent Name

## Agent Config

| Field | Value |
|-------|-------|
| Agent ID | |
| Project | |
| Region | |
| Model | |
| Temperature | |
| Autonomy | |

## Tools

| Tool | Studio ID | Action ID | Purpose |
|------|-----------|-----------|---------|
| | | | |

## Knowledge Tables

| Table | Purpose |
|-------|---------|
| | |

## Key Design Decisions

-

## Workflow Summary

1.
AGENTEOF
      echo "  Created builds/$BUILD_DIR_NAME/agent.md"
    else
      echo "  builds/$BUILD_DIR_NAME/agent.md already exists"
    fi

    if [ ! -f "$BUILD_DIR/system-prompt.md" ]; then
      cat > "$BUILD_DIR/system-prompt.md" << 'PROMPTEOF'
# System Prompt

Notes (preamble, not deployed):

- Edit only the body between BEGIN PROMPT / END PROMPT markers.
- No markdown tables in the body. The pre-tool hook blocks deploys that contain them.
- No em or en dashes. Use commas, full stops, parentheses, or `--`.
- Tool references: bare `{{_actions.<id>}}` pills only. No backticks, no bold around them.

---

BEGIN PROMPT

# Identity

You are a [role] for [purpose]. You operate on ONE [entity] per task.

# Scope

You answer [scope]. You decline anything else.

# Rules

- [rule]
- [rule]

# Your Tools

{{_actions.<id>}}

# Workflow

1. [step]
2. [step]

# Output Format

[describe the output shape]

END PROMPT
PROMPTEOF
      echo "  Created builds/$BUILD_DIR_NAME/system-prompt.md"
    else
      echo "  builds/$BUILD_DIR_NAME/system-prompt.md already exists"
    fi
  fi
fi

# --- 8. Run verification ---

echo ""
echo "Running verification..."
if [ -f "$SCRIPTS_DIR/verify-setup.sh" ]; then
  bash "$SCRIPTS_DIR/verify-setup.sh"
fi

# --- 9. Next steps ---

echo ""
echo "========================================="
echo "  Setup complete."
echo "========================================="
echo ""
echo "Your project: $PROJECT_NAME_CLEAN"
echo "Kit folder:   $(basename "$REPO_DIR")"
echo "MCP server:   $MCP_SERVER_NAME"
echo "MCP target:   https://mcp.relevanceai.com (Relevance AI prod, OAuth)"
echo ""
echo "========================================="
echo "  AUTHENTICATE MCP"
echo "========================================="
echo ""
echo "To connect to Relevance AI, open Claude Code and run:"
echo ""
echo "  /mcp"
echo ""
echo "This will trigger OAuth login in your browser against mcp.relevanceai.com."
echo "Log in with your Relevance AI account and select your project."
echo ""
echo "-----------------------------------------"
echo ""
echo "Next steps:"
echo "  1. cd $REPO_DIR"
echo "  2. Start Claude Code:  claude"
echo "  3. Run /mcp to authenticate"
echo "  4. Read the onboarding guide:  docs/getting-started.md"
echo ""
echo "Quick reference:  docs/advanced-usage.md"
echo ""
