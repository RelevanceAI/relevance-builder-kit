# AI Browser -- Technical Reference

> Platform-native browser automation via Airtop cloud infrastructure. Use for form filling, UI testing, and interactive web tasks that HTTP-based scraping cannot handle.

## What It Is

AI Browser is a managed wrapper on top of **Airtop**, a cloud browser infrastructure provider. The backend dependency is `@airtop/sdk` (^0.1.38).

- The browser process runs in **Airtop's cloud**, not on Relevance servers
- Element targeting uses **Airtop's AI vision/NLP engine** (natural language descriptions, not CSS selectors)
- Returns a `live_view_url` so you can watch the session in real time
- Pricing goes through Airtop credit conversion

### Two Integration Layers

| Layer | What it is | API Key | Capabilities |
|-------|-----------|---------|-------------|
| **AI Browser steps** (`browser_*` / `airtop_*`) | Relevance platform tool steps wrapping Airtop | Platform-managed or BYO | 10 basic operations (see below). Limited params exposed |
| **Airtop Direct API** | Call the Airtop REST API directly from JS code steps | BYO Airtop key (project secret) | Full API surface including form-filler automation, file upload, Tab key, structured output, session profiles, full-page screenshots, and more |

The platform steps are convenient but expose a subset of Airtop's capabilities. For advanced use cases (form automation, file uploads, full-page screenshots), call the Airtop API directly from a JS code step using a BYO API key stored as a project secret.

---

## Platform Steps (AI Browser)

### All 10 Steps

| Step | What It Does | Key Params |
|------|-------------|------------|
| `browser_create_window` | Start a session | `url`, `proxy_enabled`, `proxy_country`, `proxy_sticky` |
| `browser_load_url` | Navigate to a URL | `window_id`, `session_id`, `url` |
| `browser_click` | Click an element | `element_description` (natural language), `wait_for_navigation` |
| `browser_type` | Type into a field | `element_description`, `text`, `press_enter_key` |
| `browser_scroll` | Scroll the page | `x`, `y` (coordinate-based) |
| `browser_screenshot_page` | Take a screenshot | Returns `screenshot_url` (temp JPEG, viewport only) |
| `browser_query_page` | Ask AI about the page | `query` string, returns content text |
| `browser_monitor_page` | Wait for a condition | `condition_description`, `timeout_seconds` (default 30s) |
| `browser_download_file` | Download a triggered file | `session_id` only, URL valid 1 hour |
| `browser_close_window` | End session | Terminates Airtop session |

### Element Targeting

All element targeting is **natural language**. You write `"the Submit button"` or `"the dropdown labeled Country"` and Airtop's AI vision locates it. No CSS selectors, no XPath, no DOM traversal.

### Platform Step Limitations

These are limitations of the **Relevance platform steps**, not Airtop itself. The Airtop Direct API has solutions for most of these (see next section).

| Limitation | Platform Step | Airtop API Solution |
|-----------|--------------|-------------------|
| No dropdown/select step | Must use `browser_click` twice | Same (no select endpoint exists in Airtop either) |
| No file upload | Not exposed | `file-input` endpoint exists |
| No Tab key | Only `press_enter_key` exposed | `pressTabKey` param available on type |
| No `clearInputField` | Not exposed | Available on type |
| Viewport screenshots only | No full-page option | `visualAnalysis.scope: "page"` on screenshot endpoint |
| No structured output from query | Text only | `outputSchema` param on page-query |
| No scroll-to-element | Pixel-based only | `scrollToElement` with natural language targeting |
| No hover | Not available | `hover` endpoint exists |
| No session profiles | Not exposed | Profile save/restore available |
| No click types | Single click only | `doubleClick`, `rightClick` available |
| Free plan blocked | Minimum Starter plan | No plan gate with BYO key |

---

## Airtop Direct API -- Full Capabilities

When the platform steps are not enough, call the Airtop REST API directly from a JS code step. Requires a BYO Airtop API key stored as a project secret.

**Base URL:** `https://api.airtop.ai/api/v1`
**Auth:** `Authorization: Bearer {api_key}`

### Form-Filler Automation API

