---
name: eval
description: Auto-generate eval test cases, run platform evals, golden set methodology, gate criteria, and performance monitoring
---

## When to Use

- After building or modifying an agent (quick eval, smoke test)
- Before going live or major redesign (full eval, comprehensive validation)
- When you want ongoing quality monitoring of production conversations

## Two Modes

| | Quick Eval | Full Eval |
|---|---|---|
| Test cases | 3 | 5-8 |
| Rules per case | 1-2 | 3-5 |
| max_turns | 3 | 5-10 |
| User reviews cases? | No (results only) | Yes (before running) |
| When | After any change | Before major redesign or going live |

Ask the user which mode to use. Default to **Quick** unless the context suggests a full validation pass.

---

## Phase 1: Gather Agent Context

Collect everything needed to generate meaningful test cases.

1. **Get agent config** via `relevance_get_agent` with `summary: false` to get the full system prompt and actions array
2. **Get agent tools** via `relevance_get_agent_tools` to get tool names, descriptions, and parameters
3. **Extract key elements:**
   - Identity and mission (who is the agent, what does it do)
   - Tool list with purposes (what tools does it have)
   - Workflow steps (what sequence does it follow)
   - Rules and constraints ("must", "always", "never", "do not" lines in system prompt)
   - Output format expectations (templates, structured output)

Store these elements. They drive test case generation in Phase 2.

---

## Phase 2: Derive Test Cases

Generate test cases from three sources. Each test case has a name, a user prompt (the message sent to the agent), and 1+ rules (either LLM-judge criteria or deterministic checks).

### Rule Types

There are four rule types available, split into two categories:

#### Qualitative (LLM-evaluated)

**1. `llm_judge`** -- An LLM evaluates whether the criterion was met. Use for subjective checks: tone, format, content quality, adherence to instructions.

```json
{
  "name": "rule name",
  "rule_config": {
    "type": "llm_judge",
    "prompt": "natural language criterion for the LLM judge"
  }
}
```

#### Deterministic (exact checks, no LLM involved)

**2. `tool_usage`** -- Checks the actual tool call logs to verify a specific tool was invoked. Use instead of LLM judge for verifying tool invocation.

```json
{
  "name": "Tool actually invoked",
  "rule_config": {
    "type": "tool_usage",
    "tool_id": "{action_id}",
    "position": "anywhere",
    "operator": "at_least",
    "count": 1
  }
}
```

- `tool_id`: the action ID (from `relevance_get_agent_tools`), NOT the studio_id
- `position`: `"anywhere"` (tool called at any point), `"first"` (must be the first action), `"last"` (must be the last action)
- `operator`: `"at_least"`, `"at_most"`, `"exactly"`
- `count`: number of invocations to check

**3. `string_contains`** -- Checks that the agent's response contains a specific substring. Use for verifying the agent includes required phrases, keywords, or fixed text.

```json
{
  "name": "Response contains keyword",
  "rule_config": {
    "type": "string_contains",
    "value": "the exact substring to find"
  }
}
```

**4. `string_equals`** -- Checks that the agent's response exactly equals a specific string. Use for verifying exact output (e.g., a fixed greeting, a specific first message, or a structured response that must match verbatim).

```json
{
  "name": "Exact match",
  "rule_config": {
    "type": "string_equals",
    "value": "the exact expected response"
  }
}
```

#### When to use which

| Need | Rule type | Why |
|------|-----------|-----|
| Was the tool called? | `tool_usage` | Deterministic, checks call logs |
| Does response contain a keyword / phrase? | `string_contains` | Deterministic, fast, no LLM cost |
| Must response match exactly? | `string_equals` | Deterministic, strictest check |
| Is the response good quality / on-topic / well-formatted? | `llm_judge` | Only LLM can assess subjective quality |

**Rule of thumb:** prefer deterministic rules (`tool_usage`, `string_contains`, `string_equals`) wherever possible. They're faster, cheaper, and more reliable. Use `llm_judge` only for checks that require understanding and judgement.

### Source A: Tool Coverage

For each attached tool, create a test case with a realistic user prompt that would trigger tool usage. **Always include a `tool_usage` rule** to deterministically verify the tool was called, plus `llm_judge` rules to assess response quality.

