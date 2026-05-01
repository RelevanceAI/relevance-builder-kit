# Phone Agent

Use phone agents when the use case requires synchronous voice interaction with a single clear outcome - booking meetings, capturing intake, triaging incidents, verifying identity, or confirming appointments.

## When to Use

- You have a high-volume calling workflow (outbound BDR, inbound support, intake forms)
- The call has a single clear objective (book, capture, triage, verify, confirm)
- Pre-call context is available or can be gathered (CRM data, account history, talking points)
- You want to reduce human time on repetitive calls while keeping humans for relationship work
- Volume justifies the build (dozens to hundreds of calls per day, not occasional calls)

## When Not to Use

- The call requires deep relationship building, negotiation, or complex objection handling - these need humans
- Multiple objectives per call (book meetings AND collect feedback AND handle enquiries) - multi-objective agents lose focus and perform poorly
- No CRM or data source to front-load context from - the agent will pause mid-call to research, breaking conversational flow
- Low call volume does not justify the build - a simpler agent or manual process is cheaper
- You need multilingual support across 10+ languages - evaluate voice provider coverage first

## Default Architecture

Three-phase workforce pipeline. The phone agent should never research mid-call.

```
Pre-Call Agent  ->  Phone Agent  ->  Post-Call Agent
(research)         (conversation)    (processing)

Orchestrator coordinates all three via forced-handover edges
```

- **Pre-Call Agent:** CRM lookup, account history, recent interactions, talking points. Outputs a context package passed as params to the phone agent.
- **Phone Agent:** Focused on the live conversation. Receives pre-loaded context. Minimal tool calling. Drives one outcome.
- **Post-Call Agent:** CRM updates, summary generation, follow-up task creation, structured data extraction from the call.
- **Orchestrator:** Receives trigger context, delegates to phone agent, receives summary, forwards to post-call. Can self-schedule callbacks.

**Variations:**
- **Standalone agent when:** Simple single-purpose calls with no pre-research and no post-call integrations (appointment confirmation, simple survey). Skip the workforce.
- **Callback/retry pattern when:** Outbound calls that may reach voicemail or "call me back later." Orchestrator self-schedules using `is_scheduled_triggers_enabled: true`. Use `always-create-new` threading so each attempt is fresh. Max 3 attempts.
- **Inbound pattern when:** Support/triage/IVR replacement. Set `agent-speaks-first` with a greeting. Identify caller early. Triage quickly. Always offer human escalation.

## Key Design Decisions

- **Front-load context, minimize tool calls:** Every tool call during a live call adds latency and a "please hold" moment. Do all research before the call. If tools are unavoidable, they must respond in under 2 seconds.
- **One objective per agent:** Do not combine meeting booking with feedback collection. Build separate agents for separate outcomes. Unit of Action applies.
- **Keep responses short:** Phone is not chat. 2-3 sentences per turn max. One question at a time. People zone out after 8-10 seconds of continuous speech.
- **Voice provider selection:** Start with Cartesia Sonic-3 unless you need broad multilingual coverage (use ElevenLabs). Cartesia is ~5x cheaper with better perceived quality.
- **Model selection for phone:** Use `openai-gpt-4.1` (performance) or `openai-gpt-5-mini` (cost). Only OpenAI models work for outbound calls (Vapi requirement). Do NOT use `openai-gpt-5-nano` - it produces short completions that cause unnatural pauses.

## Tools Required

| Tool | Purpose | Notes |
|------|---------|-------|
| CRM lookup tool | Pre-call context gathering | Runs in pre-call agent, not during the call |
| CRM update tool | Post-call record updates | Runs in post-call agent |
| Calendar/booking tool | Meeting scheduling | Only if the objective is booking - keep it fast |
| Knowledge lookup | FAQ or policy reference during call | Only if knowledge set is small and indexed |

## Knowledge Tables

| Table | Purpose | Key Fields |
|-------|---------|------------|
| Call outcomes | Track results across all calls | contact_id, outcome, summary, callback_time, attempt_count |
| Contact context | Pre-call research output | contact_id, company, history, talking_points, enrichment |

## Implementation Checklist

1. Define the single objective for the phone agent
2. Build the pre-call agent with CRM lookup and context packaging
3. Build the phone agent with voice-optimized prompt (see `build-kit/phone-agents.md` for prompt templates)
4. Configure voice provider (Cartesia Sonic-3 default, speed 0.8-1.0)
5. Configure STT (Deepgram Nova-3)
6. Set up `summary_prompt` for structured post-call output
7. Build the post-call agent (CRM update, follow-up task creation)
8. Wire into workforce with forced-handover edges
9. Test with real phone conditions (background noise, accents, interruptions) - not just quiet demos
10. Run compliance checklist (recording consent, AI disclosure, opt-out)
11. Pilot with small group before full deployment

## Failure Modes and Gotchas

- **MCP wipes phone runtime config:** Any MCP write operation (`upsert_agent`, `save_agent_draft`, `patch_agent`) silently strips the `runtime` field, breaking outbound calls. Always verify phone config in the UI after MCP updates.
- **Tool-heavy phone agents:** Three tool calls during a single turn means three "please hold" moments. Front-load everything into pre-call.
- **Premature call termination:** The phantom `end_call_tool` fires aggressively on any perceived farewell. A casual "bye" mid-conversation triggers a hangup. Add explicit guardrails: "Only end the call after the full closing sequence is complete."
- **Instructions read aloud:** Parenthetical instructions like `(use context from {{intake_json}})` in the opening line get read aloud by TTS. Separate internal instructions from spoken dialogue using comments (`<!-- -->`).
- **Background sound defaults to office:** Agents created before the Background Sound setting may have `undefined` which defaults to ambient office sounds. Toggle OFF and save in UI to force the explicit `"off"` value.
- **Vapi message splitting:** Vapi splits LLM output into sentences before TTS to reduce perceived latency. This is infrastructure behavior. Mitigate by using models that produce longer completions (`gpt-4.1` not `gpt-5-nano`).
- **Lab-only testing:** Agents that work in quiet demos fail with background noise, accents, and interruptions. Always test in real conditions.
- **No post-call processing:** The call happens but nothing gets recorded. Always build the post-call agent.

## Example Prompts

See `build-kit/phone-agents.md` for full prompt templates including:
- Phone Call Experience Guidelines block
- Text normalization rules
- Conversation flow design (phase-based, not checklist)
- Objection handling patterns

## Related Files

- `build-kit/phone-agents.md` - Full implementation reference (voice config, prompt engineering, compliance, pitfalls). Read this when building.
- `.claude/skills/agent-build-patterns/unit-of-action.md` - Why one objective per agent matters
