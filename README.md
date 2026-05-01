# Relevance Builder Kit

A Claude Code workspace for building production-grade agents on Relevance AI -- pre-wired to the official Relevance AI prod MCP server at `mcp.relevanceai.com`, with opinionated build patterns and platform mechanics baked in.

**New here?** [docs/getting-started.md](docs/getting-started.md) is the full walkthrough -- written so anyone, technical or not, can get themselves set up in about 30 minutes.

## What This Is

The single home for everything you need to design, build, and run agents on Relevance AI. Build patterns, platform mechanics, integration recipes, testing rubrics, and your own build docs all live here -- not in a chat thread that disappears in 90 days, not in someone's head, not in a SaaS dashboard.

The mission is simple: **context compounds**. Every session leaves the kit with sharper patterns and more institutional knowledge than it started with, so the next builder (or you next week) can pick up cold and ship a production-grade build without rediscovering what's already known.

## One Clone Per Relevance Project

Each clone of this kit authenticates into a single Relevance AI project via OAuth, so you'll typically have multiple clones, one per project you work on. The recommended setup is a single parent "holder" folder containing each project's clone side by side:

```
~/relevance-projects/
  relevance-builder-prod/
  relevance-builder-staging/
  relevance-builder-marketing/
```

You run `setup.sh` once per clone (it gives the folder a project-specific suffix) and `/mcp` once inside Claude Code to wire that folder to its Relevance AI project. After that, switching projects is just opening a terminal in a different folder. Each folder keeps its own OAuth session, MCP connection, and build context, so credentials and work never get mixed across projects.

## Before You Start

You need four things on your machine. The setup script checks these and stops if any are missing.