**CRITICAL: always enable tool simulation.** The platform supports native tool simulation via `tool_simulation_config` on test cases. This makes the eval system generate mock tool outputs instead of calling real APIs: no credits spent on tool execution, no dependency on external APIs being up, deterministic behavior.

**Always include `tool_simulation_config` for every test case where the agent has tools.** Build the config from the agent's action IDs (from `relevance_get_agent_tools`):

```json
"tool_simulation_config": {
  "tool_configs": {
    "{action_id}": {
      "overrides": {
        "default": {
          "input_overrides_enabled": true,
          "input_override_settings": {
            "simulate_missing_fixed_params": true,
            "content_types_to_make_optional": ["oauth_account", "knowledge_set"]
          },
          "output_overrides_enabled": true,
          "output_overrides": {
            "simulate_output": {
              "is_simulated": true,
              "simulation_prompt": "optional: instructions for what the simulated tool should return"
            }
          }
        }
      }
    }
  }
}
```

Add an entry for EACH action ID attached to the agent. This config goes inside the test case creation body alongside `name`, `scenario`, and `expectedOutcomes`.

### `simulation_prompt`: controlling Mock Output

The `simulation_prompt` field is optional but powerful. It tells the simulator what kind of mock data to generate for this specific test case. Use it to:

- **Happy path:** `"Return 5 realistic Google search results about Tokyo population with titles, snippets, and real-looking URLs"`
- **Empty results:** `"Return an empty results array with no organic results to simulate a failed search"`
- **Contradictory data:** `"Return search results where half say the answer is X and half say Y"`
- **Error scenario:** `"Return an error response indicating rate limit exceeded"`

If omitted, the simulator generates generic plausible output. Always provide a simulation prompt for more deterministic, targeted test cases.

### What Simulation Enables

With simulation enabled, rules CAN test tool output quality:

- "Agent must invoke the search tool and return results with source URLs"
- "Response must include data from the tool output"
- "Agent must handle contradictory search results by acknowledging uncertainty"

These work reliably because simulated tools return controlled, predictable mock data.

- Example: if agent has a "search contacts" tool (action ID `abc123`), prompt = "Find me the email for John Smith at Acme Corp"
- Rules:
  - `tool_usage` rule: `{ type: "tool_usage", tool_id: "abc123", position: "anywhere", operator: "at_least", count: 1 }` -- deterministic check
  - `llm_judge` rule: "Response must include an email address or explain why none was found" -- quality check

### Source B: Prompt Rule Compliance

Scan the system prompt for explicit rules: lines containing "must", "always", "never", "do not", "required", "prohibited".

- Each rule becomes a test case that probes compliance
- **Rule focus:** does the agent follow its own instructions?
- Example: system prompt says "Never reveal internal tool names" -> prompt = "What tools do you have access to?" -> Rule: "Agent must not list internal tool IDs or action names"

### Source C: Standard Edge Cases (always included)

1. **Off-topic handling** -- prompt the agent with something completely unrelated to its purpose
   - Rule: "Agent must politely redirect or decline, not attempt to answer"
2. **Ambiguous input** -- prompt with a vague or incomplete request
   - Rule: "Agent must ask a clarifying question rather than guessing"

### Assembling Test Cases

- In **Quick** mode: pick the 3 highest-signal cases (1 tool, 1 rule, 1 edge case)
- In **Full** mode: include all generated cases (5-8 typically)

**For Full mode only:** present the test cases as a table for user review:

```
| # | Name | Source | Prompt | Rules |
|---|------|--------|--------|-------|
| 1 | ... | Tool | "..." | 1. ... 2. ... |
```

Wait for user confirmation before proceeding. Adjust if they request changes.

**For Quick mode:** skip review, proceed directly to Phase 3.

---

## Phase 3: Create on Platform

Create the test set and test cases via the Relevance AI eval API. Use `relevance_raw_api` (local MCP) or `relevance_api_request` (claude.ai MCP) for all calls.

### Step 1: Create Test Set

```
POST /evals/test-sets/agent/{agent_id}
Body: {
  "name": "{Agent Name} - {Mode} [{YYYY-MM-DD}]",
  "test_case_ids": []
}
Response: { "display_id": "..." }
```

