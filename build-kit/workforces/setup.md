# Workforce Setup & Lifecycle

How to build, test, debug, and operate a workforce. For edge types and threading details, see `edges.md`. For the mental model, see `workforce-patterns.md`.

---

## Lifecycle

```
1. Design → testing rubric (get user buy-in BEFORE building)
2. Create  → relevance_create_workforce
3. Configure → graph (nodes + edges) via relevance_update_workforce if needed
4. Trigger → relevance_trigger_workforce with a representative input
5. Debug  → relevance_get_workforce_task_messages
6. Iterate → fix edges / threading / prompts
7. Publish (workforces auto-publish by default; pass shouldPublish: false to save draft)
```

### Step 1: Design + Rubric

Before writing graph configuration, write a testing rubric. The rubric is the contract between what you intend to build and what you'll later check. Share it with the user; iterate on the rubric, not the build.

Rubric template:

```
□ End-to-End Flow
  - Given <typical input>, produces <expected final output>
  - All N agents in the chain complete

□ Agent Handovers
  - Data passes correctly between agents (specify what fields)
  - Each agent receives expected context (always-same vs always-create-new respected)

□ Edge Cases
  - Handles agent failures gracefully (status, not crash)
  - Timeouts are handled
  - Approval-gated steps surface for human review

□ Output Quality
  - Final output meets business requirements
  - Intermediate outputs are accessible for debugging
```

Build only after the user approves the rubric.

### Step 2: Create

```typescript
relevance_create_workforce({
  name: "Research Pipeline",
  description: "Research → Summarize → Report",
  agents: [
    { agentId: "researcher-id" },
    { agentId: "summarizer-id" },
    { agentId: "reporter-id" }
  ],
  // Default: linear chain, forced-handover, always-same. Auto-publishes.
  // Pass `shouldPublish: false` to save as draft.
})
```

When you specify only `agents`, the platform auto-links them as a linear `forced-handover` + `always-same` chain with a trigger node. Once you specify explicit `edges`, you own the entire graph -- including the trigger edge.

### Step 3: Configure (when default linear chain isn't enough)

For non-linear graphs (orchestrator + workers, branching, fan-in), pass `nodes` and `edges` explicitly. See `edges.md` for edge config details. Trigger edge is always:

```typescript
{
  source_type: "trigger",
  target_type: "agent",
  source_node_id: "<trigger-node-id>",
  target_node_id: "<entry-agent-node-id>",
  config: {
    edge_type: "forced-handover",
    config: { threading_behavior: { type: "always-same" } }
  }
}
```

Forget the trigger edge and the workforce publishes but routes nothing.

### Step 4: Trigger

```typescript
const { workforce_task_id } = await relevance_trigger_workforce({
  workforceId: "...",
  message: "Process this lead: <payload>"
})
```

`workforce_task_id` is the handle for everything afterwards (debug, status, cancel).

**Always test orchestrators via `relevance_trigger_workforce`, not `relevance_trigger_agent_sync`** on the orchestrator agent directly. Workforce edges only populate the orchestrator's runtime tool list when triggered through the workforce. A direct `trigger_agent_sync` shows `toolCalls: []` even when the orchestrator's prompt describes delegation.

### Step 5: Debug

```typescript
// Quick state check
const meta = await relevance_get_workforce_task_metadata({
  workforceId, taskId: workforce_task_id
})
// status, credits, creator

// Full execution trace
const exec = await relevance_get_workforce_task_messages({
  workforceId, taskId: workforce_task_id
})
// exec.workforce_state, exec.results[]
```

`workforce_state` values:

| State                       | Meaning                                                  |
|-----------------------------|----------------------------------------------------------|
| `running`                   | Still executing                                          |
| `completed`                 | Finished successfully                                    |
| `pending-approval`          | Blocked on a human approval (`always-ask` edge)          |
| `errored-pending-approval`  | Errored, waiting on human input                          |
| `escalated`                 | An agent called `escalate_to_manager`                    |
| `execution-limit-reached`   | Hit dispatch / wall-clock limit                          |

### Reading Execution Results

`exec.results[]` contains nested events. Each top-level entry is typically a `workforce-agent-run` with `children` containing the agent's messages and tool calls.

| `content.type`              | Meaning                              |
|-----------------------------|--------------------------------------|
| `workforce-agent-run`       | An agent execution started           |
| `assistant-message`         | The agent's response text            |
| `tool-run`                  | A tool the agent invoked, with output|
| `workforce-agent-handover`  | Handoff to another agent             |
| `user-message`              | User input (or simulated user input) |

To find a specific tool's output:

```typescript
function findToolOutput(results, toolName) {
  for (const item of results) {
    for (const child of item.children ?? []) {
      if (child.content?.type === "tool-run" &&
          child.content?.tool_details?.name?.includes(toolName)) {
        return child.content.output
      }
    }
  }
  return null
}
```

To get the full conversation for one agent in the run, pull `conversation_id` from its `workforce-agent-run` entry and pass to `relevance_get_agent_task_summary({ agentId, taskId: conversation_id })`.

---

## Workforce Types

