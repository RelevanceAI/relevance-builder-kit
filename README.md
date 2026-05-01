# Relevance Builder Kit

A Claude Code workspace for building production-grade agents on Relevance AI -- pre-wired to the official Relevance AI prod MCP server at `mcp.relevanceai.com`, with opinionated build patterns and platform mechanics baked in.

**New here?** Run `bash setup.sh` from the kit root once -- it's an interactive script that walks you through everything. [docs/getting-started.md](docs/getting-started.md) is the long-form walkthrough if you want more context.

## What This Is

The single home for everything you need to design, build, and run agents on Relevance AI. Build patterns, platform mechanics, integration recipes, testing rubrics, and your own build docs all live here -- not in a chat thread that disappears in 90 days, not in someone's head, not in a SaaS dashboard.

The mission is simple: **context compounds**. Every session leaves the kit with sharper patterns and more institutional knowledge than it started with, so the next builder (or you next week) can pick up cold and ship a production-grade build without rediscovering what's already known.

## One Clone Per Relevance Project

Each clone of this kit authenticates into a single Relevance AI project via OAuth, so you'll typically have multiple clones, one per project you work on. **Suffix each clone with the name of its Relevance AI project** so it's obvious which folder belongs to which project. The recommended setup is a single parent "holder" folder containing each project's clone side by side:

```
~/relevance-projects/
  relevance-builder-kit-lead-research/      # -> Lead Research project on Relevance
  relevance-builder-kit-customer-support/   # -> Customer Support project on Relevance
  relevance-builder-kit-acme-prod/          # -> ACME Prod project on Relevance
```

You run `bash setup.sh` once per clone (it asks for the suffix and walks you through the statusline) and `/mcp` once inside Claude Code to OAuth into the matching Relevance AI project. After that, switching projects is just opening a terminal in a different folder. Each folder keeps its own OAuth session, MCP connection, and build context, so credentials and work never get mixed across projects.

## Before You Start

You need four things on your machine. `setup.sh` checks these and stops if any are missing.

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
cd relevance-builder-kit

# 2. Run the interactive setup script (about 2-3 minutes)
bash setup.sh

# 3. Start Claude Code in the (now suffixed) folder
cd ../relevance-builder-kit-{suffix}
claude

# 4. Authenticate with Relevance AI (OAuth)
/mcp
```

> The kit ships pre-wired to the Relevance AI prod MCP server (`mcp.relevanceai.com`). No local plugin or submodule to install.

### What `setup.sh` asks you

The script walks each step in your terminal. Optional bits can be skipped with Enter.

1. **Folder + server suffix** -- Use the **name of the Relevance AI project this clone will build agents in**, lowercased and hyphenated (e.g. `lead-research`, `acme-prod`). Appended to the kit name so the folder becomes `relevance-builder-kit-{suffix}` and the MCP server becomes `relevance-ai-kit-{suffix}`. Matching the project name keeps it obvious later which folder belongs to which Relevance project. Close any other terminals open in this directory first -- the script renames the folder.
2. **Statusline** -- Pick `[a]ll on`, `[n]one` (minimal default), or `[c]ustomise` to walk eight optional sections (vim mode, context bar, cost, duration, lines changed, output tokens, cache, rate limits). Choices write to `.claude/statusline.conf`. Default is minimal: project + branch + model.
3. **`ccd` shortcut** (optional) -- Adds an alias for `claude --dangerously-skip-permissions`. Faster, but Claude can run shell commands and edit files without prompting -- only enable if you accept that tradeoff.
4. **First build folder** (optional) -- Scaffolds `builds/{build-name}/` with a starter `agent.md` and `system-prompt.md`. Useful if you have a specific build in mind; skip otherwise.

After that, the script runs a verification check and tells you to start Claude Code and run `/mcp`.

### After setup

Inside Claude Code, run `/mcp` -- this opens your browser for OAuth login to Relevance AI. Pick the project that matches the folder name and authorize. You're done -- no need to re-authenticate in this folder again.

Re-run `bash setup.sh` any time you want to redo a step. Idempotent.

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
| "Document this workforce and all its agents" | `/document-workforce` |
| "Capture this learning into the kit" | `/improve` |
| "Let's do a retro on this build" | `/capture-learning` |

Curated highlights:

| Skill | Purpose |
|-------|---------|
| `/agent-build-patterns` | Design philosophy, Unit of Action, system design patterns, architecture decision guides |
| `/eval` | Auto-generate test cases, run platform evals, golden sets, gate criteria, and performance monitoring |
| `/agent-optimiser` | Audit any agent or workforce for config, prompt, tool, and credit issues. Returns ranked optimizations |
| `/template-agent` | Design and build a starter agent: 12-point design rubric, layered architecture, build-fresh principles |
| `/document-workforce` | Document a workforce and all its agents from the platform into local markdown |
| `/improve` | Capture a single mid-flow insight as a well-scoped PR. Substance-strict bar, refuses ~half its invocations |
| `/capture-learning` | End-of-session retro: extract reusable learnings, update knowledge base or open a PR |
| `bash setup.sh` | First-time kit setup script: folder naming, `.mcp.json`, statusline walk-through, build folder scaffold (run from terminal, not a slash command) |

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
.mcp.json               # MCP target (Relevance AI prod, OAuth)
scripts/
  statusline.sh              # Statusline (config-driven via .claude/statusline.conf)
  setup-statusline.sh        # Recovery: re-wire statusLine entry into .claude/settings.json
  verify-setup.sh            # Post-setup health check
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
- **Setup failed partway** -- Just re-run `bash setup.sh` from the kit root. It's idempotent -- safe to run as many times as you need.
- **MCP tools aren't responding** -- Inside Claude Code, run `/mcp` to re-authenticate. If that doesn't fix it, run `bash scripts/verify-setup.sh` from the repo root.
- **Anything else** -- Run `bash setup.sh` again. It walks the setup steps and runs a verification pass that diagnoses what's missing.

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

`setup.sh` renames the server entry to `relevance-ai-kit-{suffix}` so multiple kit clones can run side by side without conflicting. Auth is OAuth: running `/mcp` inside Claude Code opens your browser, you log in to Relevance AI, pick the project, and you're connected. No API keys, no local plugin.

Operational skills (managing agents, tools, workforces, knowledge tables, evals, analytics) load on demand from the remote MCP. The skills in `.claude/skills/` are kit-specific build playbooks layered on top.
