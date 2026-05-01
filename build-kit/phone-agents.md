# Phone Agent Best Practices

Reference for building production-grade phone agents on Relevance AI. Covers architecture, prompt design, voice configuration, latency management, and common pitfalls.

---

## Architecture: The Three-Phase Pattern

Phone agents work best as part of a workforce pipeline, not standalone. The pattern:

```
Pre-Call Agent  →  Phone Agent  →  Post-Call Agent
(research)        (conversation)    (processing)
```

**Pre-Call Agent** - Front-load everything. CRM lookup, account history, recent interactions, talking points. The phone agent should never need to pause mid-call to research.

**Phone Agent** - Focused on the live conversation. Receives pre-loaded context as params. Minimal tool calling. Drives a singular outcome (book a meeting, capture intake, triage an incident).

**Post-Call Agent** - Processes the call outcome. CRM updates, summary generation, follow-up task creation, structured data extraction. Runs after the call ends.

**Orchestration:** Use a workforce with forced-handover edges. An orchestrator agent receives trigger context, delegates to the phone agent, receives the summary, and forwards to post-call processing.

**Callback/Retry Pattern:** The orchestrator can self-schedule callbacks using the built-in schedule capability (`is_scheduled_triggers_enabled: true`). The phone agent signals outcomes via a CALL OUTCOME block in its `summary_prompt`. The orchestrator parses the outcome and either sends to the pipeline or schedules a callback at the person's requested time. Key rules:
- Use `always-create-new` threading on the orchestrator-to-phone-agent edge so each call attempt is a fresh conversation with no carry-over
- Only schedule callbacks when the person explicitly provides a time - no automatic retries for no-answer/voicemail
- The schedule fires in the same agent conversation (not a new workforce task), so the orchestrator retains tool-call access to the phone agent
- Set a max attempt limit (e.g., 3) to prevent infinite retry loops

**When a standalone phone agent is fine:** Simple, single-purpose calls with no pre-research needed and no post-call integrations (e.g., appointment confirmation, simple survey).

---

## Core Design Principles

### 1. Front-Load Context, Minimize Tool Calls

Every tool call during a live call adds latency. The agent says "please hold" and waits. This breaks conversational flow.

- Do all research, lookups, and data gathering BEFORE the call in a pre-call agent
- Pass context into the phone agent via params (intake JSON, contact info, talking points)
- If tools are unavoidable, make them lightweight and fast (sub-2s response)
- Knowledge lookups during calls are acceptable only if the knowledge set is small and indexed

### 2. Drive a Singular Action

Each phone agent should drive ONE clear outcome:

- Book a meeting
- Capture an intake form
- Triage an incident
- Verify identity
- Confirm an appointment

Do not combine multiple objectives. Resist the temptation to have the agent answer general enquiries, handle objections AND book meetings AND collect feedback. Multi-objective agents lose conversational focus and handle calls poorly.

### 3. Keep Responses Short

Phone is not chat. People zone out after 8-10 seconds of continuous speech.

- 2-3 sentences per turn maximum
- Ask ONE question at a time - never stack questions
- Use verbal acknowledgments between turns: "Got it", "Makes sense", "Right"
- Pause after each section to let the caller respond or redirect

---

## Prompt Engineering for Voice

Voice prompts differ significantly from text agent prompts. Key differences:

### What to Add

Every phone agent system prompt should include a **Phone Call Experience Guidelines** section:

```
## Phone Call Experience Guidelines

You are in the middle of a live phone call. Speak naturally and conversationally.

Phone call audio may be interrupted by background noise -- ignore background noise and do not comment on it.

Do not apologise for audio interruptions or technical glitches caused by the phone connection.

If the caller's audio cuts out briefly, wait a moment, then say something like: "Sorry, I think I lost you for a second there -- could you say that last bit again?"

Continue speaking naturally after any interruption, following your previous train of thought, unless the person explicitly redirects the conversation.

Keep your responses concise. On a phone call, long monologues lose people. Aim for 2-3 sentences per turn, then pause for their response.

Use verbal acknowledgements naturally: "mm-hmm", "right", "got it", "makes sense" -- these signal active listening on a voice call.

If there is a long silence (5+ seconds), gently prompt: "Still with me?" or "Take your time -- no rush."

Never say "as an AI" or reference that you are an AI assistant unless directly asked. If asked, be honest.
```

