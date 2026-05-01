# Company LinkedIn Lookup

A simple research agent. Given a company name, it returns the company's LinkedIn URL plus a one-line description, using a Google search wrapper.

This is the kit's reference example. Read it alongside `system-prompt.md` and `tools/find-linkedin-url.md` to see the shape every build should aim for.

## Agent Config

| Field | Value | Notes |
|-------|-------|-------|
| Agent ID | `<set on first deploy>` | Capture from `relevance_upsert_agent` response |
| Project | `<your-project-id>` | Visible in the Relevance AI URL |
| Region | `<your-region-code>` | Find in your project settings |
| Model | `claude-sonnet-4-6` | Cheap, fast, good for short research tasks |
| Temperature | `0.2` | Deterministic for lookups |
| Autonomy | `5` calls, `auto-run` low-risk | Matches the tool budget below |
| Memory | Disabled | Each run is independent. Stateful memory adds noise |
| Thinking | Disabled | Single-step task. Inline reasoning is enough |

## Tools

| Tool | Studio ID | Action ID | Purpose |
|------|-----------|-----------|---------|
| Find LinkedIn URL | `<studio-id-1>` | `<action-id-1>` | Google search wrapper. Returns top 3 results filtered to linkedin.com/company URLs |

Replace placeholder IDs after running `relevance_upsert_tool` (studio ID) and `relevance_attach_tools_to_agent` (action ID).

## Knowledge Tables

None. This agent reads from Google search, not from a knowledge table.

## Key Design Decisions

- **One tool, not three.** A natural temptation is to add a "validate URL" tool and a "summarise company" tool. Both would push the agent above the 3-5 tool sweet spot for a starter. Validation lives inline in the prompt; summary lives in the search result snippet. See `.claude/skills/template-agent/SKILL.md` "12-point design rubric" rule 7.
- **Code Over LLM for URL filtering.** The tool itself filters Google results to URLs matching `linkedin.com/company/*`. The agent does not have to verify URL shape. See `.claude/skills/agent-build-patterns/build-philosophy.md` "Code Over LLM".
- **Confidence-aware output.** The prompt instructs the agent to emit a `confidence: low | medium | high` field plus the URL. Calling code can branch on confidence. Avoids the silent-fail failure mode where an arbitrary search result gets returned with no signal.
- **No autopilot questions.** If zero LinkedIn URLs surface, the agent emits `confidence: low` and a note. It does NOT ask the user "did you mean X?". See `.claude/rules/BUILD_PRACTICES.md` "Autopilot = No Questions".

## Workflow Summary

1. Receive company name as input (`company_name` param).
2. Call **Find LinkedIn URL** with `company_name` as query.
3. Inspect results.
4. If exactly one company URL is in the top 3 results, emit it with `confidence: high`.
5. If two or more company URLs surface, emit the first plus a note ("multiple candidates: <list>") with `confidence: medium`.
6. If no company URLs surface, emit empty URL with `confidence: low`.

## Workflow Diagram

Generate via `/generate-diagram` once the agent is deployed. URL: `<add FigJam link>`. Last updated: `<YYYY-MM-DD>`.

For a simple single-tool agent like this, a diagram is optional. It becomes load-bearing once you add a workforce.

## Test Plan

Auto-generate via `/eval` after first deploy. Minimum coverage:

- **Golden set** (3-5 cases): well-known company name returns the right URL with `confidence: high`. Misspelled name returns `confidence: medium`. Made-up name returns `confidence: low`.
- **Adversarial** (2-3 cases): prompt-injection attempts in the company name field. Off-topic input ("write me a poem"). Refusal expected for both.

Configure `default_eval_config` with the golden set as the publish gate. See `.claude/rules/BUILD_PRACTICES.md` "Golden Set in Publish Settings".

## Change Log

### v1.0 -- {YYYY-MM-DD}

**What changed:** initial deploy.
**Why:** reference build for the kit.
**Impact:** none yet (example only).
**Testing:** golden set at 100%, adversarial at 100%.
