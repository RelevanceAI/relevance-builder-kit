# Form Testing Patterns

Automated, continuous validation that web lead-capture forms successfully deliver leads into the downstream CRM or data system. Use when manual sampling of form submissions leaves broken forms undetected for days and silently drops revenue.

## When to Use

- Your team captures leads via multiple website forms (enquiry, demo request, application, contact)
- Current validation is manual sampling on a weekly or ad-hoc cadence, with no automated alerting
- A broken form would be noticed late enough that lost leads are a meaningful cost
- The forms flow into a system of record that can be programmatically checked (CRM, webhook, data lake)
- Multiple form technologies are already in use or planned (e.g. server-rendered Gravity Forms today, HubSpot or React forms later)

## When Not to Use

- Only one form exists and it is already end-to-end monitored by the site's uptime tool
- Forms are gated behind authenticated sessions you cannot script or bypass (requires a separate strategy -- session profiles or an internal test mode)
- Every form of interest is iframe-embedded (current AI Browser limitation; see "Failure Modes" below)
- Volume is low enough that manual monthly spot checks are cheaper than the build

## Default Architecture

Single agent with a per-form strategy registry. The agent reads the registry, routes each form to the correct testing approach, submits a dummy lead, verifies arrival in the system of record, and logs the result.

```
Form Registry (knowledge table)
       |
       v
 [Test Orchestrator Agent]
       |
       +-- HTTP POST tool ---------> server-rendered forms (Level 1)
       +-- AI Browser tool set ----> JS-rendered / vision-driven forms (Level 3)
       +-- API-level tool ---------> backend integration checks (Level 4)
       |
       v
   CRM / system of record check
       |
       v
 Run log (knowledge table) -> alerting
```

**Variations:**
- **Variation A -- single-agent default.** 2-15 forms, three or fewer strategies, alerting is inline. One agent, 3-5 tools. This is the right starting point.
- **Variation B -- workforce split.** Graduate when form count exceeds 10 OR reporting cadence diverges from testing cadence OR cleanup becomes complex enough to need its own agent. Split into Form Filler -> Validator+Cleaner -> Reporter. Same tools, wrapped in three agents.
- **Variation C -- registry-driven hybrid (recommended for mixed form stacks).** Add a `strategy` column to the form registry so each row routes itself. Stable Gravity Forms via HTTP POST (cheap, fast, deterministic). Anything that cannot be tested at the HTTP layer via AI Browser. Non-technical users can change routing without a rebuild.

## Key Design Decisions

- **Match approach to form technology, not to "what feels impressive".** HTTP POST is not a shortcut; for server-rendered forms it is the correct approach. It tests the actual data path (form -> webhook -> system of record) without coupling to UI implementation details. AI Browser is the correct approach for JS-rendered or vision-driven forms -- not a default.
- **Route per form, not per organisation.** A single organisation often has forms across multiple technologies. A registry with a `strategy` column lets each form use the right approach and lets ops swap routing without re-architecture.
- **Dummy data hygiene is the highest-stakes risk, not form submission.** Synthetic leads triggering marketing automation or sales follow-up is the worst failure mode. Prefix every dummy record (e.g. `TEST-`, `@test.<customer>.com`) AND agree a cleanup flow (Power Automate, Zapier, or a scheduled cleanup job) before going live.
- **Form structure drift detection is the most valuable output.** Forms rarely go fully down; they drift -- a renamed field, a new required field, a changed dropdown option. A field-structure comparison on every run catches drift before it causes lead loss. Prioritise this over "did submission succeed" checks.
- **Async verification windows are heuristics, not contracts.** Webhook processing time spikes under load. Distinguish "not yet arrived" from "definitely not arriving" in your validator logic, with explicit retry budgets and escalation thresholds.

## The Four Levels of Form Automation

Choose per form based on the form's technology, not on what feels most impressive. Most production form-testing systems use at least two levels.

### Level 1: Direct HTTP POST

Read the page HTML, extract form tokens and field names, POST the data directly to the form's submission endpoint. No browser involved.

```
Agent -> HTTP GET page -> parse HTML for tokens/fields
      -> HTTP POST form data
      -> check system of record -> done
```

**Works for:** Server-rendered forms where the submission endpoint and required tokens are visible in the HTML source. Gravity Forms (WordPress) is the textbook case -- action URL, nonce tokens, and field IDs are all in raw HTML.

**Does not work for:** JavaScript-rendered forms (React, Angular, Vue SPAs), multi-step wizards with client-side state, CAPTCHA-protected forms, forms that validate via JavaScript before enabling submit.

**Why it is the right default when it applies:** Around 2 seconds per submission, near-zero cost (no LLM calls), deterministic, no browser infrastructure. Every additional layer is more complexity that can break.

### Level 2: Headless Browser with Scripted Selectors

