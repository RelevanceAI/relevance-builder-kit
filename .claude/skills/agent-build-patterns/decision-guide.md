# Pattern Decision Guide

> **Meta-guide for choosing which pattern to apply.** Use this when reviewing a build or starting a new one.

## Pattern Applicability Matrix

| Scenario | Primary Pattern | Supporting Pattern |
|----------|----------------|-------------------|
| Agent processes multiple records in one task | Unit of Action | Compute at Right Level |
| Same tool exists 3x with different configs | Parameterize | Centralize Rules |
| Business threshold in multiple places | Centralize Rules | Code Over LLM |
| LLM classifies with deterministic rules | Code Over LLM | Centralize Rules |
| Agent A tells Agent B what to do via prompt | Data Over Routing | Compute at Right Level |
| User asks "why did the agent do that?" | Audit Enrichment | Data Over Routing |
| Tool has 3+ steps, no documentation | Note Step | -- |
| New multi-agent system being designed | Unit of Action | All patterns apply |
| Debugging a production failure | Unit of Action | Audit Enrichment |
| Business rule about to change | Centralize Rules | Parameterize |

## Design Review Sequence

Check patterns in this order. The first "no" tells you which pattern to apply:

1. **Unit of Action** -- is each task scoped to one entity? *If no, stop. Fix this first.*
2. **Note Step** -- does every 3+ step tool have documentation? *Add before continuing.*
3. **Centralize Rules** -- are business rules in one place? *Refactor if scattered.*
4. **Code Over LLM** -- are deterministic decisions in code steps? *Swap if wasting credits.*
5. **Parameterize** -- any duplicated tools or agents? *Merge and parameterize.*
6. **Compute at Right Level** -- is logic in the right layer? *Move if misplaced.*
7. **Data Over Routing** -- are agents passing data, not instructions? *Restructure if needed.*
8. **Audit Enrichment** -- do write operations have who / when / why? *Add before shipping.*

> **Why this order?** Early patterns are foundational (you can't audit if your unit of action is wrong). Later patterns are optimization (parameterization matters less if the system is small).

## Pattern Interaction Diagram

```
                +------------------+
                |  UNIT OF ACTION  |  <- Foundation
                +--------+---------+
                         |
          +--------------+--------------+
          v              v              v
+-------------+  +--------------+  +--------------+
|  NOTE STEP  |  |  CENTRALIZE  |  |  CODE OVER   |
|  (document) |  |  RULES       |  |  LLM         |
+-------------+  +------+-------+  +--------------+
                        |
          +-------------+-------------+
          v             v             v
+--------------+  +-----------+  +--------------+
| PARAMETERIZE |  |   DATA    |  |    AUDIT     |
|              |  |  ROUTING  |  |  ENRICHMENT  |
+--------------+  +-----------+  +--------------+
```

- **Top:** Unit of Action is the foundation. Always check first
- **Middle:** documentation and rule centralization enable the patterns below
- **Bottom:** parameterization, data routing, and audit are refinements

## Quick Reference

Ask yourself these questions in order. First "no" = apply that pattern:

1. Does each task operate on exactly one entity? -> **Unit of Action**
2. Is the tool documented with a Note step? -> **Note Step**
3. Are business rules defined in one place? -> **Centralize Rules**
4. Are deterministic decisions in code? -> **Code Over LLM**
5. Are there duplicate tools / agents? -> **Parameterize**
6. Is logic in the right layer? -> **Compute at Right Level**
7. Do agents pass data, not instructions? -> **Data Over Routing**
8. Do writes include who / when / why? -> **Audit Enrichment**
