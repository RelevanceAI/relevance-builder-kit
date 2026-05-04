# LLM as Judge

Most evaluator rules are scored by an LLM judge -- natural-language criteria evaluated by a smaller, fast model after the test run completes. Two things make or break this: rule design and rule type selection.

For test set / scenario design, see `test-suites.md`. For evaluator scopes (test-set-specific vs global), see `evaluators.md`. For simulating tool outputs inside scenarios, see `tool-simulation.md`.

---

## Rule Types: Pick the Cheapest That Works

The platform supports four evaluator rule types. Use the cheapest one that's deterministic enough for the check.

| Type             | `rule_config.type` | Deterministic? | Cost   | Use when                                                                           |
|------------------|--------------------|----------------|--------|------------------------------------------------------------------------------------|
| String contains  | `string_contains`  | Yes            | $0     | Verifying a specific term, URL, ID, or phrase appears in the response             |
| String equals    | `string_equals`    | Yes            | $0     | Exact-match deterministic outputs (rare; usually too brittle)                      |
| Tool usage       | `tool_usage`       | Yes            | $0     | Verifying the agent did or didn't call a specific tool, with optional position/count |
| LLM judge        | `llm_judge`        | No             | LLM    | Subjective quality, tone, completeness, reasoning, or anything string matching can't capture |

### `string_contains` and `string_equals`

```typescript
{ name: "Mentions refund policy",
  rule_config: { type: "string_contains", value: "refund policy" } }

{ name: "Returns confirmation",
  rule_config: { type: "string_equals", value: "Order confirmed." } }
```

Case-sensitive. `string_equals` matches the agent's final response exactly -- surprisingly brittle in practice (extra whitespace, trailing punctuation). Default to `string_contains` for keyword checks.

### `tool_usage`

```typescript
{
  name: "Uses CRM lookup",
  rule_config: {
    type: "tool_usage",
    tool_id: "<tool_id>",
    position: "anywhere",        // "anywhere" | "first" | "last"
    operator: "at_least",        // "at_least" | "at_most" | "exactly"
    count: 1
  }
}
```

Use this to verify routing and tool selection. Especially useful for negative checks -- "must NOT call SendEmail" with `operator: "exactly", count: 0`.

### `llm_judge`

```typescript
{
  name: "No hallucination",
  rule_config: {
    type: "llm_judge",
    prompt: "The agent does not invent information. If a tool returned no data, the agent must say so explicitly rather than fabricate a response.",
    model: "anthropic-claude-haiku-4-5"   // optional; defaults to openai-gpt-4o-mini
  }
}
```

Default model is small and fast (`openai-gpt-4o-mini`). Override with `model` for harder judgements.

---

## Writing Rules That Pass / Fail Cleanly

The LLM judge sees the rule prompt and the agent's full conversation. It returns a binary `passed` and a `reason`. Vague prompts produce flaky results -- the same conversation passes one run and fails the next.

### Good rules name a specific, observable behaviour

```
"The agent greets the user within the first message."
"The agent does not invent information. If a tool returned no data, the agent must say so explicitly rather than fabricate a response."
"When unable to help, the agent offers to transfer to a human."
"The final response includes a structured summary with Name, Company, and Title fields."
"All email addresses in the output match the format user@domain.tld."
```

These pass three tests:
1. **Specific** -- names a concrete behaviour, not "is helpful"
2. **Observable** -- can be verified from the conversation transcript alone
3. **Binary-decidable** -- there's a clear yes/no, not a spectrum

### Bad rules are vague, subjective, or unobservable

```
❌ "The agent is helpful."           // What makes it helpful?
❌ "The agent understands the user." // Not observable from output
❌ "The response is good."           // No criteria
❌ "The agent feels professional."   // Spectrum, not binary
```

### Refactor pattern

When a rule is producing inconsistent results across runs, rewrite from "the agent does X" to "the agent's response contains Y" or "the agent calls tool Z":

| Vague                                      | Refactored                                                                |
|--------------------------------------------|---------------------------------------------------------------------------|
| "Agent uses the CRM correctly"             | "Agent calls the CRM lookup tool before composing its response"           |
| "Agent gives a complete answer"            | "Final response includes all four fields: Name, Email, Company, Title"    |
| "Agent handles errors gracefully"          | "If a tool returns an error, the agent acknowledges the error and suggests a next step" |
| "Agent stays on topic"                     | "The agent does not respond to questions outside its defined scope: <list scope>" |

### Multi-criterion checks: split into separate rules

A single rule with three criteria is harder to debug than three rules with one criterion each. The judge produces one pass/fail per rule, and you want failure modes labelled.

