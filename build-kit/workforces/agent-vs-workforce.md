# Agent vs Workforce: How They Differ and Which to Build

The question every builder arrives with: **"do I build one agent, or a workforce?"** This file is the decision guide. For workforce internals, see `setup.md` and `edges.md`. For agent internals, see `build-kit/agents/`.

---

## The 60-Second Answer

> A **single agent** does ONE job, in ONE conversation, with ONE prompt and a set of tools.
> A **workforce** orchestrates **multiple specialist agents**, each with their own prompt and tools, on a graph that defines who hands work to whom.

### Default to a single agent. Promote to a workforce when one of these is true:

- The work has **two or more distinct skills** (research, write, review) and a single prompt becomes overloaded
- You want to **eval each phase separately** (test the writer's reasoning without re-testing the researcher's tool calls)
- You need **a deterministic handoff** between phases (not just "the agent decides")
- Different phases need **different models / autonomy levels** (cheap Haiku for triage, Opus for synthesis)
- You want **specialist reuse**: the same enrichment agent powers three different pipelines

### Stay with a single agent when:

- The job is one Unit of Action with one or two tools
- The "phases" are really just sequential tool calls (research → respond) and one prompt can guide both
- You're early in the build and don't have evidence one prompt is overloaded
- The output of the agent has to flow back into a chat experience without going through another system. *(Workforce outputs don't naturally route into chat replies -- see "When NOT to Use a Workforce" below.)*

> **Field heuristic:** workforces are for *tasks* (the agent runs a job and produces an output that another system / agent / human picks up). For *chat* (the agent is the user's interface), prefer a single agent -- and consolidate any sub-capabilities into that agent's tools rather than fanning out to a workforce, until you genuinely need parallelism or specialist reuse.

---

## When NOT to Use a Workforce

Real-world failure modes worth flagging up front:

1. **Pure chat experiences.** If the user is talking to "the agent" in a chat surface, the workforce-task abstraction sits awkwardly between the user message and the response. Single agents are the cleaner shape. Use a workforce only when the chat agent's output needs to flow into another agent / system.
2. **Premature decomposition.** Splitting a 200-line prompt into three 80-line agents because the prompt felt long is usually wrong. Cost goes up (more LLM calls, threading overhead), debugging gets harder, and you're now testing handoffs as well as reasoning. Wait for evidence: failing evals, prompt drift, observable confusion.
3. **Single-skill work.** If every "agent" in your proposed workforce is doing variations of the same thing (e.g. five "researchers" each with slightly different prompts), you probably want one agent that branches in its prompt or one agent invoked multiple times -- not five agents.
4. **Tasks with one tool call and one response.** A workforce is overkill. Build one agent with the tool attached.

---

## Category-by-Category Comparison

### 1. Build surface

| Aspect              | Single agent                              | Workforce                                          |
|---------------------|-------------------------------------------|----------------------------------------------------|
| What you author     | One system prompt + tools + knowledge     | A graph of nodes (trigger, agents, tools, conditions) plus edges connecting them |
| Where you build it  | Agent editor                              | Workforce visual canvas (drag/drop nodes + edges) |
| MCP write entry pt  | `relevance_patch_agent` / `upsert_agent`  | `relevance_create_workforce` / `update_workforce` |
| Reusability         | Agent can be a node in many workforces    | Workforce graph is itself one unit (can be triggered, not reused inside another workforce as easily) |

### 2. Edge / connection types (workforce only)

A single agent has no edges -- it just has tools. A workforce uses edges to define who hands work to whom. Two edge types:

| API name           | UI name        | Who decides when it fires    | Use for                                                       |
|--------------------|----------------|------------------------------|---------------------------------------------------------------|
| `forced-handover` | "Next Step"    | Platform (deterministic)     | Sequential pipelines, trigger → agent, condition outcomes    |
| `tool-call`       | "AI Connection"| Source agent (LLM decides)   | Optional / conditional invocation, orchestrator-of-workers   |

Full mechanics in `edges.md`.

### 3. State and context flow

| Aspect                   | Single agent                              | Workforce                                                                   |
|--------------------------|-------------------------------------------|-----------------------------------------------------------------------------|
| Conversation model       | One conversation, one task ID            | One workforce-task ID, plus one or more agent conversation IDs nested inside |
| Context across phases    | Always shared (same conversation)         | Configurable per edge: `always-same` shares context; `always-create-new` isolates |
| Sub-agent visibility     | n/a                                       | If `always-create-new`, parent reads only the sub-agent's response text -- *cannot* re-query |

The `always-create-new` "one-way mirror" is the biggest gotcha: orchestrators can't access sub-agent tool call results, only the final response text. Sub-agents must self-report URLs / IDs / status in their response text. See `edges.md` § "always-create-new is a one-way mirror".

### 4. Triggers

| Aspect                    | Single agent                                              | Workforce                                                            |
|---------------------------|-----------------------------------------------------------|----------------------------------------------------------------------|
| Where triggers attach     | Directly on the agent (`relevance_create_trigger`)        | On the workforce's `trigger` node (in the graph itself)              |
| Available trigger types   | Full set: gmail, slack, calendar, webhook, recurring, etc.| Same set, configured via the trigger node                            |
| Recommended for           | Self-contained agent jobs                                 | Multi-stage workflows where the trigger fans out to coordinated phases |

The actual trigger types and config schemas are the same. The difference is *where* the trigger lives. A workforce always has one trigger node as its entry point.

### 5. Approval flow

| Aspect                       | Single agent                                                   | Workforce                                                                |
|------------------------------|----------------------------------------------------------------|--------------------------------------------------------------------------|
| Autonomy budget              | One `autonomy_limit` (action count) on the agent              | Each agent in the workforce has its own `autonomy_limit`                |
| Approval surface             | One queue of pending approvals on this agent                   | Approvals come from any agent in the workforce; queue is per-agent      |
| Forced human-in-the-loop     | Per-tool `action_behaviour: "always-ask"` on the agent        | Per-edge `action_behaviour: "always-ask"` on `tool-call` edges           |
| Effect of refusal            | Conversation pauses                                            | Workforce pauses with state `pending-approval` or `errored-pending-approval` |

When an approval-gated tool fires inside a workforce, the parent agent's task pauses, not just the sub-agent's. Watch this in long pipelines -- one approval blocks downstream nodes.

### 6. Testing / Evals

| Aspect                     | Single agent eval                              | Workforce eval                                                           |
|----------------------------|------------------------------------------------|--------------------------------------------------------------------------|
| `resource_type`            | `"agent"`                                      | `"workforce"`                                                            |
| `resource_id`              | Agent ID                                       | Workforce ID                                                             |
| What runs per scenario     | One agent conversation                         | One full workforce task (multiple agent conversations)                  |
| Tool simulation shape      | `tool_configs: { <action_id>: { ... } }`       | `agent_configs: { <agent_id>: { tool_configs: { ... } } }`               |
| Per-agent simulation       | n/a (only one agent)                           | Yes -- different agents in the workforce can have different tool mocks   |
| Cost per scenario          | 1 conversation + simulator + judge             | N agent conversations + simulator + judge per rule (more credits)        |

Same tools (`relevance_create_eval_test_set`, `relevance_run_evaluation`, etc.), just with `resource_type` switched. Workforce evals cost more -- fewer scenarios, sharper rules. See `build-kit/evals-and-monitoring/test-suites.md` and `tool-simulation.md`.

### 7. Debugging

| Aspect                              | Single agent                                          | Workforce                                                                 |
|-------------------------------------|-------------------------------------------------------|---------------------------------------------------------------------------|
| Trace surface                       | `relevance_get_agent_task_summary({ agentId, taskId })` | `relevance_get_workforce_task_messages({ workforceId, taskId })`           |
| Granularity                         | One conversation, all tool calls inline               | Nested: workforce-agent-run events, each with child tool-runs / messages |
| Finding a specific tool's output    | One pass through the conversation                     | Walk `results[].children[]` looking for `tool-run` content type           |
| State value to check                | `finished_state` on the conversation                  | `workforce_state` on the workforce-task (5+ values; see `setup.md`)       |
| Common stuck states                 | Hit `autonomy_limit`, waiting on approval             | `pending-approval`, `errored-pending-approval`, `escalated`, `execution-limit-reached` |

For workforces, also pull the individual agent conversation by passing its `conversation_id` (from the workforce task) as `taskId` to the agent task tools -- useful when the workforce trace doesn't surface enough detail.

### 8. Cost shape

| Aspect                       | Single agent                                          | Workforce                                                                 |
|------------------------------|-------------------------------------------------------|---------------------------------------------------------------------------|
| Per task                     | Cost of one conversation                              | Cost of all agent conversations executed during the task                  |
| Tool / API calls             | Same (each tool call costs same regardless of host)   | Same                                                                      |
| Context cost                 | All context lives in one conversation                 | `always-same` edges duplicate context across nodes (cache helps somewhat) |
| Observability cost           | One conversation per task                             | One workforce task + N child tasks (more rows in analytics)               |

Workforces are not free relative to single agents -- extra threading, context duplication on `always-same`, judge multipliers in evals. Worth it when the design wins outweigh the cost.

### 9. Observability and analytics

| Aspect                  | Single agent                                  | Workforce                                                            |
|-------------------------|-----------------------------------------------|----------------------------------------------------------------------|
| Analytics drill-down    | Per-agent metrics (Performance tab)           | Per-workforce dashboard + per-agent within the workforce             |
| Per-conversation review | Conversations tab on the agent                | Tasks tab on the workforce; click into individual agent runs         |
| Production evals        | Global evaluators on this agent only          | Global evaluators per agent (workforce doesn't have its own globals) |
| Audit log events        | Agent create / update / publish / trigger     | Workforce create / update / trigger / edge change + child agent events |

Workforce-level observability tells you *which workforce ran which task*. Agent-level observability tells you *which agent did what inside that task*. You usually need both views.

### 10. Limits

| Limit                     | Single agent                                       | Workforce                                                  |
|---------------------------|----------------------------------------------------|------------------------------------------------------------|
| Autonomy limit            | Per agent (action count, tunable)                 | Per agent inside the workforce, plus...                    |
| Dispatch / execution limit| n/a                                                | 100 nodes/task/24h (`default`), 5000/task/24h (`chat`)    |
| Wall-clock timeout        | Tied to task / conversation timeout               | Workforce-task timeout (longer than agent task)            |
| Concurrency               | Per-agent (one in-flight task model)              | Workforce can have many tasks in flight; each task is isolated |

The dispatch limit on workforces is the most common cause of "stuck" or "execution-limit-reached" workforce-tasks -- usually means the orchestrator is in a loop or fan-out is unbounded.

---

## Migration Paths

### Single agent → Workforce ("graduating")

Triggers for migration:
- Prompt has crossed ~3-4 distinct sections ("you are also responsible for...") and is hard to maintain
- Eval rules are starting to test multiple unrelated behaviours ("does the response include LinkedIn data AND a personalised email?")
- Two distinct phases need different models or different autonomy levels
- A capability needs to be reused across multiple parent agents (extract it as a specialist)

Migration pattern:
1. Identify the phase boundaries in the existing prompt
2. Extract phase 1 as a new specialist agent with its own prompt + tools
3. Update the original agent to call the new specialist as a tool-call edge in a new workforce
4. Move the trigger from the original agent to the new workforce's trigger node
5. Migrate evals: switch `resource_type` to `workforce`, update tool-simulation shape

### Workforce → Single agent ("consolidating")

Triggers:
- The workforce is small (2-3 agents) and every edge is a `forced-handover` with `always-same` (which is functionally equivalent to one prompt with sequential tool calls)
- Output needs to flow into a chat surface and the workforce-task abstraction is in the way
- Per-edge cost is dominating credit usage and the work doesn't actually need parallelism
- Evals have to test cross-agent behaviour anyway, so eval-per-agent isn't paying off

Migration pattern:
1. Concatenate the agents' prompts into one structured prompt (sections, not paragraphs)
2. Attach all the tools to the consolidated agent
3. Move the trigger to the new agent
4. Re-run the eval suite with `resource_type: "agent"`
5. Decommission the workforce

Both directions are reversible. Don't agonise -- migrate when the evidence is clear.

---

## Common Gotchas (by mode)

### Single-agent gotchas

- **Prompt bloat.** Adding a section every time a new edge case shows up. Symptom: prompts past ~5K characters with overlapping rules. Fix: split into a workforce or move static rules to `params` / knowledge.
- **Tool overload.** 10+ tools attached and the agent picks the wrong one. Symptom: high "tool selection" eval failure rate. Fix: sharpen tool descriptions, or split into a workforce where each agent has 2-4 focused tools.
- **Implicit phases.** The prompt has "first do X, then do Y" -- but the LLM mixes them. Fix: enforce phases via a Note Step in tools, or split into a workforce.

### Workforce gotchas

- **`always-create-new` data loss.** Orchestrator can only read sub-agent response text. Sub-agents that produce URLs/files must self-report in their response. See `edges.md`.
- **`additionalProperties: false` on tool-call edges.** 100% failure mode -- the runtime injects `_subagent_params` and the validator rejects it. Always `additionalProperties: true`.
- **Direct `relevance_trigger_agent_sync` on the orchestrator.** Tool-call edges only populate the orchestrator's runtime tool list when triggered through the workforce. Direct agent-trigger shows `toolCalls: []`.
- **Forgetting the trigger edge.** When you specify `edges` explicitly, you own the trigger edge too. Forget it and the workforce publishes but routes nothing.
- **Chat-mode workforce expecting standard chat output.** Chat workforces have a different shape than single chat agents -- the user message arrives at the trigger node, not the agent. UX often needs adjustment.
- **MCP tools "missing" inside a workforce node.** Known platform issue: occasionally tools attached to an agent via MCP don't surface when the agent runs inside a workforce. Workaround: re-attach via the UI, or use `relevance_attach_tools_to_agent` then republish before triggering the workforce.
- **Same agent in multiple nodes share simulation config.** If your workforce has the same agent at two nodes, you can't simulate its tools differently per node. Either accept shared mocks or duplicate the agent.

---

## Quick Decision Tree

```
Does the work have multiple distinct skills (research + write + review)?
  │
  ├─ NO → Single agent (one prompt, the right tools)
  │
  └─ YES → Is the output going to a chat user, or to another system?
            │
            ├─ Chat user → Single agent that orchestrates internally via tools
            │              (consolidate the workforce into one agent)
            │
            └─ Another system / pipeline → Workforce
                                           │
                                           ├─ Sequential phases → forced-handover + always-same
                                           ├─ Conditional / optional → tool-call + always-create-new
                                           └─ Both → Mix per edge (most workforces have both)
```

---

## See Also

- `setup.md` -- workforce lifecycle, debugging, common issues
- `edges.md` -- edge types, threading, action config, gotchas (full mechanics)
- `workforce-patterns.md` -- mental model, type semantics (default vs chat), wall-clock + dispatch limits
- `build-kit/agents/CLAUDE.md` -- single-agent reference (prompt, tools, knowledge, triggers, phone)
- `build-kit/evals-and-monitoring/tool-simulation.md` -- the `tool_configs` vs `agent_configs.tool_configs` shape difference
- `playbooks/multi-agent-orchestration.md` -- orchestrator design philosophy
- `.claude/rules/PLATFORM_MECHANICS.md` § "Workforce Architecture" -- platform mechanics summary
- Public docs: [Workforces concept](https://relevanceai.com/docs) (UI calls them "AI Connection" / "Next Step" -- the API names are `tool-call` / `forced-handover`)
