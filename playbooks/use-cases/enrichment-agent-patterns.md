# Enrichment Agent Patterns

Patterns for building agents that enrich records with additional data - contact details, firmographics, technographics, or any field-level data augmentation. These agents typically process records in bulk and write results back to a knowledge table or CRM.

## Audit/Breadcrumb Pattern

Always mark that processing occurred, regardless of outcome:

```
Always update "enriched_status": "Enrichment Agent" regardless of the enrichment result.
```

This creates an audit trail showing:
- The agent processed this record
- When it was processed
- Even if enrichment failed, the attempt is logged

Without this, failed enrichments are invisible - you cannot distinguish "not yet processed" from "processed but found nothing."

## Change Summary Pattern

For enrichment agents, report what changed per record:

```
Share final result along with call outs:
- Phone (New / Not found / Existing)
- Email (New / Not found / Existing)
- LinkedIn URL (New / Not found / Existing)
- Job Title (New / Not found / Existing)
```

Three states:
- **New:** Successfully enriched (value was missing, now filled)
- **Existing:** Already had this value (no change needed)
- **Not found:** Attempted enrichment but could not find data

This prevents silent overwrites and lets downstream agents or humans know what actually changed.

## Tool Dependency Chains

When enrichment tools depend on each other's output, specify the order explicitly:

```
1. Use {{_actions.linkedin_lookup}} to get LinkedIn URL and Job Title FIRST
2. Use {{_actions.email_finder}} to get emails and phone numbers
   - This tool works best when you have the LinkedIn URL from the previous step
```

Pattern: Tool A -> Output -> Tool B (uses A's output). Without explicit ordering, agents may call tools in parallel and miss the dependency.

## Async Tools (Webhook Pattern)

Some enrichment tools are asynchronous - they return a job ID, and results arrive later via webhook:

```
Use {{_actions.email_finder}} to get emails and phone numbers.
- This tool works best when you have the LinkedIn URL
- This will return an async job status and results will be posted to your webhook later
```

Implications:
- Agent may need to wait for webhook callback
- Results arrive in a separate message or trigger
- Build idempotency - check if the record was already enriched before re-processing
- Handle job status polling if the webhook is unreliable

## Cost-Aware Enrichment

Enrichment tools often have per-call costs. Apply the "enrich last" rule:

```
Accuracy before cost: Get the right answer first, then optimize spend.
Wrong answers waste more credits downstream.

"Enrich last" rule: Search and qualify first. Only enrich finalists.
Gate costly actions behind intent thresholds.

Budget caps: Set a soft cap (~80%) to auto-stop before overruns
and a hard cap (100%) as a fail-safe.
```

Cost math examples for documentation:
```
People/Org Search: ceil(total_results / per_page) credits
Bulk Org Enrich: ceil(n_domains / 10) credits
Phone reveal: prospects x phone_hit_rate x 8 credits
```

Lower `autonomy_limit` for cost-sensitive enrichment agents (e.g., 20 instead of 50) since each tool call incurs real costs.

## Field Mapping and Normalization

For tools with complex parameter schemas, provide field-by-field instructions:

```
### Current Company
- Field: CURRENT_COMPANY
- Assign only when the input explicitly names a company or provides a URL
- Use the exact company name or company URL
- If no company specified, leave empty
- Example: ["BDA Surveying"]

### Region
- Field: REGION
- Normalize locations to country-level wherever possible
- Avoid city-level strings like "London, United Kingdom"
- Replace with: ["United Kingdom"]
```

Embed normalization rules for messy input:
```
Regions: "UK" -> "United Kingdom", "US" -> "United States"
Industries: "Private Equity" -> "Venture Capital and Private Equity Principals"
Titles: Prefer short, strong substrings: "Founder", "CEO", "CFO"
```

## Dead-End Status Clarity

Never save incomplete records with a success-like status. Use distinct statuses that tell the next pipeline step what to do:

- `enriched` - all required fields present, ready for next step
- `needs_linkedin_url` - name/title found but LinkedIn URL missing
- `low_confidence` - enriched but insufficient signals for downstream use
- `enrichment_failed` - tool error during enrichment, logged for retry
- `not_found` - searched but no matching records exist

See also: `.claude/rules/BUILD_PRACTICES.md` "Dead-End Status Clarity" section.

## Worked Example: Account Tiering Enrichment

**Trigger:** Webhook from HubSpot when new company record created.

**Workflow:**
1. Receive and Validate: Parse incoming company record. Confirm domain and HubSpot ID present. Skip if missing critical identifiers (log reason).
2. Enrich via API: Call enrichment API with company domain. Parse response for employee count, revenue, industry, technology stack.
3. Quality Checks: Flag if employee count differs >50% from existing HubSpot value. Validate revenue format. Map industry to standard taxonomy.
4. Update HubSpot: Write enriched fields to company properties. Set `enriched_status: "Account Tiering Agent"` plus a current timestamp.
5. Calculate Tier: Apply tiering logic based on enriched data.
6. Audit Note: Create HubSpot note summarizing fields updated (New/Existing/Not found), tier assigned, flags raised.

**Error handling:** API rate limit -> exponential backoff -> retry. Invalid response -> log, continue to next record. Partial data -> update what is available, note gaps.

## Common Failure Modes

| Failure | What It Looks Like | Root Cause |
|---------|-------------------|------------|
| Silent failures | Records show no enrichment status | No audit breadcrumb on failure path |
| Stale overwrites | Newer manual data replaced by older API data | No "newer wins" check before update |
| Rate limit crash | Batch stops halfway, partial records enriched | No backoff strategy |
| Duplicate processing | Same record enriched multiple times | No idempotency check |
| Cost overrun | Every record enriched regardless of qualification | Missing "enrich last" gate |
| Broken tool chains | Tool B fails because Tool A output was not passed | Tool dependency order not explicit |

## Related Files

- `playbooks/use-cases/research-agent-patterns.md` - Research patterns (often upstream of enrichment)
- `.claude/rules/BUILD_PRACTICES.md` - Dead-end status clarity, entity name matching
- `build-kit/agents/knowledge/knowledge-tables.md` - Knowledge table API for storing enrichment results
