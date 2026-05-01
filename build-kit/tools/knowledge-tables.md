# Knowledge Tables Reference

Complete API reference for knowledge table operations.

> **Important:** All knowledge table endpoints use **flat paths** (`/knowledge/add`, `/knowledge/list`, etc.) with the table name passed as `knowledge_set` in the request body. Do NOT use REST-style paths like `/knowledge/sets/{table}/add` - they will 404.

## Quick Reference

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Create table + insert rows | POST | `/knowledge/add` |
| List rows | POST | `/knowledge/list` |
| Update rows | POST | `/knowledge/bulk_update` |
| Delete row(s) | POST | `/knowledge/delete` |
| **List all tables** | POST | `/knowledge/sets/list` |
| **Get table metadata** | GET | `/knowledge/sets/:name/get_metadata` |
| **Rename / update metadata** | POST | `/knowledge/sets/:name/update_metadata` |
| **Delete entire table** | POST | `/knowledge/sets/delete` |

## Create Table

Tables are created **implicitly** when you add the first row. There is no dedicated create endpoint.

If you need to pre-create an empty table (e.g., from a `relevance_api_call` transformation step), use:

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/sets/upsert",
  body: {
    knowledge_set: "my-table-name",
    type: "table"
  }
})
```

> **Note:** This endpoint works from `relevance_api_call` inside tools, but may not work via `relevance_raw_api`. The reliable way is to just add your first row.

Table names must be lowercase alphanumeric with hyphens or underscores.

## Add Rows

### Single Row

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/add",
  body: {
    knowledge_set: "my-table",
    data: [
      { type: "document", value: { name: "John", email: "john@example.com" } }
    ]
  }
})
```

### Multiple Rows

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/add",
  body: {
    knowledge_set: "my-table",
    data: [
      { type: "document", value: { name: "John", email: "john@example.com" } },
      { type: "document", value: { name: "Jane", email: "jane@example.com" } },
      { type: "document", value: { name: "Bob", email: "bob@example.com" } }
    ]
  }
})
```

Each row is wrapped as `{ type: "document", value: { ... } }`. Each row automatically gets a `document_id` (UUID).

## List Rows

### Basic List

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/list",
  body: {
    knowledge_set: "my-table",
    page_size: 25,
    page: 1
  }
})
```

### With Filters

**Important:** Row data fields are nested under `data`, so filter on `data.fieldname` not `fieldname`.

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/list",
  body: {
    knowledge_set: "my-table",
    page_size: 25,
    page: 1,
    filters: [
      { field: "data.domain", filter_type: "exact_match", condition_value: "acme.com" }
    ]
  }
})
```

### Response Format

Row data is nested under the `data` field:

```json
{
  "results": [
    {
      "document_id": "uuid-1",
      "knowledge_set": "my-table",
      "data": {
        "name": "John",
        "email": "john@example.com"
      },
      "insert_date_": "2025-01-15T10:30:00Z"
    }
  ]
}
```

**Important:** Access fields via `row.data.name`, not `row.name`.

### Pagination

```typescript
// Page 1
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/list",
  body: { knowledge_set: "my-table", page_size: 50, page: 1 }
})

// Page 2
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/list",
  body: { knowledge_set: "my-table", page_size: 50, page: 2 }
})
```

**Critical pagination gotcha -- always fetch all pages before analysing:**

Rows are sorted by `insert_date_` descending (newest first). This means page order shifts every time a new row is written. If you read pages sequentially across multiple MCP calls -- waiting for each response before fetching the next -- new rows inserted mid-read can push records from one page to another, causing contacts to appear on a different page than expected or be skipped entirely.

**Correct pattern:** Fetch ALL pages in a single parallel batch before doing any filtering or analysis.

```python
# Via MCP: fire all pages in one message (parallel tool calls)
# page 1, page 2, page 3, page 4 -- all at once
# Then aggregate and filter in a single bash/python pass across all saved result files

