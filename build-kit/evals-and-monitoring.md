# Evals & Monitoring Reference

Complete reference for Relevance AI's quality and observability features. Covers platform-native Evals, Analytics dashboards, and OpenTelemetry-based Observability.

> **Relationship to local testing:** This doc covers platform features. For local testing rubrics and pre-build testing protocol, see `BUILD_PRACTICES.md` "Testing" section. Platform evals complement -- not replace -- local rubrics.

---

## Quick Reference

| Feature | Tier | UI Location | What It Measures |
|---------|------|-------------|-----------------|
| Evals | All plans | Agent > Evals tab | Agent behavior against defined test sets + evaluator rules |
| Performance | All plans | Agent > Performance tab | Production conversation quality via global evaluators |
| Analytics | Enterprise | Analytics section | Task volume, credit usage, error rates, action breakdowns |
| Observability | Enterprise | Settings > Observability | Full execution traces via OpenTelemetry export to S3 |
| Audit Logs | Enterprise | Settings > Audit Logs | Platform events (agent/tool/workforce/permission changes) |

---

## Evals (Platform-Native Testing)

### Core Concepts

- **Test Sets:** Collections of simulated user interactions grouped by theme or feature. Each test set contains scenarios and can have its own evaluators
- **Scenarios:** Individual test cases within a test set. Each has a name, a prompt (what the simulated user says), and a max turn count (1-50)
- **Evaluators:** Rules that score agent responses. Come in two scopes (see below). Each evaluator has a name and a rule (natural language pass/fail criteria)
- **Runs:** Executions of a test set. Each run produces per-scenario, per-evaluator scores and an overall average

### Evaluator Scopes

There are two distinct types of evaluators with different purposes:

**Test-set-specific evaluators** are defined within a test set and only apply to that test set's scenarios. Use these for criteria specific to a particular feature or workflow being tested.

**Global evaluators** (found in the Evaluators tab on the agent) are defined at the agent level and can be:
1. **Included in test set runs** -- reusable quality checks across multiple test sets
2. **Selected for production runs** (Performance tab) -- this is their primary purpose. Since production conversations don't have predefined "right answers," global evaluators provide the quality criteria to evaluate real agent interactions

Global evaluators are per-agent, not cross-agent.

### Creating Test Sets and Scenarios

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

### Creating Evaluators

Evaluators assess agent behavior with natural language rules.

**Evaluator rule examples:**

| Pattern | Example Rule |
|---------|-------------|
| Tool usage | "The agent must call the LinkedIn lookup tool before attempting to enrich a contact" |
| Output format | "The agent's final response must include a structured summary with Name, Company, and Title fields" |
| Accuracy | "The agent must not fabricate information. If data is unavailable, it should say so explicitly" |
| Error handling | "If the tool returns an error, the agent must inform the user and suggest next steps rather than silently failing" |
| Guardrail | "The agent must not discuss topics outside its defined scope. If asked about unrelated topics, it should redirect" |
| Tone | "The agent must maintain a professional, concise tone. No em dashes, no excessive enthusiasm" |
| Data quality | "All email addresses in the output must match the format user@domain.tld" |

**Choosing scope:**
- If the rule only matters for a specific test set (e.g., "must call the enrichment tool"), make it test-set-specific
- If the rule should apply to all test sets AND production monitoring (e.g., "no hallucination"), make it a global evaluator

### Running Test Set Evals

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

### Production Runs (Performance Tab)

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

### Published Checks (Upcoming)

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

### Credit Cost

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

## Analytics (Enterprise)

### Primary Metrics

| Metric | What It Shows | Why It Matters |
|--------|--------------|----------------|
| Tasks | Total tasks processed over time | Volume trends, adoption tracking |
| Tasks to Review | Tasks flagged for human review | Approval mode burden, autonomy tuning |
| Actions Used | Tool/action invocations | Tool adoption, over/under-use patterns |
| Credits Used | Credit consumption over time | Cost tracking, budget forecasting |

### Dashboards

