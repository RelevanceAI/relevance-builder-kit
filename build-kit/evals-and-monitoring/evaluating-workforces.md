# Evaluating Workforces

How evaluating a workforce differs from evaluating a single agent. Same MCP tools, different surface area. Read `test-suites.md`, `evaluators.md`, and `llm-as-judge.md` for the shared mechanics -- this file covers only what changes when `resource_type` flips from `agent` to `workforce`.

For the broader build-time decision (single agent vs workforce in the first place), see `build-kit/workforces/agent-vs-workforce.md`.

---

## What Stays the Same

Everything in this list works identically for agents and workforces:

- Test set / test case structure (`relevance_create_eval_test_set`, `relevance_create_eval_test_case`)
- Scenario shape (`prompt`, `max_turns`, `runs_per_scenario`, fixed first-message via `\n\nStart by saying: ...`)
- Evaluator rule types (`llm_judge`, `string_contains`, `string_equals`, `tool_usage`)
- Test-set-specific vs global scoping (with one nuance -- see "Global evaluators" below)
- Run / batch / poll workflow (`relevance_run_evaluation`, `relevance_get_eval_batch_summary`, `relevance_list_eval_runs`)
- Patch semantics on test-set / test-case updates
- Dedicated rule-management tools (`add_eval_test_case_rule`, `update_eval_test_case_rule`, `remove_eval_test_case_rule`)

If you've evaluated agents before, the surface is familiar. The differences are mostly about *where things live* and *what one scenario costs*.

---

## What Changes

### `resource_type` and `resource_id`

Flip both:

```typescript
relevance_create_eval_test_set({
  resource_type: "workforce",     // was "agent"
  resource_id: "<workforce_id>",  // was "<agent_id>"
  name: "Workforce Integration Tests"
})
```

Every eval MCP tool takes both fields. Pass them consistently throughout the flow.

### One scenario = one workforce task (not one conversation)

When the eval runs:
- For an agent, each scenario creates one **conversation** with that agent
- For a workforce, each scenario creates one **workforce task**, which in turn creates one or more **agent conversations** as the graph executes

Practical implications:

| Aspect                          | Agent eval                                       | Workforce eval                                                            |
|---------------------------------|--------------------------------------------------|---------------------------------------------------------------------------|
| Credits per scenario            | One conversation + simulator + judge            | All agent conversations in the task + simulator + judge per rule          |
| Wall-clock time per scenario    | Conversation duration                            | Sum of all agent runs (or longest path if parallel)                       |
| What the judge sees             | The full conversation transcript                 | The full workforce-task transcript (agent runs + handovers + tool runs)  |

Workforce evals are roughly **N× more expensive** than agent evals where N is the number of nodes the typical task touches. Plan accordingly: smaller suites, sharper rules.

### Tool simulation shape: `agent_configs` wraps `tool_configs`

The biggest concrete shape difference. For an agent, simulation lives directly under `tool_configs`. For a workforce, it nests one level deeper, keyed by agent ID:

```typescript
// Agent
tool_simulation_config: {
  tool_configs: {
    "<action_id>": { overrides: { "default": { ... } } }
  }
}

// Workforce
tool_simulation_config: {
  agent_configs: {
    "<agent_id>": {
      tool_configs: {
        "<action_id>": { overrides: { "default": { ... } } }
      }
    },
    "<another_agent_id>": {
      tool_configs: { /* ... */ }
    }
  }
}
```

Two important rules:

1. **Same agent appearing at multiple workforce nodes shares one simulation config.** You cannot mock its tools differently for "the orchestrator's call" vs "the worker's recursive call". If you need different mocks, duplicate the agent.
2. **Test-set-level simulation uses the agent-style flat `tool_configs`** -- applies uniformly across every agent in the workforce. For per-agent control, use scenario-level `agent_configs`.

Full mechanics in `tool-simulation.md`.

### `tool_id` is the agent's action ID, not the workforce-edge ID

For `tool_usage` rules and tool simulation, `tool_id` is the `{{_actions.<id>}}` ID on whichever agent runs the tool -- not the workforce edge ID, not the studio ID. Get it via `relevance_get_agent_tools({ agentId })` for the relevant agent in the workforce, not from the workforce graph.

### Evaluator rules see the whole task

Rules can reference behaviour from any agent in the workforce. The judge sees the entire workforce-task transcript -- every agent's messages, every tool call, every handover. Two consequences:

- **Cross-agent rules are easy to write.** "The research agent searches before the writer agent publishes" is a single rule, naturally expressed.
- **Rule prompts must be specific about which agent does what.** Vague rules like "the agent uses the right tool" don't tell the judge which of the workforce's three agents you mean. Name the agent explicitly: "The research agent calls the web search tool before any other agent runs."

### Global evaluators are per-agent, not per-workforce

The platform doesn't currently support global evaluators that live "on" the workforce itself. Global evaluators live on individual agents (the Evaluators tab). When evaluating a workforce, you can include global evaluators from the constituent agents, but there's no workforce-wide globals tab.

In practice: if there's a quality criterion that applies to "any agent in this workforce" (e.g. "no hallucination"), define it as a global on each constituent agent, or define it test-set-specific on the workforce's eval test sets.

### Production runs work, but the surface is different

Agent Performance tab → run global evaluators against real agent conversations.

Workforce-level production runs evaluate real **workforce tasks**. The shape is similar (run global evaluators, but per-agent inside the workforce task). Roll-up score is the workforce-task average.

Treat the two views as complementary: agent-level Performance for "how is the writer doing?", workforce-level for "how is the pipeline doing end-to-end?".

---

## Designing a Workforce Eval Suite

