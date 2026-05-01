# Tool Icon URLs

> **Purpose:** Known-working branded logo URLs for integration tools. Use these in the `emoji` field when creating tools.
> **Last Updated:** 2026-03-16

---

## Usage

The `emoji` field on Relevance AI tools accepts any public image URL. For integration-specific tools, use branded logos instead of generic emojis.

```json
"emoji": "https://example.com/logo.svg"
```

---

## Known-Working URLs

| Service | URL |
|---------|-----|
| Google Sheets | `https://upload.wikimedia.org/wikipedia/commons/3/30/Google_Sheets_logo_%282014-2020%29.svg` |
| Google Docs | `https://upload.wikimedia.org/wikipedia/commons/0/01/Google_Docs_logo_%282014-2020%29.svg` |
| Google Slides | `https://upload.wikimedia.org/wikipedia/commons/1/16/Google_Slides_2020_Logo.svg` |
| Google Calendar | `https://upload.wikimedia.org/wikipedia/commons/a/a5/Google_Calendar_icon_%282020%29.svg` |
| Gmail | `https://upload.wikimedia.org/wikipedia/commons/7/7e/Gmail_icon_%282020%29.svg` |
| Slack | `https://upload.wikimedia.org/wikipedia/commons/d/d5/Slack_icon_2019.svg` |
| HubSpot | `https://www.hubspot.com/hubfs/HubSpot_Logos/HubSpot-Inversed-Favicon.png` |
| LinkedIn | `https://upload.wikimedia.org/wikipedia/commons/c/ca/LinkedIn_logo_initials.png` |
| Microsoft / SharePoint | `https://upload.wikimedia.org/wikipedia/commons/e/e1/Microsoft_Office_SharePoint_%282019%E2%80%93present%29.svg` |
| Notion | `https://upload.wikimedia.org/wikipedia/commons/4/45/Notion_app_logo.png` |
| Google Drive | `https://upload.wikimedia.org/wikipedia/commons/1/12/Google_Drive_icon_%282020%29.svg` |
| Google Search | `https://cdn.jsdelivr.net/gh/RelevanceAI/content-cdn@latest/vendors/icons/google.svg` |
| Perplexity | `https://cdn.jsdelivr.net/gh/RelevanceAI/content-cdn@latest/vendors/icons/perplexity.svg` |
| Airtop (AI Browser) | `https://cdn.jsdelivr.net/gh/RelevanceAI/content-cdn@latest/vendors/icons/airtop_logo.svg` |
| Browser Use | `https://cdn.jsdelivr.net/gh/RelevanceAI/content-cdn@latest/vendors/icons/browser_use.svg` |

---

## Safe Generic Icons (Unicode Emoji Shortcodes)

For non-integration tools where a branded logo isn't needed, use unicode emoji shortcodes instead of image URLs. These always render correctly:

| Use Case | Shortcode |
|----------|-----------|
| Website / web scraping | `:globe_with_meridians:` |
| Search / lookup | `:mag:` |
| Email | `:email:` |
| Phone / call | `:telephone_receiver:` |
| Save / store | `:floppy_disk:` |
| Analytics / scoring | `:bar_chart:` |
| Processing / transform | `:gear:` |
| Document / text | `:page_facing_up:` |
| Calendar / scheduling | `:calendar:` |

## Relevance AI Vendor Icon CDN

The platform serves all its own integration icons from a predictable CDN path:

```
https://cdn.jsdelivr.net/gh/RelevanceAI/content-cdn@latest/vendors/icons/{name}.svg
```

**Try this first** before searching for external URLs. The `{name}` is lowercase, no spaces. Examples:
- `google.svg`, `perplexity.svg`, `hubspot.svg`, `slack.svg`, `notion.svg`
- For compound names try hyphenated: `google-sheets.svg`, `linked-in.svg`
- Some vendors use a `_logo` suffix instead of just the name: `airtop_logo.svg`, `browser_use.svg`. If `{name}.svg` 404s, try `{name}_logo.svg`
- If the vendor icon name is unknown, check `logo_key` in the tool's `integration_requirements` -- that's the key the platform uses internally
- Browse the directory directly: `https://github.com/RelevanceAI/content-cdn/tree/main/vendors/icons`

If the CDN path 404s, fall back to the Wikipedia Commons SVGs in the table above or upload to catbox.moe (see Apollo logo as reference).

## Adding New URLs

When you discover a working branded logo URL, add it to this table. Requirements:
- Must be a public URL (no auth required)
- **URL must NOT contain spaces or unencoded special characters** -- the API silently accepts them but the UI renders a broken/error icon
- Prefer SVG over PNG for quality
- Test by setting as `emoji` on a tool and confirming it renders in the Relevance AI UI
- If in doubt, use a unicode emoji shortcode instead -- they never break
