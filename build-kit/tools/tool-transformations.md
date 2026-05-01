# Tool Transformation Reference

Hard-won lessons about Relevance AI tool transformation steps configured via API/MCP.

## `send_email` Transformation

The `send_email` step sends email through user's Gmail or Outlook via OAuth.

### Valid Providers

- `Gmail`
- `Outlook`

**Critical:** Provider must use the `_oneof_type_` discriminator pattern:

```json
"provider": {"_oneof_type_": "Gmail"}
```

NOT `"provider": "Gmail"` or `"provider": "gmail"` -- these will fail with a `oneOf` schema validation error.

### Required Params

| Param | Type | Notes |
|-------|------|-------|
| `provider` | object | `{"_oneof_type_": "Gmail"}` or `{"_oneof_type_": "Outlook"}` |
| `oauth_account_id` | string | Connected OAuth account ID. Make this a fixed param |
| `to` | array | `["recipient@example.com"]` -- MUST be array, not string |
| `subject` | string | Email subject |
| `body` | string | Supports Markdown (auto-rendered to HTML) |

### Optional Params

- `cc` / `bcc` - arrays of email addresses
- `thread_id` - for replying to existing thread
- `gmail_message_id` - Gmail-specific, needed for thread replies
- `draft` - boolean, saves as draft instead of sending
- `attachments` - object mapping `filename -> download_url`

### Alternative: `send_email_step` (Mailgun, Server-Side)

For internal/agent use. No OAuth needed. Uses Mailgun under the hood.

```json
{
  "transformation": "send_email_step",
  "params": {
    "recipientEmails": ["user@example.com"],
    "subject": "Subject here",
    "body": {"html": "<p>HTML body</p>"}
  }
}
```

## `microsoft_api_call` - Path Requires `/v1.0/` Prefix

The native `microsoft_api_call` transformation uses base URL `https://graph.microsoft.com` with NO version suffix. Every path must include `/v1.0/` explicitly.

```
WRONG: "/drives/{driveId}/items/{itemId}"   -> 404 "Invalid version: drives"
RIGHT: "/v1.0/drives/{driveId}/items/{itemId}"

WRONG: "/search/query"   -> 404 "Invalid version: search"
RIGHT: "/v1.0/search/query"
```

## Microsoft Search API - `region` Only for App Permissions

The `region` field (e.g. `"CAN"`) in the Microsoft Graph Search API body is **only supported for application permissions** (service principal / client_credentials grant). With user-delegated OAuth it returns:

```
400 BadRequest: "SearchRequest Invalid (Region is not supported when request with delegated permission.)"
```

Omit `region` entirely when using OAuth. It is not required and causes a hard failure.

## Python Steps - No Backtick Template Injection

In Python (`python_code_transformation`) steps, variables from `state_mapping` are available as **direct Python variable names**. Backtick template syntax (`` `{{var}}` ``) is **invalid Python 3** and causes a `SyntaxError` that kills the step silently (Modal Labs reports `FileNotFoundError: No such file: out.txt` - looks like an infrastructure error but is actually a syntax error).

```python
# WRONG - backtick is not valid Python 3 syntax, causes silent crash
item_data = `{{item_metadata}}`

# RIGHT - state_mapping variable is a real Python variable
if isinstance(item_metadata, dict):
    item_data = item_metadata
```

Backtick injection IS correct for JavaScript (`javascript_code_transformation`) steps. JS supports template literals. Python does not.

## Modal Labs Minimum Timeout is 60 Seconds

Python step `timeout` param minimum is 60. Setting `timeout: 30` causes immediate validation failure: `"must be >= 60"`. Even simple Python steps need at least 60.

## Loop Body Dict Injection Doesn't Work Reliably

Passing a Python dict as `body: "{{loop.item}}"` in a `loop` transformation with `microsoft_api_call` nested inside does NOT reliably pass the dict as a JSON object - it may be stringified, causing the API to reject it with a 400.

**Pattern to avoid:**
```json
{"name": "page_call", "params": {"body": "{{loop.item}}"}}
```
where `loop.item` is a full body dict.

**Correct pattern:** Build the body as a literal JSON object in the step params with simple string template vars:
```json
{
  "body": {
    "requests": [{"query": {"queryString": "{{query_str}}"}, "size": 500}]
  }
}
```

## `@microsoft.graph.downloadUrl` - Pre-Signed Download URL

