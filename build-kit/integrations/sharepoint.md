# Microsoft SharePoint

> **SharePoint** is Microsoft's document management and collaboration platform. Integrates with Relevance AI via `microsoft_api_call` (native, delegated OAuth) or Python + `client_credentials` (service principal). This guide covers the OAuth (delegated) pattern.

## Why It Matters

SharePoint is where most enterprise customers store their internal documents - SOWs, proposals, presentations, policy docs, research. Agents that can search and read SharePoint documents are extremely high value for RFP research, knowledge retrieval, and document synthesis use cases.

---

## Auth: Two Approaches

| Approach | How | When |
|---|---|---|
| **Delegated OAuth** (recommended) | `microsoft_api_call` with connected Microsoft OAuth account | User wants their own SharePoint access scope |
| **Service principal** | Python `requests` with `client_credentials` grant using `{{secrets.client_id}}`, `{{secrets.tenant_id}}`, `{{secrets.client_secret}}` | Needs app-level access to all SharePoint content |

**Key difference:** Service principal searches ALL SharePoint content the app has been granted access to. Delegated OAuth only finds content the connected USER has access to. This affects search result scope significantly.

---

## Critical Gotchas

### 1. `microsoft_api_call` base URL has no version

The `microsoft_api_call` native step uses base URL `https://graph.microsoft.com` with NO version suffix. You MUST include `/v1.0/` in every path.

```
WRONG: "/drives/{driveId}/items/{itemId}"
RIGHT: "/v1.0/drives/{driveId}/items/{itemId}"
WRONG: "/search/query"
RIGHT: "/v1.0/search/query"
```

Forgetting this causes: `"Invalid version: drives"` or `"Invalid version: search"`.

### 2. `region` parameter breaks delegated auth

The Microsoft Graph Search API `region` field (e.g. `"CAN"`) is only supported for **application permissions** (service principal). With delegated OAuth it returns:

```
400 BadRequest: "SearchRequest Invalid (Region is not supported when request with delegated permission.)"
```

**Remove `region` entirely from all search bodies when using OAuth.** It defaults correctly without it.

### 3. Python steps: no backtick injection

In Relevance AI Python (Modal Labs) steps, variables from `state_mapping` are available as **direct Python variable names**. Do NOT use backtick template syntax - backticks are invalid Python 3 syntax and cause a SyntaxError that kills the step silently (Modal Labs reports `FileNotFoundError: No such file: out.txt`).

```python
# WRONG - backtick is invalid Python 3 syntax
item_data = `{{item_metadata}}`

# RIGHT - state_mapping variable available directly
if isinstance(item_metadata, dict):
    item_data = item_metadata
```

### 4. Loop body dict injection doesn't work

Passing a Python dict as `body: "{{loop.item}}"` in a `loop` transformation with `microsoft_api_call` nested inside does NOT reliably pass the object - it gets stringified. Microsoft's API rejects a string body.

**Workaround:** Build the body inline as a literal JSON object in the step params with simple template vars (`{{query_str}}`) instead of injecting the whole object.

### 5. `from` integer type in search pagination

The Microsoft Search API `from` field expects an integer. Injecting it via template in a JSON string context (`"from": "{{loop.item}}"`) sends the string `"0"` not the integer `0`, causing a silent 400 rejection.

**Workaround:** Omit `from` entirely for the first page (defaults to 0). For multi-page pagination, a loop-based approach requires a different strategy.

### 6. Download URLs are pre-signed

When you GET a drive item via Graph API, the response includes `@microsoft.graph.downloadUrl`. This is a **pre-signed URL** - you can download the file directly with a plain HTTP GET, no auth header needed. This means:

- Step 1: `microsoft_api_call` GET the item metadata
- Step 2: Python downloads from the pre-signed URL (no OAuth needed)

Access the key with special chars: `item_data.get('@microsoft.graph.downloadUrl')`

### 7. Modal Labs minimum timeout is 60 seconds

Python code steps using Modal Labs backend require `timeout >= 60`. Setting `timeout: 30` causes immediate validation failure.

---

## Tool Patterns

### Pattern 1: Extract File Content (PDF / DOCX / PPTX)

Two-step approach:

**Step 1 - `get_item` (microsoft_api_call):**
```json
{
  "transformation": "microsoft_api_call",
  "params": {
    "oauth_account_id": "{{oauth_account_id}}",
    "method": "GET",
    "path": "/v1.0/drives/{{drive_id_input}}/items/{{document_id_input}}"
  },
  "output": {"response_body": "{{response_body}}", "status": "{{status}}"}
}
```

