# Outreach.io Integration

> **Outreach.io** is an email sequencing platform used by enterprise sales teams for multi-step outreach cadences. Integrates with Relevance AI via native OAuth integration.

## Why It Matters

Outreach is the most common enterprise email sequencing tool. Agents push personalized messages into Outreach sequences, which handle the send timing, follow-ups, and tracking. Understanding the sequence/state/task model is essential for any outbound automation build.

## Key Concepts

### Sequence Steps
Template actions within a sequence. Most common types:
- **Automatic email** -- sends automatically when custom variables are populated and within work hours
- **Manual email** -- requires the owner to click send (simulates approval mode)
- **Call** -- provides conversation levers for the salesperson
- **LinkedIn: Send connection request** -- provides a connection message variable

Manual email steps can be changed to automatic even after the sequence has started -- this simulates the approval-to-autopilot transition.

### Sequences
A series of sequence steps. Typically one per campaign, but if steps are identical across campaigns, the same sequence can be reused since Relevance AI generates customized content via variables.

**Important:** Once prospects are active and have completed steps, you cannot insert new steps before the completed ones.

### Sequence States
The mapping object between a prospect, a sequence, and the assigned salesperson. This is how prospects get enrolled in sequences.

Owner assignment options:
- **Assigned to Outreach owner** -- use the `owner_id` from the prospect record
- **Assigned by TAM/Account/CRM mapping** -- requires the customer to provide mapping info and `user_id` for every salesperson

**Critical:** Ensure the owner in Salesforce matches the owner in Outreach (same person's email inbox doing the sending).

### Tasks
When a sequence step becomes due, it appears as a task for the assigned salesperson. Tasks are visible under the sequence > Tasks view.

Outreach has a built-in fail-safe preventing tasks from being actioned outside of work hours (set by admin). Tasks that are not yet due show as `pending` -- do not panic during testing.

## Integration Setup

Outreach uses a **native Relevance AI integration** (not Pipedream):

Integrations > Connect your integrations > Outreach > + Integration

The platform provides a generic Outreach API tool step with OAuth to hit any endpoint. API docs: https://developers.outreach.io/api/reference/overview/

### Account Requirements

One integration account needed. Ensure it has permissions for:
- Create a prospect (if needed)
- Edit prospect variables (covers email info, research notes)
- Activate a sequence
- Assign an owner to a prospect

## Custom Variable Limitations

**Outreach custom variables do not allow newline characters.** This is the most impactful gotcha.

### Workaround 1: One Variable Per Paragraph

Assign each paragraph to a separate custom variable. Each email chain requires:
- 1 variable per subject line
- 1 variable per email paragraph

Example: 4 email sequence steps, 2 paragraphs each = 1 subject + (4 x 2 paragraphs) = **9 custom variables**

If the customer does not have enough custom variables, they can contact Outreach support to request more for free.

**Note:** Creating a new subject creates a new email chain/thread.

### Workaround 2: Replace Newlines with HTML

```python
email.replace("\n", "<br>")
```

This works because Outreach renders and queues messages in HTML, so `<br>` tags force newline rendering.

## CRM Sync Considerations

### CRM > Outreach Sync Working
If the sync is set up correctly, there is a delay between CRM record creation and Outreach prospect creation. Ask the customer how long this takes, and configure the agent to wait before pushing data to Outreach.

### CRM > Outreach Sync NOT Working
If the sync is broken, the agent needs to **double-write** -- every update to the CRM must also be made separately in Outreach.

## Customer Setup Requirements

The customer must:
1. **Create sequences** and provide the `sequence_id` (found in the URL: `/sequences/{id}`)
2. **Add sequence steps** with the desired cadence and actions
3. **Declare which custom variables** are assigned per step (e.g., `custom70`, `custom75`, `custom76`)

## Questions to Ask Customers

1. How do your reps currently use Outreach?
2. How does a prospect get assigned an owner in Outreach?
3. How long does it take for a prospect to appear in Outreach after CRM creation?
4. How many custom variables can be assigned to the Relevance AI sequence?

## Common Integrations

| Integration | Trigger | Agent Action | Output |
|------------|---------|-------------|--------|
| Personalized outbound | Salesforce trigger on qualified Lead | Research prospect, generate messages | Populate custom variables, enroll in sequence |
| Follow-up sequencing | Agent completes research | Generate multi-step sequence content | Push to Outreach sequence steps |
| Re-engagement | CRM deal stage change | Generate re-engagement messages | Enroll in re-engagement sequence |

## Gotchas

- Custom variables cannot contain newline characters -- use `<br>` or one-variable-per-paragraph
- `sequence_id` is found in the Outreach URL, not returned by default in API responses
- Manual email steps simulate approval mode; switching to automatic simulates autopilot
- Tasks will not appear outside of configured work hours -- expect `pending` status during testing
- Not every Outreach feature has a public API endpoint -- some actions require customer-side setup

## Related Files

- `build-kit/integrations/salesforce.md` -- Salesforce (common upstream CRM)
- `build-kit/integrations/salesloft.md` -- SalesLoft (Outreach alternative)
- `playbooks/use-cases/outreach-agent-patterns.md` -- Outreach messaging patterns
