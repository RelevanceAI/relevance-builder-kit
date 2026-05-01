# SalesLoft Integration

> **SalesLoft** is an email sequencing and sales engagement platform. Integrates with Relevance AI via API key authentication. The primary alternative to Outreach.io for enterprise outbound.

## Why It Matters

SalesLoft integrations are rarely out-of-the-box. Clients have internal automations (Plays), custom fields, sync logic, and team structures that require a discovery session before the first tool is built. Plan a 45-60 min joint session with the customer's SalesLoft admin to scope cadences, custom fields, and permissions.

The two highest-leverage things to know before any SalesLoft build:

1. **Native Relevance tool steps exist for SalesLoft** -- prefer them over raw API calls (see Building Tools in Relevance below).
2. **Use SalesLoft as the source of truth for ownership** when possible -- writing `owner_crm_id` on the SalesLoft Person record skips the wait for Salesforce sync (see Sync Patterns below).

## Key Concepts

### Cadences

Equivalent to Outreach sequences. A series of steps (emails, calls, LinkedIn) that prospects are enrolled in.

- **Team cadences** -- shared, assigned to a group. **Required for API enrollment.**
- **Personal cadences** -- individual. The "Create a cadence membership" API endpoint will fail against personal cadences.

### Plays

In-platform automations that can trigger cadence enrollment, data syncs, or field updates.

- **Plays cannot be created from scratch.** They must be cloned from a template and customized.
- Existing customer Plays can interfere with Relevance flows (auto-enrollment, status changes on cadence activity, owner reassignment). Always review existing Plays during onboarding.
- Plays can also be used as a workaround for CRM sync delay (see Sync Patterns).

### Rhythm

The front page for BDRs and sales leaders. Shows prioritized actions and tasks. Not directly involved in API integration but useful context for explaining where reps will see Relevance-generated content.

### Custom Fields

Where Relevance writes AI-generated content. Created by the customer's SalesLoft admin under `Settings -> Data -> Field configuration`. Field type: **Text**. Default value: blank.

**Recommended naming convention** (use this on every SalesLoft build for consistency across customers):

```
Relv_General_Email_1
Relv_General_Email_2
Relv_General_Email_3
Relv_General_Email_4
Relv_General_Email_5

Relv_General_Subject_1
Relv_General_Subject_2
Relv_General_Subject_3
Relv_General_Subject_4
Relv_General_Subject_5

Relv_General_CallNotes_1

Relv_General_LinkedIn_1
```

Cadence templates then reference these fields via Liquid, e.g. `Subject: {{Relv_General_Subject_1}}`, `Body: {{Relv_General_Email_1}}`.

## Authentication

SalesLoft uses **API key authentication**. Two paths:

1. **Service account / dedicated integration user** (recommended) -- create `relevance.integration@yourcompany.com` in SalesLoft. Keeps a clean audit trail, isolates integration actions from human rep activity.
2. **Admin generates a key for their own account** -- works but mixes integration writes with the admin's personal activity. Avoid for production.

Either way: an admin generates the API key, the customer adds it to their Relevance project as a secret, and tools reference it from there.

### Required API Scopes

| Scope | What it allows |
|---|---|
| `people:read` | Read prospect records |
| `people:write` | Update prospect records (custom fields, ownership) |
| `accounts:read` | Read company/account data |
| `users:read` | Resolve user emails to user IDs (for cadence assignment) |
| `team:read` | Read team membership and assignments |
| `cadences:read` | List and inspect cadences |
| `cadences:write` | Create cadence memberships (enroll people) |
| `activities:read` | Read activity logs (emails, calls, other interactions) |
| `calls:read` | Retrieve call logs |
| `emails:read` | Read email metadata |
| `email_contents:read` | Read email body and subject content |
| `crm:read` | Read CRM integration metadata |
| `crm_id_person:write` | Write the `owner_crm_id` field on the Person object (key for sync-bypass pattern) |

`crm_id_person:write` is in SalesLoft's "privileged scopes" list -- the admin must enable it explicitly.

### "Act on Behalf Of"

For sending emails from AE/BDR inboxes via Relevance, the integration user must have **Act on Behalf Of** permissions enabled for the cadence owner. Without this, cadence enrollment succeeds but sends fail or send from the wrong mailbox.

## Sandbox & UAT Access

For testing without touching production data, ask SalesLoft to provision a UAT environment, then: (a) create a Relevance integration user, (b) generate and install the API key, (c) confirm the `<br>` sanitization feature flag is OFF if you need to test multi-line email rendering.

## Building Tools in Relevance

**Default to native tool steps before raw API.** Two native steps exist:

| Native step | Purpose | Notes |
|---|---|---|
| `Add Person into Cadence` | Enroll a person in a team cadence | Eliminates raw `POST /v2/cadence_memberships`. Requires a User ID for the sender (resolve via `GET /v2/users` first). The User ID must have "Act on Behalf Of" permission for the cadence owner. |
| `Create Person` | Create a contact directly in SalesLoft | Skips the create-in-Salesforce-then-wait-for-sync round trip. Caveat: bilaterally syncing custom fields will not be populated immediately. |

