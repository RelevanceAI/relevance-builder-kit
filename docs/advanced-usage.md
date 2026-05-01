# Advanced Usage

Quick-reference for getting the most out of Claude Code with this kit.

---

## 1. Use iTerm2

iTerm2 has native shift-enter support for multi-line input, which makes working with Claude Code much smoother. Other terminals may need keybinding configuration for the same behavior.

## 2. Notification Chime

Get notified when Claude finishes a task so you can multitask. Add to `~/.claude/settings.json`:

```json
{
  "notifications": {
    "enabled": true,
    "sound": true
  }
}
```

## 3. Statusline

The statusline shows your project folder name, git branch, and model at the bottom of the terminal by default:

```
⚡ relevance-builder-kit-team 🌿 main 🤖 Opus 4.7
```

The project name comes from your folder name (set during `/setup`). Re-run `/setup` to walk through the optional sections (vim mode, context bar, cost, duration, lines changed, output tokens, cache, rate limits); choices are written to `.claude/statusline.conf`. If `.claude/settings.json` ever loses its `statusLine` entry (e.g. someone hand-edited it), run `bash scripts/setup-statusline.sh` to re-wire it.

## 4. `/clear` Discipline

**Always `/clear` between projects.** Context from one build can contaminate another. Wrong project IDs, wrong tool references, wrong patterns.

When to `/clear`:

- After a long exploratory session before starting a focused build
- When Claude seems confused or referencing stale context

When NOT to `/clear`:

- Mid-build on the same project (you'll lose all context)

## 5. Use the Largest Model for Builds

For agent building, use the largest Claude model available (check with `/model`). Larger models handle complex multi-step MCP operations, system prompt design, and architectural decisions better than smaller models.

## 6. Use `/plan` Mode for Non-Trivial Tasks

Before starting a complex build, enter `/plan` mode. This lets you and Claude align on approach before any code or MCP calls happen. Especially useful for:

- New agent designs
- Workforce modifications
- Multi-tool builds
- Debugging sessions that might go in circles

## 7. Session Management

- **`claude --resume`** -- pick up where you left off. Useful for multi-day builds
- **`/rename`** -- name sessions descriptively (e.g. "lead-research-v2") so you can find them later
- **One terminal per project** -- for multi-project work, use separate terminal windows. Each maintains its own session and context

## 8. Copy IDs from the Platform

Before asking Claude to read or modify agents / tools:

- **Copy entity IDs** (agent IDs, tool studio IDs) from the Relevance AI platform
- **Copy native transformation names** from the tool editor UI instead of letting Claude search
- Direct ID access is faster and less error-prone than MCP search

## 9. `.local` Prefix for Uncommitted Files

Files prefixed with `.local` are gitignored. Use for:

- Local-only credentials
- Personal builds index (`.local/builds.local.md`)
- Scratch files and test results
- Anything that shouldn't be committed

## 10. Generate Test Scripts

When making changes (token optimization, tool output format, workflow modifications), generate a test script to validate the change quantitatively. Don't just eyeball it. Measure.

---

## Subagent Patterns

Claude can launch subagents for parallel research without bloating your main context:

- **Exploration** -- "Use a subagent to find all tools attached to agent X"
- **Research** -- "Use a subagent to read the phone-agents best practices file"
- **Comparison** -- "Use subagents to compare how agent A and agent B handle errors"

Subagents are great for tasks that generate lots of output you don't need in your main conversation.

## Memory System

Claude maintains memories in `.claude/projects/` that persist across conversations:

- **User memories** -- your role, preferences, expertise level
- **Feedback memories** -- corrections you've given
- **Project memories** -- ongoing work context, deadlines, decisions
- **Reference memories** -- pointers to external resources

Memories are loaded automatically when relevant. Say "remember that..." to save, or "forget that..." to remove.

## Skills

Invoke skills with slash commands:

- `/agent-build-patterns` -- design philosophy, patterns, and architecture examples
- `/template-agent` -- starter agent design rubric and anti-patterns
- `/eval` -- generate and run platform evals
- `/agent-optimiser` -- analyze an agent or workforce for config, prompt, and credit issues
- `/document-workforce` -- document a workforce and all its agents
- `/improve` -- capture a single mid-flow insight as a well-scoped PR
- `/capture-learning` -- end-of-session retro: extract reusable learnings, update knowledge base or PR
- `/setup` -- first-time kit setup walkthrough

Skills load into the conversation context, so Claude follows those patterns for the rest of the session.

## Context Management

Claude Code has a finite context window. For long sessions:

- **`/compact`** -- compress conversation history to free context
- **Use subagents** -- delegate research tasks so results don't bloat your context
- **`/clear`** -- nuclear option. Clears everything (use between projects)
- **Check the statusline** -- context usage is displayed in the status area

Tips for staying efficient:

- Be specific in requests (fewer clarification rounds = less context used)
- Don't ask Claude to "show me" large files. Just ask it to find what you need
- Use build folders to persist context across `/clear` boundaries
- Use pointers in CLAUDE.md, not inline context

## Connected Systems via MCP

You can connect external systems (Slack, Notion, Gmail, HubSpot) via additional MCP servers for richer context during builds. Configure in `.mcp.json` or `~/.claude/settings.json`.

## Useful Patterns

**Start a new build:**

```
/agent-build-patterns
Build me an agent that [description]. Check builds/ for similar patterns first.
```

**Resume work on an existing agent:**

```
Read the build docs in builds/{build-name}/ and give me a status summary.
```

Or use `claude --resume` to pick up the exact session where you left off.

**Debug a failing tool:**

```
Trigger tool [studio-id] with these params: {...} and show me the output.
```

**Check what's deployed:**

```
List all agents in the current project and compare with what's documented in builds/.
```

## Handling Large MCP Tool Outputs

Tools like `relevance_get_task_view` and `relevance_trigger_agent_sync` can return 100KB-500KB+ JSON responses. Don't grep large JSON files. It pulls the whole response into context. Limit input size before piping:

```bash
# Cap bytes read before piping to jq
timeout 3s head -c 50000 /path/to/file.json | jq ...

# Always use a timeout prefix on bash commands operating on MCP outputs
timeout 5s jq '.results[0]' /path/to/file.json
```