# Via Python in a tool step:
all_rows = []
page = 1
while True:
    result = retrieve_data('my-table', page_size=50, page=page)
    if not result['results']:
        break
    all_rows.extend(result['results'])
    page += 1
```

**When using `relevance_list_knowledge_rows` via MCP:**
- Always check if there is a page 5 (empty results = you've got everything)
- Fire pages 1 to N in parallel in a single message
- Parse all result files together in one Python/bash pass
- Never draw conclusions from a single page -- a table with 200 rows spans 4 pages and specific records can be on any of them

## Update Rows

### Single Row Update

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/bulk_update",
  body: {
    knowledge_set: "my-table",
    updates: [
      {
        document_id: "uuid-1",
        data: { status: "contacted", last_contact: "2025-01-15" }
      }
    ]
  }
})
```

### Multiple Row Update

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/bulk_update",
  body: {
    knowledge_set: "my-table",
    updates: [
      { document_id: "uuid-1", data: { status: "contacted" } },
      { document_id: "uuid-2", data: { status: "qualified" } },
      { document_id: "uuid-3", data: { status: "closed" } }
    ]
  }
})
```

Updates are partial - only specified fields are changed.

## Delete Rows

### Single Row (by document_id)

Use `document_id` (singular string) as a direct body param - **not** via filters:

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/delete",
  body: {
    knowledge_set: "my-table",
    document_id: "uuid-1"   // singular string, NOT document_ids array
  }
})
```

Response: `{}` (empty = success)

### Delete by Filter

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/delete",
  body: {
    knowledge_set: "my-table",
    filters: [
      {
        field: "data.status",
        filter_type: "exact_match",
        condition_value: "archived"
      }
    ]
  }
})
```

### Delete All Rows (clear table without deleting the table itself)

Omit both `document_id` and `filters` to delete all rows:

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/delete",
  body: {
    knowledge_set: "my-table"
  }
})
```

## Field Types

Knowledge tables are schema-less. Common field patterns:

```typescript
{
  // Strings
  name: "John Doe",
  email: "john@example.com",

  // Numbers
  score: 85,
  price: 99.99,

  // Booleans
  is_active: true,

  // Arrays
  tags: ["lead", "enterprise"],

  // Objects
  address: {
    city: "San Francisco",
    state: "CA"
  },

  // Dates (as strings)
  created_at: "2025-01-15T10:30:00Z"
}
```

## Common Patterns

### Upsert Pattern

Check if exists, then add or update:

```typescript
// 1. Try to find existing
const result = await relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/list",
  body: {
    knowledge_set: "contacts",
    page_size: 1,
    filters: [
      { field: "data.email", filter_type: "exact_match", condition_value: "john@example.com" }
    ]
  }
})

// 2. Update or add
if (result.results.length > 0) {
  // Update existing
  await relevance_raw_api({
    method: "POST",
    endpoint: "/knowledge/bulk_update",
    body: {
      knowledge_set: "contacts",
      updates: [{
        document_id: result.results[0].document_id,
        data: { last_seen: new Date().toISOString() }
      }]
    }
  })
} else {
  // Add new
  await relevance_raw_api({
    method: "POST",
    endpoint: "/knowledge/add",
    body: {
      knowledge_set: "contacts",
      data: [{ type: "document", value: { email: "john@example.com", name: "John" } }]
    }
  })
}
```

### Batch Processing

Process large datasets in chunks:

```typescript
const allData = [/* thousands of rows */]
const chunkSize = 50

for (let i = 0; i < allData.length; i += chunkSize) {
  const chunk = allData.slice(i, i + chunkSize)
  await relevance_raw_api({
    method: "POST",
    endpoint: "/knowledge/add",
    body: {
      knowledge_set: "my-table",
      data: chunk.map(row => ({ type: "document", value: row }))
    }
  })
}
```

### Export All Data

Paginate through all rows:

```typescript
let allRows = []
let page = 1
let hasMore = true

while (hasMore) {
  const result = await relevance_raw_api({
    method: "POST",
    endpoint: "/knowledge/list",
    body: { knowledge_set: "my-table", page_size: 100, page: page }
  })

  allRows = allRows.concat(result.results)
  hasMore = result.results.length === 100
  page++
}

console.log(`Exported ${allRows.length} rows`)
```

### Accessing Rows from Python Code Transformations

> **WARNING:** The template variables `{{_api_key}}`, `{{_api_project}}`, `{{_api_region}}` do NOT resolve inside `python_code_transformation` - they return "undefined". Do NOT use raw `requests` calls for knowledge table operations.

**Use built-in helpers** for reads and inserts:

```python
# Read all rows (handles auth + pagination automatically)
rows = retrieve_all('my-table')
for row in rows:
    url = row.get('data', {}).get('url', '')
    doc_id = row.get('document_id', '')

# Read with pagination control
result = retrieve_data('my-table', page_size=50)

# Insert new rows (handles auth automatically)
insert_data('my-table', [{"field1": "value1"}, {"field2": "value2"}])
```

**For updates or complex operations**, use the `relevance_api_call` transformation step (NOT Python). It handles auth automatically:

```json
{
  "name": "update_rows",
  "transformation": "relevance_api_call",
  "params": {
    "path": "/knowledge/bulk_update",
    "method": "POST",
    "body": "{{update_body}}"
  }
}
```

Where `{{update_body}}` resolves from a previous Python step's output via state_mapping. See the "Upsert Pattern" section below for the full multi-step approach.

### Upsert Pattern (Deduplicate by Key Field)

To update existing rows or insert new ones based on a unique key (e.g., `linkedin_url`), use this multi-step tool pattern:

**Step 1: `list_existing`** - `relevance_api_call` to fetch all rows (auth automatic)
```json
{
  "name": "list_existing",
  "transformation": "relevance_api_call",
  "params": {
    "path": "/knowledge/list",
    "method": "POST",
    "body": { "knowledge_set": "my-table", "page_size": 1000 }
  }
}
```

**Step 2: `prepare`** - Python code to split records into updates vs inserts
```python
existing_results = []
try:
    resp = list_existing
    if isinstance(resp, dict):
        existing_results = resp.get('response_body', {}).get('results', [])
except:
    pass

# Build key → document_id map
key_map = {}
for row in existing_results:
    data = row.get('data', {})
    key = data.get('linkedin_url', '')  # your unique key field
    if key:
        normalized = key.strip().lower().rstrip('/')
        doc_id = row.get('document_id')
        if doc_id:
            key_map[normalized] = doc_id

records = record_list if isinstance(record_list, list) else [record_list]
to_insert = []
to_update = []

for rec in records:
    key = rec.get('linkedin_url', '')
    normalized = key.strip().lower().rstrip('/') if key else ''
    if key:
        rec['linkedin_url'] = normalized
    doc_id = key_map.get(normalized)
    if doc_id:
        to_update.append({'document_id': doc_id, 'data': rec})
    else:
        to_insert.append(rec)

update_body = {'knowledge_set': 'my-table', 'updates': to_update}
insert_body = {'knowledge_set': 'my-table', 'data': [{'type': 'document', 'value': r} for r in to_insert]}

return {'update_body': update_body, 'insert_body': insert_body,
        'num_updates': len(to_update), 'num_inserts': len(to_insert)}
```

**Step 3: `do_updates`** - `relevance_api_call` to update existing rows
```json
{ "path": "/knowledge/bulk_update", "method": "POST", "body": "{{update_body}}" }
```

**Step 4: `do_inserts`** - `relevance_api_call` to insert new rows
```json
{ "path": "/knowledge/add", "method": "POST", "body": "{{insert_body}}" }
```

**State mapping:**
```json
{
  "record_list": "params.record_list",
  "list_existing": "steps.list_existing.output",
  "prepare": "steps.prepare.output.result",
  "update_body": "steps.prepare.output.result.update_body",
  "insert_body": "steps.prepare.output.result.insert_body",
  "do_updates": "steps.do_updates.output",
  "do_inserts": "steps.do_inserts.output"
}
```