### What to Ban

Explicitly prohibit in the prompt:

- Markdown formatting (bold, headers, bullet points, numbered lists) - the agent may say "asterisk asterisk" aloud
- Reading structured data, JSON, or lists verbatim on the call
- Em dashes in spoken output (use regular dashes or reword)
- Stacking multiple questions in one turn
- Long monologues (set a sentence limit)

### Text Normalization

Phone agents must speak data naturally:

- Emails: "first dot last at company dot com" (say "dot" for periods, "at" for @)
- Phone numbers: group digits naturally ("oh four one two, three four five, six seven eight")
- Dates: "March nineteenth" not "2026-03-19"
- Money: "fifteen hundred dollars" not "$1,500"
- URLs: avoid reading URLs on calls - offer to send via email/SMS instead

### Conversation Flow Design

Structure prompts around **phases**, not checklists:

```
Phase 1: Opening (30 seconds)
- Greeting, introduce yourself, confirm it is a good time

Phase 2: Core Discussion (5-7 minutes)
- Weave required information gathering into natural conversation
- Do NOT present as a checklist - ask follow-up questions naturally

Phase 3: Closing (30 seconds)
- Summarise what you heard back to the caller for confirmation
- Explain next steps
- Thank them
```

Each phase should have sample dialogue showing the conversational tone expected.

### Objection Handling

For outbound agents especially, include explicit objection handling:

- "I don't have time right now" → Offer to call back, capture preferred time
- "I'm not interested" → Respect immediately, thank them, end gracefully
- "Can you just email me?" → Offer the email but gently note that a quick call surfaces better insights
- "Are you a robot?" → Be honest if asked directly

The key principle: **never pressure**. Phone agents that push past objections destroy trust and brand reputation.

---

## Voice Configuration

### Voice Providers on Relevance AI

**Cartesia Sonic-3**
- Better voice quality perception in head-to-head tests
- Lower cost (~5x cheaper than ElevenLabs)
- 3-second voice cloning
- 15 languages supported
- Good default for most use cases

**ElevenLabs Multilingual V2**
- Wider language support (70+ languages)
- Marginally faster first-byte latency (~75ms vs ~95ms)
- 30-second voice cloning requirement
- Better for multilingual deployments

**Recommendation:** Start with Cartesia Sonic-3 unless you need broad language coverage. Adjust `speed` param (0.8-1.0 range) based on the use case - slightly slower (0.8) for empathetic/support calls, normal (1.0) for transactional calls.

### Transcription (STT)

**Deepgram Nova-3** is the default and recommended choice:
- Native streaming with sub-300ms latency
- Multi-language support
- Built-in diarization
- Better real-world accuracy than Whisper (36% lower word error rate with accents/noise)

**Deepgram Flux** (newer): Purpose-built for voice agents with model-integrated end-of-turn detection at ~260ms.

### Runtime Configuration

> **CRITICAL: MCP Wipes Phone Runtime Config**
>
> The MCP plugin has **zero awareness** of the `runtime` field. Any agent write operation (`relevance_upsert_agent`, `relevance_save_agent_draft`, `relevance_patch_agent`) can silently strip the entire phone runtime config -- including `first_message_mode`, voice, transcriber, and all phone settings. The backend resets to defaults, which omit `first_message_mode`, causing outbound calls to hang and fail with `"Got empty content response without a function call"`.
>
> **Workaround:** After ANY MCP write to a phone agent, verify the phone runtime config in the UI or re-apply it with a `relevance_patch_agent` call that includes the full `runtime` object. See `PLATFORM_MECHANICS.md` "Agent Write Operations" for details.
>
> **Fix status:** Pending fix in the MCP plugin.

