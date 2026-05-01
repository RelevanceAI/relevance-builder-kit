# CRM Knowledge Architecture

How to build and maintain the instance-specific knowledge a CRM agent needs to be effective. Covers the flat-table approach, skill-based architecture, loading strategies, and migration path.

## What CRM Knowledge Is

A CRM API reference tells the agent what is possible -- endpoints, methods, parameters. CRM knowledge tells the agent what is actually configured in your specific CRM instance.

Without it, every interaction starts from scratch: discover pipeline stages, look up property names, find owner IDs, figure out custom object schemas -- all before answering the actual question.

**The compounding advantage:** Early interactions are slower (discovery phase). Later interactions are faster (knowledge-base hits). Each successful query adds knowledge that makes the next query faster.

## Knowledge Categories

These categories are consistent regardless of CRM platform:

| Category | What to Capture | Why It Matters |
|----------|----------------|----------------|
| Pipeline and Stages | Pipeline IDs, stage IDs, names, win probabilities | Deal creation needs exact IDs. Stage names alone are ambiguous. |
| Deal Properties | Custom property internal names, which property for what purpose | Wrong property = wrong data or silent failure. Many CRMs have duplicate/legacy properties. |
| Custom Objects | Object type IDs, key properties, status values, business rules | No standard documentation. Cannot discover from generic API docs. |
| Contact/Company Properties | Custom field names, precedence when multiple fields serve the same purpose | Prevents picking the wrong field from accumulated duplicates. |
| CRM Owners | Owner IDs, emails, roles | Assignment requires exact IDs. Display names are ambiguous. |
| API Patterns | Discovered gotchas, endpoint quirks, workarounds | Prevents repeating mistakes. Some behaviors are undocumented. |
| Date/Timestamp Rules | Format requirements, tool usage rules | Timestamps are the #1 source of CRM API bugs. |
| SOPs and Processes | Multi-step workflows as named procedures | Agent can execute from memory without re-deriving steps. |

## Architecture A: Flat Knowledge Table

The simplest approach that works in production. Good starting point.

### How It Works

A single vector-embedded knowledge table where each entry is a text blob with a date and ID:

```
Knowledge Table: my_crm_knowledge
Embedding Model: text-embedding-3-large
Fields: ID, date, knowledge

Entry 1: "Pipeline 'Sales' (id: default): Stage1..."
Entry 2: "Always use amount_in_home_currency for..."
Entry N: "SOP: Add people from email to deal: ..."
```

### Self-Learning Tool Pipeline

| Step | What Happens |
|------|-------------|
| 1. Vector Search | Find 5 most similar existing entries |
| 2. LLM Decision | Compare new knowledge against matches. Decide: update (merge) or create (new entry) |
| 3. Parse | Extract decision to structured JSON |
| 4. Timestamp | Add current date |
| 5. Branch | Route to update path (upsert with existing ID) or create path (new ID) |

### Pros

- Simple to implement -- one table, one tool, works immediately
- Self-maintaining -- the LLM merge step prevents most duplication
- Works at small scale -- 30-50 entries are easily searched semantically
- No schema required -- any text can be an entry

### Cons

- Entries mix categories -- pipeline stages sit next to API patterns sit next to SOPs
- Hard to audit -- reviewing 40 unstructured text blobs is tedious
- No selective refresh -- cannot easily update "just the pipeline config"
- SOPs are compressed -- multi-step procedures get squeezed into one-liners
- Scaling concern -- at 100+ entries, vector search returns less relevant results as categories blur
- No version control -- changes are invisible (no git diff)

## Architecture B: Skill-Based Knowledge (Recommended)

Topical, loadable, human-reviewable, version-controlled knowledge files.

### Structure

```
CRM Knowledge Skills/
  pipeline-config.md        -- All pipeline stages, IDs, probabilities
  deal-properties.md        -- Deal field mappings and usage rules
  custom-objects.md         -- Custom object schemas, statuses, business rules
  contact-company-fields.md -- Contact/company property mappings
  crm-owners.md             -- Team member IDs and roles
  api-patterns.md           -- Discovered gotchas and workarounds
  date-handling.md          -- Timestamp rules and tool usage
  sops/
    monthly-reporting.md
    email-contacts-to-deal.md
    meeting-links-extraction.md
```

### Why This Is Better

| Benefit | How |
|---------|-----|
| Clear scope per file | Review `pipeline-config.md` in isolation and know it is complete |
| Loaded on demand | Agent or classifier loads relevant files based on request type |
| Human-reviewable | Markdown readable by anyone. No database query needed to audit |
| Version-controlled | Git diff shows exactly what changed and when. PR reviews for knowledge updates |
| SOPs have room | Each SOP gets full step-by-step detail, edge cases, examples |
| Selective refresh | Update just `pipeline-config.md` when stages change |
| Selective injection | Inject only relevant files into context -- reduces noise and token cost |

### Example: pipeline-config.md

```markdown
# Pipeline Configuration
Last verified: {date}

## Sales Pipeline (id: {pipeline_id})

| Stage | ID | Probability | Notes |
|-------|-----|------------|-------|
| Meeting | {id} | 5% | First meeting booked |
| Qualified | {id} | 10% | BANT criteria met |
| Closed Won | {id} | 100% | |
| Closed Lost | {id} | 0% | Requires loss reason |

## Usage Rules
- "Booked demo" = deals entering "Meeting" stage
- "Closed Won" stage ID is {id} (not the default label)
```

