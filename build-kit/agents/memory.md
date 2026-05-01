# Agent Memory

Agent memory persists facts, preferences, and context across conversations so an agent doesn't have to re-learn the same things every run. This file covers what memory is, how the two scoping levels work, what they're keyed on, and the contamination risk that catches builders out when the same agent is used in multiple workforces.

For the agent variables (`params_schema`) tab — which holds *config* values, not memory — see `prompt/agent-variables.md`. They're separate systems.

---

## The Two Scope Levels

Memory is configured on the agent via the `memory` object. The two valid `memory_level` values:

| `memory_level` | What's keyed on                       | Persisted in                                                  | Use for                                                                          |
|----------------|---------------------------------------|---------------------------------------------------------------|----------------------------------------------------------------------------------|
| `"project"`    | `project_id` + `agent_id`             | A knowledge set keyed to the agent ID, with rows filtered by `agent_id` | Facts about the *agent's domain* that should hold across all users (a CRM agent's known custom field names, naming conventions) |
| `"user"`       | `project_id` + `agent_id` + `user_id` | Postgres (`UserMemoryDAO`)                                    | Facts about the *individual user* (preferred tone, time zone, recurring requests) |

Enable memory via `memory.enabled: true` and pick a level. The field is `memory.enabled` — not `memory_enabled` — nested under `AgentMemoryConfig`.

> **The level `"task"` does not exist.** UI dropdowns for *threading behaviour* in the workforce builder use the words "Fresh start, no memory of previous calls" — that copy refers to conversation threading (`always-create-new` vs `always-same`), which is a separate system from long-term memory. See `prompt/CLAUDE.md` and `workforces/edges.md` for the threading concept.

---

## Memory and Workforces: Sharing is the Default

**The same `agent_id` reused across multiple workforces shares its memory.** There is no per-workforce or per-task isolation.

Concretely, the platform's memory read function (`FetchAgentMemories`) takes only:
- the agent record
- the ingestion input (which carries `project`)
- the user ID (for `memory_level: "user"`)

It does not take `workforce_id`, `workforce_task_id`, or `conversation_id`. There is no namespace key that would partition memory by workforce.

| Scenario                                                                                  | What happens                                                                                                                              |
|-------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| Agent A runs in Workforce 1, writes a memory ("Customer prefers Slack notifications")     | The memory is stored against `project + agent_A_id` (or `+ user_id` for user-level)                                                       |
| Agent A runs in Workforce 2 (same project)                                                | All memories from Workforce 1 are visible. Workforce 2's run injects the same memories into the agent's prompt context                    |
| Threading on the inbound edge is `always-create-new`                                      | **Memory is unaffected.** Threading controls conversation history, not long-term memory. The agent still receives all stored memories     |
| Different users trigger Workforce 1 and Workforce 2, agent uses `memory_level: "user"`    | Memories are isolated by `user_id`. Each user sees only their own memories                                                                |
| Different users, agent uses `memory_level: "project"`                                     | Memories are shared. User A's memory surfaces in User B's run                                                                             |

---

## Cross-Workforce Contamination Risk

The risk you need to design for: an agent reused across workforces with `memory_level: "project"` accumulates a single mixed pool of memories from every context it runs in. There is no isolation, no namespace per workforce, no override at the workforce node level.

### Worked example

Imagine an agent `Lead Researcher` with `memory_level: "project"`:

- **Workforce 1 (Inbound Lead Qualification):** writes "This contact came from a partner referral" memory
- **Workforce 2 (Outbound Cold Outreach):** retrieves all `Lead Researcher` memories at run time and sees the partner-referral memory — possibly leading to incorrect outreach phrasing because that fact is irrelevant to a cold-outreach context

Or worse for trust:

- **Workforce 1 (Customer Onboarding):** stores a customer's specific naming conventions ("They call deals 'opportunities' in their CRM")
- **Workforce 2 (Internal Forecasting):** runs the same agent and absorbs the customer's terminology, biasing internal-only outputs

### Mitigations

1. **Use different agent IDs for distinct contexts.** This is the only platform-level isolation. If the work in two workforces should not share memory, build them as two separate agents — even if 95% of the prompt is the same. Treat memory as part of the agent's identity.

2. **Use `memory_level: "user"` when memories are inherently per-user.** Reduces blast radius — only the same human triggering both workforces will see cross-flow.