> **Status: PARKED (as of Apr 2026).** Do not use in production. Airtop's form-filler API returns a server-side protobuf enum error (`AUTOMATION_ERROR_CODE_BROWSER_AUTOMATION_FAILED` is not recognised by Airtop's own serialisation layer) when run against dynamically-rendered forms. The operation allocates an `automationId` but then fails internally; `fill-form` calls against that ID time out, the sync `/execute-automation` endpoint returns 404, and the async variant has no working status-lookup endpoint. Documentation gaps confirm this is not production-ready: the user guide page (`docs.airtop.ai/guides/browser-use/automation`) returns 404, the changelog is empty, and error codes are undocumented.
>
> **Workaround:** Use the Type with Tab pattern instead (`pressTabKey: true` on the type endpoint, combined with `clearInputField: true` for retries). Six type calls plus one full-page screenshot is enough to fill and verify a six-field form reliably, including on JS-rendered HubSpot forms where form-filler fails.
>
> **When to revisit:** Around Oct 2026. Signals the feature is ready -- a populated changelog with form-filler entries, a working code example in the Airtop docs, documented error codes, the user guide page existing.

Airtop has a dedicated form-filling subsystem. Instead of calling click/type for each field, you create a reusable form-filler automation and execute it with a single call.

**Endpoints:**

| Endpoint | Method | What It Does |
|----------|--------|-------------|
| `/windows/{windowId}/create-form-filler` | POST | Creates a form-filler for the current page. Returns `automationId` |
| `/windows/{windowId}/fill-form` | POST | Executes a form-filler by `automationId` with a `parameters` object |
| `/automations` | GET | List all saved automations |
| `/automations/{automationId}` | GET | Get automation details (id, domainName, description, template, schema) |
| `/automations/{automationId}` | PATCH | Update automation description |
| `/automations/{automationId}` | DELETE | Delete an automation |

**Pattern:**
1. Navigate to the form page
2. Call `create-form-filler` -- Airtop analyzes the form and creates an automation with a schema
3. Call `fill-form` with the `automationId` and field values as `parameters`
4. The automation handles field targeting, filling, and interaction internally

Automations are **reusable across sessions** and persist via CRUD API. Create once for each form type, reuse indefinitely.

Async variants also exist: `/async/windows/{windowId}/create-form-filler` and `/async/windows/{windowId}/fill-form` (with webhook support).

### Type -- Additional Params

| Param | Type | Description |
|-------|------|-------------|
| `clearInputField` | boolean | Clears the input field before typing. Essential for editing pre-filled fields or retrying |
| `pressTabKey` | boolean | Simulates Tab key after typing. Enables tab-through-fields pattern. Note: Tab fires AFTER Enter if both enabled |
| `waitForNavigation` | boolean | Waits for navigation after typing (useful for search-on-type) |
| `configuration.waitForNavigationConfig.timeoutSeconds` | integer | Default 30. Max wait time |
| `configuration.waitForNavigationConfig.waitUntil` | string | `load`, `domcontentloaded`, `networkidle0`, `networkidle2` |

### Click -- Additional Params

| Param | Type | Description |
|-------|------|-------------|
| `configuration.clickType` | string | `click` (default), `doubleClick`, or `rightClick` |
| `waitForNavigation` | boolean | Wait for navigation after clicking |
| `configuration.waitForNavigationConfig.waitUntil` | string | `load`, `domcontentloaded`, `networkidle0`, `networkidle2` |
| `configuration.experimental.scrollWithin` | string | Natural language description of a scrollable container to scroll within before clicking |

### Scroll -- Additional Params

| Param | Type | Description |
|-------|------|-------------|
| `scrollToElement` | string | Natural language element description. Overrides pixel-based scrolling |
| `scrollBy.xAxis` / `scrollBy.yAxis` | string | Pixels or percentage |
| `scrollToEdge.xAxis` / `scrollToEdge.yAxis` | string | Scroll to left/right/top/bottom edge |
| `scrollWithin` | string | Natural language description of scrollable container (defaults to full page) |

### Page Query -- Additional Params

| Param | Type | Description |
|-------|------|-------------|
| `configuration.outputSchema` | string | JSON schema string for structured output |
| `followPaginationLinks` | boolean | Auto-loads paginated content |
| `configuration.visualAnalysis.scope` | string | `viewport`, `page`, `scan`, `auto`. Full-page analysis |
| `configuration.experimental.includeVisualAnalysis` | string | `auto`/`enabled`/`disabled`. Force visual analysis on/off |
| `costThresholdCredits` | integer | Soft credit limit |
| `timeThresholdSeconds` | integer | Soft time limit |

### Screenshot -- Full-Page Capture