**When to fall back to raw API:**

- Reading person records (`GET /v2/people?email_addresses=...`) -- no native equivalent
- Writing custom fields (`PUT /v2/people/{id}`) -- no native equivalent
- Anything not covered by the two native steps above

**Native first.** Per `BUILD_PRACTICES.md`, prefer native tool steps; fall back to raw API when no native step covers the need.

## API Reference

Base URL: `https://api.salesloft.com`. Auth: `Authorization: Bearer {api_key}`.

| # | Method | Endpoint | Purpose |
|---|---|---|---|
| 1 | `GET` | `/v2/people?email_addresses={email}` | Find a Person by email. Returns `id`, `crm_id`, `crm_object_type`, `owner_crm_id`. |
| 2 | `PUT` | `/v2/people/{id}` | Write `custom_fields` (Relevance-generated content) and/or `owner_crm_id` (ownership bypass). |
| 3 | `GET` | `/v2/users?search={email}` | Resolve a sender email to a SalesLoft `user_id`. Required input for cadence enrollment. |
| 4 | `POST` | `/v2/cadence_memberships?person_id={pid}&cadence_id={cid}&user_id={uid}` | Enroll a Person into a Team Cadence as the specified sender. |

### Payload sketch -- write custom fields (call 2)

```json
PUT /v2/people/{id}
{
  "custom_fields": {
    "Relv_General_Subject_1": "Quick question on Q1 sourcing",
    "Relv_General_Email_1": "Hey Sam,<br><br>Saw your team just rolled out...",
    "Relv_General_LinkedIn_1": "Sam, noticed your post on..."
  }
}
```

### Dynamic href traversal

SalesLoft API responses include `href` links to related resources (e.g. a Person record exposes its cadences endpoint). Similar to HubSpot's pattern. Useful when an agent needs to chase associations without a second hardcoded URL.

### Full SalesLoft API docs

`https://developers.salesloft.com/docs/api/`
Scopes reference: `https://developers.salesloft.com/docs/platform/api-basics/scopes/`

## Sync Patterns

CRM-to-SalesLoft sync delay is the most common production friction point. Three patterns to handle it:

### 1. SalesLoft as source of truth for ownership (preferred)

When ownership in Salesforce changes, instead of waiting for SalesLoft to sync, write `owner_crm_id` directly on the SalesLoft Person via `PUT /v2/people/{id}`. This requires the `crm_id_person:write` scope.

This is the highest-leverage pattern in this doc. It eliminates an entire category of "wrong mailbox" bugs.

### 2. Play-triggered immediate sync

Customer creates a SalesLoft Play that fires when a dummy custom field becomes non-null. Relevance writes a value into the dummy field. The Play's "Review Record" action forces an immediate CRM sync. Use this when the customer cannot grant `crm_id_person:write` but can build a Play.

### 3. In-tool delay (last resort)

If ownership matching is critical and neither pattern above is available, add a deliberate delay step in the tool flow before reading owner data. Surface this to the customer as a workaround, not the recommendation.

## Customer Onboarding Checklist

Walk the customer's SalesLoft admin through this in a 45-60 min joint session.

### Pre-requisites (confirm before the call)

- [ ] SalesLoft Admin / Owner identified
- [ ] Relevance integration user created (`relevance.integration@yourcompany.com`)
- [ ] API key generated and added to Relevance as a secret
- [ ] (Ideal) Customer UAT environment connected to Relevance UAT

### Sync & Permissions

- [ ] Confirm CRM <-> SalesLoft sync coverage: Contacts/Leads, Opportunities, Owner/assignment
- [ ] Confirm sync frequency (continuous, scheduled, action-triggered)
- [ ] Confirm Salesforce owner changes propagate to SalesLoft
- [ ] Verify all required API scopes are granted (see Authentication)
- [ ] Confirm CRM lead owner matches SalesLoft user (mailbox routing)
- [ ] Confirm integration user has "Act on Behalf Of" permissions for in-scope reps

### Group & Team Structure

- [ ] Decide which reps and groups are in scope (ADRs, AEs, both)
- [ ] Map global vs regional groups (e.g. West ADRs, EMEA ADRs)
- [ ] **Recommendation:** create a sub-group within the existing target parent group rather than reusing the top-level group -- cleaner pilot rollback
- [ ] Decide which group the agent's cadence is assigned to

### Custom Fields

- [ ] Create text custom fields using the `Relv_General_*` naming convention (see Key Concepts)
- [ ] Confirm field type is **Text** and default value is blank
- [ ] Test `<br>` tag rendering in a custom field (see Gotchas)

### Cadence Setup

