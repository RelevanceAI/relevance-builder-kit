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

### Step 2: Name This Folder

Ask the user:

> Choose a name for this folder. The name is appended as a suffix to the kit name, so the folder becomes `relevance-builder-kit-{suffix}` and the MCP server becomes `relevance-ai-kit-{suffix}`.
>
> Examples: `dev`, `prod`, `staging`, `personal`, `team`
>
> So `dev` gives you `relevance-builder-kit-dev` / `relevance-ai-kit-dev`.

Sanitize the suffix: lowercase, hyphens for spaces, alphanumeric and hyphens only. Strip any leading hyphen the user may include (e.g. `-dev` -> `dev`).

Rename the folder (suffix appended, do NOT replace `kit`):
```bash
mv /path/to/relevance-builder-kit /path/to/relevance-builder-kit-{suffix}
```

If the current folder is already `relevance-builder-kit-something`, treat the existing suffix as already-set and skip the rename unless the user wants to change it.

### Step 3: Customize .mcp.json

Ensure `.mcp.json` contains the project-specific server name (suffix appended to `relevance-ai-kit`, NOT replacing `kit`):

```json
{
  "mcpServers": {
    "relevance-ai-kit-{suffix}": {
      "type": "http",
      "url": "https://mcp.relevanceai.com"
    }
  }
}
```

The server name `relevance-ai-kit-{suffix}` ensures each clone of the kit has an independent MCP connection.

### Step 4: Configure Statusline

The statusline is wired into the project-level `.claude/settings.json` (committed). It runs `scripts/statusline.sh`, which is config-driven via `.claude/statusline.conf`. If the conf file is missing, the statusline shows a **minimal default**: project + branch + model. The setup walks the user through each optional section one at a time, showing an example, and writes the choices into `.claude/statusline.conf`.

Tell the user:

> The default statusline is minimal -- just project, branch, and model. I'll walk you through the optional sections one at a time. Say `yes` to add a section, `no` to skip. You can re-run `/setup` later to change your mind.
>
> Default looks like this:
> ```
> ⚡ relevance-builder-kit-dev 🌿 main 🤖 Opus 4.7
> ```

Then ask the user about each toggle in order. For each one, show the example, ask yes/no, and remember the answer. **Keep the same exact style as the current statusline** (colours, emojis, spacing). Do not invent new styles -- just toggle whether each existing section renders.

Toggles to walk through (in this order):

1. **Vim mode** -- shows current vim mode if vim mode is enabled in Claude Code.
   Example: `✎ INSERT`
   Conf key: `show_vim`

2. **Context window** -- coloured progress bar of context used, with token count.
   Example: `🧠 ████░░░░░░ 42% (420k/1000k tok)`
   Conf key: `show_context`

3. **Cost** -- total session cost in USD.
   Example: `💰 $0.123`
   Conf key: `show_cost`

4. **Duration** -- total session wall-clock time.
   Example: `⏱ 1m15s`
   Conf key: `show_duration`

5. **Lines changed** -- lines added / removed this session.
   Example: `+12 -3`
   Conf key: `show_lines`

6. **Output tokens** -- total tokens generated this session.
   Example: `✍ 12k`
   Conf key: `show_output_tokens`

7. **Cache hits** -- cache-read tokens this session.
   Example: `⚡cache 50k`
   Conf key: `show_cache`

8. **Rate limits** -- 5h and 7d rate limit usage bars (Pro / Max only).
   Example: `5h: ████░░░░░░ 42% ↺2h15m  7d: ██░░░░░░░░ 18% ↺5d12h`
   Conf key: `show_rate_limits`

After collecting all answers, write `.claude/statusline.conf` with one `KEY=value` line per toggle. Always include the three always-on lines (`show_project=true`, `show_branch=true`, `show_model=true`) for clarity, even though they are also the script defaults:

```bash
cat > .claude/statusline.conf <<EOF
show_project=true
show_branch=true
show_vim={true|false}
show_model=true
show_context={true|false}
show_cost={true|false}
show_duration={true|false}
show_lines={true|false}
show_output_tokens={true|false}
show_cache={true|false}
show_rate_limits={true|false}
EOF
```

After writing the file, show the user a one-line preview of what their statusline will look like with their selections and tell them to restart Claude Code (or wait for the next refresh) to see it live.

If the user wants to skip the walk-through entirely, just leave `.claude/statusline.conf` absent -- the script falls back to the minimal default.

If the user picks **everything**, the result looks like:

```
⚡ relevance-builder-kit-dev 🌿 main ✎ INSERT 🤖 Opus 4.7  🧠 ████░░░░░░ 42% (420k/1000k tok)  💰 $0.123  ⏱ 1m15s  +12 -3  ✍ 12k  ⚡cache 50k  5h: ██░░░░░░░░ 18% ↺2h15m  7d: █░░░░░░░░░ 8% ↺5d12h
```

Run `bash scripts/setup-statusline.sh` if the project-level `.claude/settings.json` ever loses its `statusLine` entry (e.g. someone hand-edited it). That script is for re-wiring the settings entry only, not for the conf toggles above.

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
