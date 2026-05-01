# Tool Simulation

When an eval scenario runs, by default every tool call hits the real external system — costing credits, sending emails, updating CRMs. Tool simulation lets you override individual tool outputs with deterministic stub responses so the agent reasons against a simulated world.

For test set / scenario design, see `test-suites.md`. For evaluator rule types, see `llm-as-judge.md`.

---

## What to Simulate

Simulate **external integrations** — anything that calls an API, hits a database, or has side effects.

| Simulate                                | Don't simulate                                          |
|-----------------------------------------|---------------------------------------------------------|
| Search APIs (Google, Perplexity, web)   | The agent's LLM reasoning                              |
| CRM lookups (HubSpot, Salesforce)       | Code-step computation (deterministic, free, fast)      |
| Enrichment APIs (Clearbit, ZoomInfo)    | Knowledge table reads (cheap, deterministic data)      |
| Outbound integrations (email, Slack)    | Internal Relevance routing (workforce edges, etc.)     |
| File / image generation                 |                                                          |
| Knowledge writes that have side effects |                                                          |

The goal: the agent's reasoning runs for real; only the messy / expensive / side-effecty parts are mocked.

### Anti-Pattern: Don't Simulate LLM-Only Tools

If a tool's only step is a `prompt_completion`, that reasoning belongs in the agent's system prompt, not in a tool. Creating tools-around-prompts so you can simulate them in evals means the eval tests a fake LLM output, bypassing the actual agent reasoning you want to validate.

| Wrong                                                                          | Right                                                                  |
|--------------------------------------------------------------------------------|------------------------------------------------------------------------|
| Create "Score Lead" tool (single LLM step) → simulate it                       | Put scoring logic in agent system prompt → eval the agent              |
| Create "Draft Email" tool (single LLM step) → simulate it                      | Put writing logic in agent system prompt → eval the agent              |
| Simulate "Lookup Company" tool (real API call)                                 | ✅ Correct — tool calls an external service                            |
| Simulate "Enrich + Summarize" (real API + `prompt_completion` post-processing) | ✅ Correct — the API part is real-world, the LLM post-processing runs naturally |

**Exception:** tools that combine real external work with `prompt_completion` are fine to simulate. The anti-pattern is only when LLM is the *only* step.

---

## Config Levels

Tool simulation config can live at three places, with strict precedence:

| Level               | Set on                                          | Applies to                                                | Overridden by   |
|---------------------|-------------------------------------------------|-----------------------------------------------------------|-----------------|
| **Test-set level**  | `tool_simulation_config` on the test set        | All scenarios in the test set                            | Scenario level  |
| **Scenario level**  | `tool_simulation_config` on the test case       | That scenario only                                        | Nothing (wins)  |
| **Batch level**     | `tool_simulation_config` on the run-eval call   | Ad-hoc runs that pass `scenario_ids` (NOT `test_set_id`) | Scenario level  |

**Rules:**
- Scenario-level config always wins.
- You cannot pass `tool_simulation_config` to `relevance_run_evaluation` together with `test_set_id` — the platform returns 400. Set test-set or scenario configs ahead of the run instead.

**When to use test-set-level config:** every scenario in the suite needs the same tool mocks (e.g. all 8 scenarios mock the same CRM lookup). Saves repeating the same block on every test case. Individual scenarios can still override.

**When to use scenario-level config:** the mock differs per scenario (one scenario gets a "no results" CRM response, another gets a populated one). This is also the only way to set per-agent simulations in a workforce — see below.

---

## Agents: `tool_configs`

