# Workforce Patterns: Deep Reference

> **Scope:** Mental model, type semantics, schedule capability, dispatch limits, sub-agent approval mechanics. The headline rules and gotchas live in `.claude/rules/PLATFORM_MECHANICS.md` § "Workforce Architecture" -- this file holds the long-form context.

---

## Mental model: graph, not tree

A workforce is **a graph with arbitrary entry points**, not a parent-child tree. The edge `threading_behavior` expresses the *relationship* between two agents, not a hierarchy:

- **`always-same`** ("continue same task" in UI) expresses **two entities communicating** -- peer-to-peer, even if the receiver is functionally "a child". Used for follow-up / multi-round interactions.
- **`always-create-new`** ("start new task" in UI) expresses **one-off delegation** -- each invocation instantiates a fresh sub-agent, similar to how Claude Code, Codex, or Grok chat spawn subagents.

Because threading is an edge property (not an agent property), the same sub-agent can be invoked under different configs by different parents. **Sub-agent prompts must therefore be context-agnostic** -- they cannot assume what context they inherit when invoked.

**Source:** Relevance AI platform team guidance.

---

## Type: `default` vs `chat`

**Always default to `type: "default"` on `relevance_create_workforce`.** `type: "chat"` workforces are hidden from both `relevance_list_workforces` and the Relevance UI's Workforces tab. They still run (trigger accepts messages, graph executes), but users cannot discover or chat with them through the normal UI.

**Gotcha:** changing type from `chat` to `default` via `relevance_update_workforce` publishes successfully and `get_workforce` confirms the new type, but **the workforce still does not appear in `list_workforces` or the UI Workforces tab**. Some visibility flag is set at create time and isn't retroactively flipped. Fix: delete the chat-type workforce and recreate from scratch with `type: "default"`. Same agents + edges can be reused (agent IDs don't change), but the workforce_id changes -- grep the repo for the old ID and replace.

Only use `type: "chat"` if you have a specific chat-widget-embed or external chat-entry requirement.

---

## Schedule Capability in Workforces

Agents with `is_scheduled_triggers_enabled: true` can schedule messages to themselves. In a workforce context:

- The scheduled message fires in the **same agent conversation**, not a new workforce task
- The agent retains access to all workforce edges (tool-call to other agents)
- The workforce task itself may show as `completed` before the schedule fires -- this is expected
- Use this for self-scheduling callbacks/retries without external scheduling systems (n8n, cron)
- Always include full context in the scheduled message (the agent won't have access to the original trigger params)

---

## Sub-agent approval propagation

Propagation is default for all workforces (the `SubagentApprovalPropagation` flag was removed). Sub-agent approvals bubble up to the top-level workforce task view via `agent_chain` tracking; approving routes back down to the correct sub-agent conversation. Three edge-level modes: **Auto run** (`never-ask`) / **Approval required** (`always-ask`) / **Let agent decide** (prompt-driven).

**Production gotcha:** despite propagation being default, "subagents cannot wait for approval" still surfaces on some AI Edge connections. Workarounds (descending reliability):

1. Webhook-separate agents into distinct workforces
2. Put the approval tool on the parent
3. Tool-as-trigger if upstream is 100% deterministic
4. Built-in escalate

Always test approval paths end-to-end before handoff.

---

## Wall-clock and dispatch limits

- **Workforce tasks time out at ~15 minutes.** Large orchestrators fanning out sequentially hit this. Mitigations: enable Parallel Tool Calls, decouple via knowledge table + scheduled triggers, or split the workforce at a natural boundary.
- **Sequential sub-agent dispatch degrades past ~5-10 invocations** -- the orchestrator inconsistently fails to invoke the sub-agent the full N times. Above ~10 items: use Parallel Tool Calls with `always-create-new`, or decouple via tool-as-trigger / KT intermediary.

---

## Credential Isolation

- OAuth/API keys configured at edge level via `default_values`
- Never expose credentials in orchestrator prompts

---

## Edge configuration: full reference

| Field | Purpose |
|-------|---------|
| `threading_behavior` | `always-same` (memory) vs `always-create-new` (stateless) |
| `action_behaviour` | `never-ask` (auto) / `always-ask` (human approval) / `let-agent-decide` (prompt-driven) |
| `params_schema` | Input contract -- REQUIRED, or first call fails with `"must have required property 'message'"` |
| `prompt_for_when_to_use` | Routing guidance injected into orchestrator prompt |

### `additionalProperties: false` is a 100% failure mode

The runtime auto-injects `_subagent_params` into every sub-agent invocation before schema validation. `additionalProperties: false` rejects it and every sub-agent call fails with:

```
Studio Params Validation Error: must NOT have additional properties {"additionalProperty":"_subagent_params"}
```

Correct pattern:

```json
{
  "type": "object",
  "properties": {
    "message": { "type": "string", "description": "..." },
    "_subagent_params": {
      "type": "object",
      "description": "Platform-injected. Do not set manually."
    }
  },
  "required": ["message"],
  "additionalProperties": true
}
```

LLM guardrails belong in `prompt_for_when_to_use` and the orchestrator's system prompt, NOT in the schema.

### `relevance_update_workforce` merges, does not replace

Setting an edge field to a value then trying to remove it by omitting it from the next update **does not work** -- the old value persists. Always set fields to their desired value explicitly. To nuke a complete subconfig, re-specify the whole subconfig.

### Explicit edges disable auto-linking

Passing any `edges` to `relevance_create_workforce` disables auto-linear-chain behaviour entirely -- including the trigger -> first-agent edge. Always include the trigger edge when passing custom edges:

```json
{ "source_index": -1, "target_index": 0, "edge_type": "forced-handover", "threading_behavior": "always-same" }
```

### Testing orchestrators: `trigger_workforce`, not `trigger_agent_sync`

Workforce edges populate the orchestrator's runtime tool list ONLY when triggered through the workforce. Direct `trigger_agent_sync` shows the orchestrator describing delegation but `toolCalls: []` -- no actual delegation.

Corollary: `relevance_get_agent_tools` on a workforce orchestrator returns empty because workforce edges don't populate `actions`. Inspect the workforce graph instead (`relevance_get_workforce`).

---

## See Also

- `.claude/rules/PLATFORM_MECHANICS.md` § "Workforce Architecture" -- headline rules
- `playbooks/use-cases/multi-agent-orchestration.md` -- orchestrator design reference (mental model, 7+1 generative principles, capability contracts, scale guardrails, dispatch decision)
- `build-kit/agents/tools/parallel-tool-calls.md` -- Parallel Tool Calls early-access details
- The `managing-relevance-workforces` skill is loaded on demand by the remote MCP for CRUD operations
