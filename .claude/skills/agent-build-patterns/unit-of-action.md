# Unit of Action

> **The "unit of action" is the single atomic entity that one agent task operates on.** One lead. One deal. One ticket. Never "all leads" or "leads and deals together."

## Why It Matters

This is the **single most important pattern** for production reliability. When an agent task fails:

| | With Unit of Action | Without Unit of Action |
|-|--------------------|-----------------------|
| **Blast radius** | One record affected | Unknown -- did it process 3 of 50? |
| **Diagnosis** | You know exactly which record | Which 3? What state are the other 47? |
| **Recovery** | Retry that one record | Partial state, manual cleanup |

> Unit of action is how you sleep at night when the agent runs unattended overnight.

## The Pattern: One Entity Per Task

```
TRIGGER (webhook / schedule / manual)
  | passes ONE entity
AGENT (processes that entity)
  | writes result
DESTINATION (CRM update / notification / log)
```

## Anti-Patterns

### Anti-Pattern 1: Batch processing in a single task

```
Trigger: "Process all new leads from today"
Agent: Fetches 50 leads, loops, updates each
Problem: Fails at lead #23 -> leads 1-22 updated, 23-50 are not.
         No retry mechanism. Partial state.
```

### Anti-Pattern 2: Mixed entity types

```
Trigger: "New deal created"
Agent: Updates deal, ALSO updates contact, ALSO creates task
Problem: If contact update fails, deal is updated but task isn't.
         Three entities, three failure modes, one retry mechanism.
```

### Anti-Pattern 3: Find-and-do in one agent

```
Trigger: Schedule (daily)
Agent: Searches for stale deals, then updates each one
Problem: Search returns 100 deals. Context window fills up.
         Late deals get worse processing. Search + action logic coupled.
```

## Correct Patterns

### One entity, one task

```
Trigger: Webhook fires for EACH new lead (one at a time)
Agent: Receives one lead -> enriches -> updates CRM
Result: If it fails, exactly one lead is affected. Retry is trivial.
```

### Separate finder from doer

```
Finder Agent: Searches for stale deals -> outputs list
Workforce: Fans out, triggers Doer Agent once PER deal
Doer Agent: Receives one deal -> updates it
Result: Each deal is independent. Failures are isolated.
```

## Exception: Read-Only Aggregation

Aggregation across multiple entities is fine **if no writes happen**:

- **OK:** "Summarize all support tickets from this week" (read-only)
- **OK:** "Generate a report of deal pipeline" (read-only)
- **NOT OK:** "Summarize tickets and then close the resolved ones" (read + write)

## System Design Flow

| Event Source | Trigger | Agent |
|-------------|---------|-------|
| CRM webhook | Per-record trigger | Process one record |
| Schedule | Finder agent -> Workforce fan-out | Doer agent (xN) |
| Manual input | Direct trigger | Process one input |
| Meeting end | Webhook | Process one meeting |

> **Key insight:** triggers are where you enforce unit of action. If your trigger passes a batch, everything downstream is contaminated.

## Build Checklist

- [ ] **Single entity** -- each agent task operates on exactly one entity
- [ ] **Identified entity type** -- you can name the unit (e.g., "one HubSpot contact")
- [ ] **Isolated failure** -- if this task fails, no other entity is affected
- [ ] **Retryable** -- can re-trigger for a single entity without side effects
