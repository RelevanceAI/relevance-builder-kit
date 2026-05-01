# Meeting Intelligence

Use meeting intelligence agents when your team needs to automatically capture, analyze, and act on meeting content - extracting insights, updating CRM, routing action items, and triggering follow-up workflows without manual note-taking.

## When to Use

- Your team has high meeting volume (sales calls, CS check-ins, internal syncs) and insights are being lost
- Post-meeting manual work is a bottleneck (CRM updates, summary emails, action item tracking)
- You need structured data extraction from unstructured conversations (deal signals, objections, commitments, next steps)
- An existing call recording tool (Gong, Chorus, native Relevance call intelligence) provides transcripts that are not being actioned
- You need cross-meeting intelligence (patterns across accounts, teams, or time periods)

## When Not to Use

- No call recording or transcript source - you need a data input before you can process it
- Low meeting volume (a few calls per week) - manual follow-up is faster than building automation
- You only want transcription and storage without any downstream action - point users to a recording tool
- Compliance constraints prevent transcript processing or storage - verify before building

## Default Architecture

Trigger-based capture with phased processing.

```
Meeting Ends (trigger)
  -> Capture Agent (transcript + metadata extraction)
    -> Analysis Agent (insights, signals, action items)
      -> Action Agent (CRM update, follow-up tasks, notifications)
```

- **Trigger:** Meeting ends event from calendar integration, call platform webhook, or scheduled polling
- **Capture Agent:** Retrieves transcript and meeting metadata (participants, duration, account, deal stage). Stores raw data in knowledge table.
- **Analysis Agent:** Extracts structured insights - deal signals, objections raised, commitments made, action items with owners, sentiment. Produces a structured summary.
- **Action Agent:** Routes outputs to the right systems - CRM field updates, Slack notification to AE, follow-up email draft, task creation in project management tool.

**Variations:**
- **Single agent when:** Simple summarize-and-store with no downstream routing. One agent captures, analyzes, and writes to a knowledge table. No workforce needed.
- **Real-time pattern when:** You need live call intelligence, not post-call. Use Relevance native call app with SuperGTM for real-time context surfacing during the call, then post-call processing as above.
- **Cross-meeting analysis when:** You need aggregate patterns (common objections, win / loss signals across deals). Add a periodic analysis agent that reads across the knowledge table and produces trend reports.

## Key Design Decisions

- **Transcript source:** Native Relevance call intelligence vs external (Gong, Zoom, Teams recordings). Native gives tighter integration. External requires a capture step to pull transcripts via API or webhook.
- **Structured extraction over summarization:** Summaries are nice but structured fields (deal_signal, objections[], action_items[], next_steps[]) are what downstream automation needs. Always extract structured data, optionally generate a human-readable summary alongside.
- **Knowledge table as pipeline glue:** Store raw transcripts and extracted insights in a knowledge table. This enables cross-meeting queries, trend analysis, and audit trails. The knowledge table is the single source of truth.
- **Separation of capture from analysis:** Keep transcript capture as a separate step from analysis. Transcripts are raw data that should be stored regardless of whether analysis succeeds. If the analysis agent fails or needs reprocessing, the transcript is preserved.

## Tools Required

| Tool | Purpose | Notes |
|------|---------|-------|
| Transcript retrieval tool | Pull transcript from call platform | Platform-specific (Zoom API, Gong API, or native Relevance) |
| CRM update tool | Write insights back to deal/contact records | Match on meeting participants to CRM contacts |
| Slack notification tool | Alert team members with meeting summary | Route to relevant channel based on account or deal |
| Knowledge table write tool | Store transcripts and extracted data | Central pipeline storage |

## Knowledge Tables

| Table | Purpose | Key Fields |
|-------|---------|------------|
| Meeting transcripts | Raw transcript storage | meeting_id, date, participants, account, transcript, duration |
| Meeting insights | Extracted structured data | meeting_id, deal_signals, objections, action_items, next_steps, sentiment, summary |

## Implementation Checklist

1. Confirm transcript source and access method (API, webhook, native)
2. Build capture agent - retrieve transcript + metadata, store in knowledge table
3. Define the extraction schema (what structured fields to extract from each meeting)
4. Build analysis agent with structured extraction prompt
5. Build action agent(s) for downstream routing (CRM, Slack, tasks)
6. Wire into workforce with trigger on meeting end event
7. Test with real transcripts (not synthetic - real meetings have interruptions, tangents, and messy audio)
8. Validate CRM field mapping - ensure extracted data writes to the correct fields
9. Set up monitoring for failed extractions or missed meetings

## Failure Modes and Gotchas

- **Transcript quality variance:** Real meetings have cross-talk, background noise, accents, and domain jargon. Extraction quality depends heavily on transcript quality. Test with actual call recordings, not clean samples.
- **Participant matching failures:** Mapping meeting participants to CRM contacts requires fuzzy matching on names and emails. External participants may not match any CRM record. Build a fallback path (create new contact or flag for manual review).
- **Extraction schema too ambitious:** Trying to extract 20 fields from every meeting produces inconsistent results. Start with 5-7 high-value fields (deal signals, action items, next steps, objections) and expand based on what is actually used downstream.
- **Missing meeting context:** The analysis agent needs to know the deal stage, account context, and what was discussed previously to extract meaningful signals. Feed this context from CRM, not just the transcript alone.
- **Trigger reliability:** Meeting-end webhooks can be flaky or delayed. Build idempotency (check if this meeting was already processed) and consider a polling fallback.
- **Token costs on long meetings:** Hour-long meeting transcripts are large. Use chunking or summarize-then-extract patterns to manage token costs on long calls.

## Example Prompts

Extraction prompt pattern:

```
You are analyzing a sales meeting transcript. Extract the following structured data:

1. DEAL SIGNALS: Any buying signals, budget mentions, timeline commitments, or competitive mentions
2. OBJECTIONS: Concerns or pushback raised by the prospect, with exact quotes where possible
3. ACTION ITEMS: Commitments made by either party, with owner and deadline if mentioned
4. NEXT STEPS: Agreed next steps and follow-up timeline
5. SENTIMENT: Overall meeting sentiment (positive/neutral/negative) with brief justification

Meeting context:
- Account: {{account_name}}
- Deal stage: {{deal_stage}}
- Participants: {{participants}}

Transcript:
{{transcript}}
```

## Related Files

- `build-kit/phone-agents.md` - Phone agent architecture (relevant if combining phone agents with meeting intelligence)
- `.claude/skills/agent-build-patterns/unit-of-action.md` - Why capture, analysis, and action should be separate agents
- `build-kit/tools/knowledge-tables.md` - Knowledge table API for storing transcripts and insights
