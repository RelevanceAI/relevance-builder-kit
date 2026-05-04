# Workforce Edges

Edges are how nodes in a workforce graph hand data and control to each other. Edge type and threading behaviour are the two highest-leverage decisions in any workforce design -- get them wrong and the workforce either deadlocks, loops, or silently drops context.

For the lifecycle (create / trigger / debug), see `setup.md`. For the mental model and overall workforce concepts, see `workforce-patterns.md`.

---

## Edge Anatomy

```typescript
{
  edge_id: string,
  source_node_id: string,
  target_node_id: string,
  source_type: "trigger" | "agent" | "tool" | "condition",
  target_type: "trigger" | "agent" | "tool" | "condition",
  config: {
    edge_type: "forced-handover" | "tool-call",
    config: {
      threading_behavior: { type: "always-same" | "always-create-new" },
      action_config?: { ... }    // tool-call edges only
    }
  }
}
```

Two independent decisions per edge:

1. **Edge type** (`forced-handover` vs `tool-call`) -- who decides when this edge fires?
2. **Threading behaviour** (`always-same` vs `always-create-new`) -- does the target see the source's conversation context?

---

## Edge Types

| API name           | UI name        | Who decides when it fires       | Use for                                              |
|--------------------|----------------|---------------------------------|------------------------------------------------------|
| `forced-handover` | "Next Step"    | Platform (deterministic)        | Sequential pipelines, trigger → agent, condition outcomes |
| `tool-call`       | "AI Connection"| Source agent (LLM decides)      | Optional / conditional invocation by the LLM         |

The UI names are what builders see in the visual canvas; the API names are what you'll see in `relevance_get_workforce` output and what's referenced throughout this kit. They're the same thing.

**`forced-handover`** runs the target as soon as the source finishes. No LLM decision involved. The flow is fixed in the graph.

**`tool-call`** exposes the target as a callable tool to the source agent. The source's system prompt sees a tool with the target's name, description, and schema; it calls when (and only when) the LLM decides to.

### Compatibility Matrix

| Source → Target    | `forced-handover` | `tool-call` |
|--------------------|-------------------|-------------|
| trigger → agent    | ✅                | ❌          |
| trigger → tool     | ✅                | ❌          |
| agent → agent      | ✅                | ✅          |
| agent → tool       | ✅                | ✅          |
| agent → condition  | ✅                | ❌          |
| tool → agent       | ✅                | ❌          |
| tool → tool        | ✅                | ❌          |
| condition → agent  | ✅                | ❌          |

**Rule:** `tool-call` is only valid when the source is an `agent` -- only agents can decide.

---

## Choosing Edge Type

```
Is this edge in a deterministic pipeline (always runs in this order)?
  YES → forced-handover
  NO  → Should the source agent decide whether and when to call?
          YES → tool-call
          NO  → Re-shape the graph: this is probably a forced-handover with a condition node upstream
```

**Default to `forced-handover`.** Use `tool-call` only when the source agent genuinely needs to choose at runtime -- for example, an orchestrator that routes based on the input, or an agent that may or may not need a follow-up step.

If a `tool-call` edge fires every single time, replace it with `forced-handover`. The LLM-decision overhead is wasted.

---

## Threading Behaviour

| Threading             | Behaviour                                                          | Use for                                          |
|-----------------------|--------------------------------------------------------------------|--------------------------------------------------|
| `always-same`         | Target shares the source's conversation. Sees full prior context.  | Sequential pipelines where context must flow    |
| `always-create-new`   | Target gets a fresh conversation. No memory of previous steps.     | Isolated tasks, parallel branches, fan-out       |

### `always-create-new` is a one-way mirror

This is the highest-impact gotcha in workforce design.

When an orchestrator calls a sub-agent with `always-create-new`, the sub-agent runs in an **isolated conversation**. After it finishes:

- The orchestrator can read **only the sub-agent's response text**.
- It cannot access the sub-agent's tool call results, artifacts, or internal state.
- It cannot re-query the sub-agent -- every call creates a fresh thread with no memory.

**Anti-pattern:**

```
Orchestrator → Writer: "Write an article about X"      // Writer creates DOCX, gets URL
Orchestrator → Writer: "What was the DOCX URL?"        // NEW thread -- Writer has no memory
```

**Correct:** make the sub-agent self-report all important data in its response text:

```
Writer system prompt:
  "Your response MUST end with: **DOCX URL:** <exact URL from save tool>
   The orchestrator can ONLY read your response text."
```

The orchestrator parses URLs / IDs / results out of the sub-agent's response.

If the orchestrator needs to feed data from one sub-agent to another, extract from the first response and include it in the message of the next invocation.

### `always-same` is a context firehose

Sharing the conversation works for clean linear pipelines but bites in two ways:

