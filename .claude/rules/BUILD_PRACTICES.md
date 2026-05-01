# Agent Building Best Practices

Consolidated build preferences and patterns for production-grade Relevance AI agents. These are hard-won rules from real builds. Follow them unless you have a specific reason not to.

---

## System Prompts

### Headline rules

- Use clear headings (markdown headers, not tables) to separate sections.
- **Never use em dashes** (see root `CLAUDE.md` "Hard Rules": applies to all output including system prompts).
- Production prompts follow tiered structure: Identity / Mission -> Scope -> Rules -> Tools -> Workflow -> Output Templates.
- Always include a `# Scope` section that explicitly tells the agent to decline off-topic requests. Without explicit scope guardrails, agents will helpfully answer anything.
- The first sentence of the identity section sets the entire mental model. Frame the unit of work correctly there (one item vs. all items at once).
- Output format should match the consumer: markdown tables + status icons for humans, clean JSON for downstream agents / tools. Hybrid (JSON-with-prose) is a design smell.

### No Markdown Tables (enforced)

**Do not use markdown tables inside the deployed system prompt.** They flatten to pipe-noise inside the agent UI's prompt editor and add tokens for no upside. Convert every table to a bullet list.

Enforced at deploy time by `scripts/pre-tool-system-prompt-check.sh` (PreToolUse hook on `relevance_upsert_agent` / `relevance_patch_agent` / `relevance_save_agent_draft`). The hook blocks the deploy. Run `bash scripts/lint-system-prompts.sh` to catch earlier in `builds/**/system-prompt*.md`.

**Common copy-paste trap.** Tables ARE fine in `agent.md` (human docs); structured KB inventories often get copy-pasted from `agent.md` into `system-prompt.md` and the deploy now has tables. Re-format on the way in. See `DOC_RULES.md` § "system-prompt.md and other deployable prompt files".

### Tool References

- Always reference tools using `{{_actions.ID}}` pills, not just describing them by name.
- **Never wrap `{{_actions.ID}}` in markdown formatting** (backticks or bold). Bare tokens render as clickable pills; wrapping breaks the binding.
- Tools must have their own dedicated section in the prompt with purpose, params, and when-to-use guidance for each.

### Default tool-injection mode

`inject_action_references: false` AND inline `{{_actions.ID}}` pills inside a `# Your Tools` section of the prompt body. Suppresses the auto-injected `## Tool References` markdown table while keeping deterministic LLM tool bindings. Narrow exception (prose-only, no pills) applies only to genuinely user-edited template prompts.

### Placeholder Tools

`{{_placeholder.TOOL <name>}}` reserves a slot. Use for template / starter agents to telegraph future capabilities. Avoid for marketplace publishing (validation blocks) or production SLAs (mock echo). Companion skill: `/template-agent`. Full mechanics: `build-kit/agents/prompt/placeholder-tools.md`.

### Deep system-prompt design reference

Identity-framing examples, output-format selection, formatting elements (variables, comments, dividers, inline code), tool-pill UI insertion, action-ID retrieval workflow, prompt-readability tradeoffs: `build-kit/agents/prompt/system-prompts.md`.

---

## Tools

### General

- Give tools descriptive, self-explanatory names. Name each step individually (`name` and `display_name`).
- Use native / built-in tool steps before writing custom code. Native steps show a "Verified" pill in the step picker and are the most reliable path. Use them whenever available.
- Prefer Relevance platform keys (image gen, voice gen) over external API keys.
- **Code Over LLM for computed values:** never make the LLM calculate time offsets, unit conversions, or arithmetic for tool params. Wrap computed values in a code step that takes human-readable input (ISO datetime) and outputs the machine value (minutes). LLMs are unreliable at math; a 1-hour error on a scheduling tool is typical.

### Intent Input/Output Pattern

For tools called many times in a row (once per contact, once per account), add an `intent` string param ("1-sentence why this call is being made") and an `intent_result` / `explanation` output from a cheap Haiku step. The intent param improves chain of thought; the explanation gives business users human-readable context. Cost: ~2-3 credits per call.

