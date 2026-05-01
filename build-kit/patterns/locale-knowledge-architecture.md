# Locale Knowledge Architecture

How to build and maintain the locale-specific knowledge that multilingual agents need to generate culturally fluent content. Covers glossary design, locale guideline structure, LQA evaluation framework, and knowledge table schemas.

## What Locale Knowledge Is

A translation API tells the agent what languages are possible. Locale knowledge tells the agent what is actually correct for this brand, this market, this tone, and this audience.

Without it, agents produce content that reads as translated rather than natively written. They default to generic registers, miss cultural conventions, and use inconsistent terminology across messages. The result looks "directionally right" but not professionally publishable.

**The distinction matters:** Google Translate can convert English to German. Locale knowledge ensures the German output uses "Sie" for enterprise prospects, follows DD.MM.YYYY date formatting, avoids Denglisch buzzwords, and signs off with "Beste Gruesse" rather than "Cheers."

## Knowledge Categories

| Category | What to Capture | Why It Matters |
|----------|----------------|----------------|
| Glossary / Term Bank | Source terms, approved translations, do-not-translate terms, context notes | Prevents inconsistent terminology. Brand names, product features, and technical terms must be rendered identically every time. |
| Locale Guidelines | Tone, formality, subject line conventions, CTA patterns, orthography per language and region | Languages within the same family differ significantly. LATAM Spanish vs Spain Spanish, Brazilian Portuguese vs European Portuguese. Guidelines encode these differences. |
| LQA Evaluation Rubric | Evaluation dimensions, severity scales, pass/fail thresholds per language | Quality assurance agents need a structured framework to evaluate output. Without it, QA is subjective and inconsistent. |
| Cultural Constraints | Topics to avoid, humour guidelines, business etiquette, visual/imagery notes | What works in one culture offends in another. "Book a demo" is standard in US English but overly aggressive in Japanese business communication. |
| Translation Memory (optional) | Previously approved translations paired with source text | Reduces cost and improves consistency for repeated content patterns (email signatures, standard disclaimers, recurring CTAs). |

## Glossary Table Design

The glossary is the most critical knowledge table. Every localization build starts here.

### Schema

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `source_term` | string | English term | "Data Streaming" |
| `target_term` | string | Approved translation | "Daten-Streaming" |
| `language_iso` | string | ISO 639-1 + region | "de-DE" |
| `do_not_translate` | boolean | Keep in English | true for product names and technical terms |
| `context` | string | When this translation applies | "Use in technical contexts. For marketing copy, use 'Echtzeit-Datenverarbeitung'" |
| `category` | string | Term type | "product", "technical", "brand", "industry" |
| `approved_by` | string | Native speaker or team | "DACH localization team" |
| `date_approved` | date | Last verified | "2026-03-15" |

### Loading Strategy

- **Usage type:** `"tool"` (explicit invocation), not `"instructions"` (auto-inject). Glossaries can be large (500+ terms). Auto-injection wastes tokens when the agent does not need terminology lookup.
- **Retrieval:** Keyword match on `language_iso` + vector search on `source_term` for the terms appearing in the content being generated.
- **Shared tool:** Build one "Extract Language Glossary" tool and share it across all agents in the workforce. Avoids glossary drift between agents.

### Governance

- **Who approves new terms:** A native speaker or the customer's localization/branding team. Tip: most sales teams do not know their company has a localization team. Have them search Slack for "localization team", "branding team", or "language team", or ask in marketing.
- **Existing glossaries:** Many companies already maintain glossaries. Check the customer's website for a glossary page (e.g., `company.com/glossary` or `company.com/{lang}/glossary`). These are ready-made seed data.
- **Conflict resolution:** When the same term has multiple approved translations in different contexts, the `context` field disambiguates. The agent should prefer the context-matched translation.

## Locale Guideline Structure

Every locale guideline covers 10 sections. These encode how a native speaker in that market writes professional communications. Use `build-kit/templates/locale-guide.template.md` as the fill-in-the-blanks starting point.