- [ ] Decide cadence strategy: one cadence or multiple (e.g. one for MQLs, one for PQLs)
- [ ] Decide steps + spacing (e.g. 5 email steps at Day 1, 3, 5, 8, 12)
- [ ] Decide email-only vs email + call + LinkedIn at launch
- [ ] Create the cadence as a **Team Cadence** (not personal)
- [ ] Assign cadence to the in-scope group(s)
- [ ] **For testing:** set delivery to Manual Approval so reps review before sends

### Templates & Personalization

- [ ] Create email templates that pull in the `Relv_General_*` custom fields
- [ ] Standard disclaimers / footers / links in template body
- [ ] **Recommendation:** keep greeting inside the AI-generated content (`"Hey Sam,"`) instead of using `{{first_name}}` -- avoids messy or all-caps name fields from marketing imports

### Plays Interference Review

- [ ] List existing Plays that auto-enroll into cadences
- [ ] List Plays that auto-sync on field update (avoid double-trigger with Relevance writes)
- [ ] List Plays that change owners or statuses based on cadence activity

### Permissions Matrix

- [ ] Who can change contact ownership?
- [ ] Who creates and uses Plays?
- [ ] Who creates and manages custom fields?
- [ ] One group for all reps vs groups per segment / region?

## Typical Setup Session (45-60 min)

A session structure that has worked well in real UAT walkthroughs.

1. **Confirm pre-reqs (5 min)** -- UAT connected, API key installed, integration user authenticates. Skip plumbing.
2. **Review custom fields (5 min)** -- admin shares screen on `Settings -> Data -> Field configuration`. Confirm all `Relv_General_*` fields exist as Text.
3. **Discuss groups & target reps (10 min)** -- map customer's group structure. Decide pilot scope.
4. **Create a Team Cadence (10 min)** -- e.g. "Relevance - MQL Nurture". Assign to ADR group(s). Add an Email Step with Subject + Body wired to custom fields. Set to Manual Approval.
5. **End-to-end test with a real test lead (10 min)** -- Relevance looks up the Person via API, populates custom fields, enrolls into the cadence as the correct sender. **Expect a scope error on first attempt** -- admin updates scopes, retest.
6. **Multi-step test (5 min)** -- add a second template step. Confirm `Relv_General_Subject_2` and `Relv_General_Email_2` populate.
7. **Production rollout discussion (10-15 min)** -- final cadence count, step spacing, pilot reps, ownership-source decision (Salesforce vs SalesLoft), AE-vs-ADR handling.

Outcome: customer leaves the call with a working test cadence, a clear production rollout plan, and visible proof that Relevance content lands in the right place.

## Common Integrations

| Integration | Trigger | Agent Action | Output |
|---|---|---|---|
| Personalized outbound | CRM trigger on qualified lead | Research, generate messages | Populate custom fields, enroll in team cadence |
| Multi-channel sequencing | Agent research complete | Generate email + call + LinkedIn content | Push to cadence steps via custom fields |
| Re-engagement | Deal stage change or inactivity | Generate re-engagement messages | Enroll in re-engagement cadence |
| Ownership correction | Salesforce owner change | Update SalesLoft Person directly | `PUT /v2/people/{id}` with new `owner_crm_id` (skip sync wait) |

## Gotchas

- **Cadence enrollment requires a team cadence.** Personal cadences fail at the API.
- **`<br>` tags may be sanitized by default** in customer instances. Test early. If sanitized, the customer must contact their SalesLoft CSM to request the engineer-level flag flip -- it is a per-custom-field setting and not a customer-facing toggle. Internal sandbox has this flag stuck ON; cannot test line breaks on sandbox.
- **Plays can only be cloned from templates,** never created from scratch. Factor this into customer expectations.
- **Dynamic subject lines split email threads.** Each unique subject creates a new thread -- if you want a multi-step single thread, keep the subject constant or skip subject variation.
- **Admin must have "Act on Behalf Of"** for multi-rep sending. Cadence enrollment will succeed but sends fail or use the wrong mailbox without it.
- **Different team groups affect Plays and template access.** A cadence assigned to the wrong group will not be visible to the in-scope reps.
- **CRM owner must match SalesLoft user** for correct mailbox routing. If they diverge, either fix in SalesLoft via `owner_crm_id` write or in Salesforce + sync wait.
- **`crm_id_person:write` is a privileged scope.** Admin must enable it explicitly -- not in the default scope set.
- **First end-to-end test almost always errors on scopes.** Bake this into the session timeline. Admin updates scopes mid-call, retest.

## Resources

- SalesLoft API: `https://developers.salesloft.com/docs/api/`
- SalesLoft API scopes: `https://developers.salesloft.com/docs/platform/api-basics/scopes/`

## Related Files

- `build-kit/integrations/salesforce.md` -- Salesforce (the most common upstream CRM)
- `build-kit/integrations/outreach.md` -- Outreach.io (SalesLoft's main competitor; many patterns transfer)
- `playbooks/use-cases/outreach-agent-patterns.md` -- Outbound messaging patterns (Outreach + SalesLoft both)
- `.claude/rules/BUILD_PRACTICES.md` "Integrations" -- native > raw API > Pipedream rule, OAuth consistency