Key `runtime.phone_call` settings:

| Setting | Recommendation | Why |
|---------|---------------|-----|
| `first_message_mode` | `agent-speaks-first` for inbound, `agent-generates-first-message` for outbound | Inbound callers expect immediate greeting; outbound needs dynamic context |
| `end_call_tool_enabled` | `true` always | Phantom tool - auto-injected, lets agent end calls gracefully |
| `recording_enabled` | `true` for production | Required for QA, compliance, and post-call processing |
| `background_sound` | `off` or `default` | Background office noise can sound artificial |
| `background_denoising_enabled` | `true` for noisy environments | Helps with mobile/speakerphone callers |
| `silence_timeout_seconds` | 30 | Default is fine - prevents zombie calls |

### Agent Settings for Phone

| Setting | Recommendation | Why |
|---------|---------------|-----|
| `autonomy_limit_behaviour` | `terminate-conversation` | Cannot ask for human approval mid-call |
| `autonomy_limit` | 20 | High enough for full call flow |
| `temperature` | 0 - 0.3 | Low temp for consistent, predictable responses |
| `model` | `openai-gpt-4.1` (performance) or `openai-gpt-5-mini` (cost) | Only OpenAI models work for outbound calls (Vapi requirement). `gpt-4.1` produces cohesive responses; `gpt-5-nano` causes message splitting |
| `action_behaviour` on tools | `never-ask` or `agent-decide` | Tools must run without approval during calls |
| `avatar` | `phone_agent_avatar_{N}.svg` (range 08-12) | Visual distinction from text agents |

---

## Latency Management

Latency is the single biggest differentiator between a good and bad phone agent. Target sub-800ms mouth-to-ear response time.

### Latency Budget

```
STT transcription:     200-400ms
LLM inference:         200-500ms
TTS synthesis:         75-100ms (first byte)
Network overhead:      50-100ms
─────────────────────────────────
Total target:          < 800ms per turn
```

Adding a tool call roughly doubles the LLM portion. Two tool calls and you are into "please hold" territory.

### Strategies

1. **Pre-load all context** - The most impactful thing you can do. Move lookups to a pre-call agent
2. **Use fast, lightweight tools** - If a tool must run mid-call, it should respond in <2 seconds
3. **Use `relevance-performance-optimized` model** - Cost-optimized is cheaper but adds noticeable latency
4. **Avoid knowledge table queries mid-call** unless the table is small and well-indexed
5. **Filler phrases** - When a tool call is unavoidable, acknowledge the pause: "Let me check that for you", "One moment"
6. **Post-call processing** - Move CRM updates, email sends, and summary generation to after the call ends

---

## Handling Voice-Specific Edge Cases

### STT Quirks

Speech-to-text is imperfect. Design for it:

- **Names**: Ask callers to spell unusual names. STT mangles uncommon names frequently
- **Emails**: Ask callers to spell out emails. Recognise spoken "at" and "dot" and normalise
- **Numbers**: STT may split digit sequences across multiple messages. Buffer and wait for complete input
- **Accents**: Test with diverse accents. STT accuracy drops significantly with non-standard pronunciations
- **Background noise**: Mobile callers, speakerphones, and car noise all degrade accuracy. Enable denoising

### Keypad Input

For structured input (verification codes, account numbers), offer keypad as an alternative:

```json
"keypad": {
  "enabled": true,
  "delimiter": "#",
  "timeout_seconds": 2
}
```

Instruct the agent: "You can say the code, or type it on your keypad followed by the hash key."

### Call Transfers and Escalation

Always build an explicit escalation path:

- Define triggers (caller asks for a human, sentiment drops, agent loops 3+ times on same topic)
- Warm handoff preferred: agent summarises context before transferring
- Never trap callers in loops with no way out

---

## Post-Call Processing

After the call ends, extract structured data silently (never read JSON on the call).

