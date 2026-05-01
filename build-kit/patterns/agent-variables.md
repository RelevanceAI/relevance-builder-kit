# Agent Variables (`params_schema`)

The Variables tab in the agent UI shows editable fields that inject values into the system prompt as `{{variable_name}}` at runtime. This is the primary no-code config layer for non-technical users.

The headline rule sits in `.claude/rules/BUILD_PRACTICES.md` § "Agent Variables (params_schema)"; the full implementation pattern lives here.

---

## You need BOTH `params_schema` and `params`

To make variables appear in the Variables tab, you need both:

1. `params_schema` -- defines the fields, types, titles, and descriptions (what renders in the UI)
2. `params` -- provides the default values

**`params` alone (via `patch_agent`) does NOT work.** The values are stored internally but the Variables tab stays blank. This is a known platform behaviour -- without `params_schema`, the UI has no schema to render.

---

## `patch_agent` does NOT support `params_schema`

You must use `relevance_save_agent_draft` with the FULL config (PUT semantics -- any field you omit is wiped). The fetch-merge-save pattern from `.claude/rules/PLATFORM_MECHANICS.md` § "Agent Write Operations" applies.

---

## Implementation pattern

```json
"params": {
  "messaging_tone": "Consultative",
  "target_geography": "Southeast Asia"
},
"params_schema": {
  "properties": {
    "messaging_tone": {
      "type": "string",
      "title": "Messaging Tone",
      "description": "Controls writing style",
      "enum": ["Professional", "Consultative", "Conversational", "Challenger"]
    },
    "target_geography": {
      "type": "string",
      "title": "Target Geography",
      "description": "Regions to qualify accounts from"
    }
  }
}
```

In the system prompt, reference variables directly: `Messaging Tone: {{messaging_tone}}`. The runtime injects the current variable value at execution time.

**Use `enum`** for dropdown fields (tone, language, region presets) -- it renders as a select in the UI instead of a free-text field.

**Add a `{{_comment.Edit these values in the Variables tab - no rebuild required}}` annotation** in the system prompt section where variables appear -- visible in the prompt editor, hidden from the LLM, helps operators find the right tab.

---

## Workflow for adding variables to an existing agent

1. `relevance_get_agent(summary: false)` -- get full config
2. Add `params_schema` + update `params` with defaults
3. Update `system_prompt` to replace hardcoded values with `{{variable_name}}`
4. `relevance_save_agent_draft` with the complete config (PUT semantics -- include everything)