### Same principles as agent evals, plus two

From `test-suites.md` § "Eval Suite Design Guide":
- Full coverage of major use-cases
- Minimal test cases (each is expensive)
- Targeted scenarios (one capability per case)
- Realistic prompts
- Specific, observable rules

Two additions for workforces:

1. **Cover the *handoffs*, not just the agents.** A workforce can have every agent passing its individual evals and still fail end-to-end because data doesn't flow correctly between agents. At least one scenario per major handoff: "input X arrives → agent A produces Y → agent B receives Y and produces Z".

2. **Mock at the boundary, run the middle real.** Simulate external integrations (CRM, search, email send) but let the agent reasoning and inter-agent handoffs run naturally. Mocking sub-agent outputs means you're testing your mocks, not the workforce.

### A typical workforce test suite (4-6 cases)

| Case                                  | What it tests                                          | Rules                                                                              |
|---------------------------------------|--------------------------------------------------------|------------------------------------------------------------------------------------|
| Happy path, end-to-end                | All nodes run, final output meets requirements         | Tool usage on each agent + final-output `llm_judge`                                 |
| Conditional branch (path A)           | Routing logic when condition is met                    | `tool_usage` on the path-A agent, NOT on path-B agent                              |
| Conditional branch (path B)           | Routing logic when condition is not met                | `tool_usage` on path-B, NOT on path-A                                              |
| Sub-agent failure / partial data      | Workforce handles incomplete data gracefully           | `llm_judge` on whether the orchestrator surfaces the issue, not silently proceeds  |
| Out-of-scope input                    | Workforce rejects work that's not its job              | `llm_judge` on scope guardrail                                                     |
| (Optional) Approval-gated step        | `always-ask` edge surfaces approval, doesn't auto-run | Workforce reaches `pending-approval` state                                         |

That's ~5-15 rules across 4-6 scenarios. Don't go bigger unless you have a specific reason -- workforce evals are credit-heavy.

### Single-input vs multi-turn

Default `max_turns` is 10. For workforces:
- **Use `max_turns: 1`** when the workforce is fired by a non-chat trigger (webhook, recurring, custom_webhook). The workforce gets one input message and runs to completion.
- **Use multi-turn** when the workforce is `chat`-typed and the user has an ongoing conversation with the entry agent.

Most workforces evaluated as automation (lead pipelines, content pipelines, post-call processing) want `max_turns: 1`. Save the credits.

---

## Reading Workforce Eval Results

Same flow as agents:

1. `relevance_get_eval_batch_summary({ eval_batch_id })` -- overall scores, run-by-run pass/fail, `summary_score` (0-1)
2. `relevance_list_eval_runs({ eval_batch_id })` -- each run's `result.rule_results[]`

For a failed workforce-task in an eval run, you can also pull the actual workforce-task ID from the run result and use `relevance_get_workforce_task_messages({ workforceId, taskId })` to inspect the transcript directly. This is how you debug "why did the rule fail?" beyond the judge's stated `reason`.

If a rule is failing intermittently across runs, set `runs_per_scenario: 3-5` to surface the flakiness -- usually a sign the rule prompt needs sharpening or the workforce has nondeterministic handoffs.

---

## Common Issues

### "Rule keeps failing but the workforce did the right thing"

The rule prompt is probably ambiguous about which agent does what. The judge reads the whole transcript and may attribute behaviour to the wrong node. Rewrite the rule to name the specific agent or specific tool by ID.

### "Tool simulation isn't applying"

For workforces, the most common cause is putting `tool_configs` at the top level instead of nesting under `agent_configs.<agent_id>.tool_configs`. Or vice versa for test-set-level simulation. Match the level to the shape:

| Where the config lives  | Required shape                                          |
|-------------------------|---------------------------------------------------------|
| Test-set (workforce)    | Flat `tool_configs` (applies uniformly to all agents)   |
| Test-case (workforce)   | `agent_configs.<agent_id>.tool_configs` (per-agent)     |
| Test-set (agent)        | Flat `tool_configs`                                     |
| Test-case (agent)       | Flat `tool_configs`                                     |

### "Eval batch took 20 minutes"

Workforce evals are slow when the workforce itself is slow. Two levers:

1. Lower `max_turns` to 1 if the workforce isn't chat-style.
2. Aggressively simulate external integrations -- every real API call is wall-clock cost.

### "Same agent at two nodes -- can I simulate them differently?"

No. The platform shares simulation config across all instances of the same agent in a workforce graph. If the two nodes need different mocks, duplicate the agent into a separate agent ID and use that at the second node.

### "I want a workforce-level global evaluator that runs on every agent"

Not currently supported as a single configuration. Workarounds:

- Add the same evaluator as a global on each constituent agent, then include all of them in the workforce eval run
- Or add the evaluator as a test-set-specific evaluator on every test set

---

## See Also

- `build-kit/workforces/agent-vs-workforce.md` -- when to build a workforce vs single agent (read first if you're still deciding)
- `test-suites.md` -- shared mechanics: test sets, scenarios, scenario templates, build-type test depth
- `evaluators.md` -- shared mechanics: evaluator scopes, rule templates by category
- `llm-as-judge.md` -- rule type selection, writing rules that pass/fail cleanly, cost control
- `tool-simulation.md` -- full simulation reference (covers both agent and workforce shapes)
- `monitoring-and-analytics.md` -- production runs, traces, audit logs
- `build-kit/workforces/setup.md` -- workforce lifecycle and debugging via `relevance_get_workforce_task_messages`
- `.claude/skills/eval/SKILL.md` -- `/eval` skill (auto-generates evaluators)