### Pattern: Use `summary_prompt` for Structured Output

Phone agents do not directly control their return message to the orchestrator. The phone runtime's `summary_prompt` field generates the text that gets sent back. Put structured output requirements in the `summary_prompt`, not the system prompt.

For example, to signal call outcomes for callback logic, add a CALL OUTCOME block instruction to the `summary_prompt`:

```
At the very end of your summary, include:

CALL_OUTCOME: [completed | no_answer | deferred | declined]
PREFERRED_CALLBACK_TIME: [ISO datetime or "none"]
CALLBACK_REASON: [brief reason or "none"]
```

The orchestrator then parses these fields to decide whether to send data to the pipeline or schedule a callback.

**Important:** The `summary_prompt` is part of `runtime.phone_call` config. Update it via `relevance_patch_agent` with the `runtime` field, and verify the full phone config is intact after.

### Pattern: Silent JSON Extraction (Legacy)

For agents NOT in a workforce (standalone phone agents with tools), the system prompt can include instructions to call a post-call tool with structured data AFTER the call ends:

```
After the call ends, extract all captured information into a JSON object
and send it using the {{_actions.tool_id}} tool.

Do NOT read the JSON out loud on the call. This happens silently after
the conversation ends.
```

**Note:** For workforce-based phone agents, prefer the `summary_prompt` pattern above. The phone runtime auto-generates the summary and returns it to the orchestrator - the agent doesn't need to call a tool itself.

### What to Capture

Standard post-call payload:

- **Call metadata**: status (completed/deferred/declined/no_answer), duration, confidence level, gaps identified
- **Contact info**: name, team, role
- **Structured data**: whatever the call was designed to capture (intake form, incident details, qualification data)
- **Conversation summary**: 3-5 sentence plain-English handoff note
- **Follow-up actions**: callback time, tasks created, escalation needed

### Processing Pipeline

For production deployments, the post-call flow is:

```
Call ends → Phone agent sends JSON → Webhook/n8n → CRM update + task creation + notification
```

Keep the phone agent's responsibility simple: capture and send. Let downstream systems handle routing, storage, and follow-up logic.

---

## Outbound vs Inbound Patterns

### Outbound (BDR/SDR, Intake Calls, Surveys)

- Pre-call research is essential - the agent must know who they are calling and why
- Opening line must establish context immediately: who you are, why you are calling, who referred them
- Always ask "Is now a good time?" before diving in
- Have a clear deferral path: capture callback time, note call status, end gracefully
- Drive one action: book a meeting, capture intake, confirm details
- Hybrid model works best: AI qualifies and books, humans close

### Inbound (Support, Triage, IVR Replacement)

- First message should be pre-set (`agent-speaks-first`) with a clear greeting
- Identify the caller early (name, account number, reference number)
- Triage quickly - understand the issue, assess severity, route appropriately
- Always offer escalation to a human agent
- Keep menus minimal - use natural language intent detection, not "press 1 for..."

---

## Common Pitfalls

