---
name: agent-build-patterns
description: Design philosophy, architecture patterns, and decision guides for production-grade Relevance AI builds. Use this skill when designing a new agent or tool, reviewing existing architecture, debugging production failures, deciding where logic should live (code vs LLM vs knowledge table), structuring multi-agent workforces, eliminating duplicated tools, adding audit trails, or when someone asks "is this the right pattern?" or "why is my agent doing X wrong?". Covers Unit of Action, Note Step, Centralize Rules, Code Over LLM, Parameterize, Compute at Right Level, Data Over Routing, and Audit Enrichment patterns.
---

## When to Use

- Designing a new agent, tool, or workforce system
- Reviewing an existing build for production readiness
- Choosing which architecture pattern to apply
- Debugging production failures (start with Unit of Action)

## Quick Reference: 8 Patterns + Decision Sequence

Two foundational patterns (Unit of Action, Note Step) plus six system design patterns. Walk them in order.

Check patterns in this order. The first "no" tells you which pattern to apply:

1. **Unit of Action** -- is each task scoped to one entity? *Fix this first.*
2. **Note Step** -- does every 3+ step tool have documentation?
3. **Centralize Rules** -- are business rules in one place?
4. **Code Over LLM** -- are deterministic decisions in code steps?
5. **Parameterize** -- any duplicated tools or agents?
6. **Compute at Right Level** -- is logic in the right layer?
7. **Data Over Routing** -- do agents pass data, not instructions?
8. **Audit Enrichment** -- do writes include who / when / why?

## Pattern Summary

| Pattern | Problem It Solves | Key Question |
|---------|------------------|--------------|
| Compute at Right Level | Logic in wrong layer | "Where does this data naturally live?" |
| Parameterize | Tool / agent duplication | "Am I copy-pasting to change one value?" |
| Centralize Rules | Scattered business logic | "How many places define this rule?" |
| Code Over LLM | Wasted credits on deterministic logic | "Can this be if / else?" |
| Data Over Routing | Invisible control flow | "Am I passing data or instructions?" |
| Audit Enrichment | Untraceable agent actions | "Can I explain WHY from data alone?" |

## Reference Files

| File | Content |
|------|---------|
| [build-philosophy.md](build-philosophy.md) | Lens for evaluating build decisions, 3-layer architecture, design discipline |
| [unit-of-action.md](unit-of-action.md) | The foundational pattern: one entity per task |
| [system-design-patterns.md](system-design-patterns.md) | All 6 architecture patterns with anti-patterns and examples |
| [note-step.md](note-step.md) | Documentation-as-first-step pattern for tools |
| [decision-guide.md](decision-guide.md) | Meta-guide: which pattern to apply when |
| [architecture-examples.md](architecture-examples.md) | Real-world integration patterns (data pipeline, meeting intelligence, creative pipeline) and workforce design |
| [contracts.md](contracts.md) | Tool contracts, prompt contracts, and naming conventions |
