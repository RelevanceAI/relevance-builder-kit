# Tool Sandbox Auth: Python vs JS

Python and JS tool sandboxes have different runtime globals. Same Relevance project, same tool -- different auth surface.

The headline rule sits in `.claude/rules/PLATFORM_MECHANICS.md` § "JS Sandbox Auth"; the full asymmetry, header formats, and guard patterns live here.

---

## Runtime globals at a glance

| Global | Python (`python_code_transformation`) | JS (`js_code_transformation`) |
|---|---|---|
| `authorization` (`{project}:{key}:{region}:undefined`) | Yes | **undefined** |
| `credentials` | No | **undefined** |
| `process.env` | Yes | **undefined** (browser-like sandbox, not Node) |
| `fetch` | via `requests` | **native** |
| `crypto.subtle` | No | **available** |

---

## Python `authorization` keyword

The built-in `authorization` variable provides project auth context.

**Format:** `{project_id}:{api_key}:{region}:undefined`

```python
parts = authorization.split(':')
project_id = parts[0]
api_key = parts[1]
region = parts[2]
```

**Limitation:** the runtime API key is **scoped** and may lack permissions for certain endpoints (e.g. `/slide_show`). For endpoints requiring full access, use project secrets or user API keys.

---

## JS sandbox: no `authorization` global

JS tools hitting the Relevance API (`/knowledge/*`, `/studios/*`, `/agents/*`) must source a project API key another way:

- **Preferred:** Project secret prefixed `chains_` -- reference as `` `{{secrets.chains_your_key_name}}` ``. See `.claude/rules/PLATFORM_MECHANICS.md` § "Reserved Variable Prefixes".
- **Header format:** `Authorization: ${PROJECT_ID}:${API_KEY}` -- the raw API key alone returns 401. Project ID can be hardcoded (tool is project-scoped).
- **Ugly fallback:** pass the key as a fixed `params_schema` param with `is_fixed_param: true` and a `default` value. Exposes the key in tool config; avoid unless no secret exists.

---

## Always guard against unresolved secrets

Unresolved templates become the literal string `"undefined"` rather than throwing -- a silent 401 trap.

```js
const API_KEY = `{{secrets.chains_your_secret}}`;
if (!API_KEY || API_KEY.includes('{{') || API_KEY === 'undefined') {
  return { error: 'secret did not resolve', sitemap_errors: [{ stage: 'auth' }] };
}
```

---

## When to pick JS over Python for a tool

When the tool fetches from Cloudflare-protected external sites. Python `requests` in the sandbox gets TLS-fingerprint-challenged by CF even with browser UAs, while Node `fetch` passes cleanly. See `platform-tool-gotchas.md` § "Cloudflare-Protected Sites: Python requests vs Node fetch".
