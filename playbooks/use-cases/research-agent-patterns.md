# Research Agent Patterns

Patterns for building agents that gather information from multiple sources, assess quality, and produce structured deliverables. These apply to account research, competitive analysis, lead qualification, and any agent whose primary job is finding and validating information.

## When This Pattern Applies

- The agent must run to completion without human intervention (triggered by schedule, webhook, or event)
- Information is distributed across multiple searchable sources (web, APIs, databases)
- Quality depends on depth and cross-referencing, not speed
- The output is a structured deliverable (report, briefing, analysis) with confidence scores
- There is no user available to answer clarifying questions mid-execution

The core tension: thoroughness vs efficiency. Research agents must resist the temptation to stop at first results. The first query establishes context; follow-up queries find the real story.

## Minimum Tool Usage Requirements

Research agents default to shallow, single-query approaches. Counter this by specifying minimum tool call counts:

```
* {{_actions.google_search}} - use this to perform a Google Search.
  You must use this at least 3 times with different search queries.

* {{_actions.scrape_website}} - use this to scrape websites.
  You must use this at least 3 times with different websites.
```

Without minimums, research agents often make one search, get a partial answer, and declare themselves done.

## Iterative Research Rounds

For research-heavy agents, define explicit numbered rounds with specific focus areas rather than a single "do research" instruction:

```
Round 1: Identify primary revenue streams
Round 2: Deep-dive into pricing tiers using multiple sources
Round 3: Research customer segments and target markets
Round 4: Analyze competitive positioning
Round 5: Research highest business costs with validation
Validation Step: Cross-reference all findings across sources
Quality Check: Can you confidently explain each component? If not, research more.
```

Each round has a specific focus. Validation happens after all rounds, not inline.

## Self-Assessment Before Output

Before producing the deliverable, force the agent to validate its own completeness:

```
Self-Assessment Questions (answer before proceeding):
- Can I explain exactly how this company makes money?
- Do I know their specific pricing for each product/service?
- Can I map their complete customer acquisition process?
- Do I understand their major cost centers?
- Have I verified this information across multiple reliable sources?
- Are there any assumptions or "best guesses" in my analysis?

If ANY answer is "No" or "Partially", IMMEDIATELY continue research.
```

This prevents premature output when the agent has gaps it could fill.

## Stop Criteria by Depth

Define explicit stop conditions based on a depth parameter. This lets the same agent serve quick lookups and deep dives:

| Depth | Tool Calls | Stop When |
|-------|------------|-----------|
| Minimal | 1-2 max | Primary must-haves at 3/5 confidence OR 1 no-signal call |
| Lite | 3-5 | Must-haves covered OR 2 consecutive no-signal calls |
| Standard | 6-10 | Diminishing returns for 3 calls OR all fields at 3/5+ |
| Deep | 15-20 | Secondary fields covered AND critical fields at 4/5+ OR explicit gaps logged |

**Universal stops:** Tool-call cap reached, user stops, all must-haves at target confidence.

## Confidence Scoring

Define an explicit confidence scale in the prompt so the agent rates its own findings:

| Score | Meaning |
|-------|---------|
| 5/5 | Verified against 2+ sources (LinkedIn + company site + press) |
| 4/5 | Verified against 1 secondary source |
| 3/5 | Single source, unambiguous |
| 2/5 | Single source, some ambiguity |
| 1/5 | Unclear or conflicting data |

Confidence scoring lets downstream agents and humans know which findings to trust and which need validation.

## Full Autonomy Pattern

For research agents triggered by webhooks or schedules (no human available to answer questions):

```
CRITICAL AUTONOMY REQUIREMENT: You NEVER ask for clarification,
additional information, or user input during the research process.
You work with whatever information is provided and continue
researching until you have completed ALL steps.

NEVER STOP UNTIL THE FINAL STEP IS COMPLETE.
NEVER PAUSE FOR CLARIFICATION - Keep researching until gaps are filled.
```

Use when: triggered agents, scheduled research, workforce sub-agents where the user is not in the loop.

## Smart Defaults and Fallbacks

When user input is incomplete, infer sensibly rather than asking:

```
No goal + "prep for call" -> "Prepare for sales call"
No stage + "cold outreach" -> Prospecting
No depth specified -> Standard
```

When primary research approach yields thin results, pivot:

```
Thin people results -> pivot to Account and Triggers
No trigger found -> pivot to Competition and Status-Quo
Source precedence: CRM > LinkedIn > news
```

## Discovered Mechanisms

Learnings from production research agents:

- **Efficiency vs thoroughness is a real tension.** One agent was optimized from 7 tool calls down to 2-4 for "efficiency" and produced noticeably shallower results. Fix: make the stopping condition confidence-based, not count-based. For research agents, thoroughness should win.
- **Completeness checklists beat vague iteration.** "Iterate until confident" is interpreted loosely by agents. Domain-specific checklists give concrete stopping criteria (can explain in one sentence? know key people? found risks? checked cross-references?).
- **Explicit confidence criteria prevent vague assessments.** "High confidence" means nothing without criteria. Tying confidence to observable conditions (e.g., "High = history retrieved + cross-channel search + multiple sources agree") enables consistent self-assessment.

## Worked Example: Pre-Call Research Agent

**Trigger:** Calendar event - upcoming sales call with prospect.

**Research flow:**
1. Company Overview (Round 1): Web search for company, revenue model, recent news. Minimum 3 different search queries.
2. Key Stakeholders (Round 2): LinkedIn lookup for meeting attendees, decision-maker mapping.
3. Recent Activity (Round 3): Last 90 days of news, funding, hiring patterns, product launches.
4. Competitive Context (Round 4): Who are their alternatives? What is their switching risk?
5. Validation Step: Cross-reference findings across sources. Flag contradictions.
6. Self-Assessment: Can I explain how they make money? Do I know their key challenges? Have I verified across 2+ sources? If any answer is "no" - continue targeted research.
7. Deliverable: Structured briefing with company snapshot, attendee profiles, talking points, and things to avoid.

Each finding carries a confidence score with justification: "4/5: verified against LinkedIn and company site, but no recent press coverage found."

## Common Failure Modes

| Failure | What It Looks Like | Root Cause |
|---------|-------------------|------------|
| Single-query shallow | First search result taken as the full answer | No minimum tool usage requirement |
| Premature stopping | Research ends after querying each source once | Count-based stopping instead of confidence-based |
| Clarification blocking | Agent asks user a question and waits forever | Missing full-autonomy instruction |
| No source attribution | Facts presented without provenance | Output format does not require confidence scores |
| Efficiency over thoroughness | Optimized for minimum tool calls | Wrong optimization target for research archetype |

## Related Files

- `playbooks/use-cases/synthesis-agent-patterns.md` - Patterns for synthesizing research into briefings
- `playbooks/use-cases/enrichment-agent-patterns.md` - Patterns for data enrichment agents
- `.claude/skills/agent-build-patterns/unit-of-action.md` - Why research and synthesis should be separate agents
- `.claude/rules/BUILD_PRACTICES.md` - General agent building practices
