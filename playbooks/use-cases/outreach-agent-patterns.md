# Outreach Agent Patterns

Patterns for building agents that write personalized outreach messages - LinkedIn sequences, email campaigns, follow-ups. Covers both the structural patterns (how to build the agent) and the messaging framework (how the agent should write).

## Messaging Principles

Five rules that apply to every outreach agent regardless of channel or use case:

1. **Peer-to-Peer, Not Seller-to-Buyer.** The agent is starting a conversation between two professionals. Not pitching, not selling, not "reaching out."
2. **Give Before You Ask.** Every message offers something - an insight, a relevant observation, a genuine compliment on their work. The ask comes later.
3. **Never Pitch-Slap.** If the first sentence could be sent to 1,000 people unchanged, it is a pitch-slap. Every opener must reference something specific to THIS person.
4. **Earn the Right to Their Time.** The first message earns a reply. The reply earns a follow-up. The follow-up earns a meeting request. Never skip steps.
5. **Respect the Platform.** LinkedIn is not email. Messages should feel like natural professional conversation, not marketing copy.

## 3-Message Sequence Structure

### Message 1: Conversation Starter (Day 0)

**Goal:** Get a reply. Not a meeting, not a pitch - a reply.

**Structure:**
1. Hook - Reference something specific from research (1-2 sentences)
2. Bridge - Connect their situation to a relevant challenge or trend (1 sentence)
3. Question - Ask something they would genuinely want to answer (1 sentence)

**Word limit:** 100 words maximum (sweet spot 70-90)

**Must NOT include:** Self-introduction longer than a clause, product features, "I hope this message finds you well", the words "synergy," "leverage," "ecosystem," or "solution"

### Message 2: Different Angle (Day 3)

**Goal:** Re-engage with a fresh perspective. Show depth beyond the first message.

**Structure:**
1. Acknowledge - Brief, not apologetic ("Quick thought on something else I noticed...")
2. New angle - A completely different observation from Message 1
3. Lighter ask - Softer question or offer of a resource

**Word limit:** 80 words maximum (sweet spot 50-70)

**Must NOT include:** "Just bumping this", "Following up on my last message", "Did you see my previous message?", repetition of anything from Message 1, guilt-tripping

### Message 3: Direct Ask (Day 10)

**Goal:** Clear, respectful final attempt.

**Structure:**
1. Direct value statement - One sentence about what you can offer
2. Specific ask OR graceful exit
3. Warm close - No pressure, no guilt

**Word limit:** 60 words maximum (sweet spot 40-55)

**Must NOT include:** "This is my last attempt", escalation in intensity, any implication they owe a response

## Personalization Hierarchy

What data points matter most, in order of impact:

**Tier 1 - High Impact (use if available):**
- Their recent LinkedIn post or article (shows you engaged with their thinking)
- A specific career move (new role, promotion, company change within 6 months)
- Company-specific initiative (expansion, funding round, product launch, hiring spree)

**Tier 2 - Medium Impact (solid foundation):**
- Industry-specific challenge (regulatory change, market trend)
- Job postings from their company (technology signals)
- Company technology stack (clues from website, GitHub, job descriptions)

**Tier 3 - Minimum Viable (fallback only):**
- Their role/title + company size
- Industry + geography
- Shared connections or groups

**Minimum viable rule:** Every message must include at least one Tier 1 or Tier 2 data point. If research only turns up Tier 3, flag the contact as "low research confidence" rather than sending a weakly personalized message.

## CTA Progression

The call-to-action escalates naturally across the sequence:

| Message | CTA Type | Examples |
|---------|----------|---------|
| Day 0 | Soft (question) | "Curious how you're thinking about this?" / "Worth a quick exchange?" |
| Day 3 | Medium (resource offer) | "Want me to send over a summary?" / "Happy to share if useful" |
| Day 10 | Direct (meeting or offer) | "Worth a 20-minute chat?" / "Happy to send the brief - no strings" |

**Phrasing that works:** "Curious - [question]?", "Would it be useful to [action]?", "Worth a quick [exchange/chat]?"

