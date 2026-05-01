# Golden Test Sets

A golden set is a curated collection of test inputs with expected behaviors that serves as the baseline for agent evaluation. Golden sets are the most important testing artifact you maintain.

---

## Building a Golden Set

### Step 1: Define Categories

Every golden set should cover these categories:

| Category | Description | Minimum Cases |
|----------|-------------|--------------|
| **Happy path** | Typical, well-formed requests | 3-5 |
| **Edge cases** | Boundary inputs, missing fields, unusual formats | 2-3 |
| **Ambiguous** | Inputs where the agent should ask for clarification | 1-2 |
| **Out of scope** | Requests the agent should refuse | 1-2 |
| **Adversarial** | Prompt injection, role confusion | 1-2 |

Aim for 10-15 test cases total. More is better but with diminishing returns after 20.

### Step 2: Write Test Cases

Each test case needs:

```markdown
### TC-001: [Descriptive name]

**Category:** Happy path
**Input:** "The exact message sent to the agent"
**Expected behavior:**
- Agent calls [specific tool]
- Response includes [specific data points]
- Output follows [template name] format
**NOT expected:**
- Agent should NOT call [wrong tool]
- Agent should NOT hallucinate [specific field]
```

Focus on **expected behavior**, not exact text. Agent responses will vary. That's fine. Test for:

- Correct tool selection
- Required data present in output
- Format compliance
- Appropriate refusals

### Step 3: Store the Golden Set

Store golden sets alongside the build's docs:

```
builds/{build-name}/
  golden-set.md       # Test cases with expected behaviors
  eval-results/       # Timestamped eval reports
    eval-2025-01-15.md
```

---

## Running a Golden Set

**Preferred: platform evals** (use the `/eval` skill):

1. Create a test set on the platform from your golden set cases
2. For each case, add eval rules (prefer `tool_usage` and `string_contains` over `llm_judge`)
3. **Enable tool simulation** on every test case to avoid calling real APIs during eval
4. Run `generate_and_score` eval batch
5. Review per-case results from the batch summary

**Fallback: manual triggering** (for quick smoke tests):

1. Trigger the agent: `relevance_trigger_agent({ agent_id: "...", message: "..." })`
2. Poll for result: `relevance_poll_agent_result({ ... })`
3. Compare response against expected behavior

**Scoring:**

- Platform evals report `summary_score` (0-1) across all rules
- 90%+ = passing gate for promotion
- Review individual rule failures to distinguish agent issues from test design issues

**Tool simulation is critical.** Without it, evals trigger real integrations (Notion writes, CRM updates, API calls). With it, the platform generates controlled mock outputs. Always include `tool_simulation_config` with an entry for every action ID on the agent. Use `simulation_prompt` to control mock data per test case.

---

## Maintaining Golden Sets

### When to Update

| Trigger | Action |
|---------|--------|
| New tool added to agent | Add test cases covering the new tool |
| Workflow logic changed | Update expected behaviors for affected cases |
| New edge case discovered in production | Add to golden set |
| False positive (test fails but agent is correct) | Update expected behavior |
| Agent scope expanded | Add cases for new capabilities |

### When NOT to Update

- Agent fails a test case legitimately. Fix the agent, not the test
- Test case is flaky due to LLM variance. Make expected behavior less specific, don't remove
- You want the pass rate to look better. That defeats the purpose

### Version Control

Golden sets evolve with the agent. When updating:

1. Note the change in the golden set file with a date comment
2. Re-run the full set after changes to establish new baseline
3. Keep eval results timestamped so you can track trends

---

## Golden Set Anti-Patterns

- **Testing exact text:** LLM outputs vary. Test behavior and structure, not wording
- **Too few cases:** 3 happy-path cases isn't a golden set, it's a smoke test
- **Never updating:** a golden set that doesn't evolve with the agent becomes useless
- **Testing implementation:** "Agent calls tool X" is good. "Agent sends exactly these params" is brittle
- **No adversarial cases:** if you don't test refusals, you don't know if guardrails work