### Step Naming

- Never prefix step names with `steps.`: the namespace is added automatically.
- Step names are plain identifiers: `calc_date`, `fetch_contacts`, `format_output`.
- `steps.` belongs only in REFERENCES (`{{steps.calc_date.output}}`) or state_mapping values (`"steps.calc_date.output"`).

### Finding Tool Steps

Copy native transformation names and entity IDs from the Relevance UI before asking Claude to read / modify. Direct ID access is faster than search. Step types reference: `build-kit/agents/tools/tool-transformations.md`.

### Icons

- Always set a tool icon via the `emoji` field. Icons should let the user quickly infer the task type.
- Integration-specific tools: use branded logos via public image URLs (`emoji` accepts any public URL). Working URLs tracked in `build-kit/agents/tools/tool-icon-urls.md`.
- **Icon URL validation:** must NOT contain spaces or unencoded special characters. The API accepts them but the UI renders broken. Use URLs from `tool-icon-urls.md` or unicode emoji shortcodes.
- For non-integration tools (utilities, scrapers, generic research), prefer unicode emoji shortcodes. They always render correctly.

### OAuth

- OAuth on a tool should be set to "Set Manually" by default. The agent should never auto-set OAuth accounts.
- **Never hardcode OAuth account IDs in tool step params.** Make `oauth_account_id` a top-level input param in `params_schema`, add to `state_mapping` as `params.oauth_account_id`, reference in the step as `{{oauth_account_id}}`. Use the OAuth selector type:
  ```json
  "oauth_account_id": {
    "metadata": {"content_type": "oauth_account", "is_fixed_param": true},
    "type": "string",
    "title": "OAuth Account"
  }
  ```

### Fixed Params and Agent Autonomy

Tools with `is_fixed_param: true` cannot be filled by the agent. If no `default` is set, the agent enters `pending-approval` instead of running. For tools that need to run autonomously, set a `default` in the param schema or hardcode in the step params. (Standalone tool triggers always pass params explicitly. This only matters for agent-attached tools.)

### state_mapping and Inter-Step Data Flow

**Headline rules** (full mechanism + worked examples in `build-kit/agents/tools/state-mapping.md`):

- Every tool MUST have a `state_mapping` field.
- No curly braces in state_mapping VALUES: use `"params.name"`, NOT `"{{params.name}}"`.
- Naming consistent end-to-end: `params_schema` key == state_mapping key == `{{key}}` in step body. `params.` belongs ONLY in state_mapping values, never in step bodies or schema keys.
- state_mapping declares runtime scope wiring; `params_schema` declares the public input contract. A key in one does not imply a key in the other.
- Each state_mapping key is bound as a top-level variable in the step's scope. In JS, **re-declaring with `const`/`let`/`var` is a hard crash**, not a silent shadow.
- **Never use a state_mapping key matching a JS built-in** (`fetch`, `crypto`, `console`, `URL`, `TextEncoder`): silently overrides in scope.
- JS inter-step data: prefer the `steps` global (`steps.step_name.output.transformed.<field>`) over `JSON.parse({{steps.X.output}})`. No size limit.
- **Non-JS steps cannot access the `steps` global.** Pass prior outputs via state_mapping and reference `{{key.field}}` in the step body.
- **Template engine supports only `{{var}}` and `{{var.subfield}}`**: NO Handlebars / Mustache helpers (`{{#if}}`, `{{#each}}`).
- **Guard unresolved templates:** they become literal `"undefined"` or `{{var}}`, not an error: `if (!val || val === 'undefined' || val.includes('{{')) { ... }`.

Platform-injected `__mas_store_id` / `__mas_id` / `__conversation_id` are NOT template-variable-accessible unless declared in `params_schema`. See `PLATFORM_MECHANICS.md` § "Platform-Injected System Variables".

### MCP Tool Parameter Handling

