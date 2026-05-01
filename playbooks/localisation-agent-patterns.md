# Localization Agent Patterns

Localization agents generate culturally fluent content in target languages by combining locale-specific knowledge retrieval with multi-stage generation, quality assurance, and post-editing. They augment existing outreach or content agents rather than replacing them.

## When to Use

- You have existing outreach or content agents producing English content and need to scale to multiple language markets (LATAM, EMEA, APAC expansion)
- Word-for-word translation is missing cultural nuance (formal vs informal register, honorifics, locale-specific CTAs, date / number formatting)
- Volume justifies the multi-agent pipeline: more than a handful of messages per language per week
- Localization pain shows up internally as "our reps in Brazil just translate the English emails" or "we tried Google Translate but it sounds robotic"
- Your product or glossary page already exists in multiple languages (signals existing investment in localization)

## When Not to Use

- **Single language only:** Add locale instructions directly to the existing agent's system prompt or knowledge. A full workforce is overkill for one target language at low volume.
- **You already have an existing TMS that works:** Smartling, Phrase, memoQ, Lokalise. Integrate with that TMS rather than building a parallel translation system. Relevance can feed content into a TMS via API.
- **Legally required human-certified translation:** Regulated industries (medical, legal, financial disclosures) where machine-generated translations carry compliance risk. Localization agents can draft but a human must certify.
- **Static website copy or documentation translation:** This pattern is for generative content (emails, outreach, ad copy). Bulk static translation is a different problem better served by TMS platforms.
- **No access to a native speaker to validate initial output:** The first 10-20 outputs per language must be reviewed by a native speaker to calibrate quality. Without this, quality drifts undetected.

## Default Architecture

A 3-agent workforce where the entry agent generates locale-native content, then routes to quality assurance and post-editing.

```
                    [Trigger]
                        |
                  forced-handover
                        |
                        v
            +-----------------------+
            |   Entry Agent         |
            |   (Locale-Native      |
            |    Content Generator) |
            +-----------+-----------+
                        |
              +---------+---------+
              |                   |
          tool-call           tool-call
          (always-same)       (always-same)
          (never-ask)         (never-ask)
              |                   |
              v                   v
    +-------------------+  +------------------+
    | Locale QA Agent   |  | Post-Editing     |
    | (LQA Evaluation)  |  | Agent            |
    +-------------------+  +------------------+
```

**Key architectural details:**

- **Entry agent is NOT a translator.** It generates content natively in the target language using an instruction-builder tool (outputs structured writing guidance) and a content-generator tool (produces the actual content from those instructions). This two-tool pattern separates style/tone decisions from content production.
- **Tool-call edges, not forced-handover.** The entry agent decides when to invoke QA and post-editing. This allows the entry agent to skip QA for high-confidence outputs or re-route based on QA results.
- **Always-same threading** on all edges. QA and post-editing agents retain conversation context across invocations within the same task.
- **Never-ask action behaviour.** The pipeline runs fully autonomously. Low confidence is a status to record, not a question to ask.
- **`node_context` passes `target_language_and_iso_code`** from the trigger through to downstream agents. The QA agent uses this to load the correct locale guideline and glossary.

**Variations:**

- **Single-agent variation when:** Only one target language and volume is low (under 20 messages/week). Collapse into a single agent with locale guidelines loaded from knowledge. Skip the QA and post-editing agents. Add them later when volume increases or quality issues emerge.
- **QA-first variation when:** Customer prioritizes catching errors over throughput speed. Route entry agent -> QA agent first, then QA agent routes to post-editing only when issues are found. This saves post-editing cost on content that passes QA clean (the QA agent returns "Transcreation is Ready" and the original content ships as-is).
- **Augmenting existing outreach when:** Customer already has a working outreach agent. Do not rebuild from scratch. Add the localization workforce as a downstream node. The existing outreach agent generates the English brief/instructions, and the localization workforce takes the brief as input to produce locale-native output.

## Key Design Decisions

- **Generate natively, do not translate from English.** Straight translation does 1:1 sentence mapping which breaks down in languages with very different grammar and structure. The instruction-builder pattern separates content intent from language execution, so the content-generator produces output that reads as natively written. This is the single most important design decision in this pattern.

- **Locale guidelines in knowledge tables, not hardcoded in system prompts.** Guidelines change per-region, per-client, and over time. Knowledge tables allow updates without redeploying agents. Store as `usage_type: "tool"` so they are retrieved by ISO code at runtime rather than auto-injected into every conversation.

- **Shared tools for glossary and guideline retrieval.** Build one "Extract Language Glossary" tool and one "Search Language Guidelines" tool. Share them across all agents in the workforce. This prevents glossary drift where one agent uses a different translation than another.

- **Two-tool content generation (instruction builder + content generator).** The instruction builder outputs structured writing guidance (tone, formality, CTA style, vocabulary constraints). The content generator receives only these instructions plus the content brief. All the heavy lifting lives in the instruction layer. This makes it modular: changing the locale guideline changes the instructions, which changes the output, without touching the content generator.

