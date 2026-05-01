#!/bin/bash
# Relevance Builder Kit -- First-Time Setup
#
# Run from the kit root:   bash setup.sh
# Idempotent. Safe to re-run any time.
#
# What it does:
#   1. Checks prerequisites (python3, git, claude CLI)
#   2. Verifies .mcp.json points to the prod Relevance AI MCP
#   3. Names this clone (folder + MCP server suffix)
#   4. Walks the statusline toggles
#   5. Optional: ccd shell alias
#   6. Optional: scaffolds your first build folder
#   7. Runs verify-setup.sh
#
# After it finishes, start Claude Code in this folder and run /mcp
# to authenticate with Relevance AI via OAuth.

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_STEPS=7

# ── Colors ──────────────────────────────────────────────
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RED=$'\033[38;5;196m'
  GREEN=$'\033[38;5;82m'
  YELLOW=$'\033[38;5;226m'
  BLUE=$'\033[38;5;75m'
  ORANGE=$'\033[38;5;214m'
  PURPLE=$'\033[38;5;141m'
  RESET=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; ORANGE=""; PURPLE=""; RESET=""
fi

# ── UI helpers ──────────────────────────────────────────
header() {
  local step="$1"; local title="$2"
  echo
  echo "${BOLD}${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo "${BOLD}${ORANGE}  Step ${step}/${TOTAL_STEPS}  ${RESET}${BOLD}${title}${RESET}"
  echo "${BOLD}${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo
}
ok()    { echo "  ${GREEN}✓${RESET} $1"; }
warn()  { echo "  ${YELLOW}⚠${RESET} $1"; }
fail()  { echo "  ${RED}✗${RESET} $1"; }
info()  { echo "  ${BLUE}ℹ${RESET} $1"; }
ask()   { printf "  ${BOLD}>${RESET} %s" "$1"; }

trap 'echo; fail "Setup interrupted. Re-run when ready."; exit 130' INT

# ── Banner ──────────────────────────────────────────────
echo
echo "${BOLD}${PURPLE}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}${PURPLE}║       Relevance Builder Kit -- First-Time Setup           ║${RESET}"
echo "${BOLD}${PURPLE}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo
echo "  Wires this clone to one Relevance AI project."
echo "  ${DIM}Idempotent. Re-run any time.${RESET}"
echo
echo "  ${DIM}Working in: $REPO_DIR${RESET}"

# ── Step 1: Prerequisites ───────────────────────────────
header 1 "Prerequisites"

MISSING=0

if command -v python3 >/dev/null 2>&1; then
  PY=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  ok "python3       ${DIM}$PY${RESET}"
else
  fail "python3 not found"
  info "Install: brew install python  (macOS) or apt install python3  (Linux)"
  MISSING=1
fi

