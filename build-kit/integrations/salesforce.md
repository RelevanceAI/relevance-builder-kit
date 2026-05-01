# Salesforce Integration

> **Salesforce** is the most common enterprise CRM. Integrates with Relevance AI via native OAuth integration with SOQL-based triggers.

## Why It Matters

Salesforce is the most-used CRM integration for enterprise customers. Agents typically read/write Leads, Contacts, Accounts, and Deals. The integration uses native OAuth (not Pipedream) and SOQL triggers for event-driven workflows.

## Core Concepts

Salesforce is a database management tool with specific terminology:

| Salesforce Term | General Equivalent |
|----------------|-------------------|
| Object | Table |
| Field | Column |
| Record | Row |
| SOQL | SQL variant for Salesforce |

Record IDs are globally unique. The first 3 characters indicate the object type (e.g., `00Q` = Lead). This is useful when building generic API tools that need to determine which object endpoint to call.

## Authentication

### Requirements

The customer needs a Salesforce account with **API access enabled**:

1. Navigate to: Cog > Setup > Profiles
2. Assign a profile with **Administrative Permissions > API Enabled**
3. If "API Enabled" is not available, confirm the Salesforce plan includes API access (not all editions do)
4. Authenticate the account in Relevance AI: Integrations > Salesforce > + Integration

### Testing Access

Use the Salesforce String Search tool step to verify the account can make API calls. If the API step runs correctly, the account has correct permissions.

## Triggers (SOQL-Based)

### Setup

Configure via: Edit Agent > Agent profile > Salesforce

After authenticating, configure:

1. **SOQL Query** -- determines which records trigger the agent:

```sql
SELECT Id, FirstName, LastName, Email
FROM Lead
WHERE Id LIKE '00Q%'
```

The trigger polls Salesforce at the sync interval, checking for records with the latest `SystemModStamp`. This means both created AND updated records trigger the agent (any modification counts).

2. **Task creation mode** -- choose between creating new tasks or appending to existing tasks. You can set up multiple triggers with the same auth but different SOQLs and different task creation modes.

3. **Deduplication field** -- prevents the same record from triggering twice. If set to `Email`, a previously triggered email will not trigger again. Defaults to `Id` if not set.

4. **Sync interval** -- Minutely, Hourly, or Daily.

### SOQL Gotchas

- SOQL triggers do not handle extra spaces/newlines well. If the query works in a tool step but not the trigger, trim whitespace.
- Always test your SOQL in the Salesforce SOQL Query tool step before using it as a trigger.
- SOQL is case-insensitive for keywords but case-sensitive for field names in some contexts.

## Client Onboarding Checklist

### Authentication
- [ ] Authenticate an API-enabled Salesforce account into Relevance AI

### Fields
- [ ] Internal names of all fields to feed into the agent
- [ ] Internal names of all fields the agent should update
- [ ] All dropdown fields and their valid values
- [ ] Create tracking fields:
  - `relevance_outreach__c` (true/false) -- agent marks true when sending outreach
  - `relevance_stop__c` (true/false) -- agent checks before sending; if true, stop the sequence
  - `relevance_outreach_date__c` -- timestamp of last outreach

### Notes Format
Ask which format they want agent research stored as:
- Chatter Notes
- ContentNote
- Note Field
- Task

### Objects
Confirm which objects the agent should read/write:
- Lead (most common)
- Contact
- Account
- Custom Objects (less common)

## Common Integrations

| Integration | Trigger | Agent Action | Output |
|------------|---------|-------------|--------|
| Lead qualification | SOQL trigger on new/updated Lead | Research + enrich lead | Update Lead fields, add notes |
| Deal tracking | SOQL trigger on Deal stage change | Pull context, prepare briefing | Update Deal notes, notify team |
| Contact enrichment | SOQL trigger on new Contact | Enrich via ZoomInfo/Clay | Update Contact fields |
| Outbound sequencing | SOQL trigger on qualified Lead | Research, generate messages | Push to Outreach/SalesLoft |

## Gotchas

- Salesforce expects UNIX timestamps in **milliseconds** (not seconds) -- use the date parser tool, never hand-calculate
- Record IDs have object-type prefixes (first 3 chars) -- useful for routing in generic API tools
- Multiple triggers with different SOQLs can run against the same auth account
- The common flow is: Lead Updated/Created > Relevance > Outreach Email > Update fields > Update Notes
- Some Salesforce editions do not include API access -- verify before onboarding

## Related Files

- `build-kit/integrations/outreach.md` -- Outreach.io (common downstream from Salesforce)
- `build-kit/integrations/salesloft.md` -- SalesLoft (alternative to Outreach)
- `build-kit/integrations/zoominfo.md` -- ZoomInfo enrichment
- `build-kit/patterns/crm-knowledge-architecture.md` -- CRM knowledge architecture patterns
