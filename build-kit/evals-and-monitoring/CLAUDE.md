# Evals & Monitoring

Platform evals (test sets, evaluators, LLM-as-judge, tool simulation), Analytics dashboards, OpenTelemetry observability.

## Contents

- `overview.md` -- Quick reference table, where each topic lives
- `test-suites.md` -- Test sets, scenarios, running evals, build-type test depth, scenario templates
- `evaluators.md` -- Evaluator scopes (test-set-specific vs global), creating evaluators, evaluator rule templates
- `llm-as-judge.md` -- (Stub) Model selection, scoring tiers, hallucination evaluators, accuracy gates
- `tool-simulation.md` -- (Stub) `tool_simulation_config`, per-step overrides, timeout/error injection, async callback simulation
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
