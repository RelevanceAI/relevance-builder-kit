# Workforces

Multi-agent orchestration: edge configuration, lifecycle, setup gotchas. The "how" to `playbooks/multi-agent-orchestration.md`'s "what".

## Contents

- `agent-vs-workforce.md` -- **Start here when deciding.** When to use a single agent vs a workforce, category-by-category comparison (build surface, state, triggers, approval, evals, debugging, cost, observability, limits), migration paths (single agent ↔ workforce), common gotchas by mode
- `workforce-patterns.md` -- Mental model (graph not tree), type semantics (default vs chat), schedule capability, sub-agent approval propagation, wall-clock + dispatch limits, full edge configuration overview
- `edges.md` -- Edge type deep-dive: `forced-handover` ("Next Step") vs `tool-call` ("AI Connection"), `params_schema` design, threading decision tree, dispatch patterns, the `always-create-new` one-way mirror
- `setup.md` -- Lifecycle (create → attach → configure → test → publish), debugging via `workforce_state` + execution traces, common patterns (linear, fan-out, branching, multi-layer, KT intermediary), common issues

## Routing

Come here when:

- Deciding whether to build a single agent or a workforce
- Designing a workforce (graph mental model, type, edges)
- Configuring an edge (params_schema, threading, additionalProperties)
- Debugging workforce handoff failures
- Considering multi-layer orchestration
- Planning a migration single-agent ↔ workforce

## See Also

- `build-kit/CLAUDE.md` -- build-kit hub
- `build-kit/agents/` -- single-agent reference (when one agent is enough)
- `playbooks/multi-agent-orchestration.md` -- orchestrator design philosophy
- `.claude/rules/PLATFORM_MECHANICS.md` § "Workforce Architecture" -- platform mechanics
- `.claude/rules/BUILD_PRACTICES.md` § "Workforce / Orchestrator Patterns" -- highest-impact build rules
