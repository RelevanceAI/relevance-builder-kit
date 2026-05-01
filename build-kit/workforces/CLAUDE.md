# Workforces

Multi-agent orchestration: edge configuration, lifecycle, setup gotchas. The "how" to `playbooks/multi-agent-orchestration.md`'s "what".

## Contents

- `workforce-patterns.md` -- Mental model (graph not tree), type semantics (default vs chat), schedule capability, sub-agent approval propagation, wall-clock + dispatch limits, full edge configuration overview
- `edges.md` -- (Stub) Edge type deep-dive: forced-handover vs tool-call, params_schema design, threading decision tree, dispatch patterns
- `setup.md` -- (Stub) Lifecycle (create → attach → configure → test → publish), approval propagation, type semantics, scheduling, failure recovery, multi-layer orchestration

## Routing

Come here when:

- Designing a workforce (graph mental model, type, edges)
- Configuring an edge (params_schema, threading, additionalProperties)
- Debugging workforce handoff failures
- Considering multi-layer orchestration

## See Also

- `build-kit/CLAUDE.md` -- build-kit hub
- `build-kit/agents/` -- single-agent reference (when one agent is enough)
- `playbooks/multi-agent-orchestration.md` -- orchestrator design philosophy
- `.claude/rules/PLATFORM_MECHANICS.md` § "Workforce Architecture" -- platform mechanics
- `.claude/rules/BUILD_PRACTICES.md` § "Workforce / Orchestrator Patterns" -- highest-impact build rules
