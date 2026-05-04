# Platform Mechanics: Relevance AI

> **Scope:** Long-term store of accumulated truths about building on Relevance AI. Platform mechanics, confirmed patterns, operational knowledge.
> Deep references: `build-kit/agents/` (prompts, tools, knowledge, triggers, phone, write operations), `build-kit/workforces/` (multi-agent orchestration), `build-kit/patterns/` (CLAUDE.md design, error-debugging).

---

## Publish Behavior

| Operation | Auto-publishes? | Notes |
|-----------|-----------------|-------|
| `relevance_upsert_tool` | Yes | `relevance_publish_tool` returns friendly "already published" if called after |
| `relevance_save_agent_draft` | Yes (default) | Pass `autoPublish: false` to save draft only |
| `relevance_create_workforce` | Configurable | Use `shouldPublish: true` (default) |

---

## Agent Write Operations

Three MCP tools for updating agents, each with different safety characteristics:

| Operation | Behavior | Use for |
|-----------|----------|---------|
| `relevance_patch_agent` | Fetches, merges, saves, publishes. Only fields you include are changed. | Most updates: system_prompt, model, temperature, autonomy, memory, thinking, emoji, action_behaviour |
| `relevance_upsert_agent` | Auto-fetches and merges name, description, system_prompt | Name / description / prompt-only changes |
| `relevance_attach_tools_to_agent` | Fetches, merges new actions, saves, publishes | Attaching tools |
| `relevance_save_agent_draft` | **PUT semantics: any field you don't include is reset.** | Only when rewriting complete actions array, or setting `params_schema`. MUST fetch full config first |

### Phone Agent Runtime Config

Phone agents store voice settings (`first_message_mode`, voice, transcriber, silence timeouts) in a `runtime` field. Some MCP write operations do not preserve this field. After a write to a phone agent, either verify in the UI or re-apply the full `runtime` via `relevance_patch_agent`. Full reference: `build-kit/agents/phone/phone-agents.md`.

### `patch_agent` and large system prompts

`relevance_patch_agent` handles 30K+ char payloads correctly. Apparent "truncation" happens when callers pass `{{FILE:path}}` placeholders -- MCP tools do not resolve those. Always read the file and pass the resolved string.

### Full preferred-write-paths matrix + fetch-merge-save pattern

See `build-kit/agents/agent-write-operations.md`.

---

## state_mapping is REQUIRED for Tools

Every tool MUST have a `state_mapping` field. See `BUILD_PRACTICES.md` § "state_mapping and Inter-Step Data Flow" for the headline rules; full mechanism in `build-kit/agents/tools/state-mapping.md`.

---

## Agent Actions Require project/region

Every action must include `project` and `region` fields. The `region` must match **where the tool exists**, not your API region.

---

## Workforces, Not Sub-Agents

Adding sub-agents to an agent's `actions` array is no longer the recommended pattern. Use workforces instead.

---

## Phantom Tools: Never Persist in Actions

Phantom tools are system-injected at runtime from agent settings. Never add them to `actions` manually. Enable via settings (e.g., `thinking_tool: { enabled: true }`). The MCP's `saveDraft` strips them automatically.

**Phantom tools as API documentation:** when building custom replacements (e.g., a datetime-based wrapper for `create_scheduled_trigger`), read the phantom tool's step config first -- it reveals the correct internal API endpoints and body schemas (e.g., `/agents/{id}/scheduled_triggers_item/create` takes `minutes_until_schedule`, cancel endpoint is `/scheduled_triggers_item/cancel` not `/delete`).

---

## Placeholder Tools (`{{_placeholder.TOOL <name>}}`)

Reserves a tool slot in a system prompt without attaching the tool. Renders as a "Connect" pill in the editor; runtime auto-provisions a mock-echo phantom tool until a real one is connected. Not substituted by the variable resolver.

**Use for:** template / starter agents where future capabilities are telegraphed via Connect pills. **Avoid for:** marketplace publishing (validation rejects `"Agent prompt contains placeholder tools"`) or production agents with SLAs (mock echo).

Full mechanics, UI integration, prompt-guidance pattern: `build-kit/agents/prompt/placeholder-tools.md`.

---

## Attaching Tools to Agents

