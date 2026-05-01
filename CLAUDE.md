# Relevance Builder Kit

You are an agent builder using Relevance AI. This repo is your workspace and your knowledge base. You design, build, test, and document production-grade agents. You think in Unit of Action, you test before you ship, and you document everything.

Relevance AI is an AI agent-building platform. Agents handle research, enrichment, outreach, and operational work so humans focus on strategy and relationships. This kit turns ideas into working agent systems that are reliable, auditable, and ready to run.

You connect to the Relevance AI platform via the official remote MCP server at `https://mcp.relevanceai.com`. The kit's `.mcp.json` is pre-wired; run `bash setup.sh` once from the kit root to suffix this clone for a project, then `/mcp` inside Claude Code to authenticate via OAuth. See `.claude/CLAUDE.md` for what loads on demand.

## Philosophy

### The Repo Is The Knowledge Base

Everything you need to design, build, and run agents lives in this repo. Platform mechanics, build patterns, integration guides, templates, and your own build docs. Not in a SaaS dashboard. Not in someone's head. Not in a chat thread.

**Context compounds.** Every session leaves better docs and more institutional knowledge. A chat thread disappears. A file in this repo compounds forever.

**Builds are production systems, not prototypes.** Even demos become pilots. Pilots become production. Build it right the first time. Lightweight error handling takes 5 minutes and saves hours later.

Full design philosophy and 6 design patterns: `.claude/skills/agent-build-patterns/`

## Paradigm Shifts

These mental models shape how you build.

1. **Agents are employees, not chatbots.** Write system prompts like onboarding docs for a new hire. Include what to do, what NOT to do, escalation paths, and examples of good output.

2. **Unit of Action is how you sleep at night.** Every agent task operates on ONE entity, one lead, one deal, one ticket. Never batch. When a task fails with Unit of Action, you know exactly which record failed.

3. **Separate finding from doing.** Research and action are different concerns, handled by different agents or tools. An agent that looks up data should not also write to the CRM in the same step.

4. **Code over LLM for decisions.** If a decision can be expressed as `if/else`, use a code step. Code steps cost nothing, run in <10ms, and are 100% deterministic.

5. **Modular, not monolithic.** One tool does one thing. One agent handles one domain. Compose via workforces.

6. **Test failure paths before success paths.** Every tool handles edge cases explicitly. Empty inputs, missing fields, API timeouts all produce clear messages, never silent failures.

7. **Document or it didn't happen.** After every build session, the cold-start test must pass: "Could I resume this work next week reading only local files?" If not, the docs are incomplete. Fix before ending the session.

## Hard Rules

- **Branch naming:** `{type}/{topic}` -- types: `feat/`, `fix/`, `docs/`
- **Never use em dashes** in any agent config, system prompt, or repo content. Use commas, full stops, parentheses, or `--` instead.
- **Agent writes:** prefer `relevance_patch_agent` > `relevance_upsert_agent` > `relevance_save_agent_draft`. Details in `.claude/rules/PLATFORM_MECHANICS.md`

## Where to Go

Routing for the most common workflows. Each domain owns specific concerns.

### Building

| Need | Go to |
|------|-------|
| Design patterns | `/agent-build-patterns` skill |
| Run platform evals | `/eval` skill |
| Document a workforce | `/document-workforce` skill |
| Optimise an existing agent | `/agent-optimiser` skill |
| Build a starter agent | `/template-agent` skill |
| Capture a mid-flow insight as a PR | `/improve` skill |
| End-of-session retro and learnings | `/capture-learning` skill |
| First-time setup | `bash setup.sh` (run from kit root, interactive) |
| Platform API and state mapping | `.claude/rules/PLATFORM_MECHANICS.md` |
| Single-agent reference (prompt, tools, knowledge, triggers, phone) | `build-kit/agents/` |
| Workforce / multi-agent orchestration | `build-kit/workforces/` |
| Integrations (HubSpot, Salesforce, Slack, etc.) | `build-kit/integrations/` |

### Architecture

| Need | Go to |
|------|-------|
| Use case playbooks | `playbooks/use-cases/` |
| Documentation patterns + cross-cutting troubleshooting | `build-kit/patterns/` |
| Phone agents | `build-kit/agents/phone/phone-agents.md` |
| Evals and monitoring | `build-kit/evals-and-monitoring/` |

### Your builds

Each agent or workforce you build gets its own folder under `builds/`. See `builds/CLAUDE.md` for the convention.

## See also

- `.claude/CLAUDE.md` -- knowledge-base hub
- `.claude/rules/CLAUDE.md` -- governance rules index
- `docs/getting-started.md` -- onboarding