if command -v git >/dev/null 2>&1; then
  GIT_V=$(git --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  ok "git           ${DIM}$GIT_V${RESET}"
else
  fail "git not found"
  MISSING=1
fi

if command -v claude >/dev/null 2>&1; then
  CC=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [ -n "$CC" ]; then
    ok "claude CLI    ${DIM}$CC${RESET}"
  else
    ok "claude CLI    ${DIM}(version unknown)${RESET}"
  fi
else
  fail "claude CLI not found"
  info "Install from claude.com/claude-code"
  MISSING=1
fi

if [ "$MISSING" = "1" ]; then
  echo
  fail "Missing prerequisites. Install them and re-run setup."
  exit 1
fi

# ── Step 2: MCP Config ──────────────────────────────────
header 2 "MCP configuration"

MCP_JSON="$REPO_DIR/.mcp.json"

if [ ! -f "$MCP_JSON" ]; then
  warn ".mcp.json missing"
  if git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    info "Restoring from git..."
    git -C "$REPO_DIR" checkout .mcp.json
    ok ".mcp.json restored"
  else
    fail "Not a git repo and no .mcp.json. Re-clone the kit."
    exit 1
  fi
fi

if ! python3 -c "import json; json.load(open('$MCP_JSON'))" 2>/dev/null; then
  fail ".mcp.json has invalid JSON"
  exit 1
fi

if ! grep -q "mcp.relevanceai.com" "$MCP_JSON"; then
  warn ".mcp.json does not point to mcp.relevanceai.com"
  ask "Restore default? [Y/n]: "
  read -r ANS
  if [ -z "$ANS" ] || [ "$ANS" = "y" ] || [ "$ANS" = "Y" ]; then
    git -C "$REPO_DIR" checkout .mcp.json
    ok "Restored from git"
  fi
fi

CURRENT_SERVER=$(python3 -c "
import json
d = json.load(open('$MCP_JSON'))
keys = list(d.get('mcpServers', {}).keys())
print(keys[0] if keys else '')
")

ok ".mcp.json valid"
info "Server name:     ${BOLD}${CURRENT_SERVER:-<none>}${RESET}"
info "URL:             ${BOLD}https://mcp.relevanceai.com${RESET}"

# ── Step 3: Folder & Server Suffix ──────────────────────
header 3 "Folder & MCP server suffix"

cat <<EOF
  Pick a suffix that ${BOLD}matches the Relevance AI project${RESET} this clone
  will build agents in. One clone = one Relevance project, so the
  match keeps it obvious which folder belongs to which project, and
  prevents multiple clones from colliding.

  Folder:       ${BOLD}relevance-builder-kit-{suffix}${RESET}
  MCP server:   ${BOLD}relevance-ai-kit-{suffix}${RESET}

  Use the project name lowercased and hyphenated.
  ${DIM}e.g. \"Lead Research\" -> lead-research, \"ACME Prod\" -> acme-prod${RESET}

EOF

CURRENT_FOLDER=$(basename "$REPO_DIR")
PARENT_DIR=$(dirname "$REPO_DIR")
CURRENT_SUFFIX=""
if [[ "$CURRENT_FOLDER" =~ ^relevance-builder-kit-(.+)$ ]]; then
  CURRENT_SUFFIX="${BASH_REMATCH[1]}"
  info "Current folder: ${BOLD}$CURRENT_FOLDER${RESET}"
  info "Current suffix: ${BOLD}$CURRENT_SUFFIX${RESET}"
  ask "Press Enter to keep '${BOLD}$CURRENT_SUFFIX${RESET}' or type a new suffix: "
elif [ "$CURRENT_FOLDER" = "relevance-builder-kit" ]; then
  info "Current folder: ${BOLD}$CURRENT_FOLDER${RESET} (no suffix yet)"
  ask "Choose a suffix: "
else
  warn "Folder '$CURRENT_FOLDER' does not match the kit naming convention"
  ask "Suffix to rename to 'relevance-builder-kit-{suffix}' (or type 'skip'): "
fi

read -r SUFFIX_INPUT

# Sanitize: strip leading hyphens, lowercase, replace invalid chars with hyphen
SUFFIX=$(echo "$SUFFIX_INPUT" | tr '[:upper:]' '[:lower:]' | sed 's/^-*//' | sed 's/[^a-z0-9-]/-/g')

if [ -z "$SUFFIX_INPUT" ] && [ -n "$CURRENT_SUFFIX" ]; then
  SUFFIX="$CURRENT_SUFFIX"
  ok "Keeping suffix: ${BOLD}$SUFFIX${RESET}"
elif [ "$SUFFIX_INPUT" = "skip" ]; then
  warn "Skipping rename. Hooks may not fire until the server is renamed."
  SUFFIX=""
elif [ -z "$SUFFIX" ]; then
  fail "Suffix cannot be empty"
  exit 1
elif [ "$SUFFIX" != "$SUFFIX_INPUT" ]; then
  ok "Sanitized: ${DIM}$SUFFIX_INPUT${RESET} -> ${BOLD}$SUFFIX${RESET}"
else
  ok "Suffix: ${BOLD}$SUFFIX${RESET}"
fi

# Rename folder if needed
if [ -n "$SUFFIX" ]; then
  TARGET_FOLDER="relevance-builder-kit-$SUFFIX"
  if [ "$CURRENT_FOLDER" != "$TARGET_FOLDER" ]; then
    NEW_PATH="$PARENT_DIR/$TARGET_FOLDER"
    if [ -e "$NEW_PATH" ]; then
      fail "Cannot rename: $NEW_PATH already exists"
      info "Either pick a different suffix or remove the existing folder."
      exit 1
    fi
    info "Renaming: ${DIM}$CURRENT_FOLDER${RESET} -> ${ORANGE}$TARGET_FOLDER${RESET}"
    mv "$REPO_DIR" "$NEW_PATH"
    REPO_DIR="$NEW_PATH"
    MCP_JSON="$REPO_DIR/.mcp.json"
    cd "$REPO_DIR"
    ok "Folder renamed"
    warn "After this script exits, ${BOLD}cd $REPO_DIR${RESET} (your shell is still in the old path)"
  else
    ok "Folder already named ${BOLD}$TARGET_FOLDER${RESET}"
  fi

  # Update MCP server name
  TARGET_SERVER="relevance-ai-kit-$SUFFIX"
  if [ "$CURRENT_SERVER" != "$TARGET_SERVER" ]; then
    info "Renaming MCP server: ${DIM}$CURRENT_SERVER${RESET} -> ${ORANGE}$TARGET_SERVER${RESET}"
    python3 - <<PYEOF
import json
with open("$MCP_JSON") as f:
    d = json.load(f)
servers = d.get("mcpServers", {})
new_servers = {}
for k, v in servers.items():
    if k == "$CURRENT_SERVER":
        new_servers["$TARGET_SERVER"] = v
    else:
        new_servers[k] = v
d["mcpServers"] = new_servers
with open("$MCP_JSON", "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
PYEOF
    ok "Server name updated in .mcp.json"
  else
    ok "MCP server already named ${BOLD}$TARGET_SERVER${RESET}"
  fi
fi

# ── Step 4: Statusline ──────────────────────────────────
header 4 "Statusline configuration"

PROJECT_DISPLAY="${SUFFIX:+relevance-builder-kit-$SUFFIX}"
[ -z "$PROJECT_DISPLAY" ] && PROJECT_DISPLAY="$(basename "$REPO_DIR")"

cat <<EOF
  Default (always on):

    ${ORANGE}⚡ $PROJECT_DISPLAY${RESET} ${BLUE}🌿 main${RESET} ${PURPLE}🤖 Opus 4.7${RESET}

  Optional sections you can toggle:

    1. Vim mode               ${DIM}✎ INSERT${RESET}
    2. Context window bar     ${DIM}🧠 ████░░░░░░ 42% (420k/1000k tok)${RESET}
    3. Cost                   ${DIM}💰 \$0.123${RESET}
    4. Duration               ${DIM}⏱ 1m15s${RESET}
    5. Lines changed          ${DIM}+12 -3${RESET}
    6. Output tokens          ${DIM}✍ 12k${RESET}
    7. Cache hits             ${DIM}⚡cache 50k${RESET}
    8. Rate limits (Pro/Max)  ${DIM}5h: ████░░ 42% ↺2h15m${RESET}

EOF

show_vim=false
show_context=false
show_cost=false
show_duration=false
show_lines=false
show_output_tokens=false
show_cache=false
show_rate_limits=false

ask "Pick mode: [a]ll on, [n]one (minimal default), or [c]ustomise one by one? [a/n/c]: "
read -r MODE

case "$MODE" in
  a|A|all)
    show_vim=true
    show_context=true
    show_cost=true
    show_duration=true
    show_lines=true
    show_output_tokens=true
    show_cache=true
    show_rate_limits=true
    ok "All sections on"
    ;;
  n|N|none|"")
    ok "Minimal default (project + branch + model only)"
    ;;
  c|C|custom|customise|customize|*)
    ask_toggle() {
      local var="$1" label="$2" example="$3"
      echo
      echo "    ${BOLD}$label${RESET}  ${DIM}$example${RESET}"
      printf "    ${BOLD}>${RESET} Show? [y/N]: "
      read -r a
      case "$a" in y|Y|yes) eval "$var=true" ;; *) eval "$var=false" ;; esac
    }
    ask_toggle show_vim           "Vim mode"             "✎ INSERT"
    ask_toggle show_context       "Context window bar"   "🧠 ████░░░░░░ 42% (420k/1000k tok)"
    ask_toggle show_cost          "Cost"                 "💰 \$0.123"
    ask_toggle show_duration      "Duration"             "⏱ 1m15s"
    ask_toggle show_lines         "Lines changed"        "+12 -3"
    ask_toggle show_output_tokens "Output tokens"        "✍ 12k"
    ask_toggle show_cache         "Cache hits"           "⚡cache 50k"
    ask_toggle show_rate_limits   "Rate limits"          "5h: ████░░ 42% ↺2h15m"
    echo
    ;;
