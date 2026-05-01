# {Use Case Name}

{One sentence: what this use case is, who it's for, what problem it solves. Write as an explicit assertion, not a vague description.}

## When to Use

- Qualifying signals from discovery calls
- Customer patterns that indicate this is the right fit
- Technical prerequisites that must be true

## When Not to Use

- Conditions where this pattern is a poor fit
- Cheaper or simpler alternatives to suggest instead
- Disqualifying signals (e.g., customer lacks required integration, volume too low to justify)

## Default Architecture

Describe the recommended architecture:
- Single agent or workforce?
- Data flow (what triggers execution, what data moves where)
- Required vs optional components

```
ASCII diagram of the architecture
```

**Variations:**
- **Variation A when:** {condition} -- {what changes}
- **Variation B when:** {condition} -- {what changes}

## Key Design Decisions

Document the important choices and tradeoffs:

- **Decision 1:** What was chosen and why. What was the alternative and why it was rejected
- **Decision 2:** What was chosen and why

## Tools Required

| Tool | Purpose | Notes |
|------|---------|-------|
| tool_name | What it does | Caveats, credit cost, or alternatives |

## Knowledge Tables

| Table | Purpose | Key Fields |
|-------|---------|------------|
| table_name | What it stores | Important columns |

## Implementation Checklist

Step-by-step build path. A builder should be able to follow this to build a working version:

1. {First step}
2. {Second step}
3. {Validate by...}

## Failure Modes and Gotchas

Each gotcha must be a specific failure mode with context, not a generic warning.

- **{Specific scenario}:** What happens and how to prevent or handle it
- **{Platform quirk}:** The unexpected behavior and the workaround
- **{Edge case}:** When it occurs and what to do

## Example Prompts

System prompt snippets or conversation starters that work well. Keep examples small and reusable.

```
Example prompt or template here
```

## Related Files

- `{exact/path/to/file.md}` -- what it covers and when to read it
- `{exact/path/to/other.md}` -- relationship to this playbook
