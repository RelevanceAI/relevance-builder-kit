# Evals & Monitoring

Platform evals (test sets, evaluators, LLM-as-judge, tool simulation), Analytics dashboards, OpenTelemetry observability.

## Contents

- `overview.md` -- Quick reference table, where each topic lives
- `test-suites.md` -- Test sets, scenarios, running evals, build-type test depth, scenario templates
- `evaluators.md` -- Evaluator scopes (test-set-specific vs global), creating evaluators, evaluator rule templates
- `llm-as-judge.md` -- Rule type selection (`llm_judge` vs `string_contains` / `string_equals` / `tool_usage`), writing rules that pass/fail cleanly, model selection, cost control, anti-patterns
- `tool-simulation.md` -- `tool_simulation_config` shape (agent vs workforce), config levels (test-set vs scenario vs batch precedence), per-call indexing, simulation_prompt design
- `evaluating-workforces.md` -- What changes when `resource_type` flips from `agent` to `workforce`: `agent_configs` wrapping, cross-agent rules, test-suite design (cover handoffs), reading workforce-task results
- `monitoring-and-analytics.md` -- Analytics dashboards, OpenTelemetry traces, audit logs, approval-mode monitoring, common production failure patterns

## Routing

Come here when:

- Designing a test set for an agent
- Writing evaluator rules (test-set-specific or global)
- Configuring an LLM-as-judge for production runs
- Simulating tool responses inside scenarios
- Setting up OpenTelemetry export, Analytics dashboards, or audit log review
- Diagnosing production agent failures via monitoring

## See Also

- `build-kit/CLAUDE.md` -- build-kit hub
- `.claude/skills/eval/SKILL.md` -- `/eval` skill (auto-generates eval test cases, runs platform evals)
- `.claude/rules/BUILD_PRACTICES.md` § "Testing" -- testing standards (golden sets, gate criteria, default eval config)
- `build-kit/patterns/error-debugging.md` -- cross-cutting symptom-to-root-cause guide
