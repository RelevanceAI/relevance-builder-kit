# state_mapping and Inter-Step Data Flow

How data moves between tool steps in Relevance AI. The headline rules sit in `.claude/rules/BUILD_PRACTICES.md` § "state_mapping basics"; the full mechanism, edge cases, and worked examples live here.

---

## What state_mapping does

Every tool MUST have a `state_mapping` field. It declares the runtime scope wiring -- what gets bound as a top-level variable inside each step.

| Source | What gets injected |
|---|---|
| `state_mapping` key | Top-level variable in the step (with resolved value); also templated as `{{key}}` |
| `params_schema` key with no state_mapping entry | NOT a top-level variable. Still accessible via `params.<key>` (the `params` object is always populated from user inputs) |
| state_mapping value pointing at a non-existent path | Variable is still injected, value is `undefined` |

`params_schema` declares the public input contract; `state_mapping` declares the internal scope wiring. They are separate concerns -- a key in one does not imply a key in the other.

**Naming consistency rule.** If an input is called `company_name` in `params_schema`, the state_mapping key must also be `company_name`, and the step reference must be `{{company_name}}`. Never alias or rename between layers. The `params.` prefix belongs ONLY in state_mapping values (the runtime path) -- never in step bodies or params_schema keys.

**No curly braces in state_mapping values.** Use `"params.name"`, NOT `"{{params.name}}"`.

---

## Inter-step data access

Three patterns work in JS code steps. Pick the cleanest for the situation.

### 1. `steps` global object (preferred for typed access)

```js
const records = steps.fetch.output.transformed.records;
Object.keys(steps); // every step in the tool, including the current one
```

Full shape: `steps[name] = { output: { transformed: <return_value> }, status, executionTime }`. Returns parsed objects directly -- no `JSON.parse` needed.

### 2. state_mapping with a `steps.X.output...` value

Cleanest when the value is reused multiple times.

```json
"state_mapping": {
  "search_query": "params.search_query",
  "prev_result": "steps.fetch.output.transformed"
}
```

Then in JS: `prev_result.records.length` works directly.

### 3. Template injection

`` `{{steps.step1.output.transformed.foo}}` `` -- resolves to the stringified value at parse time. Useful for one-off references; subject to a ~5-10KB size limit on large payloads (see "Template injection size limit" below).

---

## Non-JS steps cannot access the `steps` global

`prompt_completion`, `update_knowledge_set_rows`, `bulk_update`, etc., rely on state_mapping or templated `{{step_name.field}}` references in their step body. To pass a prior step's output into a non-JS step, add a state_mapping entry:

```json
"state_mapping": {
  "search_query": "params.search_query",
  "check_is_meeting": "steps.check_is_meeting.output.transformed"
}
```

Then reference `{{check_is_meeting.is_meeting}}` in the step body. Without the state_mapping entry, the template stays as a literal string.

---

## Variable shadowing and JS built-ins

Because state_mapping keys are injected as `let`/`const` declarations in JS code, **re-declaring them with `const`, `let`, or `var` is a hard crash, not a silent shadow:**

```
Code failed to run: Identifier 'prompt' has already been declared
```

```javascript
// state_mapping has "prompt": "params.prompt"

// WRONG -- crashes at parse, before any line executes
const prompt = `{{prompt}}`;

// CORRECT -- prompt is already in scope with the resolved value
const result = prompt + " for " + platform;
```

**Sneakier failure mode:** state_mapping keys named after JS runtime built-ins (`fetch`, `crypto`, `console`, `setTimeout`, `URL`, `TextEncoder`, `structuredClone`, etc.) **silently override the built-in** in the step's scope. Subsequent calls error with confusing type mismatches ("fetch is not a function").

**Rules:**
- If a name is in `state_mapping`, never re-declare it with `const`/`let`/`var` in the JS code -- use it directly.
- Never use a state_mapping key matching a JS built-in. Verified-conflicting names: `fetch`, `crypto`, `console`, `setTimeout`, `clearTimeout`, `setInterval`, `URL`, `URLSearchParams`, `TextEncoder`, `TextDecoder`, `atob`, `btoa`, `performance`, `structuredClone`, `AbortController`, `queueMicrotask`.
- Generic names that are natural for both state_mapping and JS locals (`prompt`, `query`, `message`, `input`, `url`, `name`, `result`, `output`, `data`) -- pick one layer per name and stick to it.
- Block scope (`(() => { const prompt = ...; })()`) escapes the collision if you genuinely need a local with the same name -- but renaming the local is cleaner.

Full mechanism, probe matrix, runtime globals inventory, and Python parity in `platform-tool-gotchas.md` § "JS Code Step Variable Shadowing and Built-in Override".

---

## Python sandbox: same shadowing risk for `region`, `authorization`

Python steps inject runtime globals (`authorization`, `region`) BEFORE state_mapping resolution. If a state_mapping key matches one of these names, the platform-injected value silently wins -- your user param is dropped with no error.

Confirmed conflicts: `region` (project region code), `authorization` (`{project}:{key}:{region}:undefined`).

**Workaround:** rename the state_mapping key (e.g. `region` → `region_param`).

See `platform-tool-gotchas.md` § "Companion: Python sandbox has the same family of bugs".

---

## Supported template syntax

The Relevance AI template engine supports ONLY simple variable interpolation and dot-notation access:

- `{{variable}}` -- resolves a param or state_mapping key
- `{{variable.subfield}}` -- dot-notation access into objects
- `{{steps.step_name.output}}` -- access step outputs (in state_mapping values only)

**The template engine does NOT support Handlebars/Mustache block helpers.** These render as broken literal text in the UI and cause errors at runtime:

- `{{#variable}}...{{/variable}}` -- conditionals (NOT supported)
- `{{#each list}}...{{/each}}` -- loops (NOT supported)
- `{{#if condition}}...{{/if}}` -- if blocks (NOT supported)
- `{{> partial}}` -- partials (NOT supported)

For optional params in prompt steps, just reference `{{optional_param}}` directly -- if it's empty, it resolves to an empty string. Do not try to conditionally include/exclude prompt sections.

---

## Unresolved template guards

Template variables that don't resolve stay as literal strings (e.g., `{{__mas_store_id}}` if the param isn't declared). Guard against this in JS code:

```javascript
const val = `{{some_var}}`;
const isResolved = val && val !== 'undefined' && !val.includes('{{');
```

---

## Platform-injected system variables (`__` prefix)

The runtime ALWAYS injects `__mas_store_id` (workforce task ID), `__mas_id` (workforce ID), and `__conversation_id` (agent conversation ID) into every tool run. Reference them as `{{params.__mas_store_id}}`. They are NOT available as template variables unless declared in `params_schema`. Add them as optional params with `"metadata": {"is_fixed_param": true}`. See `.claude/rules/PLATFORM_MECHANICS.md` § "Platform-Injected System Variables" for the full spec.

---

## Template injection size limit

When a JS step reads a previous step's output via `` `{{steps.stepName.output.response_body}}` ``, the injected value has a ~5-10KB ceiling. Larger payloads truncate silently, causing `JSON.parse()` to fail in the catch block. Symptom: step reports 0 results even though the API call succeeded.

**Workaround:** prefer the `steps` global object (no size limit) over template injection. If you must use template injection (e.g. in a non-JS step), split into a list tool (IDs/metadata only) + per-record reader tool, or request only small properties in batch reads.