Never pass file path references (`{{FILE:path}}`) to MCP tool parameters. MCP tools pass values as-is with no template resolution. The tool will save the literal string, which can replace agent config (e.g., a 36K system prompt replaced with a 34-char string). Always read the file content and pass the actual string value. For large prompts (30K+ chars), `relevance_patch_agent` handles them correctly. The issue is only with file references, not payload size.

### JS Code Steps

- **NEVER inject params using single-quote string literals** (`'{{param}}'`). Always backtick template literals (`` `{{param}}` ``); single quotes break on apostrophes.
- When a tool param is typed `array`, `{{param}}` may serialize as comma-separated string. Handle both: try `JSON.parse()` first, fall back to `.split(',').map(s => s.trim()).filter(Boolean)`.
- Add error guards for action / enum params. Return an error if value doesn't match any valid branch.
- **JS step output envelope:** runtime output is `{ output: { transformed: <return> }, status, executionTime }`. Downstream references must use `steps.{name}.output.transformed`, not `.output`.
- **Prefer the `steps` global** over `JSON.parse({{steps.X.output}})`: no template size limit, returns parsed object.
- **Legacy chain compatibility:** if an existing tool uses `JSON.parse({{steps.X.output}})`, add `"transformed": "{{transformed}}"` to the source step's output config to make it serialize as parseable JSON.
- **Deep path traversal in step params shows UI false-positive errors.** The UI validator only recognises one-level-deep `{{state_mapping_key}}` references. Surface nested values via the source step's `output` config and add a flat state_mapping key.

### Knowledge Table Tools

Any tool whose `transformations.steps[]` includes a KT operation MUST start with:

1. **Read `build-kit/agents/knowledge/knowledge-tables.md` in full.** Format A vs B filter shapes, `data.` prefix rules, partial-update semantics, delete endpoints all live there.
2. **Grep the project for existing uses of the transformation:** treat zero matches as a caution signal.

Enforced by PreToolUse hook on `relevance_upsert_tool` (`scripts/pre-tool-kt-check.sh`).

Top trip-ups:

- `raw_filters` on native steps uses simple-dict shape `[{"data.<field>": "<value>"}]`, NOT the verbose `/knowledge/list` shape.
- Always `data.fieldname` prefix for row-data filters.
- Empty-string filter values match-on-empty; they do NOT "skip filter". Split into single-purpose tools instead.
- Make `knowledge_set` (and `filter_type`) top-level variables with KT-picker metadata when reusing a tool across tables.

---

## Integrations

- **Always prefer native** Relevance integrations. Native shows "Verified" in the step picker and is the most reliable path. Use it whenever available.
- **Same OAuth account across a tool suite** (e.g., all SharePoint tools use the same Microsoft OAuth). Don't mix OAuth strategies within a suite.
- **`slack_retrieve_message` is public-channels-only** (resolves by name, only C... channels). Private (G...) / DM (D...) need `slack_api_call` with hardcoded channel ID. IDs are stable. Full prefix table + channel-history pattern: `build-kit/integrations/slack.md`.

---

## Agent Config

### Agent Write Operations

- **`relevance_patch_agent`** for most updates. Handles fetch / merge / save / publish internally. Works for system_prompt, model, temperature, autonomy_limit, memory, thinking_tool, emoji, action_behaviour, etc.
- **`relevance_upsert_agent`** for name / description / system_prompt. Auto-fetches and merges safely.
- **`relevance_attach_tools_to_agent`** to attach tools. Auto-merges.
- **`relevance_save_agent_draft`** only for full config rewrites (e.g. complete actions array, `params_schema`). PUT semantics: always fetch full config first with `relevance_get_agent(summary: false)`, merge, then save.

Full operations matrix, phone agent runtime safeguards, fetch-merge-save code: `PLATFORM_MECHANICS.md` § "Agent Write Operations" and `build-kit/agents/agent-write-operations.md`.

### Avatars

