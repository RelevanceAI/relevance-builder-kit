---
name: setup
description: First-time setup for this kit -- MCP config verification (prod remote MCP), project naming, OAuth authentication, statusline, and first build folder. Use when someone says they just cloned the kit, needs to get connected, wants to set up the MCP connection, asks about statusline setup, or says "get me set up" or "I'm new here".
---

## When to Use

When someone opens Claude Code in this kit for the first time and needs to get set up. This does everything `setup.sh` does, but conversationally so the user does not need to leave Claude Code.

## Architecture Overview

Each Relevance AI project gets its own clone of this kit:

- **One folder per project** (e.g., `relevance-builder-personal`, `relevance-builder-team`)
- **OAuth authentication** against the official Relevance AI MCP server (no API keys stored locally, no plugin)
- **HTTP MCP server** connects to `mcp.relevanceai.com` (remote, loads operational skills on demand)

To work on multiple projects, clone the kit multiple times and open separate terminals.

## Prerequisites Check

Before starting, verify:

1. **Python 3** -- run `python3 --version` (3.10+ recommended)
2. **Git** -- run `git --version`
3. **Claude CLI** -- run `claude --version` (need 2.0.0+; if outdated, suggest `claude update`)

Stop here if prerequisites fail. Don't continue with partial setup.

## Setup Steps

### Step 1: Verify MCP Config

Confirm `.mcp.json` exists in the kit root and points to the Relevance AI prod MCP:

```bash
cat .mcp.json
```

Expected: a `mcpServers` entry with `"url": "https://mcp.relevanceai.com"`. If missing or wrong, restore it:

```bash
git checkout .mcp.json
```

The kit ships pre-wired -- no local plugin or submodule to initialize.

### Step 2: Project Naming

Ask the user:

> Choose a name for your project. This will:
> - Rename this folder to `relevance-builder-{name}`
> - Set the MCP server name to `relevance-ai-{name}`
>
> Examples: `personal`, `team`, `marketing`

Sanitize the name: lowercase, hyphens for spaces, alphanumeric and hyphens only.

Rename the folder:
```bash
mv /path/to/relevance-builder /path/to/relevance-builder-{name}
```

### Step 3: Customize .mcp.json

Ensure `.mcp.json` contains the project-specific server name:

```json
{
  "mcpServers": {
    "relevance-ai-{name}": {
      "type": "http",
      "url": "https://mcp.relevanceai.com"
    }
  }
}
```

The server name `relevance-ai-{name}` ensures each project folder has an independent MCP connection.

### Step 4: Configure Statusline

The statusline is configured in the project-level `.claude/settings.json` (committed to the repo), so it works automatically on pull. Run `bash scripts/setup-statusline.sh` if you need to re-setup or clean up a stale user-level entry.

### Step 5: Offer ccd Alias

Ask the user:

> Would you like a `ccd` shortcut for `claude --dangerously-skip-permissions`? This skips the permission prompts for every tool call. I'll add it to your shell config.

If yes, append to `~/.zshrc` (or `~/.bashrc`):
```bash
# Claude Code shortcut (skip permissions)
alias ccd="claude --dangerously-skip-permissions"
```

Only add if not already present. Tell the user to restart their shell or `source ~/.zshrc`.

### Step 6: Create First Build Folder

Ask the user:

> Want me to create your first build folder? This gives you a scaffold for documenting an agent build.
>
> What's the build called? (e.g. `lead-research`, `phone-receptionist`)

If yes, create:
```
builds/{build-name}/
  agent.md    # Template with mandatory fields (blank)
  tools/      # Tool docs go here
```

Use the agent.md template with blank fields for Agent ID, model, temperature, autonomy, tool table, knowledge tables, design decisions, workflow summary.

### Step 7: Run Verification

Run `bash scripts/verify-setup.sh` from the kit root and show the results. If anything fails, explain how to fix it.

### Step 8: Authenticate via OAuth

Tell the user:

> **Setup complete.** One last step: authenticate with Relevance AI:
>
> 1. Run `/mcp` in Claude Code
> 2. Your browser will open for OAuth login
> 3. Log in with your Relevance AI account and select your project
> 4. Once authorized, you're connected. No need to re-authenticate in this folder.
>
> **What's configured:**
>
> - **.mcp.json** -- HTTP MCP server with project-specific name
> - **Statusline** -- shows project folder name + model at the bottom
> - **First build folder** -- `builds/{build-name}/` ready for your first build (if created)
>
> **Next steps:**
>
> - Read `docs/getting-started.md` for a walkthrough
> - Or just tell me what you want to build
>
> **Key commands to know:**
>
> - `/agent-build-patterns` -- load design patterns before building
> - `/template-agent` -- design rubric and checklist for a starter agent
> - `/eval` -- generate and run platform evals

## Edge Cases

- **.mcp.json already customized:** skip Step 3 if it already has the right server name
- **Folder already renamed:** skip the rename in Step 2
- **No build folder needed:** skip Step 6 if user declines
- **OAuth needs re-auth:** tell the user to run `/mcp` again. It re-opens the browser login.
