# Note Step Pattern

> **Every non-trivial tool starts with a Markdown Note step** that documents what the tool does, its inputs / outputs, field mappings, and version history. The Note renders as formatted documentation directly in the Relevance tool builder UI.

## Why First Step, Not Last

> **WARNING:** the Note step must be the **first** step, not the last. The Relevance execution engine uses the last step's output as the tool's return value. A Note at the end would overwrite your real output with documentation text.

Place it first. It executes, renders in the UI, and the tool proceeds to do real work.

## When to Use

| Always Use When | Skip When |
|-----------------|-----------|
| Tool has more than 2 transformation steps | Single-step tools (simple API wrappers) |
| Tool involves field mappings between systems | Throwaway / prototype tools |
| Tool contains business logic or decision trees | |
| Tool is part of a production system | |
| Tool will be maintained by someone else | |

## What to Include

### Required Sections

| Section | Purpose | Example |
|---------|---------|---------|
| Overview | One-line description | "Enriches a HubSpot contact with Clearbit data and updates the CRM record." |
| Input Fields | Parameters the tool accepts | `company_domain` (string, required) |
| Output Fields | What the tool returns | `enriched_contact` (object) |
| Version History | When and what changed | "v1.1 -- Added revenue field mapping" |

### Optional Sections

- **Field Mapping Table** -- when translating between two systems
- **Business Rules** -- when the tool applies thresholds or routing
- **Dependencies** -- when the tool requires secrets, OAuth, or other tools
- **Known Limitations** -- edge cases or unsupported scenarios

## Copy-Paste Template

```markdown
# [Tool Name]

## Overview
[One-line description of what this tool does]

## Input Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `field_name` | string | Yes | Description |

## Output Fields
| Field | Type | Description |
|-------|------|-------------|
| `field_name` | string | Description |

## Field Mappings
| Source (System A) | Destination (System B) | Transform |
|-------------------|----------------------|----------|
| `source.field` | `dest.field` | Direct / Formatted / Computed |

## Version History
- **v1.0** (YYYY-MM-DD) -- Initial build
```

## Implementation

```typescript
relevance_upsert_tool({
  studio_id: "my-tool",
  transformations: {
    steps: [
      {
        name: "documentation",
        transformation: "note",
        params: {
          note: "# My Tool\n\n## Overview\nThis tool enriches..."
        }
      },
      // ... actual tool steps follow
    ]
  }
})
```

The Note step has **zero cost** (no LLM call, no API call) and renders as formatted Markdown in the tool builder UI.

---

> **Build Standard:** all production tools with more than 2 steps should include a Note step as the first transformation. Takes 2 minutes to add, saves hours of debugging and onboarding.
