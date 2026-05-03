# Test Suites: Test Sets, Scenarios, and Runs

Platform-native testing for agent behavior. Defines test sets, scenarios within them, and how to run evals against them.

For evaluator rules and templates, see `evaluators.md`. For LLM-as-judge design, see `llm-as-judge.md`. For simulating tool responses inside evals, see `tool-simulation.md`.

---

## Core Concepts

- **Test Sets:** Collections of simulated user interactions grouped by theme or feature. Each test set contains scenarios and can have its own evaluators
- **Scenarios:** Individual test cases within a test set. Each has a name, a prompt (what the simulated user says), and a max turn count (1-50)
- **Evaluators:** Rules that score agent responses. Come in two scopes (see `evaluators.md`). Each evaluator has a name and a rule (natural language pass/fail criteria)
- **Runs:** Executions of a test set. Each run produces per-scenario, per-evaluator scores and an overall average

---

## Creating Test Sets and Scenarios

Each scenario needs:
- **Name:** Descriptive identifier (e.g., "Happy path - contact enrichment")
- **Prompt:** What the simulated user says to the agent. Write as a persona, not as instructions
- **Max turns:** 1-50. Use 1 for single-shot tasks, 3-5 for tool-using agents, 10+ for multi-turn conversations

**Prompt guidance:**
```
Good: "Hi, I need to enrich the contact john@acme.com with their LinkedIn profile and company size."
Bad: "Test that the agent can enrich contacts using the LinkedIn lookup tool."
```

The prompt should sound like a real user, not a test specification. Include realistic details (names, emails, URLs) that match what the agent would encounter in production.

---

## Running Test Set Evals

1. Navigate to Agent > Evals tab
2. Select a test set to run
3. Optionally include global evaluators alongside the test set's own evaluators
4. Click "Run Evaluation"
5. Results show:
   - **Overall average score** (0-100%) across all scenarios and evaluators
   - **Per-scenario breakdown** with individual evaluator scores
   - **Per-evaluator breakdown** to identify which quality criteria are failing

**Interpreting results:**
- 90%+ -- Production ready for the tested scenarios
- 70-90% -- Needs prompt or tool refinement. Check which evaluators are failing
- Below 70% -- Significant issues. Review failing scenarios individually to diagnose

---

## Production Runs (Performance Tab)

Production runs evaluate **real agent conversations** -- not simulated test scenarios. This is the primary use case for global evaluators.

**Why production runs exist:** In test sets, you control the input and know what "good" looks like. In production, users send unpredictable messages. Global evaluators let you define quality criteria (accuracy, tone, guardrails) that apply regardless of what the user asked.

**How it works:**
1. Define global evaluators on the agent (Evaluators tab)
2. Navigate to Agent > Performance tab
3. Select which global evaluators to run against production conversations
4. Review scores to identify quality trends across real usage

**When to use production runs:**
- After deploying a new agent version to monitor quality drift
- To validate that test-set evals translate to real-world performance
- For ongoing quality monitoring on production agents

---

## Published Checks (Upcoming)

> **Status: Not yet released.** This feature is in development.

Published checks will enable CI/CD-style gating for agent publishing. The planned behavior:
- Configure a specific test set (e.g., "Golden Examples") as a publish check
- Set a pass threshold
- When you publish, the test set runs automatically
- If it passes the threshold, the agent auto-publishes
- If it fails, the publish is blocked

This is similar to CI that runs tests and only merges if the suite passes.

**Recommendations by build type (to apply once this feature ships):**
- **Demo builds:** No check needed
- **Pilot builds:** Optional check at 70% threshold
- **Production builds:** Required check at 80-90%
- **Enterprise builds:** Required check at 90%, with manual review of failures before override

---

## Credit Cost

Each eval run consumes credits from three sources:
1. **Agent task credits:** The agent runs normally, consuming its usual credits per task
2. **Simulator credits:** The simulated user persona uses an LLM to generate messages
3. **Evaluator credits:** Each evaluator assessment uses an LLM to score the response

**Order-of-magnitude guidance:**
- Single scenario, 1 turn, 1 evaluator: ~3x a normal task (agent + simulator + evaluator)
- 5 scenarios, 3 turns each, 3 evaluators: ~15-20x a normal task
- Factor in tool execution credits if tools make external API calls

Plan eval runs accordingly. During active development, run individual scenarios. Run the full suite before publication milestones.

---

## Tool Testing Protocol (Pre-Eval Setup)

Always test tools independently before attaching to agents:

1. Use `relevance_trigger_tool` with representative inputs
2. Check for empty `{}` output -- indicates missing output configuration
3. Verify error handling returns useful messages, not silent failures
4. Test with edge case inputs (empty strings, long text, special characters)

If tools return empty or malformed output, evaluators will surface symptoms (agent ignores tool, fabricates response) but the root cause is the tool. Fix tools first.

---

## Eval Suite Design Guide