- Always set SVG avatar icons from the Relevance CDN (not unicode emojis): `https://cdn.jsdelivr.net/gh/RelevanceAI/content-cdn@latest/agents/agent_avatars/agent_avatar_{N}.svg` (range: 10-24). Phone agents: `phone_agent_avatar_{N}.svg`.
- **Never override an existing agent's avatar.** Only set on initial creation or if the agent doesn't have one.

### Agent Variables (params_schema)

The Variables tab in the agent UI shows editable fields that inject into the system prompt as `{{variable_name}}` at runtime. The primary no-code config layer.

**Headline rules:**

- To render the Variables tab you need BOTH `params_schema` (declares fields) AND `params` (default values). `params` alone does NOT render the tab.
- `relevance_patch_agent` does NOT support `params_schema`. Use `relevance_save_agent_draft` with the FULL config (PUT semantics).
- Use `enum` for dropdown fields (tone, language, region presets).
- Add `{{_comment.Edit these values in the Variables tab - no rebuild required}}` near the variables in the prompt: visible in editor, hidden from LLM.

Full implementation pattern, JSON example, workflow: `build-kit/agents/prompt/agent-variables.md`.

### Descriptions and Documentation

Every agent must be easy to understand if handed off. Add thorough descriptions, comments, and helpful context. Descriptions explain what the agent does, when to use it, and how it fits the broader workflow.

---

## Testing

### Platform Evals (Primary)

Use `/eval` to auto-generate and run platform evals. Primary testing mechanism for individual agents:

- **Quick eval** after any agent change (smoke test, 3 cases auto-generated)
- **Full eval** before going live or major redesign (5-8 cases, user-reviewed)
- **Performance monitoring** for production agents: `/eval` Phase 6 enables ongoing auto-evaluation of real conversations

### Default: Test on Platform

**Always create and run tests on the platform by default.** Test sets are persistent, rerunnable, versioned. Organize by concern area:

- **Golden Set** -- core functionality: happy paths, edge cases, input validation (5-10 cases)
- **Adversarial / Safety** -- guardrails: prompt injection, off-topic, fabrication (3-6 cases)

Define a small set of **reusable rule names** (`No fabrication`, `Correct format`, `Uses [tool] tool`, `Stays in scope`) and apply consistently across cases. Use ad-hoc local testing (`relevance_trigger_tool` directly) only for one-off debugging.

### Golden Set in Publish Settings (Mandatory)

**Always configure `default_eval_config` on production agents.** Runs the golden test set automatically on every publish; blocks deployment if threshold isn't met. Set via `relevance_save_agent_draft` (full config required):

```json
"default_eval_config": {
  "test_set_ids": ["<golden-test-set-id>"],
  "threshold_score": 100,
  "block_on_failure": true
}
```

Use the golden set, not adversarial. `threshold_score: 100` = all rules must pass. `block_on_failure: true` prevents agents from going live if evals fail, even if someone publishes without running evals manually.

### Proactive Testing Rubric

When creating a new agent / tool / workforce, create a testing rubric BEFORE building: 3-5 qualitative checks, present to user, get approval, then build, then create platform test sets, run evals, report results.

### Other practices

- After a rocky task, do a self-improvement review: what went wrong, what to do differently.
- Test each tool with `relevance_trigger_tool` during development. Tools that return empty `{}` need output config fixes.
- Always enable tool simulation on eval test cases to avoid real API calls.

**Comprehensive testing reference** (test pyramid, golden sets, eval reports, gate criteria): `/eval` skill.

---

## Workforce / Orchestrator Patterns

**Full orchestrator design reference:** `playbooks/use-cases/multi-agent-orchestration.md`. Mental model, generative principles, capability contracts, scale guardrails, dispatch pattern decision, approval handling, failure catalog. Load that first when designing an orchestrator.

**Platform mechanics for workforces** (edge types, `additionalProperties` rules, `relevance_update_workforce` merge semantics, parallel tool calls, mental model): `PLATFORM_MECHANICS.md` § "Workforce Architecture" + `build-kit/workforces/workforce-patterns.md`.