- **Token bloat.** Every prior step's output is in the agent's context. Long pipelines burn cache and slow each step.
- **Confused identity.** Late-stage agents see early-stage agents' system prompts and tool results, which can leak roles ("Wait, am I supposed to be the researcher?"). Identity-framing in the system prompt has to be assertive enough to override.

Choose `always-same` when later steps genuinely need earlier context. Choose `always-create-new` when each step is independent and the data flows via explicit response-text contracts.

### Parallel Tool Calls = always-create-new only

Behind the parallel-tool-calls feature flag, every parallel-dispatched edge **must** be `always-create-new`. `always-same` raises a race error because two agents can't write to one conversation simultaneously. See `build-kit/agents/tools/parallel-tool-calls.md`.

---

## Action Config (tool-call edges only)

```typescript
{
  edge_type: "tool-call",
  config: {
    threading_behavior: { type: "always-create-new" },
    action_config: {
      action_behaviour: "never-ask",
      wait_for_completion: true,
      prompt_for_when_to_use: "Use this agent when ...",
      params_schema: {
        type: "object",
        additionalProperties: true,
        properties: {
          linkedin_url: { type: "string", description: "LinkedIn profile URL" }
        },
        required: ["linkedin_url"]
      }
    }
  }
}
```

| Field                    | What it does                                                                  |
|--------------------------|-------------------------------------------------------------------------------|
| `action_behaviour`       | `"never-ask"` auto-approves; `"always-ask"` requires human approval per call |
| `wait_for_completion`    | Source waits for target before continuing                                     |
| `prompt_for_when_to_use` | Injected into source's system prompt as the tool's "when to use" guidance     |
| `params_schema`          | JSON Schema for parameters the source passes to the target                    |

### `additionalProperties: true` is mandatory

The runtime auto-injects `_subagent_params` into every tool-call payload before validation. A schema with `additionalProperties: false` rejects `_subagent_params` and the call fails 100% of the time.

LLM guardrails about what the source should pass belong in `prompt_for_when_to_use`, not in a strict schema.

```json
{
  "type": "object",
  "additionalProperties": true,
  "properties": { "...": "..." },
  "required": ["..."]
}
```

### `prompt_for_when_to_use` is the agent's whole instruction

The orchestrator's LLM only sees three things about a `tool-call` target:
1. The target node's name
2. The target node's description (`entity_information.description`)
3. `prompt_for_when_to_use`

If you want the orchestrator to call this edge only on certain conditions ("only when score >= 6"), say it here. Don't rely on the orchestrator inferring from the target's name.

---

## Common Edge Patterns

### Linear pipeline (forced-handover, always-same)

```
Trigger → Researcher → Writer → Publisher
```

Each step needs the previous step's output. Use `forced-handover` for ordering and `always-same` for context.

### Orchestrator + workers (tool-call, always-create-new)

```
        ↗ Worker A
Trigger → Orchestrator → Worker B
        ↘ Worker C
```

Orchestrator decides which workers to call. Each worker runs isolated. Each worker self-reports key data in its response text. Orchestrator stitches results.

### Branching with a condition node (forced-handover from condition)

```
Trigger → Triage Agent → Condition → Path A (if X)
                                   → Path B (otherwise)
```

`condition` nodes are deterministic branchpoints. Edges out of a condition are always `forced-handover`.

### Approval-gated step (tool-call, always-ask)

```
Orchestrator → Approval-Required Worker
```

Set `action_behaviour: "always-ask"` on this edge. Each call surfaces a human approval before the worker runs.

---

## Edge Update Semantics

`relevance_update_workforce` **merges**, it doesn't replace. To remove a field, you must explicitly set it to its new value -- omitting it does not clear it.

To delete an edge entirely, fetch the workforce, remove the edge from the array, and save.

`relevance_create_workforce` with `agents: [...]` and no explicit `edges` auto-links them as a linear chain with `forced-handover` + `always-same`. As soon as you specify `edges`, auto-linking is off and you own the trigger edge (`source_type: "trigger"`) too. Forget it and the workforce publishes but routes nothing.

---

## See Also

- `setup.md` -- workforce lifecycle, debugging, common issues
- `workforce-patterns.md` -- mental model, type semantics (default vs chat), wall-clock and dispatch limits
- `build-kit/agents/tools/parallel-tool-calls.md` -- parallel dispatch + threading constraint
- `playbooks/multi-agent-orchestration.md` -- orchestrator design philosophy (capability contracts, scale guardrails)
- `.claude/rules/PLATFORM_MECHANICS.md` § "Workforce Architecture" -- platform mechanics summary
- `.claude/rules/BUILD_PRACTICES.md` § "Workforce / Orchestrator Patterns" -- highest-impact build rules
