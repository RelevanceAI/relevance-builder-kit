# LinkedIn Lookup (Sub-Agent)

Returns the LinkedIn company URL for a given company name with a confidence rating. Mirrors the standalone agent in `builds/example/`; here it runs as a child of the Lead Research Workforce orchestrator.

## Agent Config

| Field | Value |
|-------|-------|
| Agent ID | `<agent-id-2>` |
| Node ID (in workforce) | `<node-id-2>` |
| Model | `claude-sonnet-4-6` |
| Temperature | `0.2` |
| Autonomy | `3` calls, `auto-run` low-risk |
| Memory | Disabled |
| Thinking | Disabled |
| Max output tokens | `500` |
| Last updated by | `<name>` (`<date>`) |

## Role

Find the LinkedIn company page URL for a given company name. Return it with a confidence rating. Single tool, single concern.

## Tools

| Tool | Chain ID | Behaviour | Status | Description |
|------|----------|-----------|--------|-------------|
| Find LinkedIn URL | `<studio-id-find-linkedin>` | `auto-run` | Active | Google search wrapper. Returns top 3 results filtered to `linkedin.com/company/*` URLs |

Same tool as `builds/example/tools/find-linkedin-url.md`.

## Knowledge Tables

None.

## Workflow

1. Receive `{ "company_name": "<string>" }` from the orchestrator.
2. Call **Find LinkedIn URL** with the company name as `query`.
3. Inspect results:
   - Exactly one company URL: emit it with `confidence: high`.
   - Two or three: emit the first, list the rest in `notes`, set `confidence: medium`.
   - Zero: emit empty URL with `confidence: low`.
4. Return the JSON output below.

## Output Format

```json
{
  "linkedin_url": "<url or empty>",
  "confidence": "low | medium | high",
  "notes": "<one short sentence, optional>"
}
```

## Key Constraints

- Always call the search tool. Never guess a URL from training data.
- Never invent a URL.
- Never ask clarifying questions (autopilot mode: low confidence is the answer).
- Match URL shape strictly: `https://www.linkedin.com/company/<slug>` or `https://linkedin.com/company/<slug>`. People pages, posts, jobs, schools do not count.

## System Prompt

See `system-prompt.md` (placeholder). Mirrors `builds/example/system-prompt.md` structure: Identity / Scope / Rules / Tools / Workflow / Output Format, with bare `{{_actions.<id>}}` pills.
