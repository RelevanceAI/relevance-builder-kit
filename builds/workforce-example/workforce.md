# Lead Research Workforce

Example workforce: given a company name, returns the company's LinkedIn URL plus a one-line description by fanning out to two sub-agents in parallel.

This is the kit's reference example for a workforce build. Single-agent shape lives in `builds/example/`; multi-agent shape lives here. Read it alongside the per-agent docs in `workforce-agents/` to see how the orchestrator + sub-agents pattern wires up.

## Overview

The orchestrator receives a company name from the trigger, dispatches **both** the LinkedIn lookup and the company-summary sub-agent in parallel, then merges their outputs into a single structured response.

The build is intentionally narrow: two cheap research sub-agents, one orchestrator, no external CRM writes. Use it as the structural template for richer fan-out workforces (lead intake, deal triage, research-then-write).

## IDs

| Field | Value | Notes |
|-------|-------|-------|
| Workforce ID | `<set on first deploy>` | Capture from `relevance_create_workforce` response |
| Project | `<your-project-id>` | Visible in the Relevance AI URL |
| Region | `<your-region-code>` | Find in your project settings |
| Status | Draft | Move to Production after eval pass |

## Data Flow Diagram

```
            trigger (company_name)
                  |
                  v
    +---------------------------+
    |   lead-research-          |
    |   orchestrator            |
    +---------------------------+
        |                    |
        | tool-call          | tool-call
        | always-new         | always-new
        v                    v
+---------------+    +---------------+
| linkedin-     |    | company-      |
| lookup        |    | summary       |
+---------------+    +---------------+
        |                    |
        +----------+---------+
                   |
                   v
           orchestrator merges
           outputs and returns
```

## Triggers

- **Type:** Manual / API trigger (also valid: webhook, form)
- **Trigger node ID:** `<trigger-node-id>`
- **Input shape:** `{ "company_name": "<string>" }`

## Agents

| Agent | Node ID | Agent ID | Model | Role |
|-------|---------|----------|-------|------|
| lead-research-orchestrator | `<node-id-1>` | `<agent-id-1>` | claude-sonnet-4-6 | Receives the company name, dispatches both sub-agents in parallel, merges results |
| linkedin-lookup | `<node-id-2>` | `<agent-id-2>` | claude-sonnet-4-6 | Returns the LinkedIn company URL with confidence rating (mirrors `builds/example/`) |
| company-summary | `<node-id-3>` | `<agent-id-3>` | claude-sonnet-4-6 | Returns a one-line description of the company from a Google search snippet |

## Edges

| From | To | Edge Type | Threading | Notes |
|------|----|-----------|-----------|-------|
| trigger (`source_index: -1`) | lead-research-orchestrator | `forced-handover` | n/a | Always routes the trigger payload into the orchestrator |
| lead-research-orchestrator | linkedin-lookup | `tool-call` | `always-create-new` | Parallel-dispatched (see "Parallel Tool Calls" below). `params_schema` MUST set `additionalProperties: true` |
| lead-research-orchestrator | company-summary | `tool-call` | `always-create-new` | Same: parallel-dispatched, `additionalProperties: true` |

Reminder: explicit `edges` disable auto-linking. The trigger edge with `source_index: -1` MUST be present, otherwise the workforce publishes but routes nothing. See `build-kit/patterns/workforce-patterns.md`.

## Parallel Tool Calls

Both sub-agent edges are dispatched in parallel from a single orchestrator turn. Hard rule from `.claude/rules/PLATFORM_MECHANICS.md` "Parallel Tool Calls": every parallel-dispatched edge MUST use `always-create-new` threading. `always-same` raises a race error on the first concurrent call.

If the user's project does NOT have the parallel-tool-calls flag enabled, threading still works but the calls run sequentially. The workforce shape stays the same.

## Knowledge Tables

None. Both sub-agents read from Google search at runtime, not from a knowledge table. A more realistic build would back the company-summary sub-agent with a cached company-facts table; see `build-kit/patterns/crm-knowledge-architecture.md`.

## Workflow Summary

1. Trigger fires with `{ "company_name": "Acme Corp" }`.
2. Orchestrator receives the payload, validates it is a single company name (one entity, Unit of Action).
3. Orchestrator dispatches BOTH `linkedin-lookup` and `company-summary` in parallel (one tool call per sub-agent).
4. `linkedin-lookup` returns `{ linkedin_url, confidence }`.
5. `company-summary` returns `{ summary, confidence }`.
6. Orchestrator merges both into a single output record and returns it.

## Output Shape

```json
{
  "company_name": "Acme Corp",
  "linkedin_url": "https://www.linkedin.com/company/acme",
  "linkedin_confidence": "high",
  "summary": "Acme Corporation builds widgets for the wholesale market.",
  "summary_confidence": "medium",
  "notes": "Optional, surfaces low-confidence reasons"
}
```

## External Integrations

None directly. Both sub-agents call the platform-native Google Search step. No external OAuth account required.

## Key Design Decisions

- **Fan-out, not chain.** The two sub-agents have no dependency on each other. Running them in parallel halves wall-clock latency. See `.claude/rules/BUILD_PRACTICES.md` "Batch vs. Fan-Out".
- **Orchestrator does NOT do research itself.** Its job is dispatch + merge. Research lives in the sub-agents. Separates finding from doing per `agent-build-patterns/build-philosophy.md`.
- **Confidence per source, not per output.** LinkedIn-confidence and summary-confidence are independent. Calling code can downstream branch on either.
- **No autopilot questions.** If either sub-agent returns `confidence: low`, the orchestrator reports it and proceeds. No "did you mean X?" prompts. See `.claude/rules/BUILD_PRACTICES.md` "Autopilot = No Questions".

## Test Plan

Auto-generate via `/eval` against the orchestrator after first deploy. Minimum coverage:

- **Golden set** (3-5 cases): well-known company name returns both fields with high or medium confidence; misspelled name returns medium; made-up name returns both `confidence: low`.
- **Adversarial** (2-3 cases): prompt-injection attempts in the company-name field; off-topic input. Refusal expected.
- **Workforce E2E**: trigger via `relevance_trigger_workforce` (NOT `trigger_agent_sync`) so workforce edges actually populate the orchestrator's runtime tool list. See `.claude/rules/PLATFORM_MECHANICS.md` "Workforce Architecture".

Configure `default_eval_config` on the orchestrator with the golden set as the publish gate.

## Change Log

### v1.0 -- {YYYY-MM-DD}

**What changed:** initial deploy.
**Why:** reference workforce build for the kit.
**Impact:** none yet (example only).
**Testing:** golden set at 100%, adversarial at 100%.