```
❌ One rule:
  "Agent calls CRM lookup, then composes a personalised email mentioning the company."

✅ Three rules:
  - "Agent calls the CRM lookup tool"  (tool_usage)
  - "Final email mentions the company by name"  (llm_judge)
  - "Final email is personalised -- references at least one specific fact about the contact"  (llm_judge)
```

When the test fails, you see which criterion broke.

---

## Scoping: Test-Set-Specific vs Global

| Scope                | Lives on                          | Used for                                                       |
|----------------------|-----------------------------------|----------------------------------------------------------------|
| Test-set-specific    | A single test set                 | Criteria specific to the workflow that test set is checking   |
| Global               | The agent (Evaluators tab)        | Always-on quality checks. Reusable across test sets AND used in production-runs (Performance tab) |

**Choose test-set-specific** when the rule only makes sense for that scenario:
- "Agent calls the LinkedIn enrichment tool" (only for enrichment tests)
- "Final response includes deal stage" (only for sales-pipeline tests)

**Choose global** when the rule is universally applicable:
- "No hallucination"
- "Stays in scope"
- "Output format compliance"
- "Graceful error handling"

Global evaluators are also the only rules that can be run against real production conversations via the Performance tab. So everything you want to monitor in production must be a global evaluator.

---

## Model Selection

The default judge (`openai-gpt-4o-mini`) is fast and cheap. Override when:

- **Subtle reasoning checks** ("did the agent identify the implicit objection?") → `anthropic-claude-haiku-4-5` or `anthropic-claude-sonnet-4-6`
- **Long conversations** (10+ turns) → larger context model
- **Highly subjective tone judgements** → larger model with specific instructions

Model IDs follow `{provider}-{model-name}`: `openai-gpt-4o-mini`, `anthropic-claude-haiku-4-5`, `google-gemini-2.5-flash`, etc.

Don't pay for a larger model when a `tool_usage` or `string_contains` rule can do the same check for free.

---

## Cost Control

Each eval run consumes credits from three sources:
1. The agent / workforce running the scenario (full conversation cost)
2. The simulated user generating messages (LLM)
3. Each evaluator rule's judge LLM (per rule, per run, per scenario)

Order of magnitude:

| Suite shape                                    | Cost vs one normal task |
|------------------------------------------------|--------------------------|
| 1 scenario, 1 turn, 1 rule                     | ~3x                      |
| 5 scenarios, 3 turns each, 3 rules             | ~15-20x                  |
| 10 scenarios, 5 turns each, 5 rules            | ~50x                     |

Strategies:

- **Use deterministic rule types where possible.** `tool_usage` and `string_contains` add zero LLM cost.
- **Lower `max_turns`.** If the agent's job needs 1 turn, set `max_turns: 1`. Don't pay for 10 turns of simulated chitchat.
- **Run small smoke suites during dev, full suites on milestone changes.**
- **Combine related checks into one scenario.** Five scenarios checking five things is more expensive than one scenario with five rules -- same coverage, fifth the simulator cost.
- **Watch out for `runs_per_scenario`.** Setting this to 5 for variance testing 5x's the cost.

---

## Anti-Patterns

### Don't create LLM-only tools just to "test reasoning via tool simulation"

If a tool's only step is `prompt_completion`, that reasoning belongs in the agent's system prompt, not in a tool. Simulating a `prompt_completion`-only tool means your eval is testing a fake LLM output, not the agent's actual reasoning. See `tool-simulation.md` § "What to Simulate (and What NOT to)".

### Don't mix rule types into a single ambiguous rule

```
❌ "The agent calls the CRM tool and the response mentions the company."
   // Will the LLM judge check both? Probably. Will it report which failed? No.

✅ Two rules: one tool_usage (for the call), one llm_judge (for the mention).
```

### Don't write rules that depend on hidden context

```
❌ "The agent provides the correct answer."
   // The LLM judge doesn't know what "correct" is.

✅ "The agent's response includes the city 'Sydney' and a temperature."
   // Or: pre-compute correctness in tool simulation and check against the simulated value.
```

### Don't rely on a single eval run

LLM judges have variance. For rules that matter, set `runs_per_scenario: 3-5` to catch flaky behaviour. Watch for rules that pass 3/5 -- that's a sign the rule prompt is too vague.

---

## See Also

- `test-suites.md` -- test set + scenario design (`prompt`, `max_turns`, `runs_per_scenario`)
- `evaluators.md` -- scopes (test-set-specific vs global), templates by category
- `tool-simulation.md` -- how to simulate tool outputs so the judge tests agent logic, not infrastructure
- `monitoring-and-analytics.md` -- using global evaluators for production-run monitoring
- `.claude/skills/eval/SKILL.md` -- `/eval` skill (auto-generates evaluators)
- `.claude/rules/BUILD_PRACTICES.md` § "Testing" -- golden sets, gate criteria, default eval config
