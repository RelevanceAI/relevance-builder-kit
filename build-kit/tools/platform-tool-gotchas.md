# Platform Tool Gotchas

Non-obvious behaviors for platform-provided transformations and tools. These are things you only learn by getting burned -- not documented in the standard tool descriptions.

---

## Crustdata - LinkedIn People Search

Transformation: `linkedin_people_search_crustdata`

### search_type matters more than filters

The `search_type` parameter controls whether Crustdata searches its cached index or does a live LinkedIn query:

- **"Cost optimized"** -- searches cached/indexed data. Cheaper but some companies simply aren't in the index. If a company isn't indexed, no amount of filter tweaking will return results.
- **"Performance optimized"** -- real-time LinkedIn search. 10-20x more credits but finds profiles that Cost mode misses entirely.

### Escalation pattern

1. Start with "Cost optimized", LIMIT=1, company only (no filters) -- validates whether the company is indexed
2. If zero results: switch ALL remaining searches to "Performance optimized" -- the company isn't cached
3. If Performance optimized also returns zero: the company genuinely has minimal LinkedIn presence. Skip to Google fallback

**Anti-pattern:** Retrying "Cost optimized" with different SENIORITY_LEVEL / FUNCTION / REGION filters when the validation search returned zero. The company isn't in the index -- no filter combination will fix that.

### Other notes
- FUNCTION values must be from a fixed allowed list (e.g., "Information Technology", "Engineering", "Operations"). Custom strings like "General Management" will silently return no results
- SENIORITY_LEVEL is for broad categories ("CXO", "Vice President", "Director"), not job titles. Put specific titles like "Head of IT" in CURRENT_TITLE instead
- Failed searches (0 results) consume minimal credits. Don't be afraid to do a cheap validation search first

---

## Google Search, Scrape and Summarise

### LinkedIn profile discovery is unreliable

`site:linkedin.com/in` queries are increasingly unreliable for finding individual LinkedIn profiles. LinkedIn restricts Google from indexing many profiles. Do not rely on this as a primary contact-finding method -- use Crustdata first, Google as fallback only.

### Cloudflare-protected sites return empty

Sites behind Cloudflare security challenges return empty results (not errors). The scraper cannot bypass CAPTCHA or JS challenges. This commonly affects small company websites.

### Exclude data provider sites

Always add `-site:zoominfo.com -site:crunchbase.com -site:apollo.io` when searching for people. These sites are paywalled and will return results you can't actually read, wasting a scrape step.

---

## Unipile - LinkedIn Actions

Transformation: `linkedin_action`

### `_oneof_type_` is mandatory

The `action` object MUST use the `_oneof_type_` discriminator pattern. The `type`/`provider_id` format (e.g., `"type": "SEND_MESSAGE", "provider_id": "LINKEDIN"`) is undocumented and will fail with `must NOT have additional properties` validation errors. See `build-kit/tools/tool-transformations.md` for all valid `_oneof_type_` values and required params.

### Capabilities
- Send messages, start new chats, send connection requests
- Get user profiles (by LinkedIn URL)
- Get all chats, get chat messages
- Send comments, create posts, manage invitations

### Send Invitation: use username, not URL

The `Send Invitation` action passes the `identifier` directly to Unipile with no preprocessing. Unlike `Get User Profile` (which has a built-in slug extraction step), you must pass the **LinkedIn username** (e.g. `johndoe`), not the full URL (`https://linkedin.com/in/johndoe`). Full URLs fail with `"Error calling LinkedIn API. undefined"`.

### Send Invitation: no-note workaround

Free LinkedIn accounts only allow 5 connection requests with a note per month (150 without). The `linkedin_action` transformation requires `message` as a property at the platform level. To send without a note:

- Pass a **single space** (`" "`) as the message
- Empty string `""`, period `"."`, and omitting the field entirely all fail
- A feature request has been submitted to make `message` non-required on the transformation

See `build-kit/integrations/linkedin.md` for full account limit details.

### Does NOT support
- **People search** -- cannot search LinkedIn for people at a company. Use Crustdata for that
- **Company search** -- cannot search for companies