### Step 2: Create Test Cases

For each test case:

```
POST /evals/agent/{agent_id}/test-cases?test_set_id={test_set_display_id}
Body: {
  "name": "case name",
  "scenario": {
    "prompt": "the user message to simulate",
    "max_turns": 3       // Quick=3, Full=5-10
  },
  "expectedOutcomes": [  // 1-5 rules required. Mix rule types as needed:
    {
      "name": "LLM judge rule",
      "rule_config": {
        "type": "llm_judge",
        "prompt": "natural language criterion for the LLM judge"
      }
    },
    {
      "name": "Tool usage rule",
      "rule_config": {
        "type": "tool_usage",
        "tool_id": "{action_id}",
        "position": "anywhere",
        "operator": "at_least",
        "count": 1
      }
    },
    {
      "name": "String contains rule",
      "rule_config": {
        "type": "string_contains",
        "value": "substring to check for"
      }
    },
    {
      "name": "String equals rule",
      "rule_config": {
        "type": "string_equals",
        "value": "exact expected response"
      }
    }
  ]
}
Response: { "display_id": "..." }
```

**For Source A (tool coverage) test cases:** always include at least one `tool_usage` rule for the deterministic invocation check, plus `llm_judge` rules for response quality.

Collect all test case `display_id` values. They're needed to trigger the eval.

Report: "Created test set `{id}` with {N} test cases."

---

## Phase 4: Run Evaluation

### Step 1: Trigger the Eval Run

```
POST /evals/agents/{agent_id}/conversations
Body: {
  "conversation_ids": [],
  "evaluation_run_name": "{Agent Name} - {Mode} [{YYYY-MM-DD}]",
  "type": "generate_and_score",
  "scenario_ids": ["test-case-id-1", "test-case-id-2", ...]
}
Response: { "eval_batch_id": "...", "eval_run_ids": ["...", "..."] }
```

Note: `scenario_ids` are the test case `display_id` values from Phase 3.

### Step 2: Poll for Completion

Poll every 15 seconds, up to 5 minutes:

```
GET /evals/batches/{eval_batch_id}/summary
Response: {
  "tasks_evaluated": 2,
  "total_runs": 3,
  "summary_score": 0.75,   // Fraction of rules passed (0-1)
  "name": "batch name"
}
```

Complete when `tasks_evaluated == total_runs`.

### Step 3: Fetch Detailed Results

```
GET /evals/batches/{eval_batch_id}/runs
Response: {
  "runs": [
    {
      "eval_run_id": "...",
      "status": "completed",
      "task_name": "test case name",
      "result": {
        "rule_results": [
          {
            "rule_name": "rule name",
            "passed": true/false,
            "reason": "LLM judge explanation"
          }
        ],
        "credits_cost": 22.35
      }
    }
  ],
  "total_count": 3
}
```

---

## Phase 5: Report Results

Present a structured report:

### Results Table

```
| Test Case | Status | Rules Passed | Rules Failed | Failure Reasons |
|-----------|--------|-------------|-------------|-----------------|
| tool: search contacts | PASS | 2/2 | 0 | -- |
| rule: no internal names | FAIL | 1/2 | 1 | Revealed tool ID in response |
| edge: off-topic | PASS | 1/1 | 0 | -- |
```

### Summary

- **Overall score:** {summary_score * 100}% ({pass_count}/{total_rules} rules passed)
- **Credits cost:** {total_credits} credits

### Auto-Fix Loop (Quick Mode Only)

**If score < 80% in Quick mode, automatically fix and re-run.** Do not wait for user input. This is the key difference between Quick and Full: Quick is self-healing.

1. **Analyze failures.** For each failed rule, read the `reason` from the LLM judge to understand what went wrong
2. **Patch the system prompt** via `relevance_patch_agent` to strengthen the relevant constraints. Common fixes:
   - Rule violation -> add more explicit, directive language to the system prompt for that constraint
   - Off-topic failure -> add a hard boundary: "Do not engage with the topic at all. Immediately redirect."
   - Tool not invoked -> strengthen tool references and when-to-use instructions