The highest-impact build rules below.

### Batch vs. Fan-Out: Choose Based on Volume and Complexity

- **Small list (2-15 items) + complex per-item analysis -> single batch agent.** Pass the full list, agent iterates internally. One agent reasons holistically; no context accumulation in orchestrator. Self-validates inline.
- **High volume (15+ items) OR simple per-item action -> fan-out.** Orchestrator dispatches ONE AT A TIME (NOT a single planning response for all items: accumulates output, risks token limits mid-pipeline). Each item gets fresh context.

Anti-patterns: "I'll now research all 7 contacts. Here's the plan for each..." (planning response too long); sending 40 pages to one batch agent (context overflow).

**Rule of thumb:** if a single human analyst could hold all items in their head, batch it. If it would overwhelm them, fan out. Parallel Tool Calls may change fan-out patterns where enabled.

### Micro-Agents for Rule-Based Validation Are an Anti-Pattern

A dedicated validation agent (e.g. Haiku returning `{validated: true/false}`) is only justified if validation needs genuine reasoning: a tool call, KT lookup, or external data comparison.

If validation is `if/then` quality rules (reject LOW confidence, require specific evidence), those rules belong in the analysis agent's prompt as a structured self-check phase. Each separate validation agent adds context init, threading overhead, sub-call budget; sees only one finding at a time so can't catch cross-item patterns.

**Default:** merge validation into the analysis agent. Separate validation agent is the exception.

### Autopilot = No Questions

If an agent / workforce is designed to run unattended (overnight batch, scheduled trigger, autopilot mode), it must NEVER surface choices to the user. Low confidence is a status to record, not a question to ask.

- Low-quality results -> status `low_research_confidence` with notes
- Missing data -> status `needs_[field]` (e.g. `needs_linkedin_url`)
- Tool failures -> status `research_failed` with the error
- Ambiguous situations -> make best judgment and proceed

**Anti-pattern:** "I found limited results. Would you prefer Option A, B, or C?" in an unattended pipeline.

### Dead-End Status Clarity

Never save incomplete records with a success-like status. If a downstream step requires specific fields, contacts missing those fields must NOT have the same status as complete records. Use distinct statuses that tell the next step what to do (`found`, `needs_linkedin_url`, `low_research_confidence`, `research_failed`, `approved`).

### Entity Name Matching

Tools that look up records by company / account / entity name should use substring or fuzzy matching, not exact string equality. Agents are inconsistent with naming (legal suffixes, parenthetical regional names, abbreviations). Implementation patterns: `build-kit/agents/tools/platform-tool-gotchas.md`.

---

## Articulating Agent Value (KPI Framework)

Every production agent should be tied to measurable outcomes. Categories:

- **Efficiency:** time saved per task, tasks automated, cost per task, throughput increase
- **Quality:** accuracy, completeness, error rate, consistency
- **Adoption:** active usage, completion rate, escalation rate
- **Business impact:** revenue influenced, SLA improvement, capacity freed

Rules of thumb: 2-4 KPIs per agent. At least one efficiency + one quality. Baseline the manual process first. Align KPIs with the stakeholder who approves the build.

---

## Production Compliance Checklist

Before deploying any agent to production, verify:

**Data & Privacy**
- [ ] PII fields identified and documented; agent only accesses what's necessary
- [ ] Data residency confirmed (project region matches your needs)
- [ ] No sensitive data logged in tool step outputs unnecessarily

**Safety**
- [ ] Agent autonomy level appropriate for use case
- [ ] Refusal behaviors tested (agent declines out-of-scope requests)
- [ ] Output format validated (no hallucinated data in structured outputs)

**Access Control**
- [ ] OAuth accounts use "Set Manually" with minimum required scopes
- [ ] Workforce triggers restricted to authorized entry points

---

## Agent Build Philosophy

See `/agent-build-patterns` for the full design philosophy, core principles (Unit of Action, Separate Finding from Doing, Document Everything), and six system design patterns.
