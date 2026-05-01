# Contracts

Contracts define the interface between components in an agent system. They make expectations explicit so that tools, prompts, and agents can be built and tested independently.

---

## Tool Contracts

A tool contract defines what a tool promises to its caller (the agent).

### Schema

Every tool should have an implicit or explicit contract:

```markdown
### Tool: {tool_name}

**Input contract:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| query | string | yes | Search query, max 500 chars |
| limit | number | no | Max results, default 10 |

**Output contract:**
| Field | Type | Guaranteed | Description |
|-------|------|-----------|-------------|
| results | array | yes | Always present, may be empty |
| results[].name | string | yes | Non-null |
| results[].score | number | no | Present when ranking applied |

**Error contract:**
| Condition | Response |
|-----------|----------|
| No results | `{ results: [] }` (empty array, not error) |
| Invalid input | `{ error: "descriptive message" }` |
| Integration down | `{ error: "service unavailable", retry: true }` |
```

### Key Rules

- **Never return empty `{}`.** Always return structured output, even for errors
- **Arrays may be empty, but must be present.** The agent shouldn't need null checks
- **Error messages should be actionable.** "HubSpot returned 401" not "Something went wrong"
- **Document retry behavior.** Can the agent retry on failure?

---

## Naming Conventions

Consistent naming reduces cognitive load across builds.

### Agents

- **Format:** `{verb}-{domain}` or `{domain}-{role}`
- **Examples:** `enrich-contacts`, `score-leads`, `meeting-scheduler`, `support-triage`
- **Anti-pattern:** generic names like `agent-1`, `my-agent`, `test`

### Tools

- **Format:** `{verb}_{object}` (snake_case)
- **Examples:** `lookup_company`, `send_email`, `update_crm_record`, `generate_summary`
- **Anti-pattern:** `tool1`, `helper`, `do_stuff`

### Knowledge Tables

- **Format:** `{domain}_{purpose}`
- **Examples:** `contacts_enrichment_log`, `meeting_transcripts`, `product_catalog`
- **Anti-pattern:** `data`, `table1`, `test_kb`

### Tool Steps

- **Format:** `{verb}_{object}` (snake_case, no `steps.` prefix)
- **Examples:** `fetch_contact`, `parse_response`, `format_output`
- **Reference:** use `steps.` prefix only in references: `{{steps.fetch_contact.output}}`

### Workforces

- **Format:** `{domain}-{process}`
- **Examples:** `lead-qualification-pipeline`, `support-escalation-flow`

---

## Using Contracts

### During Build

- Define tool contracts before building tools (input / output / error)
- Define prompt contracts before writing system prompts (goal / constraints / output)
- Share contracts with stakeholders for validation before building

### During Testing

- Tool unit tests validate the tool contract (correct output schema, error handling)
- Agent scenario tests validate the prompt contract (correct behavior, refusals)
- See `/eval` for the full testing framework

### During Handoff

- Contracts are the primary handoff artifact for technical stakeholders
- Include contracts in agent.md under a "Contracts" section