### Example: sops/monthly-reporting.md

```markdown
# SOP: Monthly Reporting

## Purpose
Generate monthly metrics by running 12 CRM searches (one per month)
using BETWEEN filters.

## Steps
1. Determine date range using date parser tool (UNIX ms)
2. For each month, search deals with BETWEEN filter on date property
3. Aggregate results with math tool
4. Format as markdown table with monthly columns

## Edge Cases
- > 100 results per month: paginate using after cursor
- Use amount_in_home_currency not amount for value reporting
- Dates must be in milliseconds (use date parser tool)
```

## Loading Strategy

When the agent receives a query, a classifier determines which files to load:

| Query Pattern | Load These Skills |
|--------------|-------------------|
| "Create a deal..." | pipeline-config.md, deal-properties.md |
| "Who owns the account for...?" | crm-owners.md, contact-company-fields.md |
| "Monthly report on..." | sops/monthly-reporting.md, deal-properties.md |
| "What's the status of subscription...?" | custom-objects.md |
| "Search for contacts where..." | contact-company-fields.md, api-patterns.md |
| Unknown / general | Load all (fallback) |

Implementation options:
- **Simple:** Keyword matching in the system prompt
- **Medium:** LLM classification step before main execution
- **Advanced:** Embedding-based similarity against skill file descriptions

## Migration Path: Flat Table to Skill Files

### Phase 1: Export and Categorize
1. Export all entries from the knowledge table
2. Sort each entry into the appropriate category
3. Create skill files with sorted content
4. Add dates and sources where known

### Phase 2: Parallel Run
1. Keep flat table active (agent still reads from it)
2. Load skill files as additional context
3. Route new knowledge writes to skill files (not flat table)
4. Verify agent behaves the same with skill files

### Phase 3: Cutover
1. Confirm all flat table knowledge is captured in skill files
2. Remove flat table from agent's knowledge injection
3. Update self-learning tool to write to skill files
4. Archive flat table (do not delete -- keep as backup)

### What NOT to Migrate
- Stale entries with outdated dates -- verify against live CRM first
- Duplicate entries -- deduplicate during migration
- Overly specific entries -- generalize ("Always use X for reporting" not "On Aug 7 we decided to use X")

## Building Your Knowledge Base

### Step 1: Run Pre-Flight Discovery

| Discovery Query | What It Produces |
|----------------|-----------------|
| List all pipelines | pipeline-config.md |
| List custom properties per object type | deal-properties.md, contact-company-fields.md |
| List custom object schemas | custom-objects.md |
| List CRM owners | crm-owners.md |
| List association types | api-patterns.md |

### Step 2: Document Each Category

For each category, include:
- **Verified date** -- when last confirmed against live CRM
- **Source** -- which API call produced the information
- **Business rules** -- non-obvious rules ("Renewed" status is NOT counted in active metrics)

### Step 3: Set Up Self-Learning

Route discoveries to the right file:
- New property mapping -> relevant properties file
- API gotcha discovered -> api-patterns.md
- User teaches new SOP -> new file in sops/

### Step 4: Schedule Reviews

| Frequency | What to Review |
|-----------|---------------|
| Quarterly | All skill files -- check for stale entries, verify against live CRM |
| On CRM change | Specific file -- when pipelines, properties, or team members change |
| After incidents | api-patterns.md -- capture new gotchas |

## Four Governance Principles for CRM Agents

From production HubSpot agent design:

1. **"If You're Unsure, Just Ask"** -- When a request is vague, stop and ask follow-ups rather than guessing. Wrong CRM writes are expensive to fix.
2. **"Feel Free to Look, But Think Twice Before Changing"** -- Reading is always safe. Writes require confirmation. Creates asymmetric risk model.
3. **"Knowledge-Base First"** -- Check accumulated knowledge before querying the live API. Eliminates redundant calls, makes the agent look competent.
4. **"Continuous Learning"** -- Eagerly capture CRM configuration when encountered during normal operation. After overcoming errors, when user shares settings, or on successful task completion.

## Composable Tool Architecture

Four tools cover the entire CRM surface better than 20 domain-specific ones:

1. **Generic API Gateway** -- Authenticated HTTP requests to any endpoint. Agent intelligence is in knowing WHICH call to make. Scales to new endpoints without new tools.
2. **Date Parser** -- Natural language to UNIX timestamps. Isolates the #1 source of CRM bugs (milliseconds vs seconds, timezone handling).
3. **Math Engine** -- LLM-generated Python for any numeric operation. Handles aggregation patterns without pre-built formulas.
4. **Self-Learning Knowledge** -- Vector search + LLM merge to prevent duplication. See flat table architecture above.

## Related Files

- `build-kit/agents/knowledge/knowledge-tables.md` -- Knowledge table API reference (CRUD, filters, Python helpers)
- `playbooks/enrichment-agent-patterns.md` -- Enrichment patterns that interact with CRM data
- `playbooks/multi-agent-orchestration.md` -- Governance and permission design for multi-agent CRM systems
- `.claude/rules/BUILD_PRACTICES.md` -- Entity name matching, dead-end status clarity