**Phrasing that does not work:** "Let me know if you'd like to learn more" (vague), "Would love to set up a call to discuss how we can help" (self-serving), "When would be a good time for a demo?" (too aggressive for first touch)

## Constrained Choice Pattern

Force the agent to pick exactly ONE value module or angle per message:

```
Value module choices (pick ONE):
- Innovation/Tech (unique capabilities, fast NPD)
- Bottom line (cost reduction, lead times)
- Turnkey solution (speed to market, compliance)
- Upgrade path (stock/custom, sustainability)

Don't stack modules - choose one.
```

Prevents bloated messages that try to cover everything.

## Lens/Perspective Pattern

Instruct the agent to analyze through a specific lens:

```
Always analyze through the lens of [Company's] capabilities:
custom formulation, innovative packaging, global compliance,
quality control, supply chain transparency...
```

Ensures all research is framed for relevance to your company's offerings, not generic observations.

## Anti-Patterns with Rewrites

### The Pitch-Slap
Bad: "Hi [Name], I work with [Company] and help companies [do thing]. We offer [features]. Would love to schedule a call. When works for you?"
Why: Zero personalization. Leads with what YOU sell. Could be sent to anyone.
Good: "Your recent push into [market] is bold - [specific challenge] there is no joke. I work with [Company] helping [industry] companies navigate exactly that. Curious how you're thinking about [specific question]?"

### The Guilt Trip Follow-Up
Bad: "Hi [Name], I reached out last week but haven't heard back. I know you're busy, but I really think this could benefit [Company]."
Why: "Haven't heard back" makes them feel bad. "I really think" - nobody cares what you think about their company yet.
Good: "Quick thought on a different angle - I noticed [Company] has a few open roles for [role type]. If you're building that team out, there are [relevant programs]. Want me to send a quick summary?"

### The Feature Dump
Bad: "[Product] offers [Feature 1], [Feature 2], [Feature 3], [Feature 4], and many other services that could benefit [Company]."
Why: Nobody reads feature lists in a LinkedIn message. This is a brochure, not a conversation.
Good: "Companies in [their industry] that are scaling across [region] keep running into the same [challenge]. Curious if [Company] is seeing that too?"

### The Corporate Jargon Storm
Bad: "We help enterprises leverage cloud-native solutions to drive digital transformation and create synergies across their technology ecosystem."
Why: This means nothing. Every word is a buzzword.
Good: "We help companies in [region] figure out if [solution] makes sense for them, and if it does, we make sure they don't overpay for it."

## Word Count Discipline

These limits are strict. LinkedIn is not email. Long messages get ignored.

| Message | Max Words | Sweet Spot | Why |
|---------|-----------|-----------|-----|
| Day 0 | 100 | 70-90 | Long enough to show research, short enough to read in 15 seconds |
| Day 3 | 80 | 50-70 | Follow-ups should be lighter and faster to process |
| Day 10 | 60 | 40-55 | Final attempt should be punchy and direct |

How to hit limits: cut throat-clearing, use contractions, one idea per sentence, no self-introduction paragraphs, no sign-offs ("Best regards" wastes words).

## Discovered Mechanisms

- **The "pick ONE" constraint is counterintuitively powerful.** Left unconstrained, agents list every product capability. Forcing a single value module selection produces more persuasive messages because they are focused. The agent must judge which angle resonates most.
- **BAD/GOOD example pairs calibrate voice faster than instructions.** Instead of describing the desired tone, show it. The model pattern-matches on examples more reliably than it follows abstract tone descriptions.
- **Knowledge-driven personalization via sample emails.** The best outreach agents use knowledge sets (`{{_knowledge.sample_emails}}`) for voice calibration. Sample messages teach the model what "good" sounds like better than any instruction can.
- **Outreach agents succeed through constraint optimization, not information gathering.** The challenge is not finding data - it is compressing insight into a message that fits strict length limits, hits the right tone, and includes exactly one personalized observation and one CTA.

## Related Files

- `playbooks/use-cases/research-agent-patterns.md` - Research patterns (upstream of outreach)
- `playbooks/use-cases/enrichment-agent-patterns.md` - Enrichment patterns that feed outreach