Launch a real browser in headless mode. Navigate to the URL, find fields by CSS selector, type values, click submit, wait for confirmation.

```
Agent -> launch Chromium -> navigate(url)
      -> fill('#email', 'test@example.com')
      -> click('#submit')
      -> waitForSelector('.confirmation') -> done
```

**Works for:** JavaScript-rendered forms, SPAs, multi-step wizards, forms with client-side validation.

**Does not work for:** CAPTCHA (without a solving service), bot-fingerprinting that detects headless browsers.

**Tradeoff:** Realistic simulation, but the test is now coupled to CSS selectors. When a developer renames `.form-submit` to `.btn-primary`, the test breaks. Infrastructure cost: a browser host (Browserless, BrowserBase, Playwright in a Python step, or a self-hosted runner).

**When to pick Level 2 over Level 3:** The form layout is stable, you already have Playwright / Puppeteer scripts in CI, and determinism matters more than resilience.

### Level 3: AI-Driven Browser Automation (AI Browser / Airtop)

Instead of scripted selectors, an AI model looks at the page and decides what to do. Element targeting is natural language ("the email field", "the Submit button"). On Relevance AI this is the AI Browser integration (powered by Airtop). Full technical reference: `build-kit/tools/ai-browser.md`.

```
Agent -> launch browser -> screenshot page
      -> LLM: "fill in the enquiry form with test data"
      -> LLM outputs click/type actions
      -> execute actions -> repeat until done
```

**Works for:** Everything Level 2 handles, plus resilience to UI changes -- a form redesign does not break the test because vision still sees "the email field" even if the developer renames every CSS class.

**Does not work for:** Iframe-embedded content (confirmed Airtop limitation, on roadmap). Check every form's embed method before scoping -- a brand-name form (HubSpot, Calendly, Typeform) is not automatically iframe-embedded. Check the actual implementation.

**Tradeoff:** Slowest and most expensive per run. Each interaction loop costs an LLM call. A 5-field form may take 8-12 calls. Minor non-determinism -- vision occasionally targets the wrong element, OCR can misread clipped text.

**Where Level 3 shines:** When forms change frequently, when many different form types are in scope that you cannot predict in advance, or when the actual UX (not just the data flow) needs testing.

### Level 4: API-Level Testing (skip the UI entirely)

If the form ultimately calls a backend API to create the lead, hit the API directly. No form, no browser, no HTML parsing.

**Works for:** Testing the data pipeline (form -> backend -> system of record) without testing the form UI itself. Excellent complement to Level 1-3, not a replacement.

**Does not test:** Whether the form renders correctly, whether fields are visible to users, whether JavaScript validation works.

**Typical use:** "Is the CRM reachable and accepting leads right now?" as a baseline health check, run alongside per-form tests that verify "do real users get through?"

## Per-Form Strategy Matrix

Use this as a first-pass routing decision. Encode the result in the registry's `strategy` column.

| Form characteristic | First choice | Fallback |
|---------------------|--------------|----------|
| Server-rendered, tokens extractable (Gravity Forms, most WordPress plugins) | Level 1 | Level 3 if structure is unstable |
| JS-rendered, DOM-embedded (HubSpot JS embed, React app) | Level 3 | Level 2 if selectors are stable |
| Iframe-embedded (some HubSpot, Calendly, Typeform setups) | Custom Puppeteer / Playwright (Level 2) | Level 4 (API) if direct endpoint is available |
| CAPTCHA-protected | Level 4 (API) | Level 2 with CAPTCHA-solving service (requires security signoff) |
| Chatbot widget | Level 4 (chatbot API) | Not Level 3 -- widgets are JS-heavy iframes and current browser automation cannot reach them reliably |
| Authenticated-only form | Level 2 or 3 with a saved session profile | Internal test-mode bypass URL provided by the dev team |

## Tools Required

| Tool | Purpose | Notes |
|------|---------|-------|
| HTTP POST submitter | Level 1 submissions | Custom tool. Fetches the page, extracts tokens, POSTs. Verify tokens per run (they can expire / rotate) |
| AI Browser tool set | Level 3 submissions | Either platform `browser_*` steps (convenient, limited) or a bespoke Airtop Direct API tool suite (full control, BYO key). See `build-kit/tools/ai-browser.md` for the full menu and tradeoffs |
| System-of-record check | Validator stage | Query the CRM / data lake for the dummy record. Use distinct search keys (unique email, unique company name) to avoid false positives from real users |
| Run logger | Record every test | Writes a row to the run-log knowledge table: timestamp, form, strategy, submission status, verification status, notes |
| Cleanup tool (or external flow) | Dummy data hygiene | Either a tool the agent calls post-verification, or an external workflow (Power Automate, Zapier) that runs on a schedule and purges flagged test records |

