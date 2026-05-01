# HubSpot Integration

> **HubSpot** is a CRM platform with contacts, companies, deals, and tickets. Integrates via REST API (OAuth or private app token). Supports webhooks for real-time triggers.

## Why It Matters

HubSpot is the **most common CRM** in Relevance AI engagements. Most builds touch HubSpot at some point.

> **Production vs demo:** Production reliability means proper error handling for API rate limits, field validation before writes, and audit trails on every CRM update.

## Common Integrations

| Integration | Trigger | What It Does | Key API |
|------------|---------|-------------|---------|
| Contact Management | Webhook: contact created | Enrich, score, route to rep | Contacts API |
| Email Tracking | Schedule: check emails | Summarize threads, detect sentiment | Engagements API |
| Webhook Triggers | HubSpot workflow | Fire agent on CRM events | Webhooks API |
| Deal Pipeline | Webhook: stage change | Update forecast, notify team | Deals API |
| Custom Properties | Agent action | Write results back to CRM | Properties API |
| Notes & Activities | Agent action | Log agent actions for audit trail | Engagements API |



  ## Triggering Relevance AI Workforces

While Relevance AI has native agent triggers in HubSpot, **workforces must be triggered using custom code** in HubSpot workflows.

javascript
// HubSpot Custom Code Action
import os
import json
import requests

def main(event):
    auth_token = os.environ.get("auth_token")
    
    REGION = "<your-region-code>"  # Your Relevance AI region (find in your project settings)
    WORKFORCE_ID = "<your-workforce-id>"  # Your workforce ID
    
    url = f"https://api-{REGION}.stack.tryrelevance.com/latest/workforce/trigger"
    
    # Extract form data from HubSpot event
    first_name = event.get("inputFields").get("firstname", "")
    last_name = event.get("inputFields").get("lastname", "")
    email = event.get("inputFields").get("email", "")
    company_name = event.get("inputFields").get("company", "")
    job_title = event.get("inputFields").get("jobtitle", "")
    business_challenge = event.get("inputFields").get("what_would_you_like_to_do_with_relevance_ai", "")
    
    # Format message for workforce
    message = f"""# Triggered by HubSpot

A new person has just submitted a demo form with the following details. Now go and research about a prospect using the 'Book demo enrichment' agent and let it do the enrichment:

**First Name:** {first_name}

**Last Name:** {last_name}

**Email address:** {email}

**Company Name:** {company_name}

**Job title:** {job_title}

**What would you like to do with Relevance AI?** {business_challenge}"""
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": auth_token,
    }
    
    payload = {
        "workforce_id": WORKFORCE_ID,
        "trigger": {
            "message": {
                "role": "user",
                "content": message,
            }
        },
    }
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    return {"outputFields": {"status": response.status_code, "body": response.text}}


**Required Environment Variables:**
- `auth_token`: Your Relevance AI authentication token
- Set `REGION` and `WORKFORCE_ID` as constants in your code

**Key Points:**
- Use `event.get("inputFields").get("field_name", "")` to access HubSpot form data
- Structure the trigger message with role and content
- Handle errors gracefully for production reliability
- The workforce API endpoint follows the pattern: `https://api-{REGION}.stack.tryrelevance.com/latest/workforce/trigger`
## Advanced Mode

### Authentication Options

| Method | Use Case | Setup |
|--------|----------|-------|
| **OAuth** (Recommended) | Production integrations | Connect in Relevance project settings |
| **Private App Token** | Dev/testing | Store as secret: `hubspot_api_key` |

**Base URL:** `https://api.hubapi.com`

### Python: Contact Management

```python
import requests

HUBSPOT_TOKEN = "your-token"
HEADERS = {
    "Authorization": f"Bearer {HUBSPOT_TOKEN}",
    "Content-Type": "application/json"
}

# Search contact by email
def get_contact(email: str):
    return requests.post(
        "https://api.hubapi.com/crm/v3/objects/contacts/search",
        headers=HEADERS,
        json={"filterGroups": [{"filters": [{
            "propertyName": "email",
            "operator": "EQ",
            "value": email
        }]}]}
    ).json()

# Update contact
def update_contact(contact_id: str, properties: dict):
    return requests.patch(
        f"https://api.hubapi.com/crm/v3/objects/contacts/{contact_id}",
        headers=HEADERS,
        json={"properties": properties}
    ).json()
```

### Python: Deal Pipeline

```python
def get_deals_by_stage(stage: str, limit: int = 100):
    return requests.post(
        "https://api.hubapi.com/crm/v3/objects/deals/search",
        headers=HEADERS,
        json={
            "filterGroups": [{"filters": [{
                "propertyName": "dealstage",
                "operator": "EQ",
                "value": stage
            }]}],
            "limit": limit,
            "properties": ["dealname", "amount", "closedate"]
        }
    ).json()

def update_deal_stage(deal_id: str, new_stage: str, reason: str = ""):
    properties = {"dealstage": new_stage}
    if reason:
        properties["stage_change_reason"] = reason
    return requests.patch(
        f"https://api.hubapi.com/crm/v3/objects/deals/{deal_id}",
        headers=HEADERS,
        json={"properties": properties}
    ).json()
```

### Python: Audit Trail (Notes)

```python
import time

def log_agent_action(contact_id, agent_name, action, details):
    note_body = f"**Agent: {agent_name}**\n\nAction: {action}\n\nDetails:\n{details}"
    return requests.post(
        "https://api.hubapi.com/crm/v3/objects/notes",
        headers=HEADERS,
        json={
            "properties": {
                "hs_note_body": note_body,
                "hs_timestamp": str(int(time.time() * 1000))
            },
            "associations": [{
                "to": {"id": contact_id},
                "types": [{"associationCategory": "HUBSPOT_DEFINED", "associationTypeId": 202}]
            }]
        }
    ).json()
```

## Production Considerations

### Rate Limits
- 100 req/10s (private apps)
- 150 req/10s (OAuth)
- Use unit of action pattern
- Add retry for 429 responses

### Field Validation
- Check required fields exist
- Validate email format
- Verify deal stage values
- Check property exists before write

### Audit Trail
- Create custom properties (once)
- Write HubSpot note per change
- Include: agent, action, reason, timestamp

## 5-Minute Quick Start

1. **Get token**: HubSpot -> Private Apps -> Create -> Copy access token
2. **Add as secret**: `hubspot_api_key`
3. **Search**: `relevance_search_transformations({ query: "hubspot" })` (20+ available!)
4. **Wrap**: `relevance_create_tool_from_transformation({ transformationId: "hubspot_search_contacts" })`
5. **Test**: `relevance_trigger_tool({ studioId: "...", params: { email: "test@example.com" } })`
6. **Attach to agent** and test end-to-end

## Glossary

| Term | Definition |
|------|-----------|
| Object | CRM entity type: Contact, Company, Deal, Ticket, or Custom Object |
| Property | A field on an object (e.g., `email`, `dealstage`, `amount`) |
| Association | Relationship between objects (e.g., Contact <-> Deal) |
| Pipeline | Sequence of stages (e.g., Prospect -> Qualified -> Closed Won) |
| Engagement | Activity record: email, call, meeting, note, task |
| Workflow | HubSpot automation -- can trigger webhooks for Relevance agents |