When you GET a drive item via Graph API, the response includes `@microsoft.graph.downloadUrl`. This is a pre-signed URL that allows file download **without any auth header**. Access it with:
```python
download_url = item_data.get('@microsoft.graph.downloadUrl')
r = requests.get(download_url)  # No Authorization header needed
```

## `params_schema` Must Use Proper JSON Schema Structure

When passing `params_schema` via MCP, it MUST be a valid JSON Schema object with `properties` nested correctly:

```json
{
  "type": "object",
  "required": ["email", "name"],
  "properties": {
    "email": {"type": "string", "title": "Email"},
    "name": {"type": "string", "title": "Name"}
  }
}
```

**NOT** flat keys like:
```json
{
  "email": {"type": "string", "title": "Email"},
  "name": {"type": "string", "title": "Name"}
}
```

The flat format is accepted by the API but the UI cannot render it (shows no inputs, and `{{param}}` references fail to resolve). Always wrap params inside `properties` with `type: "object"` and `required` at the top level.

## `linkedin_action` Transformation (Unipile)

LinkedIn actions via the Unipile integration. Supports messaging, connection requests, profile lookups, and chat management.

**Critical:** The `action` object must use the `_oneof_type_` discriminator pattern:

```json
"action": {
  "_oneof_type_": "Send Invitation",
  "oauth_account_id": "{{oauth_account_id}}",
  "identifier": "{{identifier}}",
  "message": "{{message}}"
}
```

NOT `"action": {"type": "SEND_MESSAGE", "provider_id": "LINKEDIN"}` -- the `type`/`provider_id` format is undocumented, fragile, and will fail with `must NOT have additional properties {"additionalProperty":"type"}` if mixed with `_oneof_type_`.

### Valid `_oneof_type_` Values

| `_oneof_type_` | Required Params | Optional Params |
|----------------|-----------------|-----------------|
| `"Send Invitation"` | `oauth_account_id`, `identifier`, `message` | `conversation_id` |
| `"Start New Chat"` | `oauth_account_id`, `identifier`, `text`, `account_type` | `title` |
| `"Send Message In A Chat"` | `chat_id`, `text` | - |
| `"Get User Profile"` | `oauth_account_id`, `identifier` | `notify` |
| `"Get All Chats"` | `oauth_account_id` | `before`, `after`, `cursor`, `limit` |
| `"Get All Messages From Chat"` | `oauth_account_id`, `chat_id` | `before`, `after`, `cursor`, `limit` |
| `"Send Comment"` | `oauth_account_id`, `post_id`, `text` | `comment_id` |
| `"Create A Post"` | `oauth_account_id` | `caption`, `attachments` |
| `"Get InMail Balance"` | `oauth_account_id` | - |
| `"List Sent Invitations"` | `oauth_account_id` | `cursor`, `limit` |
| `"List Received Invitations"` | `oauth_account_id` | `cursor`, `limit` |
| `"Accept/Reject Invitation"` | `oauth_account_id`, `invitation_id`, `shared_secret`, `invitation_action` | - |
| `"Get All Comments From Post"` | `oauth_account_id`, `post_id` | `cursor`, `limit` |
| `"Get All Reactions From Post"` | `oauth_account_id`, `post_id` | `cursor`, `limit` |
| `"Add Reaction To Post"` | `oauth_account_id`, `post_id`, `reaction_type` | - |

### Nested `_oneof_type_`: `account_type` for Start New Chat

`Start New Chat` requires `account_type` which is itself a `_oneof_type_` discriminator:

```json
"account_type": {"_oneof_type_": "Classic"}
```

Valid values: `"Classic"` (standard LinkedIn), `"Recruiter"` (LinkedIn Recruiter), `"Sales Navigator"`

### Param Name Gotchas

- `Start New Chat` and `Send Message In A Chat` use `text`, not `message`
- `Send Message In A Chat` does NOT take `oauth_account_id` (only `chat_id` + `text`)
- `Send Invitation` uses `message` (max 200 chars free, 300 chars premium)

### InMail Subject Line (via `title`)

The `title` param on `Start New Chat` (Sales Navigator accounts) maps to the **InMail subject line** at the Unipile layer. It's optional but expected for InMail - LinkedIn renders it as the subject in the recipient's inbox.

- **Target 25-50 chars, design for mobile at 30-40 chars.** Specific to the prospect; never generic ("Quick question" is throwaway).
- `text` (the body) supports `\n\n` for **paragraph breaks** - LinkedIn renders them as paragraph separators. Use one per formula part for mobile scannability.
- When char-counting the body, exclude the `\n\n` separators - they're ~6 chars of non-content.
- Body under 400 chars = 22% higher response rate. 400-500 is still good.