| Param | Type | Description |
|-------|------|-------------|
| `configuration.screenshot.format` | string | `base64` or `url`. URL gives signed download link (1-hour expiry) |
| `configuration.screenshot.visualAnalysis.scope` | string | `viewport`, `page`, `scan`, `auto`. **"page" = full-page capture** |
| `configuration.screenshot.visualAnalysis.partitionDirection` | string | `vertical` (default), `horizontal`, `bidirectional` |
| `configuration.screenshot.visualAnalysis.overlapPercentage` | integer | Default 30. Overlap between chunks |
| `configuration.screenshot.visualAnalysis.maxScanScrolls` | integer | Default 50. Max scrolls in scan mode |
| `configuration.screenshot.visualAnalysis.scanScrollDelay` | integer | Default 1000ms. Delay between scrolls |
| `configuration.screenshot.maxWidth` / `maxHeight` | integer | Scale constraints (preserves aspect ratio) |

**Important nesting:** Params go under `configuration.screenshot`, NOT directly under `configuration`. Wrong nesting causes 422.

Full-page screenshots return multiple chunks (e.g., 4 for a typical form page). Each chunk has its own `signedDownloadUrl`.

### Additional Endpoints

| Endpoint | What It Does |
|----------|-------------|
| `hover` | Hover over elements via natural language targeting. Same visual analysis config as click. For tooltips, dropdown menus, hover-revealed content |
| `scrape-content` | Raw markdown dump of page content. No prompt needed. Returns `scrapedContent.text`, `title`. Fast alternative to `query_page` for static pages |
| `file-input` | File upload to form inputs. Targets via `elementDescription`, supports `includeHiddenElements`. Handles single/multiple input detection |
| `paginated-extraction` | Extract data across paginated content. `paginationMode` (auto/paginated/infinite-scroll), `outputSchema` for structured output |
| `batch-operate` | Process multiple URLs in parallel. `maxConcurrentSessions` (default 30). Supports `shouldHaltBatch` and dynamic URL discovery |

### Session Management and Profiles

| Feature | How |
|---------|-----|
| **Save profile** | `sessions.saveProfileOnTermination(sessionId, "PROFILE_NAME")` before terminating. Saves cookies + localStorage (encrypted AES-256) |
| **Restore profile** | Pass `configuration.profileName` when creating a session |
| **Delete profiles** | `profiles.delete({profileNames: [...]})` |
| **Session timeout** | `configuration.timeoutMinutes` (default 10 min idle) |
| **Chrome extensions** | Pass `extensionIds` array on session creation |

Profiles persist authenticated state across sessions. Only saved on explicit `terminate()` -- crashes/timeouts may lose profile data.

### Proxy Configuration

**Built-in residential proxy:** 100M+ IPs, 100+ countries, sticky sessions (same IP up to 30 min).

**Bring Your Own Proxy (BYOP):**
- String: `proxy: 'https://user:pass@proxy.com'`
- Object: `proxy: { url, username, password }`
- Domain-specific routing with pattern matching

**Blocked domains on built-in proxy:** Netflix, banking/financial sites, Ticketmaster, LinkedIn.

---

## When to Use vs Alternatives

| Option | Can Fill Forms? | Notes |
|--------|----------------|-------|
| **AI Browser steps** | Yes (basic) | Platform steps. Limited params but convenient |
| **Airtop Direct API** | Yes (full control) | BYO key. Form-filler automation, Tab key, file upload, full-page screenshots |
| **Apify Actor** | Yes (via custom actors) | BYO API key. Puppeteer/Playwright with full capabilities |
| **Firecrawl** | No | HTTP-based scrape + LLM extraction only |
| **Browserless Scrape** | No | CSS selector extraction, read-only |
| **Direct HTTP POST** | Yes (specific cases) | Works for server-rendered forms (Gravity Forms). Fastest and cheapest when applicable |

### Decision Guide

- **Default:** Direct HTTP POST if the form technology allows it (server-rendered, tokens in HTML). Fastest, cheapest, most reliable
- **Use AI Browser steps when:** Quick form fill on a JS-rendered page, no advanced requirements
- **Use Airtop Direct API when:** Need form-filler automation, file uploads, full-page screenshots, Tab key, structured output, or session profiles
- **Use Apify when:** Form is inside an iframe, needs CAPTCHA solving, or requires full Puppeteer/Playwright control
- **Check for iframes first.** Many marketing forms (HubSpot, Calendly, Typeform) embed via iframe. Airtop confirmed iframes are not supported (on roadmap)

---

## Form-Filling Pattern (Platform Steps)