| Tool | Why | How to install (Mac) | How to install (Windows) |
|------|-----|---------------------|--------------------------|
| **Terminal** | To run commands | Open Spotlight (`Cmd+Space`), type "Terminal", hit Enter | Use Windows Terminal or PowerShell from the Start menu |
| **Git** | To clone the repo | `xcode-select --install` (one-time) | [git-scm.com/download/win](https://git-scm.com/download/win) |
| **Python 3.10+** | Used by setup helpers | Comes with Mac, or `brew install python` | [python.org/downloads](https://python.org/downloads) |
| **Claude Code CLI 2.0+** | The tool you'll work in | [claude.com/claude-code](https://claude.com/claude-code) -- follow install instructions | Same -- [claude.com/claude-code](https://claude.com/claude-code) |

You also need a **Relevance AI account** -- sign up or log in at [app.relevanceai.com](https://app.relevanceai.com).

> **Brand new to terminals?** [docs/getting-started.md](docs/getting-started.md) walks through everything above with copy-paste commands and what each one does.

## Quick Start

```bash
# 1. Clone the kit
git clone https://github.com/RelevanceAI/relevance-builder-kit.git

# 2. Run setup (asks you a few questions, takes about 5 minutes)
cd relevance-builder-kit && bash setup.sh

# 3. cd into the renamed folder, then start Claude Code
cd ../relevance-builder-{your-suffix}
claude

# 4. Inside Claude Code, authenticate with Relevance AI (OAuth)
/mcp
```

> The kit ships pre-wired to the Relevance AI prod MCP server (`mcp.relevanceai.com`). No local plugin or submodule to install.

### What setup.sh asks you

The script is interactive. Read each prompt -- it tells you what's about to happen and lets you skip optional bits.

1. **Project name** -- The setup renames your folder to `relevance-builder-{name}` so you can have one folder per Relevance AI project. Pick something short: `personal`, `team`, `marketing`.
2. **Rename confirmation** -- Confirms the folder rename. Close any other terminals open in this directory first, otherwise those shells will be orphaned.
3. **`ccd` shortcut** (optional) -- Adds an alias for `claude --dangerously-skip-permissions`. Faster, but Claude can run shell commands and edit files without prompting -- only enable if you accept that tradeoff.
4. **First build folder** (optional) -- Scaffolds `builds/{build-name}/` with a starter `agent.md` and `system-prompt.md`. Useful if you have a specific build in mind; skip otherwise.

After all that the script configures the statusline, enables a notification chime, and runs a verification check.

### After setup

Run `claude` from the renamed folder. The very first thing to do inside Claude Code is `/mcp` -- this opens your browser for OAuth login to Relevance AI. Pick the project that matches the folder name and authorize. You're done -- no need to re-authenticate in this folder again.

Type `/setup` if anything is missing or you want to redo a step conversationally.

## Documentation

- **[Getting Started](docs/getting-started.md)** -- Full onboarding walkthrough, including a non-technical-friendly path
- **[Advanced Usage](docs/advanced-usage.md)** -- Power-user tips and patterns

## Skills

Skills are building muscle baked into the kit: design philosophy, build playbooks, and workflow automation, each scoped to a single job. Claude Code picks the right one **automatically** when your question matches its trigger description, so most of the time you just talk normally and the right skill loads itself. You can also invoke any skill explicitly with `/skill-name` if you want to force it.

A few examples of how auto-invocation feels in practice:

| You ask Claude | Skill that fires |
|----------------|------------------|
| "How should I architect this multi-agent workforce?" | `/agent-build-patterns` |
| "Audit this agent for credit and prompt issues" | `/agent-optimiser` |
| "Set up tests for this agent before going live" | `/eval` |
| "Build me a starter agent for lead research" | `/template-agent` |
| "Generate a diagram of this workforce" | `/generate-diagram` |
| "Document this workforce and all its agents" | `/document-workforce` |

Curated highlights:

| Skill | Purpose |
|-------|---------|
| `/agent-build-patterns` | Design philosophy, Unit of Action, system design patterns, architecture decision guides |
| `/eval` | Auto-generate test cases, run platform evals, golden sets, gate criteria, and performance monitoring |
| `/agent-optimiser` | Audit any agent or workforce for config, prompt, tool, and credit issues. Returns ranked optimizations |
| `/template-agent` | Design and build a starter agent: 12-point design rubric, layered architecture, build-fresh principles |
| `/generate-diagram` | Generate a FigJam architecture diagram from any agent or workforce URL |
| `/document-workforce` | Document a workforce and all its agents from the platform into local markdown |
| `/setup` | First-time setup, conversational. Same flow as `setup.sh` but inside Claude Code |

There are more skills in `.claude/skills/`. Browse them, and **add your own** when you spot a workflow worth automating: see [Contributing](#contributing) below.

## Keeping Up to Date

To pull the latest kit changes:

```bash
git pull
```

Operational skills (managing agents, tools, workforces, knowledge, evals, analytics) load from the remote MCP at runtime, so they're always current -- no plugin updates to chase.

## Project Structure

```
docs/                   # Human-readable documentation
setup.sh                # One-time setup (run from repo root)
.mcp.json               # MCP target (Relevance AI prod, OAuth)
scripts/
  setup-statusline.sh        # Statusline reconfiguration
  verify-setup.sh            # Post-setup health check
  statusline.sh              # Statusline (active project + model)
  lint-system-prompts.sh     # CLI lint for deployable prompts
  pre-tool-*.sh              # Pre-deploy hooks for agent and KT writes
builds/                 # Your own build docs (one folder per build)
.claude/
  rules/                # Governance + platform mechanics (auto-loaded)
  skills/               # Slash-command skills
build-kit/              # Deep reference (tools, integrations, patterns, templates)
playbooks/              # Use-case architecture playbooks
```

## When Something Breaks

- **`command not found: claude`** -- Claude Code CLI isn't installed or isn't on your PATH. Re-install from [claude.com/claude-code](https://claude.com/claude-code) and restart your terminal.
- **`command not found: git` or `python3`** -- See the prerequisites table above.
- **Setup script failed partway** -- Just re-run `bash setup.sh`. It's idempotent -- safe to run as many times as you need.
- **MCP tools aren't responding** -- Inside Claude Code, run `/mcp` to re-authenticate. If that doesn't fix it, run `bash scripts/verify-setup.sh` from the repo root.
- **Anything else** -- Open the kit in Claude Code and run `/setup`. It walks the setup steps conversationally and can diagnose what's missing.

## Contributing

This kit gets sharper every time someone uses it. A pattern you spot debugging an agent at 11pm becomes the rule that saves another builder three hours next quarter. A platform quirk you found becomes the answer the kit gives next month. **The compounding only works if you write it down.**

There are two layers, and the split matters:

### Upstream (PRs back to this kit)

If a learning is **generic** -- it would benefit any builder using Relevance AI, not just your specific environment -- it belongs upstream. The bar:

> Would another builder benefit from this in six months, with zero context from me?

If yes, open a PR. The fastest path:

1. Branch from `main`. Naming: `{type}/{topic}` (`feat/`, `fix/`, `docs/`)
2. Edit the relevant file (or create a new skill / playbook / rule)
3. Open a PR with one clear insight per change. Tight, focused PRs are easier to review and merge than broad ones.

Anything customer-specific, environment-specific, or that names internal systems should be scrubbed before pushing -- if it can't be generalised, it belongs in the local layer instead.

### Local (your copy only)

If a learning is specific to your environment, team, or one build -- credentials, internal naming conventions, customer-specific gotchas -- it stays in your local copy and never gets pushed upstream. Natural homes:

- `builds/{build-name}/` -- per-build docs (gitignored by default)
- Your own fork or downstream branch -- if you want team-internal patterns shared inside your org but not back upstream

### Where generic learnings go

| What you learned | Where it goes |
|------------------|---------------|
| Platform mechanic, API quirk, undocumented behaviour | `.claude/rules/PLATFORM_MECHANICS.md` |
| Build practice, tool / agent pattern | `.claude/rules/BUILD_PRACTICES.md` |
| Documentation or repo convention | `.claude/rules/DOC_RULES.md` |
| Reusable workflow worth automating | A new skill in `.claude/skills/` |
| Use-case architecture playbook (e.g. phone agent for X) | `playbooks/use-cases/` |
| Integration-specific gotcha (HubSpot, Salesforce, Slack, etc.) | `build-kit/integrations/` |
| Tool transformation or platform reference | `build-kit/tools/` |
| Reusable architecture pattern | `build-kit/patterns/` |

When in doubt, scope smaller and ask in the PR if you're unsure where it lands.

## How the MCP connection works

The kit ships with `.mcp.json` pre-wired to the official Relevance AI prod MCP server:

```json
{
  "mcpServers": {
    "relevance-ai": {
      "type": "http",
      "url": "https://mcp.relevanceai.com"
    }
  }
}
```

`setup.sh` renames the server entry to `relevance-ai-{your-project-name}` so multiple kit clones can run side by side without conflicting. Auth is OAuth: running `/mcp` inside Claude Code opens your browser, you log in to Relevance AI, pick the project, and you're connected. No API keys, no local plugin.

Operational skills (managing agents, tools, workforces, knowledge tables, evals, analytics) load on demand from the remote MCP. The skills in `.claude/skills/` are kit-specific build playbooks layered on top.
