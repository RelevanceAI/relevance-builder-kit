# Clay Integration

> **Clay** is an enrichment and lead sourcing automation platform. Integrates with Relevance AI via bidirectional webhooks (no native integration).

## Why It Matters

Clay is the most common enrichment platform in enterprise GTM stacks. The integration pattern is webhook-based and bidirectional -- Relevance pushes data to Clay for enrichment, Clay pushes results back to Relevance via custom webhook. This pattern is reusable for any webhook-based integration.

## Architecture

```
Relevance AI Agent
    |
    | POST to Clay webhook (push data for enrichment)
    v
Clay Table (Monitor Webhook)
    |
    | Enrichment columns run (LinkedIn, email, etc.)
    |
    | HTTP API step POSTs enriched data back
    v
Relevance AI Custom Webhook (threaded by conversation_id)
```

## Relevance AI to Clay

### Setup Steps

1. **Create a Clay table** using "Monitor Webhook" as the source
2. **Copy the webhook URL** from the Webhook column > Sources
3. **Optional auth:** Clay provides an auth token under the webhook URL. If the customer wants security, include `x-clay-webhook-auth` header with the token value
4. **Build a Relevance AI tool** that POSTs to the Clay webhook endpoint:

```
POST https://api.clay.com/v3/sources/webhook/pull-in-data-from-a-webhook-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

{
  "first_name": "{{first_name}}",
  "last_name": "{{last_name}}",
  "conversation_id": "{{conversation_id}}"
}
```

5. **Write conversation_id to conversation_metadata** -- specifically `join_field.custom_webhook_thread_id` for threading the return webhook
6. **Test the tool** -- it should create a record in Clay with all values from the body

### Threading

Use `conversation_id` for threading so enriched data returns to the correct agent conversation. If the customer has a separate unique identifier (e.g., email), that can be used instead.

## Clay Field Mapping

After the first webhook fires, Clay needs manual field mapping:

1. Create a column in Clay for each value pushed from Relevance AI
2. Map the webhook variables to those columns
3. Set up additional enrichment columns referencing the mapped fields

This mapping is manual and requires at least one test webhook to have been sent first (Clay needs a sample payload).

## Clay to Relevance AI

### Custom Webhook Setup

1. Create a **Custom Webhook** trigger on the Relevance AI agent:
   - Name and describe the webhook
   - Copy the webhook URL
   - Set input to `{{$}}` (entire payload)
   - Map thread ID to `conversation_id` (or your threading key)
   - Enable work hours if relevant
2. In Clay, add an **HTTP API** column at the end of the enrichment pipeline:
   - Method: POST
   - Endpoint: the Relevance AI webhook URL
   - Body: JSON with enriched fields (ensure double quotes around keys AND variables)

## Common Integrations

| Integration | Trigger | Agent Action | Output |
|------------|---------|-------------|--------|
| Lead enrichment | Agent identifies prospect | Push name/company to Clay | Clay enriches, returns email/phone/LinkedIn to agent |
| Account research | New deal in CRM | Push company domain to Clay | Clay returns firmographics, technographics |
| Contact verification | Before outreach sequence | Push contact details to Clay | Clay validates email, returns updated info |

## Gotchas

- Clay requires a sample webhook payload before field mapping is possible -- always test the push tool first
- Custom webhook threading requires writing `conversation_id` to `join_field.custom_webhook_thread_id` in the tool's conversation_metadata
- Clay enrichment is asynchronous -- the agent should handle the return data in a separate conversation turn triggered by the webhook
- JSON body in Clay's HTTP API step must have double quotes around both keys and variable references

## Related Files

- `playbooks/enrichment-agent-patterns.md` -- Enrichment patterns (tool chains, async webhooks)
- `build-kit/integrations/template.md` -- Integration doc template