### Trigger behavior: is_outreach_reply_only

- `is_outreach_reply_only: true` only triggers on replies to messages sent via `Start New Chat` / `Send Message` (API-sent outreach)
- Connection request acceptance notes are NOT classified as outreach -- if a contact accepts and replies to the connection note, the trigger won't fire
- Workaround: after connection acceptance, send a first DM via `Start New Chat` to establish an outreach-classified message, then the reply trigger works for all subsequent messages

---

## Perplexity Web Search

### Credit consumption on empty results

Perplexity charges credits even when results are empty. Unlike Crustdata (where zero-result searches are cheap), Perplexity can burn 2-5 credits on a search that returns nothing useful.

### Best for

- Recent news and announcements (last 30 days)
- Company-level research and market context
- Technology stack and product information

### Not good for

- Finding specific LinkedIn profile URLs (use Crustdata)
- Finding specific people at companies (use Crustdata)
- Historical data older than ~6 months

---

## Knowledge Table Matching (all tools that query by name)

### Never use exact match on entity names

Agents are inconsistent with how they save company/account names:
- "Kyocera Document Solutions" vs "Kyocera Document Solutions (Kyocera Document Solutions Singapore Pte Ltd)"
- "Snowflake" vs "Snowflake Computing"
- "GEP" vs "GEP Solutions" vs "GEP Worldwide"

Any tool that looks up records by account_name, company_name, or similar must use substring/fuzzy matching. Options:
- API-level: use `filter_type: "ilike"` in knowledge table filters
- Python-level: use `search_name in stored_name or stored_name in search_name` for bidirectional substring match
- Never use `==` for name matching in Python filter steps

---

## Brand Kit API

### PUT wipes array fields you omit

The `/branding_kits/{id}` PUT endpoint has destructive semantics for array fields. If you PUT with only `{ "brand_tone": "new tone" }`, the `colors`, `logos`, and `inspiration_photos` arrays are all wiped to `[]`. Scalar fields (name, tone, voice, font objects) survive omission.

**Always fetch the full kit first, merge your changes, then PUT the complete object.**

### GET vs PUT endpoint naming mismatch

- GET a single kit: `/branding_kit/{id}` (singular)
- PUT/DELETE a kit: `/branding_kits/{id}` (plural)

Using the wrong form returns 404.

### AI brand kit generator needs public image URLs

`POST /branding_kits/generate` accepts 1-10 image URLs. The images must be publicly accessible (no auth, no CORS blocks). Relevance `userdata-*.stack.tryrelevance.com` URLs from Chat file uploads work well.

---

## Slide Builder PPTX Export

### PPTX export is client-side, not server-side

The `/slide_show/{id}/export` API only supports `pdf_standard`, `pdf_images`, and `images`. PPTX generation happens entirely in the browser using `pptxgenjs` (DOM extraction to PPT shape primitives). The UI labels it "AI conversion (may lose formatting)".

### Top 3 formatting issues (confirmed by customers)

1. **Icons overlap text** -- the #1 reported issue. CSS-positioned elements that looked fine in HTML collide in PPTX. Always leave generous gaps (20px+) between icons/images and text.
2. **Font sizes shift** -- especially when the PPTX is re-uploaded to Google Slides (a second conversion layer).
3. **Element movement** -- CSS Grid/Flexbox layouts convert to absolute positioning. Relative sizing becomes fixed, causing drift.

### Google Fonts are embedded (safe to use)

The exporter fetches Google Fonts at export time and embeds them directly into the `.pptx` ZIP. Any Google Font is safe. Non-Google fonts risk fallback substitution if the fetch fails (network/CORS).

### What breaks in PPTX

| CSS feature | PPTX behavior |
|-------------|---------------|
| Animations/transitions | Stripped entirely (`animation-duration: 0s`) |
| Grid/Flexbox layout | Converted to absolute positioning (shifts) |
| `backdrop-filter`, blur | Rasterized to flat image |
| `box-shadow`, `text-shadow` | Imperfect mapping (PPT shadow < CSS) |
| `border-radius` | Lost on non-image elements |
| Nested tables | Converter skips nested cells |
| Emoji in text | Rasterized to flat image (not editable) |
| Videos | Only poster/thumbnail captured |
| Complex SVGs | Rasterized or fail to embed |
| Non-Google fonts | May fall back to system fonts |