- **Trends:** Time-series view of all four primary metrics. Use for spotting volume changes, seasonal patterns, or post-deployment shifts
- **Credits breakdown:** Credits consumed by agent, tool, and action type. Use for cost optimization -- find expensive agents or over-called tools
- **Workforce breakdown:** Per-workforce task distribution. Use for load balancing and identifying bottlenecks in multi-agent systems
- **Agent breakdown:** Per-agent performance metrics. Use for comparing agent versions or identifying underperformers
- **Action breakdown:** Per-action usage frequency and credit cost. Use for identifying redundant or underused tools

### Per-Agent Drill-Down

Click into any agent to see:
- **Error rate:** Percentage of tasks that failed. Spikes indicate prompt, tool, or integration issues
- **Actions per task:** Average tool calls per task. High values may indicate retry loops or inefficient workflows
- **Credits per task:** Average cost per task. Compare against budget targets
- **Task duration:** Time from start to completion. Helps identify slow tools or unnecessary turns

**Actionable patterns:**
- Rising error rate after prompt change -- rollback or fix the prompt
- High actions-per-task -- check for retry loops or missing early-exit conditions
- Credits-per-task increasing over time -- model drift or prompt bloat

---

## Observability (Enterprise)

### OpenTelemetry Export

Relevance AI exports execution traces via OpenTelemetry to an S3 bucket you configure.

**Setup summary:**
1. Navigate to Settings > Observability
2. Configure S3 bucket details (bucket name, region, access credentials)
3. Enable trace export
4. Traces are exported as OpenTelemetry-compatible spans

### Audit Log Event Types

| Category | Events |
|----------|--------|
| Agent | Create, update, delete, publish, trigger |
| Tool | Create, update, delete, trigger |
| Workforce | Create, update, delete, trigger, edge changes |
| Permission | Role changes, access grants, API key operations |
| Knowledge | Table create, update, delete, row operations |

### Execution Trace Span Types

| Span Type | What It Captures |
|-----------|-----------------|
| `invoke_agent` | Full agent task lifecycle (start to completion) |
| `chat` | Individual LLM call within an agent task |
| `multi_agent_system_trigger` | Workforce orchestration events |
| `condition_trigger` | Conditional logic evaluation in workflows |
| `tool_execution` | Individual tool/action invocations |

### Span Hierarchy

```
invoke_agent (root span)
  ├── chat (LLM reasoning)
  ├── tool_execution (action call)
  │   └── chat (if tool contains LLM step)
  ├── chat (LLM reasoning with tool result)
  ├── multi_agent_system_trigger (if workforce handoff)
  │   └── invoke_agent (child agent)
  │       ├── chat
  │       └── tool_execution
  └── chat (final response)
```

### Trace Correlation

- All spans within a single task share a `trace_id`
- `parent_span_id` links child spans to their parent
- Use trace_id to reconstruct the full execution path of a task
- In workforce scenarios, the child agent's `invoke_agent` span is nested under the parent's `multi_agent_system_trigger` span

### Token Usage Attributes

Each `chat` span includes:
- `llm.input_tokens` -- prompt tokens sent to the model
- `llm.output_tokens` -- completion tokens generated
- `llm.model` -- model identifier used
- `llm.temperature` -- temperature setting

Use these to diagnose cost spikes (unexpected input token growth = prompt bloat) or quality issues (low output tokens = truncated responses).

### PII Redaction

- Trace exports redact PII by default
- Message content in `chat` spans is summarized, not raw
- Tool inputs/outputs may contain customer data -- review your S3 bucket access policies accordingly

---

## Troubleshooting & Debugging

### Tool Testing Protocol

Always test tools independently before attaching to agents:

1. Use `relevance_trigger_tool` with representative inputs
2. Check for empty `{}` output -- indicates missing output configuration
3. Verify error handling returns useful messages, not silent failures
4. Test with edge case inputs (empty strings, long text, special characters)

### Common Failure Categories

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Tool returns empty `{}` | Missing output config or step output not mapped | Add output mapping in tool config |
| Agent never calls a tool | Tool not referenced in system prompt or poor description | Add tool section to prompt with `{{_actions.ID}}` |
| Agent calls wrong tool | Ambiguous tool descriptions or overlapping scopes | Sharpen tool descriptions, add "when to use" guidance |
| Agent loops on same tool | Missing exit condition or tool returning errors silently | Add explicit stop conditions, improve error returns |
| "Tool not found" errors | Tool not attached or action ID mismatch | Re-attach with `relevance_attach_tools_to_agent`, verify IDs |
| Intermittent failures | OAuth token expiry or rate limiting | Check OAuth account status, add retry guidance in prompt |
| Agent ignores tool results | Results not formatted for LLM consumption | Restructure tool output to be clear, concise text |
| Workforce handoff fails | Edge misconfiguration or threading mismatch | Verify edge types and threading settings in workforce doc |