See `build-kit/integrations/linkedin.md` "InMail Body Formatting" for the full outreach guidance.

---

## `markdown` Transformation (a.k.a. Note step)

Documentation-only step that renders markdown inside the tool step panel. Zero cost per run, no LLM, no downstream output contract. Use it to explain what a tool does, why it's built that way, and how the code path flows -- visible when a user opens the tool in the UI.

**NOTE:** The UI calls this a "Note step" in the step picker, but under the hood the transformation name is `markdown`.

### Shape

```json
{
  "name": "readme",
  "transformation": "markdown",
  "params": {
    "markdown": "# My heading\n\nExplain the tool here. Supports full markdown including lists, bold, headers, tables, and fenced code blocks."
  }
}
```

### Notes

- No `state_mapping` entries needed -- the step has no inputs or outputs that downstream steps consume.
- Place it as the **first step** in each tool so users who open the tool see the docs immediately before the logic.
- Use the full markdown grammar: headers, lists, bold, inline code, fenced code blocks, tables. All render in the step panel.

## JS Code Steps (`js_code_transformation`)

### Inter-Step Data Access

JS code steps cannot access a `steps` global object. Use template injection:

```javascript
// Access API call output
const raw = `{{steps.api_step.output}}`;
const parsed = JSON.parse(raw);
const results = parsed.response_body?.results || [];

// Access JS step output
const value = `{{steps.js_step.output.transformed.field_name}}`;
```

### Step Names vs Step References

The `steps.` prefix is a **namespace qualifier** used by the template resolver -- it is NOT part of the step name. A step named `calc_date` is referenced as `steps.calc_date.output` in templates and state_mapping. Never include `steps.` in the step's `name` field; doing so causes double-prefixing (`steps.steps.calc_date`) and broken references.

### Output Paths

| Step Type | Output Path |
|-----------|-------------|
| `js_code_transformation` | `steps.{name}.output.transformed` |
| `python_code_transformation` | `steps.{name}.output.transformed` (raw) or `steps.{name}.output.result` (if step has `output: {"result": "{{transformed}}"}`) |
| `prompt_completion` | `steps.{name}.output.answer` |
| `relevance_api_call` | `steps.{name}.output.response_body` |
| `notion_native_api_call` | `steps.{name}.output.response_body` |

### Tool Output Config

Always use string templates in the output config:

```json
"output": {"output": "{{steps.final_step.output.transformed}}"}
```

NOT objects like `"output": {"output": {"key": "value"}}` -- this will fail validation.

## `prompt_completion` Transformation

LLM prompt step. Sends a prompt to a model and returns the response.

### Key Params

| Param | Type | Notes |
|-------|------|-------|
| `model` | string | e.g., `anthropic-claude-sonnet-4-20250514` |
| `system_prompt` | string | System message |
| `prompt` | string | User prompt (supports `{{variable}}` templates) |

### Invalid Params

- `json_output` -- does NOT exist on `prompt_completion`. Will fail with "must NOT have additional properties". To get JSON, instruct the model in the prompt text.

### Output Path

Output is wrapped in an `answer` key:
```
steps.{name}.output.answer  →  the LLM's response text
```

NOT `steps.{name}.output` (that gives the full wrapper object).

## `notion_native_api_call` Transformation

Raw Notion API call using native OAuth. **Required when the project uses native Notion OAuth** (`provider: notion_native`). The `notion_-_notion-*` transformations (append-block, search, create-page, etc.) do NOT work with native OAuth.

### Key Params

| Param | Type | Notes |
|-------|------|-------|
| `oauth_account_id` | string | Native Notion OAuth account ID |
| `method` | string | HTTP method: GET, POST, PATCH, DELETE |
| `path` | string | Relative to `https://api.notion.com/` (e.g., `v1/search`, `v1/pages`) |
| `body` | object/array | Notion API request body |
| `headers` | object | Optional. Authorization header auto-set |

### Common Operations

| Operation | Method | Path |
|-----------|--------|------|
| Search | POST | `v1/search` |
| Create page | POST | `v1/pages` |
| Append blocks | PATCH | `v1/blocks/{page_id}/children` |
| Get page | GET | `v1/pages/{page_id}` |
| Query database | POST | `v1/databases/{db_id}/query` |

### Output Path

```
steps.{name}.output.response_body  →  Notion API response
steps.{name}.output.status         →  HTTP status code
```