| # | Section | What It Encodes | Common Pitfall Without It |
|---|---------|----------------|---------------------------|
| 1 | Tone and Voice | Brand voice adapted for locale | Agent uses generic tone that feels like a translation |
| 2 | Formality Level | Pronoun register (du/Sie, tu/usted, tu/vous) and switching rules | Agent mixes registers mid-email or defaults to informal |
| 3 | Subject Lines | Length, patterns, locale-specific keywords | Subject lines that read as English translated word-for-word |
| 4 | Opening Patterns | Culturally appropriate openers with signal-based templates | "Hope this email finds you well" translated literally |
| 5 | CTA Patterns | Locale-appropriate calls to action | "Book a demo" in cultures where this is too aggressive |
| 6 | Closing Patterns | Sign-offs matched to formality level | Using English closings or informal abbreviations |
| 7 | Vocabulary Preferences | Approved word choices, terms to avoid | Agent invents translations or uses loanwords unnecessarily |
| 8 | Orthography Conventions | Date, time, number, currency, punctuation formatting | "03/15/2026" in a DD.MM.YYYY locale |
| 9 | Cultural Constraints | Topics, humour, imagery, business etiquette | Content that is technically correct but culturally tone-deaf |
| 10 | Formatting Rules | Paragraph length, line breaks, bullet usage | Dense prose in cultures that prefer short paragraphs |

### Generating Locale Guidelines

AI can generate initial locale guidelines from:
- Best-in-class emails the customer already sends in the target language
- Interviews with local sales reps (record and transcribe, then extract patterns)
- Existing brand style guides adapted for the specific locale

The output should always be reviewed by a native speaker before use.

### Storage

Store locale guidelines as knowledge table rows (one row per locale) or as standalone markdown files in the customer's agent docs. Either way, reference them in agent knowledge sets with `usage_type: "tool"` so they are retrieved by language ISO code at runtime.

## LQA Evaluation Framework

The Locale Quality Assurance agent uses an 8-dimension evaluation framework to assess generated content. Each dimension has a severity scale and specific checks.

### Evaluation Dimensions

Evaluate in this order. For each dimension, check every segment of the target text before moving to the next.

#### 1. Accuracy

The content faithfully conveys the meaning of the source instructions -- no more, no less.

- Content added, omitted, or distorted relative to source instructions
- Meaning shifts or mistranslations, including subtle semantic drift
- Over-transcreation (target text goes beyond intended message)
- Under-transcreation (target text omits required content or nuance)
- Untranslated segments not explicitly permitted by the glossary

#### 2. Fluency

The content reads naturally, as if written by a native speaker for another native speaker.

- Grammar errors (agreement, verb tense, case)
- Awkward or unnatural syntax for the target language
- Spelling and punctuation errors
- Incorrect register or tone relative to the style guide
- Inconsistent language use across the text

#### 3. Terminology

Key terms are rendered correctly and consistently per the approved glossary.

- Terms that deviate from the glossary without justification
- Inconsistent rendering of the same term across the text
- Incorrect translation of technical, product, or brand terms

#### 4. Style

The content adheres to tone, voice, and stylistic conventions in the locale guideline.

- Tone or formality that contradicts the style guide
- Unidiomatic phrasing reflecting source-language influence
- Inconsistent voice across the text

#### 5. Locale Conventions

Locale-specific formatting is correct.

- Dates, times, numbers, currencies, measurements
- Addresses, telephone numbers, abbreviations

#### 6. Cultural and Contextual Appropriateness

The content is appropriate and clear for the target audience and culture.

- Culturally misleading or inappropriate elements
- References that are confusing or meaningless in the target culture

#### 7. Design and Layout (if applicable)

Content fits any design constraints provided (character limits, line length, template slots).

#### 8. Other / General Issues

Concrete, localized, actionable issues not covered above.

### Severity Scale

Every issue must be assigned exactly one severity level:

| Severity | Definition | Impact |
|----------|-----------|--------|
| **Critical** | Alters meaning, causes legal/functional risk, or misleads readers | Content must not ship. Requires immediate correction. |
| **Major** | Impacts clarity, usability, terminology consistency, or brand voice | Content needs revision before shipping. |
| **Minor** | Stylistic, punctuation, or low-impact issues | Content can ship but should be corrected in next iteration. |

### Pass/Fail Thresholds

| Rating | Condition | Action |
|--------|-----------|--------|
| Excellent | No issues found | Pass. Ship as-is. |
| Good | Minor issues only | Pass. Content should be checked but can ship. |
| Fair | Major issues present | Fail. Requires revision before shipping. Route to Post-Editing Agent. |
| Poor | Critical issues present | Fail. Requires full revision. Route to Post-Editing Agent with priority flag. |