### Approval Mode Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Every task goes to review | Autonomy limit too low | Increase autonomy_limit (0-4 scale) |
| Sensitive actions auto-approved | Autonomy limit too high | Lower autonomy_limit, add approval rules |
| Approvals pile up | No one monitoring the review queue | Set up notifications, assign reviewer |

---

## Eval Design Patterns

### Eval Suite Design Guide

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

Local testing rubrics (from `BUILD_PRACTICES.md`) map directly to platform evals:

1. Take each rubric check (e.g., "Agent correctly identifies meeting type")
2. Write a scenario prompt that would trigger that behavior (persona-style)
3. Write an evaluator rule that assesses the rubric criterion
4. Group related checks under test-set-specific evaluators
5. Promote universal quality checks (accuracy, tone, guardrails) to global evaluators for production monitoring

### Scenario Templates

#### Happy Path
```
Name: [Feature] - Happy path
Prompt: "Hi, I need to [primary use case] for [realistic entity].
         Here are the details: [realistic input data]."
Max turns: 3-5
Evaluators:
  - "[Expected tool] must be called with the correct parameters"
  - "Final response must include [expected output fields]"
```

#### Edge Case
```
Name: [Feature] - Edge case - [condition]
Prompt: "I need to [use case] but [unusual condition].
         [Realistic details that trigger the edge case]."
Max turns: 3-5
Evaluators:
  - "Agent must handle [condition] gracefully without errors"
  - "Agent must [expected behavior for this edge case]"
```

#### Error Handling
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

#### Multi-Turn
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

### Evaluator Templates

#### Tool Usage Evaluator
```
Name: Correct tool selection
Rule: "The agent must use [tool name] when [condition].
       It must NOT use [wrong tool] for this task.
       Tool must be called with [required parameters]."
Scope: Test-set-specific
```

#### Output Format Evaluator
```
Name: Output format compliance
Rule: "The agent's final response must follow this structure:
       [list required sections/fields]. No information may be
       omitted. Formatting must be [format requirement]."
Scope: Global (reusable across test sets + production runs)
```

#### Accuracy / Hallucination Evaluator
```
Name: No hallucination
Rule: "The agent must only include information that was returned
       by its tools or explicitly provided by the user. If data
       is unavailable or a tool returns no results, the agent
       must say so rather than fabricating a response."
Scope: Global (reusable across test sets + production runs)
```

#### Error Handling Evaluator
```
Name: Graceful error handling
Rule: "If any tool call fails or returns an error, the agent must:
       1) Acknowledge the error to the user,
       2) Not silently proceed with missing data,
       3) Suggest a next step or workaround."
Scope: Global (reusable across test sets + production runs)
```

#### Guardrail Evaluator
```
Name: Scope guardrail
Rule: "The agent must not respond to requests outside its defined
       scope: [list scope boundaries]. For out-of-scope requests,
       it must politely redirect and explain what it can help with."
Scope: Global (reusable across test sets + production runs)
```

### What to Test by Agent Type

| Agent Type | Key Scenarios | Key Evaluators |
|------------|--------------|----------------|
| CRM Enrichment | Lookup existing contact, lookup missing contact, bulk enrichment, duplicate handling | Tool usage, accuracy, output format |
| Meeting Intelligence | Pre-meeting prep, post-meeting summary, action item extraction, no-recording scenario | Accuracy, output format, error handling |
| Customer Support | FAQ response, escalation trigger, multi-turn clarification, out-of-scope request | Guardrail, tone, tool usage, accuracy |
| Workflow Automation | Happy path trigger, missing data, approval flow, error recovery | Tool usage, error handling, output format |
| Research / Analysis | Single-source research, multi-source synthesis, conflicting data, no-results scenario | Accuracy/hallucination, output format, tool usage |

### Testing by Build Type

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
