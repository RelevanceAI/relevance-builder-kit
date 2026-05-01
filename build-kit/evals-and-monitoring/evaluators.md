# Evaluators

Evaluator rules score agent responses against natural-language criteria. Two scopes (test-set-specific vs global), several reusable templates.

For LLM-as-judge model selection and prompt engineering for evaluator rules, see `llm-as-judge.md`. For test sets and scenarios, see `test-suites.md`.

---

## Evaluator Scopes

There are two distinct types of evaluators with different purposes:

**Test-set-specific evaluators** are defined within a test set and only apply to that test set's scenarios. Use these for criteria specific to a particular feature or workflow being tested.

**Global evaluators** (found in the Evaluators tab on the agent) are defined at the agent level and can be:
1. **Included in test set runs** -- reusable quality checks across multiple test sets
2. **Selected for production runs** (Performance tab) -- this is their primary purpose. Since production conversations don't have predefined "right answers," global evaluators provide the quality criteria to evaluate real agent interactions

Global evaluators are per-agent, not cross-agent.

**Choosing scope:**
- If the rule only matters for a specific test set (e.g., "must call the enrichment tool"), make it test-set-specific
- If the rule should apply to all test sets AND production monitoring (e.g., "no hallucination"), make it a global evaluator

---

## Creating Evaluators

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

---

## Evaluator Templates

### Tool Usage Evaluator
```
Name: Correct tool selection
Rule: "The agent must use [tool name] when [condition].
       It must NOT use [wrong tool] for this task.
       Tool must be called with [required parameters]."
Scope: Test-set-specific
```

### Output Format Evaluator
```
Name: Output format compliance
Rule: "The agent's final response must follow this structure:
       [list required sections/fields]. No information may be
       omitted. Formatting must be [format requirement]."
Scope: Global (reusable across test sets + production runs)
```

### Accuracy / Hallucination Evaluator
```
Name: No hallucination
Rule: "The agent must only include information that was returned
       by its tools or explicitly provided by the user. If data
       is unavailable or a tool returns no results, the agent
       must say so rather than fabricating a response."
Scope: Global (reusable across test sets + production runs)
```

### Error Handling Evaluator
```
Name: Graceful error handling
Rule: "If any tool call fails or returns an error, the agent must:
       1) Acknowledge the error to the user,
       2) Not silently proceed with missing data,
       3) Suggest a next step or workaround."
Scope: Global (reusable across test sets + production runs)
```

### Guardrail Evaluator
```
Name: Scope guardrail
Rule: "The agent must not respond to requests outside its defined
       scope: [list scope boundaries]. For out-of-scope requests,
       it must politely redirect and explain what it can help with."
Scope: Global (reusable across test sets + production runs)
```

---

## See Also

- `llm-as-judge.md` -- Model selection, scoring tiers (Critical/Major/Minor), hallucination evaluators
- `test-suites.md` -- Test sets, scenarios, running evals
- `tool-simulation.md` -- Simulating tool responses inside scenarios
- `.claude/skills/eval/SKILL.md` -- `/eval` skill (auto-generates evaluators)