- **LQA framework with 8 evaluation dimensions.** The QA agent evaluates Accuracy, Fluency, Terminology, Style, Locale Conventions, Cultural Appropriateness, Design/Layout, and General Issues. Each issue gets a severity level (Critical/Major/Minor) and a structured report. This is not subjective review -- it is a repeatable, auditable evaluation framework. See `build-kit/agents/knowledge/locale-knowledge-architecture.md` for the full framework.

- **Cost model.** LLM-native content generation costs approximately $0.001/word at Haiku-tier pricing. A 3-agent workforce adds approximately 3x per message for QA and post-editing. At scale (100K words/month across 10 languages), total LLM spend is approximately $3,000/month -- an order of magnitude cheaper than human translation agencies.

## Tools Required

| Tool | Purpose | Notes |
|------|---------|-------|
| Instruction Builder | Outputs structured writing guidance (tone, formality, CTA style, vocabulary) from locale guidelines + content brief | NOT a translator. Think of it as the locale-aware creative director. |
| Content Generator | Produces the actual content from structured instructions | Receives instructions + brief only. No direct access to locale guidelines. |
| Extract Language Glossary | Retrieves approved terminology from the glossary knowledge table by language ISO code | **Shared tool** across all agents in the workforce. Prevents glossary drift. |
| Search Language Guidelines | Retrieves the locale guideline for the target language from knowledge | **Shared tool.** Returns the full guideline document for the requested locale. |

## Knowledge Tables

| Table | Purpose | Key Fields |
|-------|---------|------------|
| Glossary / Term Bank | Approved translations, do-not-translate terms, context notes | source_term, target_term, language_iso, do_not_translate, context, approved_by |
| Locale Guidelines | One row per locale with full guideline text | language_iso, region, guideline_content, last_verified |
| Translation Memory (optional) | Previously approved source-target pairs for reuse | source_text, target_text, language_iso, content_type, date_approved |

See `build-kit/agents/knowledge/locale-knowledge-architecture.md` for full schema design, loading strategy, and governance.

## Implementation Checklist

1. **Build the glossary.** Create the glossary knowledge table and seed with 50-100 key terms. Check whether your organisation already has a glossary (website glossary page, localization team, branding team). Many companies have these and do not realize their sales teams could use them.

2. **Create one locale guideline.** Pick the highest-priority language. Use `build-kit/templates/locale-guide.template.md` as the starting point. Have a native speaker review it. AI can generate an initial draft from best-in-class emails your team already sends in the target language.

3. **Build the shared tools.** Create "Extract Language Glossary" and "Search Language Guidelines" tools. Test each with `relevance_trigger_tool` to confirm they return correct results for the target language.

4. **Build the entry agent.** Configure the instruction-builder and content-generator tools. Set up locale guideline retrieval from knowledge. Test with a single content brief in the target language.

5. **Validate output quality with a native speaker.** Run 10-20 test cases. Have the native speaker review each output against the locale guideline. Record pass/fail and common issues. This baseline is critical for calibrating QA thresholds later.

6. **Build the Locale QA agent.** Use the LQA evaluation framework (8 dimensions, severity scale). Configure the QA agent to load the glossary and locale guideline for the target language. The QA agent evaluates only -- it does not rewrite.

7. **Build the Post-Editing agent.** Configure it to receive the QA report and apply minimal corrections. The post-editing agent fixes only what the QA agent flagged. It does not improve, rephrase, or enhance unflagged content.

8. **Wire as a workforce.** Create the 3-agent workforce with tool-call edges from the entry agent to QA and post-editing. Set `always-same` threading and `never-ask` action behaviour. Pass `target_language_and_iso_code` via `node_context`.

9. **Scale to additional languages.** For each new language: create a locale guideline (from the template), add terms to the glossary, calibrate QA thresholds with native speaker review of the first 10-20 outputs. The workforce architecture does not change -- only the knowledge tables grow.

## Failure Modes and Gotchas

- **Honorific/formality mismatch in Japanese and Korean.** Agents default to casual register unless the locale guideline explicitly specifies the required keigo level (Japanese) or speech level (Korean). Japanese has 3+ levels of politeness; Korean has 6+. The locale guideline must specify which level to use and when to switch. A casual email to a Japanese enterprise CIO is a deal-breaker.

- **LATAM Spanish vs Spain Spanish pronoun mixing.** If the locale guideline says "Spanish" without specifying the region, the agent mixes "vos" (Argentine), "tu" (LATAM general), and "usted" (formal/Spain). Always use the specific ISO code (es-419 for LATAM, es-ES for Spain) and explicitly state the default pronoun in the locale guideline.

- **CTA conventions differ by culture.** "Book a demo" / "Schedule 15 minutes" is standard in US English but overly aggressive in Japanese, Korean, and many European markets. The locale guideline must include locale-specific CTA alternatives. This is the #1 source of "the output sounds translated" feedback.

