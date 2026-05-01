# Getting Started

This guide walks you through setting up the Relevance Builder Kit and getting oriented. Target: set up and oriented in under an hour. Setup itself takes 5-10 minutes; the next 30 are spent reading the build patterns and the example build before you write any code. Time-to-first-deployed-agent is two to four hours for a simple use case, not 30 minutes. The goal of orientation is to make those hours productive.

## What This Kit Is

The Relevance Builder Kit is a Claude Code workspace for building Relevance AI agents with proven patterns: separation of concerns, documentation, production readiness. It connects to the Relevance AI platform via the official remote MCP server at `https://mcp.relevanceai.com` using OAuth, so no API keys are stored locally and no plugin is required.

**Key concept: one folder per project.** Each Relevance AI project gets its own clone of this kit. To work on multiple projects, you'll have multiple folders (e.g., `relevance-builder-kit-personal`, `relevance-builder-kit-team`), each with its own MCP connection.

## Prerequisites

- **Claude Code** CLI v2.1.3+ ([claude.ai/claude-code](https://claude.ai/claude-code)) -- run `claude --version` to check, `claude update` to upgrade
- **Python 3** (3.10+ recommended)
- **Git**
- A **Relevance AI** account
- **Recommended:** iTerm2 (native shift-enter support for multi-line input)

## Setup

### 1. Clone the kit

```bash
git clone https://github.com/RelevanceAI/relevance-builder-kit.git
cd relevance-builder-kit
```

### 2. Run setup

Run the interactive setup script from the kit root:

```bash
bash setup.sh
```

`setup.sh` will:

1. Check prerequisites (python3, git, claude CLI)
2. Verify `.mcp.json` is wired to the Relevance AI prod MCP server (`mcp.relevanceai.com`)
3. Ask for a folder suffix -- use the **name of the Relevance AI project this clone will build agents in**, lowercased and hyphenated (e.g. `lead-research`, `acme-prod`). Renames the folder to `relevance-builder-kit-{suffix}` and the MCP server to `relevance-ai-kit-{suffix}`, so it's obvious later which folder belongs to which Relevance project
4. Walk you through the Claude Code statusline (`[a]ll on / [n]one / [c]ustomise`) and write choices to `.claude/statusline.conf`
5. Optionally add a `ccd` shell alias for `claude --dangerously-skip-permissions`
6. Optionally scaffold your first build folder
7. Run a verification check

The script renames the folder, so close any other terminals open in the old path before running. After it finishes, `cd` into the renamed folder before starting Claude Code.

### 3. Authenticate via OAuth

Once `setup.sh` finishes, start Claude Code in the renamed folder and run:

```
/mcp
```

Your browser will open for OAuth login against `mcp.relevanceai.com`. Log in with your Relevance AI account, select your project, and authorize. Once done, you're connected. No need to re-authenticate in this folder.

### 4. Verify

You should see the statusline at the bottom showing your project folder name and model. Try asking Claude:

```
What project am I in and how many tools do I have?
```

## Understanding the Statusline

The statusline at the bottom of Claude Code shows a minimal default:

```
⚡ relevance-builder-kit-team 🌿 main 🤖 Opus 4.7
```

- **Project folder name** -- which Relevance AI project you're connected to
- **Branch** -- current git branch
- **Model** -- the Claude model in use

`setup.sh` walks you through eight optional sections (vim mode, context bar, cost, duration, lines changed, output tokens, cache, rate limits) and writes your choices to `.claude/statusline.conf`. Re-run `bash setup.sh` to change them.

## Multiple Projects

Each project gets its own folder. To set up a new project:

```bash
git clone https://github.com/RelevanceAI/relevance-builder-kit.git
cd relevance-builder-kit && bash setup.sh   # Use the new Relevance project's name as the suffix, then `claude` and `/mcp`
```

To switch between projects, open a separate terminal window in the appropriate folder. Each folder maintains its own OAuth session, so no re-authentication is needed after the first time.

This structural isolation means you can never accidentally mix context or credentials between projects.

## Key Workflow Habits

### Separate terminals for separate projects

Context isolation is structural in this model. Each folder is an independent project. Use separate terminal windows when working on different projects. No need for `/clear` between projects since they're physically separate.

### Use `/clear` within a project when needed

Within a single project folder, `/clear` is still useful:

- After a long exploratory session before starting a focused build
- When Claude seems confused or referencing stale context

Don't `/clear` mid-build. You'll lose all conversation context. Finish the current task or commit progress first.

### Use `/plan` mode for non-trivial tasks

Before starting a complex build, enter `/plan` mode. This lets you and Claude align on approach before any MCP calls happen.

### Read skill files before building

Before starting any build, tell Claude to read the relevant skill:

- `/agent-build-patterns` -- design philosophy, Unit of Action, system design patterns, architecture examples
- `/template-agent` -- design rubric, checklist, and anti-patterns for a clean starter agent
- `/eval` -- generate and run platform evals

Claude will load the skill content and follow those patterns for the rest of the session.

### Use subagents for research

When you need Claude to explore something (search code, research a pattern, look up API docs), it can launch subagents that work in parallel without cluttering your main conversation context.

### Use `claude --resume` to pick up sessions

For multi-day builds, use `claude --resume` to continue where you left off. Use `/rename` to name sessions descriptively so you can find them later.

### How CLAUDE.md files work

Claude Code reads instructions from multiple `CLAUDE.md` files:

- **`~/.claude/CLAUDE.md`** -- your global personal preferences (applies to all repos)
- **`CLAUDE.md`** (kit root) -- kit-level instructions (checked into git)
- **`.claude/CLAUDE.md`** -- additional kit instructions (checked into git)

The kit-level files contain build patterns, API rules, and preferences that benefit every build. You can add personal preferences to your global file.

### `.local` prefix for uncommitted files

Files prefixed with `.local` are gitignored. Use for:

- Local-only credentials
- Personal builds index (`.local/builds.local.md`)
- Scratch files and test results
- Anything that shouldn't be committed

## Your First 30 Minutes After Setup

Setup gets you connected. The next 30 minutes are about orientation, not delivery. Resist the urge to build something real on day one. The kit pays back when you have internalised the patterns first.

### Minute 0-5: Verify the connection

Start Claude Code in your kit folder and ask:

```
What project am I connected to, and what tools does it have?
```

You should see Claude pull a tool list via MCP. If you do not, run `bash scripts/verify-setup.sh` and re-authenticate with `/mcp`.

### Minute 5-15: Read the build patterns

Run:

```
/agent-build-patterns
```

This loads the design philosophy, Unit of Action, and the system design patterns. Skim it. You do not need to memorise every pattern. You need to know which patterns exist so you can ask "is this the right one?" when you start a build.

### Minute 15-25: Walk through the example build

Open `builds/example/` and read `agent.md`, `system-prompt.md`, and `tools/find-linkedin-url.md` in that order. This is the shape every build aims for. You will copy this structure for your own builds.

Pay attention to:

- How `agent.md` documents IDs, tools, design decisions, and the test plan
- How `system-prompt.md` differs from `agent.md` (no tables, tool pills, BEGIN / END PROMPT markers)
- How the tool doc captures the studio ID, action ID, and step plan

### Minute 25-30: Pick what to build first

Now you know the patterns and the shape. Decide what your v1 build is. Pick something narrow. One tool, one agent, one tested workflow.

When you are ready to scope it, run:

```
/template-agent
```

This loads the 12-point design rubric and the v0-to-vN roadmap. It walks you through scoping a clean starter agent. Plan in `/plan` mode, get alignment, then build.

## Where to Find Help

- **Skills** (`.claude/skills/`) -- detailed build patterns and guides
- **Reference** (`build-kit/`) -- deep reference (knowledge tables, tool transformations, icon URLs)
- **Rules** (`.claude/rules/`) -- governance: doc standards, build practices, platform mechanics
- **Use-case playbooks** (`playbooks/use-cases/`) -- architecture playbooks for common agent types
- **API Docs** -- https://relevanceai.com/docs (or your region-specific stack URL once authenticated)

## Troubleshooting

- **MCP tools aren't responding.** Run `bash scripts/verify-setup.sh` to check connectivity. Try `/mcp` to re-authenticate.
- **Stale context.** Use `/clear` to reset conversation context.
- **Which project am I connected to?** Check the statusline, or ask Claude "what project am I in?"
- **Setup failed partway.** Re-run `bash setup.sh` from the kit root. It's idempotent. Safe to run again.
- **Need to re-authenticate.** Run `/mcp` in Claude Code. OAuth tokens may expire; re-login via browser.