esac

cat > "$REPO_DIR/.claude/statusline.conf" <<CONF
show_project=true
show_branch=true
show_vim=$show_vim
show_model=true
show_context=$show_context
show_cost=$show_cost
show_duration=$show_duration
show_lines=$show_lines
show_output_tokens=$show_output_tokens
show_cache=$show_cache
show_rate_limits=$show_rate_limits
CONF

ok "Wrote .claude/statusline.conf"
info "Restart Claude Code (or wait for the next refresh) to see changes."

# ── Step 5: ccd alias ───────────────────────────────────
header 5 "Optional: 'ccd' shell alias"

cat <<EOF
  ${BOLD}ccd${RESET} = ${DIM}claude --dangerously-skip-permissions${RESET}

  Skips permission prompts on every tool call. Faster, but Claude
  can run shell commands and edit files without asking. Only enable
  if you accept that tradeoff.

EOF

SHELL_RC=""
case "$(basename "${SHELL:-}")" in
  zsh)  SHELL_RC="$HOME/.zshrc"  ;;
  bash) SHELL_RC="$HOME/.bashrc" ;;
  *)
    [ -f "$HOME/.zshrc"  ] && SHELL_RC="$HOME/.zshrc"
    [ -z "$SHELL_RC" ] && [ -f "$HOME/.bashrc" ] && SHELL_RC="$HOME/.bashrc"
    ;;
