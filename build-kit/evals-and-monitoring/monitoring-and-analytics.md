# Monitoring & Analytics

Production observability for deployed agents: Analytics dashboards, OpenTelemetry traces, audit logs, and approval-mode monitoring.

For test-time eval runs, see `test-suites.md`.

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

## Production Failure Patterns

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

For deeper symptom-to-root-cause mapping, see `build-kit/patterns/error-debugging.md`.

### Approval Mode Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Every task goes to review | Autonomy limit too low | Increase autonomy_limit (0-4 scale) |
| Sensitive actions auto-approved | Autonomy limit too high | Lower autonomy_limit, add approval rules |
| Approvals pile up | No one monitoring the review queue | Set up notifications, assign reviewer |

---

## See Also

- `test-suites.md` -- Eval runs (test-time)
- `evaluators.md` -- Evaluator scopes and templates (incl. global evaluators used in production runs)
- `build-kit/patterns/error-debugging.md` -- Cross-cutting symptom-to-root-cause guide