Basic pattern using `browser_*` steps:

```
1. browser_create_window -> navigate to form page
2. Text fields: browser_type with element_description
3. Dropdowns: browser_click (open), browser_click (select option)
4. Checkboxes: browser_click
5. Submit: browser_click with wait_for_navigation: true
6. Verify: browser_query_page or screenshot + vision analysis
7. browser_close_window (always)
```

### Tips

- **Always close windows.** Sessions consume credits while open
- **Dropdown handling is fragile.** Two-click pattern depends on AI vision for both elements
- **Proxy for geo-restricted content.** Use `proxy_country` on `create_window`

---

## Tested Patterns and Gotchas (Apr 2026)

Learnings from real agent testing against `relevanceai.com/book-a-demo`:

### query_page cannot see JS-rendered form fields
`query_page` reads the DOM/text, not the visual page. For JS-rendered forms (React, Next.js, Vue), it returns "form fields not present in supplied content." However, `click` and `type` still work because they use AI vision targeting. **Pattern:** try `query_page` first; if it fails, switch to screenshot + vision analysis for all observation.

### prompt_completion_vision is the correct vision step
The `prompt_completion` step does NOT officially support an `images` parameter (even though it may work at runtime). Use `prompt_completion_vision` for image analysis. It does NOT support `system_prompt` -- fold instructions into the `prompt` param.

### Click-to-focus before typing can cause scroll side effects
Clicking a field to give it focus scrolls the viewport to that element. If you click-to-focus every field sequentially, the viewport shifts unpredictably and subsequent type operations may target wrong elements. **Pattern:** type directly on first pass, verify with screenshot, only use click-to-focus as a retry mechanism for fields that failed. Alternatively, use `pressTabKey: true` via the Airtop Direct API to tab between fields.

### Some email fields silently discard typed input
Fields with custom JS event handlers (especially email validation) may report `success: true` from `type` but appear blank. The field needs an explicit click (focus event) before it accepts input. Detect this via screenshot verification. The Airtop Direct API `clearInputField: true` param can help with retries.

### Never reload the page to recover
`Load URL` resets all form state. If the agent gets lost or the viewport is in the wrong position, use screenshot + analyze to reorient, then scroll or click to navigate back. Never reload.

### monitor_page returns false positives with vague conditions
"A confirmation message appears" matches too broadly. Use compound conditions: "the page URL has changed, OR text containing thank you or successfully submitted is visible, OR a red error message is displayed."

### Full-page screenshot nesting
When calling the Airtop screenshot API directly, params must be nested under `configuration.screenshot.visualAnalysis`, NOT `configuration.visualAnalysis`. Wrong nesting causes 422 validation errors.

---

## Known Airtop Limitations

| Limitation | Detail |
|-----------|--------|
| **iFrames not supported** | Cannot interact with or extract data from content inside iframes. Confirmed by Airtop (Apr 2026) -- on roadmap. Major blocker for embedded forms (HubSpot, Calendly, Typeform) |
| No CSS selectors or XPath | All targeting is natural language only |
| No coordinate-based clicking | Click is `element_description` only |
| No execute-JavaScript | Cannot run arbitrary JS in the browser |
| No drag-and-drop | No endpoint exists |
| No Shift/Ctrl keyboard combos | Only Enter and Tab keys available |
| No element state detection | Cannot directly ask "is this checkbox checked?" -- use `pageQuery` |
| No wait-for-element | Use `monitor` with natural language condition |
| Visual analysis accuracy | Decreases above 1920x1080 viewport resolution |
| Cost/time thresholds are soft | Checked periodically, not hard caps. Operations may exceed before cancellation |
| Session init time | Can take up to 1 minute (usually seconds) |
| Profile save requires explicit terminate | Crashes/timeouts may lose profile data |
| LinkedIn blocked on built-in proxy | Use BYOP for LinkedIn |
| Multiple LLM providers | Airtop uses OpenAI/Anthropic/Google with automatic switching -- behavior may vary between calls |

---

## See Also

- `playbooks/use-cases/form-testing-patterns.md` -- Use-case playbook: Level 1-4 framework for automated form testing, per-form routing, dummy-data hygiene
- `platform-tool-gotchas.md` -- General platform tool gotchas
- `tool-transformations.md` -- Other transformation step types
- `.claude/rules/BUILD_PRACTICES.md` -- Tool building standards
- Airtop API reference: `https://docs.airtop.ai/api-reference/airtop-api`
