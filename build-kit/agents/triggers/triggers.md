# Agent Triggers

How an agent receives work. The trigger feeds the agent's Unit of Action -- one record, one event, one message at a time. Choosing the right trigger pattern matters more than choosing the right trigger type.

---

## Two Patterns: Event-Driven vs Recurring

### Event-driven (push)

Fires when something happens in an external system. The system pushes the event to Relevance AI; the agent runs immediately.

| Trigger             | Event source                                    | Unit of Action          |
|---------------------|-------------------------------------------------|-------------------------|
| `gmail` / `outlook` | Incoming email                                  | One email               |
| `slack`             | Slack message in connected channel              | One message / thread    |
| `teams`             | Teams channel message                           | One message             |
| `unipile_linkedin`  | LinkedIn DM                                     | One conversation        |
| `unipile_whatsapp`  | WhatsApp message                                | One message             |
| `unipile_telegram`  | Telegram message                                | One message             |
| `google_calendar`   | Calendar event (with offset)                    | One meeting             |
| `webhook`           | Plain HTTP POST                                 | One request             |
| `custom_webhook`    | HTTP POST with message-template + field mapping | One record with payload |

**Strengths:** immediate, efficient (only runs when work exists), naturally one-entity-per-task.
**Watch out for:** requires admin access in the source system to configure. Webhook triggers depend on the upstream system staying healthy.

### Recurring (pull / scheduled)

Fires on a timer. Right choice for time-based work and for situations where event-driven isn't available.

**Frequency options:**

| Frequency      | Required fields                            | Notes                            |
|----------------|--------------------------------------------|----------------------------------|
| `minutely`     | `minute_interval` (`10`, `15`, `30`, `45`) | Min interval is 10 min           |
| `hourly`       | `hour_interval`                            |                                  |
| `daily`        | `hour` (`HH:mm`)                           |                                  |
| `weekly`       | `hour`, `day_of_week` (`mon`...`sun`)      |                                  |
| `monthly`      | `hour`, `day_of_month`                     |                                  |
| `annually`     | `hour`, `day_of_month`, `month`            |                                  |
| `no_repeat`    | `hour`, `date`                             | One-time future execution        |
| `custom_cron`  | `cron_expression`                          | AWS EventBridge cron format      |

`hour` is required even for sub-hourly frequencies. `timezone` is optional but recommended (defaults UTC).

**Good fits:** periodic reports, monitoring / health checks, batch processing of a source that has no webhooks (e.g. polling a Google Sheet for new rows), digest / rollup tasks, data sync from legacy systems.

**Watch out for:** runs even when there's no new work. Scanning agents have to manage their own deduplication and error recovery.

---

## Decision Guide

```
Is this time-based work (reports, digests, monitoring)?
  YES  → Recurring trigger
  NO   → Does the source system support webhooks or integrations?
           YES        → Event-driven trigger (webhook, email, Slack, etc.)
           PARTIALLY  → Use Zapier / Make / n8n to bridge into a custom_webhook
           NO         → Recurring trigger that polls
```

> **Tip:** if a recurring trigger ends up scanning for individual entities and acting on each, see if the source can push them instead. Event-driven gives you one-entity-per-task naturally.

---

## `webhook` vs `custom_webhook`

Use `custom_webhook` for almost everything -- Zapier, Make, n8n, CRM workflows, any system where the payload doesn't already match what you want the agent to see.

| Feature                                             | `webhook` | `custom_webhook` |
|-----------------------------------------------------|-----------|------------------|
| Endpoint URL provided                               | Yes       | Yes              |
| Configurable display name / description             | No        | Yes              |
| `message_template` to shape the agent's first input | No        | Yes              |
| `mapping.unique_id` for idempotency                 | No        | Yes              |
| `mapping.thread_id` for conversation threading      | No        | Yes              |

`message_template` is a mustache-style template:
- `{{$}}` passes the entire payload
- `{{field_name}}` extracts a top-level field
- jq-style paths (`{{.data.lead.email}}`) work via the `mapping` object for deduplication / threading

Use plain `webhook` only when the upstream is fully under your control and you don't need any transformation.

---

## Configuration Reference (by trigger type)

All triggers are created via `relevance_create_trigger({ agent_id, trigger_type, trigger_config })`. Configs below are the `trigger_config` shapes.

### Email (gmail / outlook)

```json
{
  "oauth_account_id": "<oauth-uuid>",
  "oauth_account_label": "Work Gmail"
}
```

Find OAuth IDs via `relevance_list_oauth_accounts()`. Filter by `provider`.

### Slack

```json
{
  "oauth_account_id": "<slack-oauth-uuid>",
  "channels": ["C07AGHNGV9Q"],
  "keywords": { "values": ["help", "support"], "config": { "case_sensitive": false } },
  "user_ids": [],
  "thread_reply_mode": "auto",
  "should_mention_bot": true
}
```

