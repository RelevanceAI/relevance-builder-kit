# Tool Simulation

> **STUB.** Pending net-new content in Phase 3 of the build-kit restructure.

## Planned Coverage

- `tool_simulation_config` structure (full schema reference)
- Per-step overrides (when to simulate a single step vs the whole tool)
- Timeout / error injection (testing failure paths deterministically)
- Async callback simulation (webhook-based tools, polling tools)
- When to simulate vs run real tools (cost, determinism, side-effect avoidance)
- Confidence scoring on simulated outputs
- Stub tool patterns (lightweight tools whose only purpose is eval)
- MCP research source: `relevance_set_eval_test_case_simulation_config` and existing test cases

## Until Then

- For test set creation, see `test-suites.md`
- For evaluator rule design, see `evaluators.md`
- For pre-eval real-tool testing, see `test-suites.md` § "Tool Testing Protocol"