**When to create evals:**
- After initial agent build is stable and tested manually
- Before production handoff (required for Production and Enterprise builds)
- When making significant prompt or tool changes to a production agent
- As part of ongoing quality monitoring via production runs (Performance tab)

**Minimum coverage by build type:**

| Build Type | Test Sets | Test-Set Evaluators | Global Evaluators | Published Check |
|------------|-----------|--------------------|--------------------|-----------------|
| Demo | 0 (manual testing only) | 0 | 0 | None |
| Pilot | 1 (2-3 scenarios) | 1-2 | 1-2 (accuracy, format) | Optional |
| Production | 2-3 (5-10 scenarios total) | 3-5 per set | 3-5 (used for production runs) | Required (80%+) |
| Enterprise | 3+ (10+ scenarios total) | 5+ per set | 5+ with category coverage | Required (90%+) |

**Converting rubric checks to eval scenarios:**

Local testing rubrics (from `.claude/rules/BUILD_PRACTICES.md`) map directly to platform evals:

1. Take each rubric check (e.g., "Agent correctly identifies meeting type")
2. Write a scenario prompt that would trigger that behavior (persona-style)
3. Write an evaluator rule that assesses the rubric criterion
4. Group related checks under test-set-specific evaluators
5. Promote universal quality checks (accuracy, tone, guardrails) to global evaluators for production monitoring

---

## Scenario Templates

### Happy Path
```
Name: [Feature] - Happy path
Prompt: "Hi, I need to [primary use case] for [realistic entity].
         Here are the details: [realistic input data]."
Max turns: 3-5
Evaluators:
  - "[Expected tool] must be called with the correct parameters"
  - "Final response must include [expected output fields]"
```

### Edge Case
```
Name: [Feature] - Edge case - [condition]
Prompt: "I need to [use case] but [unusual condition].
         [Realistic details that trigger the edge case]."
Max turns: 3-5
Evaluators:
  - "Agent must handle [condition] gracefully without errors"
  - "Agent must [expected behavior for this edge case]"
```

### Error Handling
```
Name: [Feature] - Error - [error type]
Prompt: "Please [action that will trigger an error condition].
         [Details that make the error scenario realistic]."
Max turns: 3
Evaluators:
  - "Agent must inform the user about the error clearly"
  - "Agent must not retry more than [N] times"
  - "Agent must suggest alternative actions or next steps"
```

### Multi-Turn
```
Name: [Feature] - Multi-turn [workflow]
Prompt: "I'd like to [initial request]. [Follow-up that
         requires context from turn 1]. [Final clarification]."
Max turns: 10
Evaluators:
  - "Agent must maintain context across all turns"
  - "Agent must not re-ask for information already provided"
  - "Final output must incorporate all provided details"
```

---

## What to Test by Agent Type

| Agent Type | Key Scenarios | Key Evaluators |
|------------|--------------|----------------|
| CRM Enrichment | Lookup existing contact, lookup missing contact, bulk enrichment, duplicate handling | Tool usage, accuracy, output format |
| Meeting Intelligence | Pre-meeting prep, post-meeting summary, action item extraction, no-recording scenario | Accuracy, output format, error handling |
| Customer Support | FAQ response, escalation trigger, multi-turn clarification, out-of-scope request | Guardrail, tone, tool usage, accuracy |
| Workflow Automation | Happy path trigger, missing data, approval flow, error recovery | Tool usage, error handling, output format |
| Research / Analysis | Single-source research, multi-source synthesis, conflicting data, no-results scenario | Accuracy/hallucination, output format, tool usage |

---

## Testing by Build Type

Match testing depth to the build's stage and importance:

**Demo:**
- Manual walkthrough only
- No platform evals needed
- Test with 2-3 representative prompts in the chat UI

**Pilot:**
- 1 test set with 2-3 scenarios covering the primary use case
- 1-2 global evaluators (accuracy + output format)
- No published check (manual eval runs only)
- Run evals after each significant prompt change

**Production:**
- 2-3 test sets covering happy paths, edge cases, and error handling
- 3-5 global evaluators used for both test sets and production monitoring
- Published check at 80%+ (once feature ships)
- Run production evaluators via Performance tab for ongoing monitoring
- Document eval results in agent.md

**Enterprise:**
- 3+ test sets with comprehensive coverage
- 5+ global evaluators covering all quality dimensions
- Published check at 90%+ (once feature ships)
- Production runs monitored continuously via Performance tab
- Analytics dashboards monitored for drift
- Observability traces reviewed for cost optimization
- Regular test set expansion based on production incidents

---

## See Also

- `evaluators.md` -- Evaluator scopes, rule design, templates
- `llm-as-judge.md` -- Model selection, scoring tiers, hallucination evaluators
- `tool-simulation.md` -- Simulating tool responses inside scenarios
- `monitoring-and-analytics.md` -- Production monitoring, traces, dashboards
- `.claude/skills/eval/SKILL.md` -- `/eval` skill (auto-generates test cases)