## Table Management Operations

### List All Tables

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/sets/list",
  body: { page_size: 50 }
})
```

### Get Table Metadata

```typescript
relevance_raw_api({
  method: "GET",
  endpoint: "/knowledge/sets/my-table/get_metadata"
})
```

Returns `metadata` with `knowledge_set`, `display_name`, `description`, `field_metadata`.

### Rename a Table (set display_name)

The internal slug (`knowledge_set`) is **immutable**. Set a user-facing display name:

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/sets/my-table/update_metadata",
  body: {
    updates: {
      display_name: "Team Directory",
      description: "Optional description"
    }
  }
})
```

Response: `{}` (empty = success)

Other metadata you can update: `model` (embedding model), `field_metadata` (per-field config), `table_metadata` (tool column config).

To remove a column from all rows:
```json
{ "updates": {}, "fields_to_remove": ["old_column"] }
```

### Delete Entire Table

```typescript
relevance_raw_api({
  method: "POST",
  endpoint: "/knowledge/sets/delete",
  body: { knowledge_set: "my-table" }
})
```

Delete multiple tables: `"knowledge_set": ["table-1", "table-2"]`

**This is different from `/knowledge/delete` which deletes rows, not the table.**

---

## Filter Types Reference

There are TWO filter formats, and they are NOT interchangeable. Pick the one that matches where you're running the filter.

### Format A -- Raw API endpoints (`filters` param)

Use this for every raw API call (`/knowledge/list`, `/knowledge/delete`, `/knowledge/update` via `relevance_api_request`, the Python sandbox `retrieve_data()` helper, etc.). The verbose shape:

```json
{
  "field": "data.fieldname",
  "filter_type": "exact_match",
  "condition_value": "value",
  "condition": "==",
  "case_insensitive": false
}
```

Wrapped in the request body as `"filters": [ ... ]`.

**Always use `data.fieldname` prefix for row data fields** (e.g. `data.email`, `data.status`).

| filter_type | Description | condition_value example |
|-------------|-------------|------------------------|
| `exact_match` | Exact value | `"Charlie Brooks"` |
| `ids` | Match array of document IDs | `["id1", "id2"]` |
| `exists` | Field exists or not | `true` or `false` |
| `regexp` | Regex match | `".*@gmail\\.com$"` |
| `ilike` | Case-insensitive LIKE | `"new%"` |
| `numeric` | Numeric comparison | `18` (with `"condition": ">"`) |
| `date` | Date comparison | `"2026-01-01"` (with `"condition": ">="`) |
| `or` | OR of sub-filters | Array of filter objects |
| `and` | AND of sub-filters | Array of filter objects |

### Format B -- Native transformation steps (`raw_filters` param)

Use this for tool steps of type `retrieve_data`, `update_knowledge_set_rows`, and any other native transformation that takes a `raw_filters` field. The shape is a **simple dict** where the KEY is the dotted field path and the VALUE is the exact match:

```json
"raw_filters": [{"data.id": "{{unique_key}}"}]
```

Template substitution works inside this shape. Multiple dict elements in the array are combined per the step's top-level `filter_type` param (`"and"` / `"or"`).

**Critical:** if you paste the Format A shape (`{field, filter_type, condition_value}`) into a native step's `raw_filters`, the step **silently returns 0 matches** regardless of whether rows exist. There is no error. The filter is just ignored / treated as non-matching. `condition` and `filter_type` keys on the filter element are ignored -- only the simple-dict key-value pair is read.

**Empty-string values are a strict match on empty, NOT "skip filter".** `[{"data.run_id": ""}]` matches rows where `data.run_id` is literally `""`. You cannot use empty strings to conditionally disable a filter -- split into two single-purpose tools or pre-construct the filter array in a prior step.

Example native step using the correct format:

```json
{
  "transformation": "retrieve_data",
  "params": {
    "knowledge_set": "{{knowledge_table}}",
    "filter_type": "and",
    "raw_filters": [{"data.id": "{{unique_key}}"}],
    "page_size": 1
  }
}
```

Cross-reference: `.claude/rules/PLATFORM_MECHANICS.md` "Knowledge Filter Syntax in Native Steps".

---

## MCP Tool Limitations (`relevance_list_knowledge_rows`)

The `relevance_list_knowledge_rows` MCP tool has no filter parameter -- it only supports `table_name`, `page`, and `page_size`. To filter rows via MCP, use `relevance_api_request` with the flat `/knowledge/list` endpoint and `filters` in the body (see "With Filters" above). Do NOT use REST-style paths like `/knowledge/sets/{name}/list` -- they return 404.

**This is the fastest way to find specific rows in a large table.** Instead of paginating through all pages looking for contacts by account name, one filtered API call returns exactly what you need:

```
relevance_api_request({
  method: "POST",
  endpoint: "/knowledge/list",
  body: {
    knowledge_set: "aws_contacts",
    filters: [{ field: "data.account_name", filter_type: "exact_match", condition_value: "Tapestry Inc." }],
    page_size: 20
  }
})
```

Always try filtered `/knowledge/list` via `relevance_api_request` before falling back to paginated `relevance_list_knowledge_rows`.

**Page size:** Keep `page_size` at 10 or below when using `relevance_list_knowledge_rows` via MCP Claude Code. Larger sizes (e.g. 50) produce results that exceed the inline token limit, get saved to disk, and require additional bash steps to parse.

**`row_count` is unreliable:** `relevance_get_knowledge_table_info` returns a `row_count` field that does not accurately reflect the number of documents in the table. Do not use it to assess table size -- paginate through `list_knowledge_rows` until you get an empty page to confirm you've seen all rows.

---

## Key Gotchas

1. **Native step filter format is different from raw API filter format.** Native transformations (`retrieve_data`, `update_knowledge_set_rows`) take `raw_filters` in simple-dict shape `[{"data.field": "value"}]`. Raw API calls (`/knowledge/list`) take `filters` in verbose shape `[{field, filter_type, condition_value}]`. Mixing shapes silently returns 0 matches. See "Filter Types Reference" above and `.claude/rules/PLATFORM_MECHANICS.md` "Knowledge Filter Syntax in Native Steps".

2. **`ilike` and `regexp` filters may silently return empty results** - On knowledge tables with default field mappings, `ilike` and `regexp` filter_types often fail (return `[]`) even when data exists. `exact_match` works reliably. If you need fuzzy/partial matching, fetch all rows and filter in JS instead.

2. **`type: "document"` not `type: "text"`** - `text` stores everything as a single string. `document` creates proper columns.

2. **`document_id` (singular) not `document_ids` (plural)** - `/knowledge/delete` body param is `document_id` as a string.

3. **`/knowledge/delete` vs `/knowledge/sets/delete`** - rows vs entire table.

4. **Filter fields need `data.` prefix** - Filter on `data.name` not `name`.

5. **Rename uses `display_name`** - The internal slug is immutable. Only the UI display name can be changed.

6. **Delete can race with vectorization** - If you update then immediately delete a row, the vectorization job may re-create it. Wait a moment or delete again if the row reappears.

7. **Vectorization is async** - After insert/update, rows may not be searchable via semantic search until the background vectorization job completes.

---

## Tips

1. **Use descriptive table names** - `sales-leads` not `table1`
2. **Include timestamps** - Add `created_at`, `updated_at` fields
3. **Use consistent field names** - Stick to snake_case or camelCase
4. **Store IDs as strings** - For cross-referencing tables
5. **Batch large operations** - 50 rows per batch is a safe limit
6. **Remember data nesting** - Response rows have fields under `.data`, not at top level
7. **Use flat endpoints** - `/knowledge/add` not `/knowledge/sets/{table}/add`