- `channels` requires Slack channel **IDs** (`C...`), not names. Use `relevance_list_slack_channels({ oauth_account_id })` to look up.
- `should_mention_bot: false` means respond to every message (loud, usually wrong).
- `keywords` is optional; omit or `{ values: [] }` to match all messages.
- `thread_reply_mode: "auto"` replies in-thread; `"none"` posts a new top-level message.

### Teams

```json
{
  "oauth_account_id": "<teams-oauth-uuid>",
  "tenant_id": "<microsoft-tenant-id>",
  "channels": [],
  "keywords": { "values": [], "config": { "case_sensitive": false } },
  "excluded_keywords": [],
  "thread_reply_mode": "auto",
  "should_mention_bot": true
}
```

### LinkedIn / WhatsApp / Telegram (Unipile)

```json
{
  "oauth_account_id": "<unipile-oauth-uuid>",
  "provider_user_id": "<provider-user-id>",
  "is_outreach_reply_only": false
}
```

- Unipile triggers also need `provider_user_id` from the OAuth account record.
- `is_outreach_reply_only: true` filters to only respond to inbound replies on outbound campaigns.

### Google Calendar

```json
{
  "oauth_account_id": "<google-oauth-uuid>",
  "calendar_id": "primary",
  "events": {
    "notifications": [
      {
        "timeOffset": { "quantity": 10, "unit": "minutes", "direction": "before" },
        "message": { "type": "raw" }
      }
    ]
  }
}
```

`timeOffset.direction` is `"before"` or `"after"`. Multiple notifications are allowed (e.g. one 24h before for prep, one 5 min before for joining).

### Custom webhook

```json
{
  "webhook_name": "Zapier Webhook",
  "webhook_description": "Receives form submissions",
  "message_template": "{{$}}",
  "mapping": {
    "unique_id": ".data.id",
    "thread_id": ".data.thread_id"
  }
}
```

Trigger creation returns a webhook URL. POST any JSON to it; `message_template` shapes the agent's first message.

### Recurring

```json
{
  "name": "Daily Report",
  "message": "Generate the daily sales report",
  "schedule": {
    "frequency": "daily",
    "hour": "09:00",
    "timezone": "America/New_York"
  }
}
```

`message` is the literal first message the agent sees on every run. Make it imperative ("Generate X") and self-contained -- the agent has no context beyond this.

---

## MCP Operations

```typescript
relevance_list_oauth_accounts()                          // find OAuth IDs
relevance_list_slack_channels({ oauth_account_id })      // resolve channel names → IDs
relevance_list_agent_triggers({ agent_id })              // see existing triggers
relevance_create_trigger({ agent_id, trigger_type, trigger_config })
relevance_delete_trigger({ document_id })                // get document_id from list_agent_triggers
```

Triggers are identified by `document_id`, which comes from `relevance_list_agent_triggers`. For some types it's a deterministic string (`agent_-_<agent_id>_-_<type>_-_<sub-id>`); for webhook/slack-style triggers it's a UUID.

---

## Gotchas

- **Slack channel IDs are not names.** `slack_retrieve_message` and the Slack trigger both want `C...` IDs. Tools that resolve names work for public channels only -- private (`G...`) and DMs (`D...`) need explicit IDs.
- **Recurring `hour` is required** even for `minutely` and `hourly` frequencies. The platform validates the field; `09:00` is a safe default if the value is irrelevant.
- **`custom_webhook` `unique_id` enables idempotency.** If the same upstream event fires twice with the same `unique_id`, the second run is suppressed. Use this when integrating with at-least-once delivery systems (Zapier retries, CRM workflow re-fires).
- **`message` for recurring triggers is the entire first input.** It is not a label. The agent must be able to act on this string alone -- no implicit context.
- **The trigger payload is the agent's first message.** Anything not in `message_template` won't reach the agent. Map every field the agent needs to reason about.
- **`__conversation_id`, `__mas_id`, `__mas_store_id` are not set by triggers** -- they're injected at runtime by the agent runner. To use them in tools, declare them in `params_schema` per `.claude/rules/PLATFORM_MECHANICS.md` § "Platform-Injected System Variables".

---

## See Also

- `build-kit/agents/CLAUDE.md` -- agents hub
- `.claude/rules/PLATFORM_MECHANICS.md` § "Triggers & Inputs" -- platform-wide trigger semantics
- `.claude/rules/PLATFORM_MECHANICS.md` § "Phantom Tools: Never Persist in Actions" -- the `create_scheduled_trigger` phantom tool as API documentation
- `build-kit/integrations/slack.md` -- Slack channel ID lookup, prefix table
- `build-kit/integrations/hubspot.md` / `salesforce.md` / etc. -- CRM-specific webhook setups
