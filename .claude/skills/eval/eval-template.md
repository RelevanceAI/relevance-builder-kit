# Evaluation Report Template

Copy this template into `builds/{build-name}/eval-results/eval-{DATE}.md` after running a golden set evaluation.

---

```markdown
# Eval Report: {Agent Name}

**Date:** {YYYY-MM-DD}
**Agent ID:** {agent_id}
**Model:** {model}
**Golden Set Version:** {version or date of golden set}
**Evaluator:** {your name}

## Summary

| Metric | Value |
|--------|-------|
| Total test cases | {N} |
| PASS | {N} |
| PARTIAL | {N} |
| FAIL | {N} |
| Pass rate | {%} |
| Previous pass rate | {%} |
| Delta | {+/- %} |

## Gate Decision

- [ ] Pass rate >= 90%
- [ ] Safety cases 100% pass
- [ ] No regressions from previous eval
- **Decision:** GO / NO-GO / CONDITIONAL

## Results by Category

### Happy Path ({N}/{N} passed)

| ID | Name | Result | Notes |
|----|------|--------|-------|
| TC-001 | ... | PASS | |
| TC-002 | ... | FAIL | [brief reason] |

### Edge Cases ({N}/{N} passed)

| ID | Name | Result | Notes |
|----|------|--------|-------|
| TC-005 | ... | PASS | |

### Ambiguous ({N}/{N} passed)

| ID | Name | Result | Notes |
|----|------|--------|-------|
| TC-008 | ... | PARTIAL | Asked for clarification but missed one detail |

### Out of Scope ({N}/{N} passed)

| ID | Name | Result | Notes |
|----|------|--------|-------|
| TC-010 | ... | PASS | Correctly refused |

### Adversarial ({N}/{N} passed)

| ID | Name | Result | Notes |
|----|------|--------|-------|
| TC-012 | ... | PASS | Prompt injection blocked |

## Failures and Action Items

### TC-002: [Name]
**Expected:** Agent calls lookup tool and returns formatted result
**Actual:** Agent hallucinated a result without calling the tool
**Root cause:** System prompt missing explicit instruction to always use tool
**Action:** Update system prompt, re-test

## Observations

- [Any patterns noticed across test cases]
- [Performance notes -- latency, token usage]
- [Suggestions for golden set updates]

## Comparison to Previous Eval

| Test Case | Previous | Current | Change |
|-----------|----------|---------|--------|
| TC-001 | PASS | PASS | -- |
| TC-002 | PASS | FAIL | Regression |
```
