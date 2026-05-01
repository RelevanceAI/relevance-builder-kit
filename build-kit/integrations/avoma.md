# Avoma Integration

> **Avoma** is a conversation intelligence platform that records, transcribes, and analyzes sales/customer calls. It extracts action items, key topics, and sentiment automatically. Integrates with Relevance AI via REST API (API key auth).

## Why It Matters

Call action items are the **highest-signal input** for agent automation. When a rep finishes a call, Avoma generates structured data that agents can immediately act on -- updating CRM records, scheduling follow-ups, creating tasks, or triggering workflows.

**Without Avoma:** Most teams rely on reps manually entering data.
**With Avoma:** Data flows automatically from **call -> agent -> action**.

## Common Integrations

| Integration | Trigger | Agent Action | Output |
|------------|---------|-------------|--------|
| Post-call CRM update | Call ends -> webhook | Extract action items, match to contact | CRM record updated |
| Pre-call context | Meeting scheduled | Fetch last call summary + deal status | Briefing sent to Slack |
| Call quality scoring | Call ends -> webhook | Analyze transcript for methodology | Score + coaching notes |
| Health signals | Call ends -> webhook | Detect churn risk, competitor mentions | Alert to CS team |
| Action item routing | Call ends -> webhook | Parse items, assign to team member | Tasks created |

## Advanced Mode

### API Authentication

Avoma uses API key authentication. Store as a Relevance secret:
- **Secret name:** `avoma_api_key`
- **Usage in tools:** `{{secrets.avoma_api_key}}`
- **Base URL:** `https://api.avoma.com/v1`

### Key API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/conversations` | GET | List recent conversations |
| `/conversations/{id}` | GET | Get conversation with transcript |
| `/conversations/{id}/action-items` | GET | Get action items from a call |
| `/conversations/{id}/notes` | GET | Get AI-generated notes |
| `/webhooks` | POST | Register webhook for call events |

### Building the Tool in Relevance

```typescript
relevance_upsert_tool({
  title: "Get Avoma Action Items",
  description: "Fetches action items from the most recent Avoma call",
  params_schema: {
    type: "object",
    properties: {
      contact_email: {
        type: "string",
        title: "Contact Email"
      }
    },
    required: ["contact_email"]
  },
  transformations: {
    steps: [
      {
        name: "documentation",
        transformation: "note",
        params: {
          note: "# Get Avoma Action Items\n\n## Input\n- contact_email (required)"
        }
      },
      {
        name: "fetch_calls",
        transformation: "api_call",
        params: {
          url: "https://api.avoma.com/v1/conversations?participant_email={{contact_email}}&limit=1",
          method: "GET",
          headers: {
            "Authorization": "Bearer {{secrets.avoma_api_key}}"
          }
        }
      }
    ]
  }
})
```

### Python Alternative (Local Testing)

```python
import requests

AVOMA_API_KEY = "your-key"
BASE_URL = "https://api.avoma.com/v1"

def get_action_items(contact_email: str):
    headers = {
        "Authorization": f"Bearer {AVOMA_API_KEY}",
        "Content-Type": "application/json"
    }
    resp = requests.get(
        f"{BASE_URL}/conversations",
        headers=headers,
        params={"participant_email": contact_email, "limit": 1}
    )
    conversations = resp.json()
    if not conversations:
        return {"action_items": [], "message": "No calls found"}
    call_id = conversations[0]["id"]
    items = requests.get(
        f"{BASE_URL}/conversations/{call_id}/action-items",
        headers=headers
    )
    return {"action_items": items.json(), "call_id": call_id}
```

## 5-Minute Quick Start

1. **Get API key** from Avoma Settings -> Integrations -> API
2. **Add as secret**: `avoma_api_key`
3. **Search existing tools**: `relevance_search_transformations({ query: "avoma" })`
4. **If found** -> wrap with `relevance_create_tool_from_transformation`
5. **If not found** -> build manually using the config above
6. **Test**: `relevance_trigger_tool({ studioId: "...", params: { contact_email: "test@example.com" } })`
7. **Attach to agent** and test end-to-end

## Glossary

| Term | Definition |
|------|-----------|
| Conversation | A recorded and transcribed call in Avoma |
| Action Item | A task or follow-up extracted from a call by Avoma's AI |
| Smart Note | Avoma's auto-generated structured summary of a call |
| Coaching Score | Assessment of call quality based on configurable criteria |
| Snippet | A highlighted segment of a call transcript |