esac

if [ -n "$SHELL_RC" ] && grep -q '^alias ccd=' "$SHELL_RC" 2>/dev/null; then
  ok "ccd alias already set in $SHELL_RC"
else
  ask "Add 'ccd' alias to ${SHELL_RC:-shell config}? [y/N]: "
  read -r ANS
  if [ "$ANS" = "y" ] || [ "$ANS" = "Y" ] || [ "$ANS" = "yes" ]; then
    if [ -z "$SHELL_RC" ]; then
      warn "Could not detect shell config (~/.zshrc or ~/.bashrc). Skipping."
    else
      {
        echo ""
        echo "# Claude Code shortcut (skip permissions)"
        echo 'alias ccd="claude --dangerously-skip-permissions"'
      } >> "$SHELL_RC"
      ok "Added to $SHELL_RC"
      info "Reload your shell: ${BOLD}source $SHELL_RC${RESET}"
    fi
  else
    info "Skipped"
  fi
fi

# ── Step 6: First Build Folder ──────────────────────────
header 6 "Optional: scaffold your first build folder"

cat <<EOF
  Each agent build lives under ${BOLD}builds/{name}/${RESET} with an
  agent.md (build journal) and system-prompt.md (deployable prompt).

  ${DIM}Already see builds/example/ for a worked reference build.${RESET}