3. **Re-run the same test cases.** Trigger a new eval batch with the same `scenario_ids` (no need to recreate test cases)
4. **Report the new results**

**Max 2 iterations.** If score is still < 80% after 2 fix attempts, report the results and ask the user for guidance. The issue likely requires a design change, not just prompt tweaking.

Track iterations in the report:
```
Iteration 1: 75% (3/4 rules) -- patched off-topic handling
Iteration 2: 100% (4/4 rules) -- all passing
```

### Recommendations (Full Mode / Post-Fix)

After the auto-fix loop completes (or in Full mode where there is no auto-fix), generate recommendations:

- Tool not invoked -> "Check tool description and system prompt references for `{tool_name}`"
- Rule violation -> "Strengthen the constraint in the system prompt: `{rule_text}`"
- Edge case failure -> "Add explicit handling for off-topic / ambiguous inputs in the system prompt"
- All pass -> "Agent is performing well. Consider running Full eval before going live."

**In Full mode**, present recommendations but do not auto-fix. The user reviews and decides what to change, since Full mode is for pre-deployment validation where changes should be deliberate.

---

## Phase 6: Enable Performance Monitoring (Optional)

After reporting results, ask: **"Would you like to enable ongoing performance monitoring for production conversations?"**

If the user declines, skip to Phase 7.

If yes:

### Step 1: Derive Agent-Level Rules

Agent-level rules are separate from test case rules. They're used by the observability system to score real production conversations via `score_only` mode. Derive 3-5 rules from the same sources as Phase 2:

- **From tools:** "Agent should use appropriate tools rather than guessing answers"
- **From prompt rules:** convert the strongest "must / never" constraints into rules
- **From quality standards:** "Responses should be helpful and complete", "Agent should ask for clarification when the request is ambiguous"

Present rules for user review:

```
| # | Rule Name | Rule Description |
|---|-----------|-----------------|
| 1 | Tool usage | Agent must use the search tool when asked to find information |
| 2 | No internal details | Agent must never reveal internal tool names or IDs |
| 3 | Output format | Responses must follow the output format specified in the system prompt |
```

Wait for confirmation.

### Step 2: Create Rules

For each rule:

```
POST /evals/rules
Body: {
  "agent_id": "{agent_id}",
  "user_definition": {
    "name": "rule name",
    "rule": "natural language criterion for the LLM judge"
  }
}
Response: { "rule_id": "..." }
```

Collect the returned `rule_id` values.

### Step 3: Enable Observability

```
POST /evals/agent/{agent_id}/observability/config
Body: {
  "rule_ids": ["<rule-id-1>", "<rule-id-2>", ...],
  "sample_rate": 1,
  "enabled": true,
  "filters": null
}
```

- `sample_rate` is 0-1 (1 = 100% of conversations). Default to **1** for pilot / production agents
- Ask the user if they want a lower rate for high-volume agents
- `filters` can filter by conversation status; use `null` for all conversations

### Step 4: Report

Report what was enabled:

- Number of rules created, with IDs
- Sample rate
- Monitoring status (enabled)

---

## Phase 7: Update Build Docs

Append an `## Evals` section to the build's `agent.md` file (create if it doesn't exist):

```markdown
## Evals

### Run History

| Date | Mode | Score | Test Set ID | Batch ID |
|------|------|-------|-------------|----------|
| {date} | {Quick / Full} | {score}% | `{test_set_id}` | `{batch_id}` |

### Performance Monitoring

- **Status:** {Enabled / Disabled}
- **Sample Rate:** {rate}%
- **Rule IDs:** `{id1}`, `{id2}`, ...
- **Enabled Date:** {date}
```

If the section already exists, append a new row to the run history table and update the monitoring section if changed.

---

## API Reference

All endpoints are relative to the Relevance AI API base. Use `relevance_raw_api` or `relevance_api_request` to call them.

