# Getting Started

This guide walks you through setting up the Relevance Builder Kit and getting oriented. Target: set up and oriented in under an hour. Setup itself takes 5-10 minutes; the next 30 are spent reading the build patterns and the example build before you write any code. Time-to-first-deployed-agent is two to four hours for a simple use case, not 30 minutes. The goal of orientation is to make those hours productive.

## What This Kit Is

The Relevance Builder Kit is a Claude Code workspace for building Relevance AI agents with proven patterns: separation of concerns, documentation, production readiness. It connects to the Relevance AI platform via the official remote MCP server at `https://mcp.relevanceai.com` using OAuth, so no API keys are stored locally and no plugin is required.

**Key concept: one folder per project.** Each Relevance AI project gets its own clone of this kit. To work on multiple projects, you'll have multiple folders (e.g., `relevance-builder-personal`, `relevance-builder-team`), each with its own MCP connection.

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

**Option A (recommended): run the script directly:**

```bash
bash setup.sh
```

The script will:

1. Verify your `.mcp.json` is wired to the Relevance AI prod MCP server (`mcp.relevanceai.com`)
2. Ask for a project name and rename the folder (e.g., `relevance-builder-team`)
3. Customize `.mcp.json` with a project-specific server name (so multiple clones don't collide)
4. Configure the Claude Code statusline (shows project folder + model)
5. Optionally add a `ccd` shell alias for `claude --dangerously-skip-permissions`
6. Optionally create your first build folder scaffold
7. Run a verification check

**Option B: let Claude do it.** Start Claude Code and type `/setup`. It walks through each step conversationally.

### 3. Authenticate via OAuth

```bash
cd relevance-builder-{your-project-name}
claude
```

In Claude Code, run:

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

The statusline at the bottom of Claude Code shows:

```
relevance-builder-team  branch main  claude-sonnet-4-6
```

- **Project folder name** -- which Relevance AI project you're connected to
- **Branch** -- current git branch
- **Model** -- the Claude model in use

To reconfigure: `bash scripts/setup-statusline.sh`

## Multiple Projects

Each project gets its own folder. To set up a new project:

```bash
git clone https://github.com/RelevanceAI/relevance-builder-kit.git
cd relevance-builder-kit && bash setup.sh   # Give it a different project name
claude                                       # Then /mcp to authenticate
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
- **Setup script failed partway.** Re-run `bash setup.sh`. It's idempotent. Safe to run again.
- **Need to re-authenticate.** Run `/mcp` in Claude Code. OAuth tokens may expire; re-login via browser.