For agent evals, the config keys tools by their `action_id` (the `{{_actions.<id>}}` ID, not the tool's studio ID).

```typescript
{
  tool_configs: {
    "<tool_action_id>": {
      overrides: {
        "default": {                         // applies to every call to this tool
          output_overrides_enabled: true,
          output_overrides: {
            simulate_output: {
              is_simulated: true,
              simulation_prompt: "Return a sunny weather forecast for the requested city, around 22C, low wind.",
              model: "anthropic-claude-haiku-4-5"   // optional; defaults to openai-gpt-4o-mini
            }
          }
        }
      }
    }
  }
}
```

`overrides` can also be keyed by call index (`"0"`, `"1"`, `"2"`) when you need different simulated outputs across multiple calls in the same conversation. `"default"` covers everything not explicitly indexed.

### Example: scenario-level simulation

```typescript
relevance_create_eval_test_case({
  resource_type: "agent", resource_id: "<agent_id>",
  test_set_id: "<test_set_id>",
  name: "Weather lookup test",
  scenario: { prompt: "What is the weather in Sydney?", max_turns: 5 },
  rules: [
    { name: "Reports weather",
      rule_config: { type: "llm_judge",
        prompt: "The agent reports a weather forecast for Sydney with a temperature." } }
  ],
  tool_simulation_config: {
    tool_configs: {
      "<weather_lookup_action_id>": {
        overrides: {
          "default": {
            output_overrides_enabled: true,
            output_overrides: {
              simulate_output: {
                is_simulated: true,
                simulation_prompt: "Return a sunny forecast for Sydney, 22C, light wind."
              }
            }
          }
        }
      }
    }
  }
})
```

### `simulation_prompt` design

The simulation prompt is given to a small LLM that generates the tool's output. Treat it like a JSON-schema-aware mock:

| Vague prompt                                           | Specific prompt                                                              |
|--------------------------------------------------------|------------------------------------------------------------------------------|
| "Return a contact"                                     | "Return `{ name: 'Jane Doe', email: 'jane@acme.com', title: 'VP Eng', company: 'Acme', linkedin: '...'}`" |
| "Pretend the search succeeded"                         | "Return 3 search results about quantum computing breakthroughs in 2024, each with `title`, `url`, `snippet`" |
| "Make up a CRM record"                                 | "Return a HubSpot contact in the standard `{ id, properties: {...} }` shape with `firstname`, `lastname`, `email` set; `lifecyclestage: 'lead'`" |

The closer the simulated output is to the real shape, the less the agent's downstream reasoning has to compensate.

---

## Workforces: `agent_configs` Wrapping `tool_configs`

For workforce evals, the config wraps per-agent tool configs by agent ID:

```typescript
{
  agent_configs: {
    "<agent_id>": {
      tool_configs: {
        "<tool_action_id>": {
          overrides: { "default": { /* ...same shape as agent eval... */ } }
        }
      }
    },
    "<another_agent_id>": {
      tool_configs: { /* ... */ }
    }
  }
}
```

**Two important rules:**

1. **If the same agent appears in multiple nodes of the workforce graph, all instances share the same simulation config.** You cannot mock a tool differently for "the orchestrator's call to the worker agent" vs "the worker agent's recursive self-call".
2. **Test-set-level workforce config uses the agent-style `tool_configs` (not `agent_configs`)** when the simulation should apply uniformly across all agents in the workforce. Use scenario-level `agent_configs` for per-agent control.

### Example: per-agent simulation in a workforce

```typescript
relevance_create_eval_test_case({
  resource_type: "workforce", resource_id: "<workforce_id>",
  test_set_id: "<test_set_id>",
  name: "Multi-agent collaboration",
  scenario: { prompt: "Research and publish an article about quantum computing." },
  rules: [
    { name: "Right tools used",
      rule_config: { type: "llm_judge",
        prompt: "The research agent searches for information and the writer agent publishes." } }
  ],
  tool_simulation_config: {
    agent_configs: {
      "<research_agent_id>": {
        tool_configs: {
          "<web_search_action_id>": {
            overrides: { "default": {
              output_overrides_enabled: true,
              output_overrides: { simulate_output: {
                is_simulated: true,
                simulation_prompt: "Return 3 plausible search results about quantum computing in 2024."
              } }
            } }
          }
        }
      },
      "<writer_agent_id>": {
        tool_configs: {
          "<publish_action_id>": {
            overrides: { "default": {
              output_overrides_enabled: true,
              output_overrides: { simulate_output: {
                is_simulated: true,
                simulation_prompt: "Return `{ status: 'published', url: 'https://example.com/article-123' }`."
              } }
            } }
          }
        }
      }
    }
  }
})
```

---

## Setting / Clearing Simulation on Existing Test Cases

```typescript
relevance_set_eval_test_case_simulation_config({
  resource_type, resource_id,
  test_case_id: "<id>",
  tool_simulation_config: { /* ... */ }   // full replacement, not patch
})

// Clear:
relevance_set_eval_test_case_simulation_config({
  resource_type, resource_id,
  test_case_id: "<id>",
  tool_simulation_config: null
})
```

This is **full replacement**. Always pass the complete config, not a partial.

For test-set-level simulation, use `relevance_update_eval_test_set` (which uses patch semantics — only sends the fields you change).

---

## Per-Call Indexing for Sequenced Calls

When the agent calls the same tool multiple times in one scenario and each call should return different data:

```typescript
{
  tool_configs: {
    "<action_id>": {
      overrides: {
        "0": { /* first call: return contact A */ },
        "1": { /* second call: return contact B */ },
        "default": { /* anything beyond → return empty */ }
      }
    }
  }
}
```

Useful for scenarios like "the agent should look up three different LinkedIn profiles in sequence and stitch the results into a brief".

---

## When NOT to Simulate (and Just Run Real Tools)

Sometimes the real call is cheaper or more useful than mocking:

- The tool is fast, free, deterministic (e.g. a code step doing a calculation, a knowledge table read of stable reference data)
- You want to test the actual integration (API contract, auth, rate limits)
- The mock would be so detailed that maintaining it costs more than running real

For integration tests against production-shaped data, run a small subset of scenarios without simulation against a sandbox / dev environment of the external system.

---

## Common Issues

### "Cannot provide tool_simulation_config when using test_set_id"

You passed both `tool_simulation_config` and `test_set_id` to `relevance_run_evaluation`. Remove `tool_simulation_config` from the call — when running a whole test set, simulation comes from the test set's own config or individual test cases.

### "The agent ignored my simulated output"

Most common causes:

1. The `<tool_action_id>` is wrong. It must be the agent's action ID (the `{{_actions.<id>}}` value), not the tool's studio ID. Check via `relevance_get_agent_tools({ agentId })`.
2. `output_overrides_enabled: false`. The flag must be `true` for `output_overrides` to apply.
3. `is_simulated: false`. Inside `simulate_output`, this must also be `true`.
4. The tool's real output is being returned instead because the agent never reached the simulation step (e.g. the agent didn't call the tool, or hit `autonomy_limit` first).

### "Simulated output doesn't match the tool's real schema"

The `simulation_prompt` is too vague. Sharpen it to specify field names, types, and a worked example. The judge LLM that generates simulated output is small — be explicit about shape.

### "Per-call indexing isn't taking effect"

Per-call indexes (`"0"`, `"1"`) count tool calls within one scenario run. If the agent retries after a "failure", the retry counts as a separate index. Add a `"default"` fallback so anything past your last indexed call has a defined output.

---

## See Also

- `test-suites.md` -- test set / scenario design, `runs_per_scenario`, `max_turns`
- `evaluators.md` -- evaluator scopes; tool-usage rules pair well with simulation
- `llm-as-judge.md` -- rule design, model selection, cost control
- `build-kit/agents/tools/state-mapping.md` -- how tool outputs are structured (informs your `simulation_prompt`)
- `.claude/skills/eval/SKILL.md` -- `/eval` skill (can auto-generate scenarios with simulation)