| Type      | Per-task execution limit (24h) | Use for                                       |
|-----------|--------------------------------|-----------------------------------------------|
| `default` | 100 node executions            | Task-based workflows that run to completion   |
| `chat`    | 5000 node executions           | Long-lived conversational interfaces          |

Pick `default` unless the workforce is explicitly user-facing chat. Going from `default` to `chat` later is harder than starting `chat`.

---

## Common Patterns

### Linear pipeline

```
Trigger → A → B → C
```

Default `relevance_create_workforce({ agents: [...] })` shape. `forced-handover` + `always-same`. Use for "research → process → deliver" flows where context needs to flow.

### Orchestrator + workers (fan-out)

```
        ↗ Worker A
Trigger → Orchestrator → Worker B
        ↘ Worker C
```

Orchestrator's edges to workers are `tool-call` + `always-create-new`. Each worker self-reports key data in its response text (see `edges.md` § "always-create-new is a one-way mirror"). Orchestrator stitches results into final output.

### Branching with condition node

```
Trigger → Triage → Condition → Path A (if true)
                            → Path B (otherwise)
```

`condition` nodes are deterministic branchpoints (rule-based or LLM-based). Edges out of a condition are always `forced-handover`.

### Multi-layer (orchestrator-of-orchestrators)

Workforces can call workforces (one workforce attaches another's entry-point agent as a tool-call target). Use sparingly -- debugging surface multiplies. Typically only justified when the inner workforce is a reusable capability.

### Knowledge-table intermediary

When the data passed between agents is large or structured, write it to a knowledge table from agent A and have agent B read by ID. Avoids `params_schema` bloat and keeps the audit trail. See `build-kit/agents/knowledge/knowledge-tables.md`.

---

## Common Issues

### "Workforce is stuck in `running`"

Most common causes:

1. An agent is waiting for approval (`action_behaviour: "always-ask"`). Check `exec.pending_approvals` -- if non-empty, that's it.
2. An agent hit its `autonomy_limit`. Check the agent run's `task_details.finished_state`.
3. A tool execution is genuinely slow (long-running scrape, slow API).

`exec.results.filter(r => r.content.type === "workforce-agent-run")` and inspect each `task_details.finished_state` -- anything that isn't `completed` is the blocker.

### "Agent isn't receiving context from the previous agent"

Edge threading is `always-create-new`. Switch to `always-same` if you want context to flow:

```typescript
{ config: { threading_behavior: { type: "always-same" } } }
```

If `always-create-new` is intentional, fix it the other way: instruct the upstream agent to put all needed data in its response text, and have the downstream agent receive that text as its input message.

### "Orchestrator can't find a sub-agent's URL / file path / output"

`always-create-new` is a one-way mirror -- the orchestrator only sees the sub-agent's response text. Re-querying the sub-agent starts a fresh thread with no memory.

Fix: add to the sub-agent's system prompt:

```
Your response MUST end with each of the following on its own line:
  **DOCX URL:** <exact URL from the save tool>
  **Status:** <success | partial | failed>
The orchestrator can ONLY read your response text.
```

Then have the orchestrator parse those fields out.

### "Agent attached to a workforce node has no tools"

Usually a region mismatch in the agent's actions config. Call `relevance_get_agent_tools({ agentId })`. If it returns empty chains, the actions exist but the region in their `entity_link` doesn't match the agent's region. Fix on the agent itself, not the workforce.

### "Delivery agent runs before the content is ready"

Edge ordering is wrong. Send / deliver / publish agents must be **last** in the pipeline:

```
✅ Research → Generate → Deliver
❌ Research → Deliver → Generate
```

Verify the graph in the UI or print `nodes` and `edges` from `relevance_get_workforce`.

### "I removed an edge field via `relevance_update_workforce` but it's still there"

`relevance_update_workforce` merges. Omitting a field doesn't delete it. To remove a field, set it to its new value explicitly. To delete an edge entirely, fetch the full graph, remove the edge from the array, save.

---

## Cancel / Stop / Cleanup

| Operation                     | MCP tool                              |
|-------------------------------|---------------------------------------|
| Cancel a running task         | (no direct cancel; let it timeout)   |
| Delete the workforce          | `relevance_delete_workforce`          |
| List tasks for the workforce  | `relevance_list_workforce_tasks`     |
| Pull a single task's metadata | `relevance_get_workforce_task_metadata` |

There's no "kill task" MCP operation today -- workforces self-terminate at the dispatch / wall-clock limit, on `escalated` / `errored` states, or on completion.

---

## URL Patterns

```
# Workforce edit page
https://app.relevanceai.com/workforces/{region}/{project}/{workforceId}

# Workforce task view
https://app.relevanceai.com/workforces/{region}/{project}/{workforceId}/tasks/{taskId}
```

---

## See Also

- `edges.md` -- edge types, threading, action config, gotchas
- `workforce-patterns.md` -- mental model, default vs chat, wall-clock + dispatch limits
- `playbooks/multi-agent-orchestration.md` -- orchestrator design philosophy
- `build-kit/evals-and-monitoring/test-suites.md` -- testing workforces with eval test sets
- `.claude/rules/PLATFORM_MECHANICS.md` § "Workforce Architecture" -- platform mechanics
