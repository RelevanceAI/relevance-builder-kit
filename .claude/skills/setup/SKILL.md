---
name: setup
description: First-time setup for this kit. Setup is an interactive bash script (setup.sh) that runs in the user's terminal -- not a conversational skill. Use this skill when the user asks "/setup", says they just cloned the kit, asks how to get connected, or wants to set up MCP / statusline. Tell them to exit Claude Code and run `bash setup.sh` from the kit root.
---

## What to do when this skill is invoked

Setup is now a self-contained interactive bash script -- **not** a conversational walkthrough. It handles prerequisites, MCP config, folder + server suffix, statusline toggles, the optional `ccd` alias, an optional first build folder, and verification, all in one terminal session.

Tell the user (verbatim or close to it):

> Setup runs as a single interactive bash script in your terminal. Exit Claude Code, then from the kit root run:
>
> ```bash
> bash setup.sh
> ```
>
> It walks through prerequisites, folder + MCP server naming, the statusline, an optional `ccd` alias, an optional first build folder, and a verification pass. Idempotent -- safe to re-run any time.
>
> When it finishes, it tells you to start Claude Code in the (possibly renamed) folder and run `/mcp` to authenticate via OAuth.

That's it. Do not try to walk the user through setup conversationally inside Claude Code -- the bash script is the single source of truth so the flow stays synced and the user doesn't context-switch between terminal and chat.

## Why bash, not a conversational skill

Earlier versions of `/setup` ran each step as a back-and-forth in chat, which (a) forced the user to bounce between terminal and Claude Code (closing/reopening for the folder rename, sourcing rc files), and (b) drifted out of sync with `setup.sh`. The bash flow keeps everything in one terminal session and survives the folder rename without tearing down the Claude Code session.

## What setup.sh does

1. **Prerequisites** -- python3, git, claude CLI checks
2. **MCP config** -- verifies `.mcp.json` points to `mcp.relevanceai.com` (restores from git if missing)
3. **Folder + server suffix** -- prompts for a suffix (e.g. `dev`, `prod`, `team`), renames folder to `relevance-builder-kit-{suffix}` and MCP server to `relevance-ai-kit-{suffix}`
4. **Statusline** -- offers `[a]ll on / [n]one / [c]ustomise` mode; writes `.claude/statusline.conf`
5. **`ccd` alias** -- optional, appends to `~/.zshrc` or `~/.bashrc`
6. **First build folder** -- optional scaffold of `builds/{name}/` with starter `agent.md` + `system-prompt.md`
7. **Verification** -- runs `scripts/verify-setup.sh`

After it finishes, the user runs `/mcp` inside Claude Code to do the OAuth login.

## Edge cases

- **Folder rename**: the script renames the folder mid-run. The shell that invoked the script keeps running fine (script `cd`s into the new path), but the user's outer shell prompt is stale -- the final message tells them to `cd` to the new path. Any other terminals open in the old path should be closed.
- **OAuth re-auth**: if MCP tools stop working later, run `/mcp` again. Not a setup concern.
- **Recovering the statusline `settings.json` entry**: if someone hand-edits `.claude/settings.json` and removes the `statusLine` block, run `bash scripts/setup-statusline.sh` to re-wire just that entry. The conf toggles still come from `setup.sh`.