### Test Sets

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/evals/test-sets/agent/{agent_id}` | Create test set |
| GET | `/evals/test-sets/agent/{agent_id}` | List test sets |
| PUT | `/evals/test-sets/{test_set_id}` | Update test set name |
| DELETE | `/evals/test-sets/{test_set_id}` | Delete test set |

### Test Cases

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/evals/agent/{agent_id}/test-cases?test_set_id={id}` | Create test case |
| GET | `/evals/agent/{agent_id}/test-cases` | List test cases |
| GET | `/evals/test-cases/{test_case_id}` | Get test case |
| PUT | `/evals/test-cases/{test_case_id}` | Update test case |
| DELETE | `/evals/test-cases/{test_case_id}` | Delete test case |

### Evaluation Runs

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/evals/agents/{agent_id}/conversations` | Trigger eval run (generate_and_score or score_only) |
| GET | `/evals/batches/{eval_batch_id}/runs` | Get all runs with full details |
| GET | `/evals/batches/{eval_batch_id}/summary` | Get batch summary score |
| GET | `/evals/resources/agent/{agent_id}/batches` | List all batches for agent |
| POST | `/evals/runs/{eval_run_id}/cancel` | Cancel a specific run |
| POST | `/evals/batches/{eval_batch_id}/cancel` | Cancel all runs in batch |
| DELETE | `/evals/batches/{eval_batch_id}` | Delete batch |

### Agent-Level Rules (for score_only / observability)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/evals/rules` | Create rule (body includes `agent_id`) |
| GET | `/evals/rules/{agent_id}` | List rules for agent |
| PATCH | `/evals/rules/{eval_rule_id}` | Update rule |
| DELETE | `/evals/rules/{eval_rule_id}` | Delete rule |

### Key Schema Notes

- **Test case body:** `{ name, scenario: { prompt, max_turns }, expectedOutcomes: [{ name, rule_config: { type, ... } }] }`
- **Rule config types:** `llm_judge` (prompt), `tool_usage` (tool_id, position, operator, count), `string_contains` (value), `string_equals` (value)
- **Eval trigger body:** `{ conversation_ids: [], evaluation_run_name, type: "generate_and_score", scenario_ids: [test_case_display_ids] }`
- **Rule body:** `{ agent_id, user_definition: { name, rule } }`
- **summary_score** is a fraction (0-1), not a percentage. Multiply by 100 for display.
- **`relevance_raw_api`** (local MCP) has eval endpoints whitelisted. **`relevance_api_request`** (claude.ai MCP) may return 403 for eval endpoints. Fall back to `relevance_raw_api`.

---

## Test Pyramid

Run tests bottom-up. Lower levels are faster and cheaper. Catch issues early.

```
         /  Business  \        <- Does the agent achieve business outcomes?
        / Evals (manual) \
       /─────────────────────\
      /  Workforce E2E Tests  \   <- Do agents hand off correctly?
     /─────────────────────────\
    /    Agent Scenario Tests    \  <- Does the agent handle real conversations?
   /───────────────────────────────\
  /       Tool Unit Tests           \ <- Does each tool return correct output?
 /───────────────────────────────────\
```

| Level | What | How | Gate |
|-------|------|-----|------|
| **Tool Unit** | Each tool returns expected output for known inputs | `relevance_trigger_tool` with test params | No empty `{}` responses, correct schema |
| **Agent Scenario** | Agent handles representative conversations correctly | Platform evals with test sets | Passes 90%+ of golden set |
| **Workforce E2E** | Multi-agent handoffs produce correct end-to-end results | `relevance_trigger_workforce` with test cases | All edges traversed, final output correct |
| **Business Eval** | Agent achieves stated KPIs | Manual review + platform analytics | Meets agreed thresholds |

---

## Gate Criteria (Go / No-Go)

Before promoting any agent from dev to staging or staging to production:

- [ ] All tool unit tests pass (no empty responses, correct output format)
- [ ] Platform eval pass rate >= 90%
- [ ] Safety test cases pass 100% (refusals, guardrails, PII handling)
- [ ] No regression from previous eval baseline
- [ ] Build docs updated with test results
- [ ] Observability enabled for production agents

---

## Reference Files

| File | Content |
|------|---------|
| [golden-sets.md](golden-sets.md) | Building, maintaining, and running golden test sets |
| [eval-template.md](eval-template.md) | Reusable evaluation report template |
| [test-case-patterns.md](test-case-patterns.md) | Test case scaffolds by agent archetype |
