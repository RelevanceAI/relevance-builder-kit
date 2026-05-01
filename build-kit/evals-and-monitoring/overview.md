# Evals & Monitoring Overview

Complete reference for Relevance AI's quality and observability features. Covers platform-native Evals, Analytics dashboards, and OpenTelemetry-based Observability.

> **Relationship to local testing:** This area covers platform features. For local testing rubrics and pre-build testing protocol, see `.claude/rules/BUILD_PRACTICES.md` "Testing" section. Platform evals complement -- not replace -- local rubrics.

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

## Where to Go

| Topic | File |
|-------|------|
| Test sets, scenarios, running evals, build-type test depth, scenario templates | `test-suites.md` |
| Evaluator scopes (test-set-specific vs global), creating evaluators, evaluator rule templates | `evaluators.md` |
| LLM-as-judge: rule type selection, writing rules that pass/fail cleanly, model selection, cost control | `llm-as-judge.md` |
| Tool simulation: config shape (agent vs workforce), levels & precedence, per-call indexing | `tool-simulation.md` |
| Evaluating workforces specifically (what changes when `resource_type` flips) | `evaluating-workforces.md` |
| Analytics dashboards, OpenTelemetry traces, audit logs, approval-mode monitoring | `monitoring-and-analytics.md` |

## See Also

- `build-kit/CLAUDE.md` -- build-kit hub
- `.claude/skills/eval/SKILL.md` -- `/eval` skill (auto-generates eval test cases, runs platform evals)
- `.claude/rules/BUILD_PRACTICES.md` -- testing standards (golden sets, gate criteria, default eval config)
