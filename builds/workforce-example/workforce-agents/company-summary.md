# Company Summary (Sub-Agent)

Returns a one-sentence description of a company from a Google search snippet. Used in parallel with `linkedin-lookup` by the Lead Research Workforce orchestrator.

## Agent Config

| Field | Value |
|-------|-------|
| Agent ID | `<agent-id-3>` |
| Node ID (in workforce) | `<node-id-3>` |
| Model | `claude-sonnet-4-6` |
| Temperature | `0.3` |
| Autonomy | `3` calls, `auto-run` low-risk |
| Memory | Disabled |
| Thinking | Disabled |
| Max output tokens | `300` |
| Last updated by | `<name>` (`<date>`) |

## Role

Find a one-sentence description of a company from a web search. Return it with a confidence rating. Pairs with `linkedin-lookup` to give the orchestrator a fuller picture in a single round-trip.

## Tools

| Tool | Chain ID | Behaviour | Status | Description |
|------|----------|-----------|--------|-------------|
| Google Search | `<studio-id-google-search>` | `auto-run` | Active | Native platform `google_search` step. Returns top 3 organic results with title, snippet, url |

## Knowledge Tables

None for v1. A v2 build would back this with a cached company-facts knowledge table to avoid re-searching well-known companies. See `build-kit/patterns/crm-knowledge-architecture.md`.

## Workflow

1. Receive `{ "company_name": "<string>" }` from the orchestrator.
2. Call Google Search with the company name as the query.
3. Read the top 3 result snippets.
4. Synthesise a single-sentence description (max 25 words). Source MUST be the snippets, not training data.
5. Score confidence:
   - `high`: snippets clearly converge on a description and the company is well-attested.
   - `medium`: snippets partially agree or only one mentions the company directly.
   - `low`: zero useful results, or all snippets describe a different entity.
6. Return the JSON output below.

## Output Format

```json
{
  "summary": "<one sentence, max 25 words>",
  "confidence": "low | medium | high",
  "notes": "<one short sentence, optional>"
}
```

## Key Constraints

- Always cite from snippets, never from training data.
- Never write more than one sentence in `summary`.
- Never invent revenue, employee count, founding year, or other figures unless directly quoted in a snippet.
- Never ask clarifying questions. Low confidence is the answer to ambiguity.

## System Prompt

See `system-prompt.md` (placeholder). Same structural shape as the other agents in this build.
