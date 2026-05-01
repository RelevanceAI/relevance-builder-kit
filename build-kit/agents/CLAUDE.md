# Agents

Everything about a single agent: how it thinks (prompt), what it can do (tools), what it knows (knowledge), how it gets work (triggers), and how it's modified (write operations). Phone agents are a specialised variant.

## Sub-directories

- `prompt/` -- System prompt design: tiered structure, identity framing, formatting, agent variables (`params_schema`), placeholder tools
- `tools/` -- Tool reference: state_mapping, transformations, gotchas, sandbox auth, parallel tool calls, AI Browser, voice, icon URLs
- `knowledge/` -- Knowledge tables (CRUD), CRM knowledge architecture, locale knowledge architecture
- `triggers/` -- Schedule, webhook, form, chat, slack triggers (`relevance_create_trigger`, etc.)
- `phone/` -- Phone agent best practices: voice config, latency, compliance

## Top-level files

- `agent-write-operations.md` -- Full operations matrix (`patch` / `upsert` / `attach-tools` / `save-draft`), phone agent runtime safeguards, fetch-merge-save pattern

## Routing

Come here when:

- Designing or revising a system prompt
- Adding or debugging an agent's tools
- Designing knowledge architecture (CRM, locale, generic)
- Configuring how an agent is triggered (schedule, webhook, form, chat)
- Building a phone agent
- Modifying an agent via MCP write operations

## See Also

- `build-kit/CLAUDE.md` -- build-kit hub
- `build-kit/workforces/` -- multi-agent orchestration (when one agent isn't enough)
- `.claude/rules/BUILD_PRACTICES.md` -- agent build standards
- `.claude/rules/PLATFORM_MECHANICS.md` -- platform mechanics (write operations, template resolution)