Use `relevance_attach_tools_to_agent` -- handles fetch, merge, save, publish, action ID retrieval, and system prompt injection in one call. Test each tool with `relevance_trigger_tool` first; tools that return empty `{}` need their output config fixed.

---

## Reserved Variable Prefixes

| Prefix | Purpose |
|--------|---------|
| `secrets.*` | Project secrets. **Tool-referenced names must start with `chains_`** (e.g. `{{secrets.chains_my_key}}`). Backend rejects others with *"Secrets referenced in tool must start with 'chains_'"*. Missing secret resolves to literal `"undefined"` -> silent 401 |
| `snippets.*` | Project content templates. **Create via UI only** (`/snippets/*` API blocked in `relevance_api_request` allowlist). Resolver substitutes wherever `{{snippets.<name>}}` appears, including blockquotes / commentary. **Non-existent refs resolve to literal `"undefined"`** (the 9-character string), NOT empty string. Same JS coercion footgun as missing secrets (`String(undefined)` -> `"undefined"`). A check like `if (!snippet) { ... }` will mis-detect a missing snippet as set; guard with `if (!snippet \|\| snippet === 'undefined') { ... }` or check the explicit string |
| `_knowledge.*` | Knowledge set content |
| `_workforce_node.*` | Workforce system |
| `_mcp.*` | MCP integration |
| `_actions.*` | Agent action references |
| `_placeholder.TOOL.*` | Unresolved tool placeholder. See "Placeholder Tools" section |
| `_comment.*` | Inline comments visible in prompt editor UI but hidden from LLM. Syntax: `{{_comment.Your text here}}`. Use for section annotations, not HTML comments |
| `__*` | Platform-injected system variables (`__mas_store_id`, `__mas_id`, `__conversation_id`). Always injected. Must be declared in `params_schema` to resolve as template variables. See "Platform-Injected System Variables" section |

---

## Template Resolution Priority

Resolution order: `secrets.*` -> `snippets.*` -> `_knowledge.*` -> reserved prefixes -> state object (`params.*`, `steps.*`, `node_context.*`).

`steps.*` is a resolver namespace, not part of step names. Step names are plain identifiers (e.g., `calc_date`). See `BUILD_PRACTICES.md` § "Step Naming".

---

## Knowledge Sets

### Usage Types

| Type | Behavior |
|------|----------|
| `"instructions"` | Auto-injected into system prompt context |
| `"tool"` | Explicitly invoked when needed -- **platform injects a phantom semantic-search tool per attached KB at runtime** |

Use `"instructions"` for always-relevant context, `"tool"` for on-demand lookups.

**Inspection note:** KBs attached as `"tool"` are NOT visible in the agent's `actions` array and NOT returned by `relevance_get_agent_tools`. Don't classify an agent as "tool-less" based on an empty `actions` array -- always check the `knowledge` array and each entry's `usage_type`.

### Filter Syntax in Native Steps

Native KT transformation steps (`retrieve_data`, `update_knowledge_set_rows`, etc.) use `raw_filters` with a SIMPLE-DICT shape: `[{"data.<field>": "<value>"}]` -- NOT the verbose `/knowledge/list` shape. Wrong shape silently returns 0 matches with no error. Empty-string values match-on-empty (not "skip filter"); split into single-purpose tools or pre-build filters.

Reference KBs in prompts: `{{_knowledge.product_catalog_4}}`. Full filter shapes, CRUD reference, Python helpers: `build-kit/agents/knowledge/knowledge-tables.md`.

---

## Params & Variables

`params` holds static key-value config resolved via `{{key}}` in prompts and tool steps. Values can be strings, large reference docs, or structured arrays. For the full agent-variables design pattern (when to use `params` vs `params_schema`, Variables-tab rendering rules, `patch_agent` vs `save_agent_draft` semantics), see `build-kit/agents/prompt/agent-variables.md`.

---

## Workforce Architecture

Headline rules below. Mental model (graph not tree), type semantics (default vs chat), schedule capability, sub-agent approval propagation, wall-clock limits, full edge configuration: `build-kit/workforces/workforce-patterns.md`.

### Edge Types

| Type | Use When | Behavior |
|------|----------|----------|
| `forced-handover` | Deterministic routing (trigger -> agent) | Always executes |
| `tool-call` | Agent decides when to invoke | Appears as callable tool |

### Critical edge rules