1. **MCP wipes phone runtime config** - Any MCP write operation (`upsert_agent`, `save_agent_draft`, `patch_agent`) silently strips the `runtime` field, breaking outbound calls. Always verify phone config in the UI after MCP updates. See the warning in "Runtime Configuration" above
2. **Tool-heavy phone agents** - Every tool call is a "please hold" moment. Front-load context instead
2. **Multi-objective agents** - "Handle enquiries AND book meetings AND collect feedback" leads to unfocused, poor-quality calls
3. **No escalation path** - Callers trapped in loops with no way to reach a human
4. **Lab-only testing** - Agents that sound great in quiet demos fail with background noise, accents, and interruptions. Test in real conditions
5. **Reading structured data aloud** - JSON, lists, bullet points spoken verbatim sound robotic and confusing
6. **Skipping pilot phase** - Always start with a small group before full deployment
7. **Cost-optimized model for phone** - Saves money but adds latency that callers notice immediately
8. **`openai-gpt-5-nano` for phone** - Produces short completions that Vapi's TTS streaming splits into multiple messages, creating unnatural pauses. Use `openai-gpt-4.1` (performance) or `openai-gpt-5-mini` (cost). Only OpenAI models work for outbound calls (Vapi requirement)
9. **Vapi message splitting** - Vapi deliberately splits LLM output into sentences before sending to TTS to reduce perceived latency. This is infrastructure behavior, not controllable via prompting or Relevance AI settings. The primary lever is model selection - larger models produce longer, more cohesive completions that get chunked less
10. **Background sound `undefined` vs `"off"`** - Agents created before the Background Sound setting was added may have `undefined` for `background_sound`, which the backend defaults to `"office"` (Vapi ambient typing/chatter). The UI may show OFF but the value was never written. Fix: toggle OFF and save in the UI to force the explicit `"off"` value to the database
11. **Missing post-call processing** - Call happens but nothing gets recorded to CRM or triggers follow-up
9. **No recording** - Cannot QA, cannot improve, cannot resolve disputes
10. **Ignoring compliance** - Recording consent, AI disclosure, and opt-out requirements vary by jurisdiction
11. **Instructions in spoken templates** - Parenthetical instructions like `(use context from {{intake_json}})` in the opening line get read aloud by the agent. Separate internal instructions from spoken dialogue clearly. Use comments (`<!-- -->`) for instructions, and keep the spoken template as pure dialogue
12. **Premature call termination** - The phantom `end_call_tool` fires aggressively on any perceived farewell. A casual "bye" or "see ya" mid-conversation can trigger an immediate hangup. Always add explicit guardrails in the prompt: "Only end the call after the full closing sequence is complete. A casual 'bye' or farewell word mid-conversation is NOT a signal to hang up. The call should only end when: (1) you have completed the closing summary, (2) the caller has confirmed they have nothing else to add, and (3) you have said your final goodbye"

---

## Compliance Checklist

Compliance requirements vary by jurisdiction. This is a starting point, not legal advice.

**Every call should:**
- Disclose AI nature if asked (and proactively in jurisdictions that require it)
- Announce recording at call start and get consent
- Provide a verbal opt-out option for outbound calls
- Store consent records

**For outbound calls:**
- Written consent may be required before AI-generated calls (FCC, Jan 2025)
- Some jurisdictions require upfront AI disclosure (e.g., California AB 2905)
- Must provide opt-out mechanism during every call

**For recordings:**
- Two-party consent required in some jurisdictions (both parties must agree)
- One-party consent in others (only one party needs to know)
- When in doubt, announce recording and get explicit consent
- Implement PII redaction on stored transcripts

---

## Relevance AI-Specific Reference

### Phone Agent Avatar URLs

```
https://cdn.jsdelivr.net/gh/RelevanceAI/content-cdn@latest/agents/agent_avatars/phone_agent_avatar_{N}.svg
```
Range: 08-12

### Phantom Tools

`end_call_tool` is auto-injected at runtime when `end_call_tool_enabled: true`. Do not add it to the actions array - it appears automatically. Reference it in prompts for graceful call endings.

### Voice Provider Config Examples

**Cartesia Sonic-3:**
```json
"voice": {
  "provider": "cartesia",
  "model": "sonic-3",
  "voiceId": "f31cc6a7-c1e8-4764-980c-60a361443dd1",
  "language": "en",
  "speed": 0.8
}
```

**ElevenLabs Multilingual V2:**
```json
"voice": {
  "provider": "elevenlabs",
  "model": "eleven_multilingual_v2",
  "voiceId": "XB0fDUnXU5powFXDhCwa",
  "language": "en",
  "speed": 1
}
```

**Deepgram Nova-3 STT:**
```json
"transcriber": {
  "model": "nova-3",
  "language": "multi",
  "provider": "deepgram"
}
```

---

## Credits

Patterns synthesised from production phone agent builds across financial services, retail, and enterprise IT, plus external voice AI research.