- **Glossary drift across agents.** If each agent maintains its own glossary copy rather than sharing a single glossary tool, translations diverge over time. One agent calls it "Daten-Streaming" while another uses "Data Streaming" untranslated. Always use shared tools pointing to a single glossary table.

- **QA scoring calibration per language.** Languages with less LLM training data (Thai, Vietnamese, Indonesian) produce lower baseline fluency scores than high-resource languages (Spanish, French, German). If you set the same pass/fail threshold for all languages, low-resource languages will fail QA at much higher rates. Calibrate thresholds per language using native speaker review.

- **Post-editing agent rewrites instead of patching.** Without explicit constraints, the post-editing agent may rewrite entire paragraphs instead of applying minimal fixes. The system prompt must include absolute constraints: never alter meaning beyond what the QA report requires, never omit content, never add content, preserve all structural elements (HTML tags, template variables, placeholders).

- **"Transcreation is Ready" short-circuit.** When the QA agent finds no issues, it returns "Transcreation is Ready" instead of a full report. The post-editing agent must check for this string first and return the original content unchanged. Without this check, the post-editing agent invents "improvements" on clean content.

- **Template variables and HTML tags in multilingual content.** Variables like `{{first_name}}`, `<br>` tags, and URL placeholders must pass through translation unchanged. Add explicit rules in both the content-generator and post-editing agent system prompts: "Never change non-translatable elements -- variables, placeholders, HTML tags, template syntax, and URLs must be returned exactly as received."

## Example Prompts

### Post-Editing Agent (condensed)

```
## Role
You are an Automatic Post-Editor (APE) for transcreated content. You are a
native speaker of {{target_language_iso_code}}. You fix and return -- you do
not evaluate, score, or re-review.

## Task
Given the original target text and an LQA Report:
- If the LQA Report contains only "Transcreation is Ready": return the
  original text unchanged. Append: "APE Status: No changes applied."
- If the LQA Report contains issues: apply corrections per the rules below.

## Correction Rules
1. Fix all issues listed in the LQA report
2. Use the Suggested Fix when provided
3. Apply best judgment when no fix is provided
4. Scope fixes to the flagged segment first
5. Do not introduce new changes
6. Preserve all structural elements (HTML, variables, placeholders)
7. Resolve conflicts: higher severity wins, then Accuracy > Fluency > others

## Output
Section 1: Full corrected target text
Section 2: APE Status (Complete / Complete with flags), issues resolved count,
flags for unresolved items
```

### Locale QA Agent -- evaluation instruction snippet

```
## Core Evaluation Principle
For every segment of the target text, ask:
"As a native speaker of {{target_language_and_iso_code}}, does this segment
accurately reflect the source instructions, read naturally, and conform to
professional standards for this locale?"

## Evaluation Order
Evaluate across these dimensions IN ORDER. Check every segment before moving
to the next dimension:
1. Accuracy  2. Fluency  3. Terminology  4. Style
5. Locale Conventions  6. Cultural Appropriateness  7. Design/Layout  8. Other

## Before Evaluating
Use Extract Language Glossary [Shared Tool] to obtain the glossary.
Use Search Language Guidelines [Shared Tool] to obtain the style guide.

## Output
- Overall Rating: Excellent / Good / Fair / Poor
- Pass / Fail based on rating
- Issue list with: ID, Category, Severity, Target Text Excerpt, Explanation,
  Suggested Fix (optional)
- Summary grouped by severity (Critical first, then Major, then Minor)
```

### Instruction Builder pattern

```
## Role
You are a locale-aware content strategist. You produce structured writing
instructions -- NOT the content itself.

## Input
- Content brief (what to write about, key messages, target audience)
- Locale guideline (from knowledge: tone, formality, CTA patterns, etc.)
- Glossary (from knowledge: approved terminology)

## Output
Structured writing guidance:
- Tone and register for this specific piece
- Approved terminology to use (and terms to avoid)
- CTA pattern to follow
- Subject line pattern to follow
- Opening and closing patterns
- Formatting constraints

The content generator receives ONLY these instructions plus the brief.
All locale decisions are made here, not in the generator.
```

## Related Files

- `build-kit/agents/knowledge/locale-knowledge-architecture.md` -- Glossary design, locale guideline structure, LQA evaluation framework, language region coverage
- `build-kit/templates/locale-guide.template.md` -- Fill-in-the-blanks template for creating per-locale guidelines
- `playbooks/outreach-agent-patterns.md` -- Outbound messaging patterns that localization augments
- `playbooks/content-marketing-seo.md` -- Content pipeline patterns (localization can be added as a downstream stage)
- `.claude/rules/BUILD_PRACTICES.md` -- Workforce patterns (batch vs fan-out, autopilot rules, dead-end status clarity)
- `build-kit/agents/knowledge/knowledge-tables.md` -- Knowledge table API reference for glossary and guideline tables
