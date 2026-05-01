# System Design Patterns

> **Six architecture patterns for production-grade agent systems.** Each pattern includes the anti-pattern (what goes wrong) and the recommended approach.

## Pattern 1: Compute at the Right Hierarchy Level

**Place logic at the level where the data naturally lives.**

### Anti-Pattern

```
WORKFORCE LAYER
  "For each lead, if score > 80,
   route to senior rep, else junior"

Problem: Routing logic in workforce layer.
         Changing threshold = editing workforce config.
         Testing requires running entire workforce.
```

### Recommended

```
TOOL: "Route Lead"
  Code step: if score > 80 -> "senior"
  (Parameterized threshold from config)
       |
AGENT: reads routing result, acts accordingly
```

> **Build Note:** routing logic belongs in a tool with a code step, not in agent prompts or workforce edges. Code steps are testable, versionable, and don't consume LLM credits.

## Pattern 2: Parameterize, Don't Duplicate

**Never copy a tool or agent to change a single value.**

### Anti-Pattern

```
+------------------+ +------------------+ +------------------+
| Enrich Lead APAC | | Enrich Lead EMEA | | Enrich Lead NA   |
| region = "apac"  | | region = "emea"  | | region = "na"    |
+------------------+ +------------------+ +------------------+
Bug fix -> update 3 tools. New region -> copy again. Drift is inevitable.
```

### Recommended

```
+------------------------------+
| Enrich Lead                  |
| params: { region: string }   |
| One tool, parameterized      |
+------------------------------+
```

> **Build Note:** applies at every level: tools, agent prompts, workforce configs. If you're about to copy-paste and change one value, stop. Add a parameter.

## Pattern 3: Centralize Business Rules

**Business rules should live in exactly one place.**

### Anti-Pattern

```
Agent Prompt:           Tool Code Step:         Workforce Edge:
"High priority if       if priority == "high":  condition:
 revenue > $100K"       threshold = 100000      "priority == high"

Three places define "high priority." Rule changes -> 3 updates needed.
```

### Recommended

```
TOOL: "Classify Priority"
  Code step:
    thresholds = { "high": 100000, "medium": 50000, "low": 0 }
    return classify(revenue, thresholds)
       | result used by
  Agent prompt: "Act on the priority classification"
  Workforce edge: routes based on classification output
```

> **Build Note:** when you anticipate the rules will change, that's your cue to centralize.

## Pattern 4: Code Over LLM for Decision Trees

**If the decision can be expressed as `if / else`, use a code step.**

| | LLM Step | Code Step |
|-|----------|-----------|
| **Cost** | ~$0.01 per call | $0.00 |
| **Latency** | ~2 seconds | <10ms |
| **Accuracy** | ~95% (hallucination risk) | 100% (deterministic) |

> **When to use LLM instead:** classification requires reading unstructured text, categories are fuzzy, rules would need 50+ branches, or you genuinely want AI judgment.

## Pattern 5: Data Over Routing

**Pass data between agents, not control flow.**

### Anti-Pattern

```
Agent A  ->  "go do X"  ->  Agent B
(router)     "go do Y"      (doer)

Routing logic is invisible, untestable. Adding routes = prompt engineering.
```

### Recommended

```
Agent A  ->  { structured data }  ->  Agent B
(enricher)                            (actor)

Agent B receives data and applies its own logic.
Routing based on data fields, not instructions.
```

> **Build Note:** in workforce edges, use data-based conditions (`output.priority == "high"`) rather than agent instructions. Data conditions are visible and testable.

## Pattern 6: Audit Enrichment

**Every agent action should enrich data with who / when / why metadata.**

### Anti-Pattern

```json
{ "status": "qualified" }
// No trace of WHY, WHEN, or WHAT informed the decision
```

### Recommended

```json
{
  "status": "qualified",
  "qualified_by": "lead-scoring-agent",
  "qualified_at": "2024-12-15T10:30:00Z",
  "qualified_reason": "Revenue > $100K, 3+ decision makers",
  "source_data": "enrichment-run-abc123"
}
```

> **Build Note:** "why did the agent do that?" is the most common question after the system is live. If you can't answer from the data alone (without reading logs), your audit trail is insufficient.

## Design Review Checklist

- [ ] **Hierarchy** -- logic at the right level? (tool vs agent vs workforce)
- [ ] **Parameters** -- any duplicated tools / agents differing by one value?
- [ ] **Centralized rules** -- business rules in exactly one place?
- [ ] **Code vs LLM** -- deterministic decisions in code steps?
- [ ] **Data routing** -- agents pass data, not instructions?
- [ ] **Audit trail** -- every write has who / when / why metadata?

## Summary

| Pattern | Problem It Solves | Key Question |
|---------|------------------|--------------|
| Compute at Right Level | Logic in wrong layer | "Where does this data naturally live?" |
| Parameterize | Tool / agent duplication | "Am I copy-pasting to change one value?" |
| Centralize Rules | Scattered business logic | "How many places define this rule?" |
| Code Over LLM | Wasted credits on deterministic logic | "Can this be if / else?" |
| Data Over Routing | Invisible control flow | "Am I passing data or instructions?" |
| Audit Enrichment | Untraceable agent actions | "Can I explain WHY from data alone?" |
