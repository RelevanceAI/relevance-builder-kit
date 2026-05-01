# LLM-as-Judge

> **STUB.** Pending net-new content in Phase 3 of the build-kit restructure.

## Planned Coverage

- Model selection criteria (when to use Sonnet vs Haiku as the judge)
- Prompt engineering for multi-level scoring (Critical / Major / Minor)
- Temperature tuning for evaluators
- Hallucination evaluators (specific rule patterns)
- Accuracy gates (threshold design)
- Edge case handling (judge confidence, abstention, ambiguous outputs)
- Cost vs accuracy tradeoffs
- MCP research source: existing `relevance_run_evaluation` evaluator schemas

## Until Then

- For evaluator rule patterns, see `evaluators.md`
- For test set design, see `test-suites.md`
- For the `/eval` skill that auto-generates evaluators, see `.claude/skills/eval/SKILL.md`