## Knowledge Tables

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `form_registry` | Source of truth for every form under test | `form_id`, `url`, `strategy` (http_post / ai_browser / api / playwright), `expected_fields` (JSON), `system_of_record_entity`, `active` (bool), `notes` |
| `run_log` | One row per test run per form | `run_id`, `form_id`, `strategy_used`, `submission_status`, `verification_status`, `structure_drift_detected` (bool), `drift_notes`, `run_duration_ms`, `timestamp` |

## Implementation Checklist

1. **Inventory the forms.** List every lead-capture form across your web properties. For each, note: URL, technology (server-rendered / JS-rendered / iframe / chatbot), owner, expected volume, downstream system.
2. **Classify each form** against the per-form strategy matrix above. Flag any iframe-embedded forms early -- they require a different approach.
3. **Build the Level 1 tool first.** HTTP POST against the first server-rendered form. Single-form, manual trigger. Validate structure comparison detects a deliberately-broken field.
4. **Build the system-of-record check.** Query CRM by unique dummy key. Handle the async delay explicitly (retry budget, explicit "not yet" status distinct from "definitely not arriving").
5. **Build the registry and logger.** Now the agent is registry-driven rather than hardcoded to one form.
6. **Add Level 3 only when a non-Level-1 form appears.** Do not pre-build AI Browser tools for hypothetical future forms.
7. **Agree the cleanup flow with stakeholders BEFORE going live.** If synthetic leads hit real downstream automations, the damage is immediate and visible.
8. **Schedule the agent** (daily is typical). Add alerting on: submission failure, verification failure, structure drift.
9. **Graduate to workforce** only when one of the triggers fires (10+ forms, diverging cadences, complex cleanup). Not before.

## Failure Modes and Gotchas

- **Synthetic leads triggering real marketing or sales automation.** The worst failure mode. A BDR calling `TEST-John Smith` or a nurture sequence firing on `test@example.com` is immediately visible to real users. Prevent with: (1) a mandatory `TEST-` prefix on names, (2) a dedicated test email domain, (3) an agreed cleanup flow that runs on its own schedule, (4) a pre-production dry run that produces zero downstream side effects.
- **Structure drift going undetected.** Forms rarely go fully down; they drift. A renamed field, an added required field, a changed dropdown. If the agent only checks "did submission succeed", it will pass while lead quality silently degrades. The field-structure comparison on every run is the most valuable single output. Track drift as a first-class status, not an exception.
- **Async verification window too short.** Webhook processing spikes to minutes under load. A hardcoded 45-second wait will produce false-negative verification failures. Distinguish "not yet arrived" (retry with exponential backoff) from "definitely not arriving" (alert). Set an upper bound (e.g. 10 minutes) at which the agent escalates rather than endlessly retrying.
- **CAPTCHA is a policy decision, not a technical one.** CAPTCHA-solving services exist (2Captcha, Anti-Captcha, etc.) but having a test agent bypass your own anti-bot protection is a conversation with security, not a technical choice. Cleaner alternative: ask the dev team for a test-mode bypass (a hidden URL parameter that disables CAPTCHA for known test IPs or headers).
- **Iframe-embedded forms cannot be tested with AI Browser.** Confirmed Airtop limitation (on roadmap, not yet shipped). A form being "a HubSpot form" does not automatically mean iframe-embedded -- HubSpot offers a JS API embed (DOM-level, AI Browser handles this fine) and an iframe embed (AI Browser cannot reach it). Check the actual implementation per form. Fallback: Level 2 (custom Playwright) or Level 4 (API-level if an endpoint exists).
- **HTTP POST tokens can rotate or expire mid-session.** Some server-rendered form frameworks rotate nonces after N uses or after a time window. Always fetch the page fresh per test run and extract tokens at the moment of submission. Never cache tokens across runs.
- **Chatbot testing is API-level, not UI-level.** Chatbot widgets are JS-heavy iframes and current browser automation cannot reach them reliably. If chatbots are in scope, plan for API-level testing (Level 4) from day one.
- **Dev environments vs production.** The structure of a form can differ between staging and production in subtle ways (field ordering, validation rules). Test against the actual production form; a passing staging test does not guarantee production.
- **Cross-region variants.** Customers running AU and NZ (or US and EU) sites often have different form instances even when the UX is identical. Treat each region as a separate registry entry unless you have confirmed same-endpoint reuse.

## Related Files

- `build-kit/tools/ai-browser.md` -- AI Browser / Airtop full technical reference (platform steps, Direct API, gotchas, limitations)
- `build-kit/tools/platform-tool-gotchas.md` -- General tool gotchas (Cloudflare TLS fingerprinting, JS vs Python sandbox auth)
- `playbooks/use-cases/multi-agent-orchestration.md` -- Graduation path when the single-agent default outgrows itself
- `.claude/rules/BUILD_PRACTICES.md` -- Unit of Action, audit patterns, state_mapping