EOF

ask "Create a new build folder now? [y/N]: "
read -r ANS

if [ "$ANS" = "y" ] || [ "$ANS" = "Y" ] || [ "$ANS" = "yes" ]; then
  ask "Build name (e.g. lead-research, phone-receptionist): "
  read -r BUILD_NAME
  BUILD_NAME=$(echo "$BUILD_NAME" | tr '[:upper:] ' '[:lower:]-' | sed 's/[^a-z0-9-]//g')
  if [ -z "$BUILD_NAME" ]; then
    warn "Empty name, skipping"
  elif [ -d "$REPO_DIR/builds/$BUILD_NAME" ]; then
    warn "builds/$BUILD_NAME already exists, skipping"
  else
    mkdir -p "$REPO_DIR/builds/$BUILD_NAME/tools"
    cat > "$REPO_DIR/builds/$BUILD_NAME/agent.md" <<MD
# $BUILD_NAME

## Identity

- **Agent ID:**
- **Name:**
- **Model:**
- **Temperature:**
- **Autonomy:**
- **Owner:**

## Purpose

(One paragraph: what this agent does, who uses it, when.)

## Tools

| Tool | Studio ID | Action ID | Purpose |
|------|-----------|-----------|---------|
|      |           |           |         |

## Knowledge tables

(Tables this agent reads from / writes to.)

## Workforce context (if applicable)

- **Workforce ID:**
- **Node ID:**
- **Edge type:**

## Design decisions

(Why-not-what notes that future-you will need.)

## Workflow summary

(High-level numbered list.)

## System prompt

See [system-prompt.md](./system-prompt.md).

## Test plan

Auto-generate via \`/eval\` after first deploy.
MD
    cat > "$REPO_DIR/builds/$BUILD_NAME/system-prompt.md" <<'MD'
<!-- BEGIN PROMPT -->

# Identity

You are ...

# Scope

You handle ...
You decline anything outside scope.

# Rules

- ...

# Your tools

(Insert {{_actions.ID}} pills here once tools are attached.)

# Workflow

1. ...

# Output

...

<!-- END PROMPT -->
MD
    ok "Scaffolded ${BOLD}builds/$BUILD_NAME/${RESET}"
    info "Files: agent.md, system-prompt.md, tools/"
  fi
else
  info "Skipped"
fi

# ── Step 7: Verification ────────────────────────────────
header 7 "Verification"

if [ -f "$REPO_DIR/scripts/verify-setup.sh" ]; then
  bash "$REPO_DIR/scripts/verify-setup.sh" || true
else
  warn "scripts/verify-setup.sh missing"
fi

# ── Final ───────────────────────────────────────────────
echo
echo "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}${GREEN}║                    Setup Complete                         ║${RESET}"
echo "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo
echo "  ${BOLD}One more step: authenticate with Relevance AI.${RESET}"
echo
echo "  ${BOLD}1.${RESET} Start Claude Code from this folder:"
echo "       ${ORANGE}cd \"$REPO_DIR\"${RESET}"
echo "       ${ORANGE}claude${RESET}"
echo
echo "  ${BOLD}2.${RESET} Inside Claude Code, run:"
echo "       ${ORANGE}/mcp${RESET}"
echo
echo "  Your browser opens for OAuth login. Pick the project that"
echo "  matches the folder suffix and authorize. Done."
echo
echo "  ${BOLD}Then start building. Useful skills:${RESET}"
echo "       ${BLUE}/agent-build-patterns${RESET}   ${DIM}-- design philosophy and patterns${RESET}"
echo "       ${BLUE}/template-agent${RESET}         ${DIM}-- starter agent design rubric${RESET}"
echo "       ${BLUE}/eval${RESET}                   ${DIM}-- generate and run platform evals${RESET}"
echo
