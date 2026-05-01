# Interactive Agent Patterns

Patterns for agents that interact directly with users via chat - copilots, assistants, conversational interfaces. These patterns focus on UX, tone, and output quality for human-facing agents.

## Conversational Style

For chat-based agents, voice is as important as logic. Users do not care about internal processes - they care about getting help.

| Principle | Bad | Good |
|-----------|-----|------|
| Write like you speak | "I will now proceed to..." | "Alright, let me..." |
| Hide the machinery | "Calling my research router..." | "Let me figure out the best way to tackle this." |
| Be direct | "Based on the analysis of your request..." | "Here's what I'm thinking..." |
| Sound helpful | "Would you like me to execute competitive research?" | "Want me to dig into who's competing?" |

Never mention tools, routers, or system processes in user-facing output.

## Progressive Disclosure

For ambiguous queries that yield multiple matches, do not dump all data. Present a compact summary of top candidates with key differentiating information and ask the user to make a selection.

This is especially important for CRM lookups where a company name might match multiple records.

## Output Formatting Rules

- Headings: H1-H3 only. Title = #, sections = ##, subsections = ###
- Paragraphs: Max 3 lines each
- Bullets: Max 6 per list, 12-16 words each, one idea per bullet
- Bold lead-ins: "**Goal:** [description]"
- Tables: Only when they improve scanning. Max 6 columns, short cell text
- Links: Always markdown format, never raw URLs

## No-Tools Content Agents

Some agents have no tools at all. They generate content purely from input context, knowledge sets, and prompt instructions.

Use cases: email drafting, LinkedIn message sequences, content personalization, copywriting.

These agents are lightweight, fast, and cheap to run. Use them when the agent does not need to look anything up - all context is passed in as params.

## Named Personas

Give agents distinct persona names for consistent voice and brand:

```
You are Reece Sauce, a specialized business model researcher...
You are Vera Nox, a professional pre-call prepper AI...
```

Benefits: creates consistent voice, makes agents memorable and distinguishable within a workforce, enables brand-building across the agent fleet.

## Post-Action Behavior

Define what the agent should do after completing its main task:

```
After sending the report, provide only a brief confirmation message.
For any follow-up questions, answer using already gathered data.
Do NOT use the Send Report tool again for follow-up questions.
```

Pattern: Main action -> Brief confirmation -> Answer follow-ups from existing context.

## Pre-flight Checklists

For complex operations in interactive agents, include structured validation before execution:

```
Quick pre-flight checklist:

Strategic checks:
- Business goal clear?
- Accuracy before cost?
- Search vs Enrich decided?

Planning checks:
- ICP filters locked?
- Probe step included?
- Volume and cost estimate computed?
- Budget cap set?

Execution checks:
- Pagination plan?
- per_page tuned?
- Retry/backoff configured?
```

The agent runs through the checklist internally before starting work. For interactive agents, surface the checklist to the user for confirmation before expensive operations.

## Related Files

- `playbooks/use-cases/outreach-agent-patterns.md` - Outreach-specific messaging patterns
- `playbooks/use-cases/synthesis-agent-patterns.md` - Briefing output patterns
- `.claude/rules/BUILD_PRACTICES.md` - General agent building practices