3. **Be explicit in the system prompt about what to remember.** The agent's `memory.add_agent_memory` tool decides what gets stored. Tighten the criteria in the prompt: "Only remember stable facts about the contact, not facts about today's task." Reduces noise.

4. **Periodically prune.** Use `relevance_delete_agent_memory` (or the UI memory panel) to clear stale or contaminated rows. Build it into the operational checklist for any agent reused widely.

5. **Audit trail.** When memory writes affect downstream behaviour, log them — either via the agent's own tool calls or via the platform's audit log events. Then a build-team reviewer can spot when memory drift is causing weird outputs.

---

## Operating on Memory via MCP

| Operation                  | MCP tool                                              | Notes                                                         |
|----------------------------|-------------------------------------------------------|---------------------------------------------------------------|
| Enable memory              | `relevance_patch_agent` with `memory: { enabled: true, level: "project" }` | Use `patch_agent`, not `save_agent_draft`, to avoid wiping other config |
| Disable memory             | `relevance_patch_agent` with `memory: { enabled: false }` | Existing memories are not deleted, just not injected at runtime |
| Add a memory programmatically | The `add_agent_memory` phantom tool fires from the agent's runtime; no direct MCP write | The agent decides when to store — you can't backfill from outside via MCP |
| Read memories              | Knowledge-table operations on the agent's memory KB (project-level) or `UserMemoryDAO` (user-level) | Project-level memory uses a knowledge set named after the agent ID |
| Delete a memory            | The `delete_agent_memory` phantom tool, or knowledge-set delete operations |                                                              |

The phantom tools `add_agent_memory` and `delete_agent_memory` are platform-injected at runtime based on `memory.enabled: true`. Don't add them to the `actions` array manually — they're auto-provisioned. See `.claude/rules/PLATFORM_MECHANICS.md` § "Phantom Tools".

---

## Memory vs Variables vs Knowledge Tables

| If the content is...                                       | Use                                          | Why                                                                            |
|------------------------------------------------------------|----------------------------------------------|--------------------------------------------------------------------------------|
| Configuration the user edits in the UI (brand, tone, rules)| Agent variables (`params_schema` + `default`)| Always in the prompt, editable in the Variables tab without prompt surgery      |
| Reference content the agent retrieves on demand (templates, product facts) | Knowledge tables                  | Doesn't bloat every prompt; agent searches and pulls relevant rows              |
| Facts the agent learns over time and should remember next session | Memory                                | Persists across runs, but be aware of cross-workforce sharing                  |

If you find yourself reaching for memory to hold *config*, you want variables. If you find yourself reaching for memory to hold *static reference content*, you want a knowledge table. Memory is for emergent, learned context — facts the agent only knows because it experienced something.

---

## Common Issues

### "Memory works in one workforce but not the other"

If both workforces use the same agent and `memory_level: "project"`, they share. If one is reading and not seeing memories the other wrote, the cause is usually one of:

1. The two workforces are in **different projects**. Project IDs are part of the memory key.
2. The memory was written with `memory_level: "user"` and a different user is now triggering the second workforce.
3. The agent's `memory.enabled` was flipped off after the writes. Existing memories aren't deleted but they're not injected. Check the agent config.

### "I added a memory via the API but the agent doesn't see it"

There is no public API for direct memory writes — memories are always added by the agent itself via the `add_agent_memory` phantom tool. If you need to seed memory, the workaround is to give the agent a "training" conversation that walks it through the facts and lets it call `add_agent_memory` itself.

### "Memories from Workforce A are leaking into Workforce B"

Working as designed. The agent ID is the namespace. Either:
- Accept the sharing and structure the prompt to handle mixed-context memories
- Split into two agent IDs (different identities, different memory pools)
- Switch to `memory_level: "user"` if the relevant boundary is per-user, not per-workforce

---

## See Also

- `prompt/agent-variables.md` -- agent variables (config, not memory)
- `knowledge/CLAUDE.md` -- knowledge tables (reference content, not memory)
- `.claude/rules/PLATFORM_MECHANICS.md` § "Phantom Tools" -- how `add_agent_memory` / `delete_agent_memory` are injected
- `workforces/agent-vs-workforce.md` -- when one agent is reused across workforces (read this first if you're considering shared agents)
