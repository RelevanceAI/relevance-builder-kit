# Architecture Examples

> Real-world integration patterns and workforce design guidance for production builds.

---

## Integration Patterns

### Authentication Flow

- Use native Relevance AI integrations whenever available
- OAuth accounts set to "Set Manually". Never auto-assigned
- Same OAuth account across a tool suite (consistency)

### Data Pipeline Pattern

```
Research Agent (find companies)
  -> Contact Finder Agent (find people)
    -> Contact Research Agent (deep research + draft)
      -> Outreach Agent (execute sequences)
```

Each agent: single responsibility, knowledge table as source of truth, Unit of Action.

### Meeting Intelligence Pattern

```
Trigger (meeting ends)
  -> Capture transcript + metadata
    -> Store in knowledge table
      -> [Optional: analyze, route insights, update CRM]
```

### Creative Pipeline Pattern

```
Orchestrator (brief creation, phase gates)
  -> Art Director (visual style, image gen)
  -> Voice Director (voice casting, audio gen)
  -> Scene Generator (video production, assembly)
```

Workforce with approval gates between phases. A shared production brief acts as the living context across phases.

---

## Workforce Design

### Thin Orchestrator, Fat Capabilities

- Orchestrator contains coordination logic only (system prompt)
- Actual work happens in sub-agents and tools
- Enables swapping components without rewriting orchestration

### When to Use a Workforce

| Scenario | Solution |
|----------|----------|
| Single task, 3-5 tools | Single agent |
| Complex pipeline, 6+ tools | Workforce with orchestrator |
| Async operations (polling, retries) | Wrap in sub-agent |
| Multi-tool decision logic | Wrap in sub-agent |

### Proactive Discovery

End sub-agent queries with "Let me know what else you think may be useful." This activates agency rather than constraining to literal interpretation.
