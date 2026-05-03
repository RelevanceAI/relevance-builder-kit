# Workforce Setup & Lifecycle

> **STUB.** Pending net-new content in Phase 3 of the build-kit restructure.

## Planned Coverage

- Lifecycle: create → attach agents → configure edges → test via `relevance_trigger_workforce` → publish
- `relevance_create_workforce` config (full reference)
- Approval propagation across sub-agents
- Type semantics (default vs chat workforces)
- Schedule capability (which trigger types work for workforces)
- Failure recovery patterns
- Multi-layer orchestration (when to nest workforces)
- Knowledge-table intermediary pattern (handing context between agents via KT instead of `params_schema`)
- State handoff: structuring `params_schema` for context flow
- Wall-clock and dispatch limits
- MCP research source: introspection of production workforces

## Until Then

- See `workforce-patterns.md` for the mental model and headline rules
- See `playbooks/use-cases/multi-agent-orchestration.md` for orchestrator design philosophy
- See `.claude/rules/PLATFORM_MECHANICS.md` § "Workforce Architecture"