State mapping: `"item_metadata": "steps.get_item.output.response_body"`

**Step 2 - Extract (python_code_transformation):**
```python
# item_metadata available directly from state_mapping (no backtick)
import json

if isinstance(item_metadata, dict):
    item_data = item_metadata
elif isinstance(item_metadata, str):
    try: item_data = json.loads(item_metadata)
    except: item_data = {}
else:
    item_data = {}

download_url = item_data.get('@microsoft.graph.downloadUrl')
if not download_url:
    return {'status': 'no_download_url', 'error': 'Check OAuth permissions'}

import requests
r = requests.get(download_url)  # No auth needed - pre-signed URL
file_content = r.content
# ... parse PDF/PPTX/DOCX ...
```

### Pattern 2: Search SharePoint (single page, up to 500 results)

**Step 1 - `build_query` (python_code_transformation):**
```python
# search, site_url, max_results_c available directly from state_mapping
site = site_url if site_url else None
query = f'{search} path:"{site}"' if site else search
return {'query': query}
```

State mapping: `"query_str": "steps.build_query.output.transformed.query"`

**Step 2 - `search_call` (microsoft_api_call):**
```json
{
  "transformation": "microsoft_api_call",
  "params": {
    "oauth_account_id": "{{oauth_account_id}}",
    "method": "POST",
    "path": "/v1.0/search/query",
    "body": {
      "requests": [{
        "entityTypes": ["driveItem"],
        "query": {"queryString": "{{query_str}}"},
        "size": 500,
        "fields": ["id", "name", "webUrl", "parentReference", "folder", "file"]
      }]
    }
  }
}
```

Note: NO `region` field. `from` omitted = defaults to 0 (first page).

**Step 3 - `process_results` (python_code_transformation):**
```python
# search_response available directly from state_mapping (no backtick)
import json

if isinstance(search_response, dict):
    response_body = search_response
elif isinstance(search_response, str):
    try: response_body = json.loads(search_response)
    except: response_body = {}
else:
    response_body = {}

business_extensions = {'.pptx', '.xlsx', '.docx', '.pdf'}
hits_containers = response_body.get('value', [{}])[0].get('hitsContainers', [])
hits = hits_containers[0].get('hits', []) if hits_containers else []

results = []
for hit in hits:
    resource = hit.get('resource', {})
    name = resource.get('name', '')
    web_url = resource.get('webUrl', '')
    if '-my.sharepoint.com/personal/' in web_url: continue
    is_folder = bool(resource.get('folder')) or (not resource.get('file') and '.' not in name)
    is_file = bool(resource.get('file')) or ('.' in name and not is_folder)
    if is_file:
        ext = '.' + name.split('.')[-1].lower() if '.' in name else ''
        if ext not in business_extensions: continue
    item_type = 'folder' if is_folder else 'file' if is_file else 'unknown'
    results.append({
        'id': resource.get('id'),
        'name': name,
        'webUrl': web_url,
        'itemType': item_type,
        'parentPath': resource.get('parentReference', {}).get('path', ''),
        'driveId': resource.get('parentReference', {}).get('driveId')
    })

return results
```

State mapping: `"search_response": "steps.search_call.output.response_body"`

### Pattern 3: Recursive Folder Listing (via Search API)

Instead of recursive `children` API calls (which require the token in Python), use the Search API's `path:` filter to get all files recursively in one call.

**Step 1 - Get folder info to extract webUrl:**
```json
{"path": "/v1.0/drives/{{drive_id_input}}/items/{{folder_id_input}}"}
```

**Step 2 - Build path query (Python):**
```python
# folder_metadata available directly from state_mapping
folder_url = folder_metadata.get('webUrl', '') if isinstance(folder_metadata, dict) else ''
folder_path = folder_url.split('?')[0]  # Strip query params
return {'folder_path_query': f'* path:"{folder_path}"'}
```

**Step 3 - Search with path filter (no region!):**
```json
{
  "body": {
    "requests": [{
      "entityTypes": ["driveItem"],
      "query": {"queryString": "{{folder_path_query}}"},
      "size": 500,
      "fields": ["id", "name", "webUrl", "parentReference", "folder", "file", "size", "lastModifiedDateTime"]
    }]
  }
}
```

---

## OAuth Account Setup

The `oauth_account_id` param must use the OAuth selector type so it shows in UI:

```json
"oauth_account_id": {
  "type": "string",
  "title": "Microsoft OAuth Account",
  "metadata": {
    "content_type": "oauth_account",
    "is_fixed_param": true,
    "oauth_permissions": [{"provider": "microsoft", "types": ["sharepoint-read-write"]}]
  }
}
```

Required scope: `Sites.ReadWrite.All` or `Files.ReadWrite.All` for SharePoint access.

---

## Pagination Limitation (OAuth)

With the current `microsoft_api_call` approach, multi-page pagination is not straightforward:
- The `from` field in the search body must be an integer, but template injection in JSON string context sends a string
- Loop body dict injection doesn't reliably pass objects to microsoft_api_call
- Single-call approach (first 500 results, no `from`) works for most use cases

For >500 results: use a service principal approach in Python (which can loop freely), or wait for a native paginated search tool step.

---

## Scope Differences: OAuth vs Service Principal

| | Delegated OAuth | Service Principal |
|---|---|---|
| Search scope | Only content the user can access | All content the app has been granted access to |
| `region` param | NOT supported (400 error) | Supported |
| Token acquisition | Platform manages via OAuth account | Python `requests.post()` to token endpoint |
| Best for | User-scoped agents, named users | Batch processing, cross-tenant access |

### Pattern 4: Upload File to SharePoint

**The key insight:** `microsoft_api_call` body is typed as `object | array` - you cannot send binary file content through it directly. The solution is a two-step pattern using Microsoft's upload session API:

1. `microsoft_api_call` creates an upload session - returns a **pre-signed upload URL** (no auth required)
2. Python downloads the source file and PUTs binary to the pre-signed URL (same as download URL trick)

**Step 1 - `create_upload_session` (microsoft_api_call):**
```json
{
  "transformation": "microsoft_api_call",
  "params": {
    "oauth_account_id": "{{oauth_account_id}}",
    "method": "POST",
    "path": "/v1.0/drives/{{drive_id}}/root:/{{file_path}}:/createUploadSession",
    "body": {
      "item": {
        "@microsoft.graph.conflictBehavior": "{{conflict_behavior}}"
      }
    }
  }
}
```

State mapping: `"upload_url": "steps.create_upload_session.output.response_body.uploadUrl"`

**Important:** Do NOT include a `name` field in the body. Graph API validates that the name in the body matches the filename in the URL path - since `file_path` includes the full path, this always conflicts. Omit `name` entirely.

**Step 2 - Upload binary (python_code_transformation):**
```python
import requests

# upload_url and file_url available directly from state_mapping (no backticks)
if not upload_url:
    return {'status': 'error', 'error': 'No upload URL - check OAuth permissions'}

r = requests.get(file_url, allow_redirects=True, timeout=60)
if r.status_code != 200:
    return {'status': 'error', 'error': f'Download failed: {r.status_code}'}

file_content = r.content
file_size = len(file_content)

headers = {
    'Content-Length': str(file_size),
    'Content-Range': f'bytes 0-{file_size-1}/{file_size}'
}

response = requests.put(upload_url, headers=headers, data=file_content, timeout=120)

if response.status_code in (200, 201):
    item = response.json()
    return {'status': 'success', 'file_id': item.get('id'), 'webUrl': item.get('webUrl'), 'name': item.get('name'), 'size_bytes': file_size}
else:
    return {'status': 'error', 'http_status': response.status_code, 'error': response.text[:500]}
```

**`file_url` sources that work from Modal Labs:**
- SharePoint pre-signed download URLs (from `@microsoft.graph.downloadUrl`) - confirmed working
- Relevance AI temporary file upload URLs - confirmed working
- Public URLs - blocked by some hosts (403/404 common)

**Upload session gotcha - 409 on retry:** If an upload session was created but the source download failed, Microsoft locks that filename for ~24 hours. If agents hit `409 nameAlreadyExists`, they must use a different destination filename or wait. To get a fresh pre-signed download URL from an existing SharePoint file, use `microsoft_api_call` GET item first, then pass `@microsoft.graph.downloadUrl` as the `file_url`.

---

## Testing Checklist

- [ ] Paths include `/v1.0/` prefix
- [ ] No `region` field in search body
- [ ] Python steps use direct variable names (no backticks)
- [ ] Modal Labs timeout >= 60 seconds
- [ ] OAuth account has `sharepoint-read-write` permission type
- [ ] Download URL extracted with `item_data.get('@microsoft.graph.downloadUrl')`
- [ ] Search body built as literal JSON object (not injected dict)
