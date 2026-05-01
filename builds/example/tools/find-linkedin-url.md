# Find LinkedIn URL

Google search wrapper that returns the top 3 LinkedIn company-page URLs for a given query.

## Identifiers

| Field | Value |
|-------|-------|
| Studio ID | `<studio-id-1>` |
| Action ID | `<action-id-1>` |
| Region | `<your-region-code>` |

Replace after `relevance_upsert_tool` (studio ID) and `relevance_attach_tools_to_agent` (action ID).

## Purpose

The agent calls this tool exactly once per task to get candidate URLs. The tool, not the agent, owns URL filtering. Keeping that filter in code rather than in the prompt makes failures explicit (zero results = empty array) and avoids LLM hallucination of plausible-but-fake URLs.

## Input

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `query` | string | Yes | The company name. The tool prepends `site:linkedin.com/company` automatically |

## Output

```json
{
  "results": [
    {
      "url": "https://www.linkedin.com/company/acme",
      "title": "Acme Corporation: Overview",
      "snippet": "Acme Corporation builds widgets..."
    }
  ]
}
```

The `results` array contains up to 3 entries. It can be empty if no LinkedIn company-page URLs match.

## Steps

1. **Native step:** `google_search`. Input: `f"site:linkedin.com/company {query}"`. Limit: 10.
2. **JS code step:** filter results to URLs matching `^https?://(www\\.)?linkedin\\.com/company/[a-z0-9-]+/?$`. Take the first 3. Return as `results`.

The JS step's `state_mapping` exposes `query` (from `params.query`) and `raw_results` (from `steps.google_search.output.transformed.results`). See `build-kit/agents/tools/state-mapping.md` for the inter-step data flow rules.

## OAuth

None. This tool uses the platform's built-in Google Search step. No external OAuth account required.

## Failure Modes

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `results: []` even for well-known companies | `site:` operator stripped by Google for low-quality queries | Increase the search step's `num_results` to 20, then filter |
| Returns `linkedin.com/in/...` (people pages) | Filter regex too permissive | Re-check the regex anchors `^` and `$` |
| Tool returns `{}` | Output config not exposing the JS step's transformed result | Add `"results": "{{transformed.results}}"` to the JS step's `output` config |
