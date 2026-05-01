# Debugging Error Chains

> **Scope:** How to read tool / agent / workforce errors back to root cause. Headline rule in `.claude/rules/PLATFORM_MECHANICS.md` § "Error Handling".

---

## Work backwards from symptoms

Errors usually surface where they fail, not where they originated.

```
ERROR LOCATION          ACTUAL CAUSE
Step N: API call        Step 0: Agent / Trigger
(parameter missing)     (value never passed)
```

## Common root causes

| Symptom | Often actually caused by |
|---------|--------------------------|
| API parameter missing | Agent didn't pass it in the tool call |
| `KeyError: 'transformed'` | Previous Python step errored or returned wrong type |
| Empty string in API call | Upstream step received empty input |
| `required property` error | `params_schema` mismatch in workforce edge |
| Tool returns `{}` | Tool's `output` config not wired up; step ran but exposed nothing downstream |
| `must NOT have additional properties {"additionalProperty":"_subagent_params"}` | Edge `params_schema` has `additionalProperties: false`. See `build-kit/patterns/workforce-patterns.md` § "additionalProperties: false is a 100% failure mode" |
| Step reports 0 results despite successful API call | Inter-step template-injection size limit (~5-10KB ceiling). See `build-kit/tools/state-mapping.md` |
| `"undefined"` literal in tool output / 401 auth errors in JS sandbox | `{{secrets.chains_*}}` reference doesn't resolve. Check secret name and `chains_` prefix |
| Phone agent calls hang silently after MCP write | `runtime` field wiped. See `build-kit/patterns/agent-write-operations.md` § "Phone agent runtime config" |

## Rule

Don't fix symptoms -- fix root causes. If Step 3 fails because Step 1 passed empty data, fix Step 1. A defensive guard at Step 3 hides the real issue and creates silent-failure paths.

## See Also

- `.claude/rules/PLATFORM_MECHANICS.md` § "Error Handling"
- `build-kit/tools/platform-tool-gotchas.md` -- non-obvious failure modes by transformation
- `build-kit/tools/state-mapping.md` -- inter-step data flow rules
