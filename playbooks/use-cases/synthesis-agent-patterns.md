# Synthesis and Intelligence Agent Patterns

Patterns for agents that gather from multiple sources and synthesize into executive-ready briefings, account summaries, or strategic recommendations. These agents must be opinionated, not neutral - data without interpretation is work for the reader.

## Separate Gathering from Synthesis

Two distinct phases with different optimization goals:

| Phase | Optimize For | Cognitive Mode |
|-------|-------------|----------------|
| Gathering | Coverage, completeness | Curious, exhaustive |
| Synthesis | Signal-to-noise, actionability | Ruthless, opinionated |

Never mix them. Gather first (multiple rounds), THEN synthesize. When gathering and synthesizing happen simultaneously, the agent prematurely commits to a narrative and stops looking for contradicting evidence.

## The CEO Elevator Test

The ultimate quality check for synthesis output:

> Imagine being stopped by the CEO: "Quick - what's going on with {company}?"

Your synthesis should:
1. Lead with the headline - one sentence that captures the essential truth
2. State what matters - 3-5 bullets maximum
3. Be opinionated - don't just report facts, interpret them
4. End with the action - what should happen next

## Executive Briefing Output Format

```
{Company}: {One-line headline that captures the situation}

What you need to know:
- {Most important thing}
- {Second most important}
- {Third if truly necessary}

Risk: {The thing that could go wrong}

Opportunity: {The thing we should pursue}

Recommended action: {Specific, concrete next step}

---
Sources: {Data sources used}. Gaps: {What's missing}.
```

## Be Opinionated, Not Neutral

Bad: "There's a renewal coming up in September"
Good: "Renewal is 7 months out but we should act NOW - there's an internal skeptic we need to neutralize"

Bad: "ARR is $65k, renewal date is Sep 30, deal stage is Quarter Way"
Good: "$65k account with strong exec buy-in, but IT friction could derail the expansion motion"

Bad: "The CFO is supportive"
Good: "CFO is a champion - use him to get the AI CoE leader in the room before the expansion demo"

## The "So What?" Rule

Every piece of information must answer:
- So what?
- Why does this matter?
- What should I do about it?

Data without interpretation is work for the reader. Insight with recommendation is value.

## Multi-Source Synthesis

When combining information from multiple sources:

| Principle | Implementation |
|-----------|---------------|
| Organize by theme | Not by source. "Key contacts" not "HubSpot says..." |
| Note contradictions | "HubSpot shows active, but Slack sentiment suggests drift" |
| Indicate freshness | "Slack = recent (days), Notion = documented (weeks), HubSpot = structured (varies)" |
| Acknowledge gaps | "Notion unavailable - missing strategic goals context" |

## Confidence Aggregation

When synthesizing from multiple sources, roll up confidence:

| Scenario | Confidence | Signal |
|----------|-----------|--------|
| 3+ sources agree | High | Strong consensus |
| 2 sources agree, 1 missing | Medium-High | Likely accurate |
| Sources conflict | Medium | Note discrepancy explicitly |
| Single source only | Medium-Low | Caveat the limitation |
| Data is stale (>30 days) | Lower | Flag freshness concern |

## Proactive Behavior

Synthesis agents should anticipate, not just answer:

| Reactive (Bad) | Proactive (Good) |
|----------------|-----------------|
| Return the data requested | Surface things the user didn't know to ask |
| List the contacts | Flag which contact is disengaged |
| Show the renewal date | Warn if renewal is at risk and why |
| Report the deal stage | Recommend the next action |

Design for the user's ACTUAL goal, not their STATED query:
```
User says: "What's going on with Acme?"
User means: "Help me feel prepared for my next interaction with Acme"
```

## Graceful Degradation

When sources fail, proceed honestly:
1. Continue with available data
2. Acknowledge the gap explicitly
3. Offer to retry when the source is available

```
"I couldn't access Notion due to an authorization error. Based on HubSpot data:
[synthesis]. Once Notion access is restored, I can add strategic goals and relationship notes."
```

Never silently omit or fabricate. Users trust honest systems.

## Discovered Mechanisms

- **"Let me know what else you think may be useful."** Adding this phrase to delegation prompts transforms sub-agent behavior. A CRM sub-agent spontaneously added risk analysis and recommended next steps that were never explicitly requested. Activate agency, do not constrain it.
- **The CEO Elevator Test as structural enforcement.** It is not just a framing device - it becomes the output format contract. The format (Headline -> Bullets -> Risk -> Opportunity -> Action) makes neutral data dumps structurally impossible.
- **Organize by theme, not by source.** Early versions produced "HubSpot says... Notion says... Slack says..." forcing the reader to mentally merge. Reorganizing by theme shifted the synthesis burden from reader to agent.
- **Confidence-based stopping over prescribed iterations.** One complex query triggered 9 tool calls because confidence was not met after 5. Another simple query completed in 3. The stopping condition was "I can give a great answer" - not a fixed count.

## Worked Example: Account Intelligence Query

**Query:** "What's going on with Acme?"

**Phase 1 - Discovery (9 tool calls):**
1. HubSpot broad query: deals, contacts, activity
2. HubSpot follow-up: recent support tickets or escalations
3. HubSpot follow-up: cross-reference competitor mention found in notes
4. Notion: account plan and strategic goals
5. Slack: search for mentions across channels
6. Slack: retrieve channel history for depth
7-9. Additional targeted queries to fill gaps

**Phase 2 - Synthesis:**
> **Acme: Solid foothold, but a competing tool's rollout is eroding daily adoption. Renewal is winnable if we reposition as the "execution layer."**
>
> What you need to know:
> - Steady ARR, renewal Sep 2026, expansion deal open
> - Competing platform now default for knowledge queries. This product is positioned as the agent / execution layer
> - Product friction: agent discoverability, export quality flagged by users
> - Champions: technical lead, project lead. Engaged but see reduced differentiation
>
> Risk: Usage drift -> "why are we paying for this?" renewal conversation
>
> Opportunity: Own the architecture. Competing tool = knowledge, this product = workflows that act
>
> Recommended action: Run positioning reset in 2-3 weeks. Deliver a comparison enablement asset, then working session with power users.
>
> Sources: HubSpot (CRM, activity notes), Slack (#acme channel). Gap: Notion Account Plan unavailable (OAuth error).

Despite Notion failing, the synthesis was excellent - demonstrating graceful degradation in practice.

## Common Failure Modes

| Failure | What It Looks Like | Root Cause |
|---------|-------------------|------------|
| Data dump | Output reads like search results | No phase separation - gathering and synthesis mixed |
| Neutral tone | "There's a renewal coming up in September" | Missing the So What rule |
| Source-organized output | "HubSpot says... Slack says..." | Reader forced to do mental synthesis |
| Silent omission | Missing source not mentioned | No explicit gap declaration in format |
| Literal interpretation | Answers the query string, not the need | Not decoding implicit intent |
| Single-pass queries | Each source queried once, shallow | Coverage-based stopping instead of confidence-based |

## Related Files

- `playbooks/use-cases/research-agent-patterns.md` - Patterns for the gathering phase
- `.claude/skills/agent-build-patterns/build-philosophy.md` - Separate Finding from Doing principle
- `.claude/skills/agent-build-patterns/unit-of-action.md` - Why gathering and synthesis should be separate agents