### Calibration Per Language

LQA thresholds may need adjustment per language. Languages with less LLM training data (Thai, Vietnamese, Indonesian) typically produce lower baseline fluency scores than high-resource languages (Spanish, French, German). Set initial thresholds conservatively and calibrate based on native speaker review of the first 10-20 outputs.

## Language Region Coverage

Languages documented in production builds, organized by sales region:

### LATAM

| Language | ISO Code | Key Differentiators |
|----------|----------|-------------------|
| Spanish (Latin America) | es-419 | "tu" pronoun, less formal register than es-ES. Avoid Spain-specific idioms. Regional variation across countries. |
| Portuguese (Brazil) | pt-BR | "voce" pronoun, significantly different from pt-PT in vocabulary, spelling, and tone. Dominant Portuguese variant by volume. |
| Portuguese (Portugal) | pt-PT | More formal register, different vocabulary choices. Smaller market but distinct requirements. |

### EMEA

| Language | ISO Code | Key Differentiators |
|----------|----------|-------------------|
| English (UK) | en-GB | Spelling (colour, organisation), date format (DD/MM/YYYY), understated tone, no Oxford comma by default. |
| French | fr-FR | Formal "vous" default in business. Gendered language requires careful handling. Space before colons and semicolons. |
| German | de-DE | "Sie" formal default. Compound nouns. DD.MM.YYYY dates. 24-hour time. Period for thousands (1.234). Capitalize formal pronouns. |
| Italian | it-IT | "Lei" formal default. Gendered language. Rich verb conjugation affects translation complexity. |
| Spanish (Spain) | es-ES | "usted" formal default (more formal than LATAM). Distinct vocabulary from es-419. |
| Dutch | nl-NL | "u" formal default. Relatively close to English but false friends are common. |
| Danish | da-DK | "De" formal (rare in practice -- Danish business culture is informal). Short, direct sentences preferred. |

### APAC

| Language | ISO Code | Key Differentiators |
|----------|----------|-------------------|
| Japanese | ja-JP | Keigo (honorific system) with multiple formality levels. Family name first. No spaces between words. Character limits differ from byte limits. |
| Korean | ko-KR | Formal/informal speech levels (6+). Family name first. Honorific suffixes required in business contexts. |
| Chinese (Simplified) | zh-CN | Mainland China. No spaces between characters. Formal register for business. Specific number formatting. |
| Chinese (Traditional) | zh-TW | Taiwan. Different character set from zh-CN. Some vocabulary differences beyond just character variants. |
| Thai | th-TH | No spaces between words. Complex honorific system. Lower LLM training data -- expect lower baseline fluency. |
| Vietnamese | vi-VN | Latin script with diacritics. Pronoun system encodes social relationships. Diacritics are mandatory (not decorative). |
| Indonesian | id-ID | Relatively simple grammar (no gendered nouns, no conjugation). "Bapak/Ibu" formal address. Growing market. |

## Knowledge Table Architecture

For a production localization build, set up these knowledge tables:

| Table | Usage Type | Content | Key Fields |
|-------|-----------|---------|------------|
| Glossary | `"tool"` | Term bank across all languages | source_term, target_term, language_iso, do_not_translate, context, approved_by |
| Locale Guidelines | `"tool"` | One row per locale with full guideline text | language_iso, region, guideline_content, last_verified |
| Translation Memory | `"tool"` (optional) | Previously approved source-target pairs | source_text, target_text, language_iso, content_type, date_approved |

All three tables should be shared across agents in the workforce to prevent drift. Use shared tools ("Extract Language Glossary", "Search Language Guidelines") rather than giving each agent its own copy.

## Related Files

- `playbooks/use-cases/localisation-agent-patterns.md` -- Use-case playbook for building localization workforces
- `build-kit/templates/locale-guide.template.md` -- Fill-in-the-blanks template for creating per-locale guidelines
- `build-kit/patterns/crm-knowledge-architecture.md` -- Peer pattern: CRM knowledge architecture (same structural approach, different domain)
- `build-kit/tools/knowledge-tables.md` -- Knowledge table API reference (CRUD operations, filters, Python helpers)
- `playbooks/use-cases/outreach-agent-patterns.md` -- Outreach patterns that localization augments