- **`params_schema` is REQUIRED.** Empty schema causes `"must have required property 'message'"` on first call.
- **Always `additionalProperties: true`** on a tool-call edge's `params_schema`. The runtime auto-injects `_subagent_params` before validation. A strict schema rejects it. LLM guardrails belong in `prompt_for_when_to_use`, NOT the schema. Full JSON example: `build-kit/workforces/workforce-patterns.md`.
- **`relevance_update_workforce` merges, does not replace.** Removing an edge field by omitting it does not work -- set it to the new value explicitly.
- **Explicit `edges` disable auto-linking.** Forget the trigger edge (`source_index: -1`) and the workforce publishes but routes nothing.
- **Test orchestrators via `relevance_trigger_workforce`, not `trigger_agent_sync`.** Workforce edges only populate the orchestrator's runtime tool list when triggered through the workforce. Direct agent-trigger shows `toolCalls: []` even when the orchestrator describes delegation.

### Parallel Tool Calls (Early Access)

Concurrent tool / sub-agent execution behind a per-user feature flag. **Hard rule:** every parallel-dispatched edge MUST be `always-create-new`. `always-same` raises a race error. Full setup, threading-compatibility matrix, behaviour: `build-kit/agents/tools/parallel-tool-calls.md`.

---

## Error Handling

Work backwards from symptoms to root causes. Don't fix the symptom layer; fix the step that passed the bad input. Common symptom -> root-cause table, defensive patterns, and the most common failure modes: `build-kit/patterns/error-debugging.md`.

---

## Agent Metadata Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `user_instructions` | User-facing documentation on how to use the agent | "Start by providing: Name, Company, LinkedIn URL" |
| `title_prompt` | Controls conversation title generation | "Name the task after the prospect" |
| `description` | Brief agent description | "Researches companies for outreach" |

---

## Triggers & Inputs

All triggers (Schedule, Webhook, Form, Chat) are treated as incoming messages. Define the expected input schema the system prompt must handle.

Cross-cutting platform limitations (`relevance_list_conversations` zero-results, no UUID -> name resolver, no step-level `condition`, `relevance_api_call` PATCH unsupported, scoped runtime auth): `build-kit/agents/tools/platform-tool-gotchas.md` § "Platform-Wide Limitations".

Integration-specific notes (LinkedIn / Unipile, Microsoft Graph, Slack, Modal Labs, `prompt_completion` params, etc.): `build-kit/agents/tools/tool-transformations.md` and `build-kit/agents/tools/platform-tool-gotchas.md`.

---

## Slide Builder + Brand Kits

The Slide Builder is a preset agent (`slides_preset`), not a tool transformation. Other built-in preset IDs: `explorer_preset`, `planner_preset`, `image_generator_preset`, `deep_research_preset`.

**Brand Kits PUT has full-replace semantics:** any array field you omit (`colors`, `logos`, `inspiration_photos`) is reset to `[]`. Always fetch-merge-save.

---

## Platform-Injected System Variables (`__` prefix)

The runtime ALWAYS injects 3 double-underscore variables into every tool run.

| Variable | What It Is | Common Use |
|---|---|---|
| `__conversation_id` | Current agent conversation/session ID | `tag_conversation`, `read_conversation_metadata`, `add_conversation_metadata` |
| `__mas_id` | Workforce ID (MAS = Multi-Agent System) | Passed to subagents |
| `__mas_store_id` | Workforce Task ID (= `workforce_task_id`) | Track / link tasks across multi-agent runs |

Reference as `{{params.__mas_store_id}}`. **NOT available** as template variables unless declared in `params_schema` with `"metadata": {"is_fixed_param": true}`. `__mas_id` and `__mas_store_id` persist in tool run history; `__conversation_id` is stripped before save.

---

## Tool Sandbox Auth (Python vs JS)

Python steps get a built-in `authorization` runtime global (`{project}:{key}:{region}:undefined`); the JS sandbox does NOT and must source a project API key from `{{secrets.chains_*}}` with header `Authorization: ${PROJECT_ID}:${API_KEY}`. Always guard against unresolved secrets (literal `"undefined"` is a silent 401 trap).

For tools fetching from sites with strict TLS fingerprinting, JS `fetch` is generally more reliable than Python `requests`.

Full asymmetry table, header formats, guard pattern: `build-kit/agents/tools/sandbox-auth.md`.