### Encode PPT-safe rules in brand kit `slide_instructions`

The `slide_instructions` field in a brand kit tells the Slide Builder how to generate slides. Encoding PPT-safe rules here (no flexbox, no overlapping elements, Google Fonts only, etc.) ensures every deck generated with that brand kit exports cleanly -- without requiring the prompter to remember the rules.

---

## Cloudflare-Protected Sites: Python `requests` vs Node `fetch`

Python `requests` in the Modal-hosted `python_code_transformation` sandbox is **TLS-fingerprint-blocked** by Cloudflare Bot Management on some sites, while Node `fetch` in `js_code_transformation` passes cleanly against the same URL.

### Symptoms

- Python `requests.get()` returns 503, OR 200 with an empty body (CF challenge interstitial that has no usable HTML / XML / `<loc>` tags)
- Realistic Chrome UA + `Accept` / `Accept-Language` / `Sec-Fetch-*` headers don't help -- CF is inspecting the TLS ClientHello, not HTTP headers
- The same URL fetched from a JS step in the same Relevance project returns 200 with the expected body
- Crawl silently returns `items: []` with **no errors raised** -- the failure is invisible unless you surface it explicitly

### Detection heuristic

When a Python fetch step silently returns empty results (zero items, zero errors) against a domain behind Cloudflare, reproduce the same fetch from a throwaway `js_code_transformation` tool. If JS succeeds, the problem is TLS fingerprinting, not UA / URL / auth.

### Fix

Rewrite the fetch-heavy tool in JS. Consequences:

- The JS sandbox has no `authorization` global -- tools that also write to the Relevance KT need a project secret prefixed `chains_`. See `.claude/rules/PLATFORM_MECHANICS.md` "JS Sandbox Auth".
- `hashlib` is unavailable; use `crypto.subtle.digest('SHA-256', ...)`.
- Always guard the entry point against a missing secret (unresolved templates become the literal string `"undefined"` -- a 401 trap otherwise).

### Defensive code patterns (regardless of runtime)

- **Surface sitemap / external-fetch failures explicitly** -- a `try/except: continue` that silently drops failed fetches will mask this bug for months. Append to an explicit `sitemap_errors` / `fetch_errors` array and return it.
- **Guard stale-cleanup / destructive post-processing** with `if urls_crawled > 0` (or similar). If the fetch stage returns nothing, do NOT run the "mark everything not-seen-this-run as removed" pass -- it will wipe the KT.

**Symptom:** previously-working Python crawl returns zero URLs once Cloudflare rules tighten on the target domain. Rewrite to JS to fix the crawl. Reported runtime savings of roughly 50% as a side effect.

---

## Studio (Tool) Deletion Endpoint

The Relevance API exposes only one working studio-delete path, and it's not the obvious one. The following all return **404**:

- `DELETE /studios/{id}`
- `DELETE /studios/{id}/delete`
- `POST /studios/delete`
- `POST /studios/{id}/delete`

**Working endpoint:** `POST /studios/bulk_delete` with body `{"ids": ["studio_id_1", "studio_id_2", ...]}`. Returns `{}` on success.

Via `relevance_api_request`: `method: "POST"`, `endpoint: "/studios/bulk_delete"`, `body: {"ids": ["..."]}`. Works for single-tool deletion too -- just pass a one-element array.

**Reminder:** never delete Relevance assets without explicit user permission. Hard rule (see root `CLAUDE.md` "Hard Rules").

---

## JS Code Step Variable Shadowing and Built-in Override (state_mapping collisions)

### TL;DR

In a `js_code_transformation` step, **every `state_mapping` key is injected as a `let`/`const`-declared variable in your code's lexical scope**, holding the resolved value. Two distinct failure modes follow:

1. **Hard crash** if your code re-declares a state_mapping key with `const`/`let`/`var` -- error `Identifier 'X' has already been declared`. 100% failure rate, every run.
2. **Silent built-in override** if a state_mapping key is named after a JS runtime built-in (`fetch`, `crypto`, `console`, `setTimeout`, `URL`, `TextEncoder`, ...). The built-in is silently replaced with the resolved value -- subsequent `fetch(url)` calls fail with confusing type errors.

Mechanism, full reserved-name catalogue, escape patterns, and prevention checklist below.

### Reproduction (the original symptom)

```
Code failed to run: Identifier 'prompt' has already been declared
```

```javascript
// state_mapping: { "prompt": "params.prompt" }
// JS code:
const prompt = `{{prompt}}`;     // <- CRASH at parse, before any line runs
const platform = `{{platform}}`;
```

### Mechanism

The `js_code_transformation` runtime is Deno-backed. Before your code runs, the platform synthesises a wrapper around it that **declares each `state_mapping` key as a `let`/`const` binding with the resolved value**. Confirmed by probe matrix:

| Test | Result |
|---|---|
| state_mapping `prompt` + `const prompt = "x"` | Crash `Identifier 'prompt' has already been declared` |
| state_mapping `prompt` + `let prompt = "x"` | Same crash |
| state_mapping `prompt` + `var prompt = "x"` | **Same crash** (proves the injection uses `let`/`const`, not `var` -- only those clash with `var` re-declaration) |
| state_mapping `prompt` + IIFE-wrapped `const prompt = "inner"` | Works -- block scope creates a fresh binding |
| state_mapping `prompt`, JS uses `prompt` directly (no re-declare) | Works -- value is the resolved input string |
| state_mapping value points to non-existent path (e.g. `params.does_not_exist`) | Variable is still injected, value is `undefined` |
| `params_schema` key NOT in state_mapping | NOT injected as a top-level global. Still accessible via `params.<name>`. |

**Key inference:** `state_mapping` is the **sole source** of top-level variable injection in JS steps. `params_schema` declares the public input contract; `state_mapping` declares the internal scope wiring. They are different layers.

### Failure mode 1: hard crash (the original bug)

The `const prompt = '{{prompt}}'` pattern is a natural one -- it captures the resolved template into a named constant for use later in the function. It CRASHES because `prompt` is already a `let`/`const` binding from state_mapping.

**Fix.** Use state_mapping-injected variables directly. They're in scope with the resolved value already:

```javascript
// state_mapping: { "prompt": "params.prompt", "platform": "params.platform" }

// WRONG -- crashes
const prompt = `{{prompt}}`;
const platform = `{{platform}}`;

// CORRECT -- prompt and platform are already declared, just use them
const dims = dimensionMap[platform];
return { full_prompt: `Image: ${prompt} at ${dims.width}x${dims.height}` };
```

### Failure mode 2: silent built-in override

If a state_mapping key is named the same as a JS runtime built-in, the runtime injection **shadows the built-in in the user's scope** with no error. Verified probe:

```javascript
// state_mapping: { "fetch": "params.input_val" }
// caller passes input_val = "shadow_value"
typeof fetch     // "string"  -- NOT "function"
fetch            // "shadow_value"

// Any later fetch(url) call: TypeError, not a function
```

This is **silent**: the tool runs to whatever line tries to use the built-in, then errors on a confusing type mismatch ("fetch is not a function"). No `Identifier already declared` error appears, because the built-ins live on an ambient global object (NOT as `let`/`const` in user scope) -- a `let fetch` declaration just creates a new lexical binding that shadows the global lookup.

**Reserved-name catalogue (runtime globals in the Deno-backed JS sandbox).** Avoid using these as state_mapping keys -- they will silently override the built-in:

| Available built-in | Type | Common use case |
|---|---|---|
| `fetch` | function | HTTP requests |
| `crypto` | object | `crypto.subtle.digest`, `crypto.randomUUID` |
| `console` | object | Logging |
| `setTimeout` / `clearTimeout` / `setInterval` | function | Delays, retries |
| `URL` / `URLSearchParams` | function | URL parsing |
| `TextEncoder` / `TextDecoder` | function | Bytes <-> string |
| `atob` / `btoa` | function | Base64 |
| `performance` | object | Timing |
| `structuredClone` | function | Deep clone |
| `AbortController` | function | Cancellable fetch |
| `queueMicrotask` | function | Task scheduling |

**Not in scope** (won't collide, but useful to know they're missing): `globalThis`, `window`, `self`, `process`, `Deno`, `require`, `module`, `exports`, `__dirname`, `__filename`, `Buffer`, `authorization`, `credentials`, `region`, `project_id`, `api_key`. The Python `authorization` runtime global has NO JS equivalent -- JS tools that need a project API key must source it from a `chains_*` secret. See `.claude/rules/PLATFORM_MECHANICS.md` "JS Sandbox Auth".

### Escape pattern: block scope

If you need a local variable that happens to share a name with a state_mapping key (or with a built-in you also need), wrap the re-declaration in a function or block scope:

```javascript
// state_mapping: { "prompt": "params.prompt" }

// Works -- IIFE scope is fresh, outer `prompt` retains the state_mapping value
const dressed = (() => {
  const prompt = `Reformatted: ${arguments_via_outer_scope}`;
  return prompt;
})();
return { outer: prompt, inner: dressed };
```

In practice this is rarely needed -- renaming the local variable (`const localPrompt = ...`) is cleaner.

### Diagnostic recipe

When a JS step throws `Identifier 'X' has already been declared`:

1. Open the tool's `state_mapping`. Look for `X` as a key.
2. In the JS code, find the offending `const X` / `let X` / `var X`.
3. Either (a) delete the local declaration and use the injected variable directly, or (b) rename the local to something not in state_mapping.

When a JS step crashes mid-run with a built-in type error (`fetch is not a function`, `crypto is undefined`, etc.):

1. Check `state_mapping` for a key matching the built-in name.
2. Rename that state_mapping key (and update its references in the JS code).

### Prevention checklist

Before writing a JS code step:

- [ ] List every key in the tool's `state_mapping`. Treat them as already-declared variables.
- [ ] Do NOT use those names with `const`/`let`/`var` in the JS code.
- [ ] Do NOT add state_mapping keys named after JS built-ins (`fetch`, `crypto`, `console`, `setTimeout`, `URL`, `URLSearchParams`, `TextEncoder`, `TextDecoder`, `atob`, `btoa`, `performance`, `structuredClone`, `AbortController`, `queueMicrotask`).
- [ ] Generic names that are natural for both state_mapping and locals -- `prompt`, `query`, `message`, `input`, `url`, `name`, `result`, `output`, `data` -- pick the layer to use them in and stick to it.

### Companion: Python sandbox has the same family of bugs

Python `python_code_transformation` steps suffer from the analogous shadowing pattern -- `region` and `authorization` are platform-injected globals. A state_mapping key matching either silently overrides the user value (or, in the case of `region`, makes the project's region code show up where the caller's input should be). Rename any colliding state_mapping key (e.g. `region_param`). See `.claude/rules/PLATFORM_MECHANICS.md` "Tool Sandbox Auth (Python vs JS)".

---

## Platform-Wide Limitations (Trigger / Conversation / API)

Cross-cutting platform mechanics that affect any build, regardless of integration:

- **`relevance_list_conversations` returns 0 results** even when conversations exist. Workaround: `relevance_api_request` with `GET /agents/conversations/list?agent_id={id}&page_size=50`. The response nests conversation data under `metadata.conversation`.
- **No user name resolution in conversations.** Conversation records only contain `user_id` (UUID). There is no MCP tool or API endpoint to resolve UUIDs to names / emails. Map manually.
- **Step-level `condition` property is not supported.** Returns 422 on transformation steps. Handle conditional logic inside the step (instruct the LLM to return null, or branch in a downstream JS step).
- **`relevance_api_call` only supports GET / POST / PUT.** PATCH is rejected. Use JS `fetch` or Python `requests` for PATCH calls.
- **Runtime `authorization` token is scoped.** The Python `authorization` keyword provides a runtime API key that may lack permissions for some endpoints (e.g. `/slide_show`). Use project secrets or user API keys for full access.

For inter-step template-injection size limit, see `build-kit/tools/state-mapping.md`.
