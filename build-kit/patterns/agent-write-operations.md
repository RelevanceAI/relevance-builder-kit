# Agent Write Operations: Deep Reference

> **Scope:** Full write-operation mechanics including phone agent runtime safeguards and the fetch-merge-save pattern. Headline rules in `.claude/rules/PLATFORM_MECHANICS.md` § "Agent Write Operations" and `.claude/rules/BUILD_PRACTICES.md` § "Agent Write Operations".

---

## Operations matrix

### PREFERRED: safe partial updates

| Operation | Behavior | Use for |
|-----------|----------|---------|
| `relevance_patch_agent` | Fetches full config, merges your changes, saves, publishes internally. Only fields you include are changed. | System prompt (any size, pass the resolved string not a file reference), model, temperature, autonomy, memory, thinking, emoji, action_behaviour -- any field except tools |
| `relevance_upsert_agent` | Auto-fetches and merges name, description, system_prompt. Safe for updates. | Name, description, system prompt changes |
| `relevance_attach_tools_to_agent` | Fetches, merges new actions, saves, publishes | Attaching tools |

### LOW-LEVEL: use with caution

| Operation | Risk | Required pattern |
|-----------|------|-----------------|
| `relevance_save_agent_draft` | PUT semantics -- wipes ENTIRE agent config for any field you don't include | Only when you need full control (e.g. rewriting complete actions array, setting `params_schema`). MUST fetch full config with `relevance_get_agent(summary: false)`, merge changes, then save the COMPLETE object |
| `relevance_api_request` (raw API) | Replaces whatever the endpoint targets | Avoid for writes |

### Other safe operations

| Operation | Behavior |
|-----------|----------|
| `relevance_upsert_tool` | Auto-fetches existing tool, merges your changes |
| `relevance_update_knowledge_rows` | Row-level, only touches specified fields |

---

## `patch_agent` and large system prompts

`relevance_patch_agent` handles raw payloads of any realistic size (30K+ chars confirmed). The observed "truncation" (40K input saved as 773 chars) happened when the caller passed a `{{FILE:path}}` file-reference placeholder instead of the resolved string: MCP tools do not resolve those references, so the literal placeholder was saved, making the result look truncated. **Always read the file and pass the full string value.**

---

## CRITICAL: Phone agent runtime config

**All MCP write operations can silently wipe the `runtime` field**, which contains the entire phone agent configuration (`first_message_mode`, voice, transcriber, `end_call_tool_enabled`, silence timeouts, etc.). The MCP has zero awareness of this field -- it is not in the `Agent` type, not handled by `upsertAgent`, `saveDraft`, or `patchAgent`.

**Impact:** After an MCP write, outbound calls hang and fail with `"Got empty content response without a function call"` because `first_message_mode` is reset to defaults.

**Workaround:** After ANY MCP write to a phone agent, either:

1. Verify phone config in the Relevance UI, or
2. Re-apply the full `runtime` object via `relevance_patch_agent` with the complete `runtime` field included

**Fix status:** Pending fix in the MCP plugin. See `build-kit/phone-agents.md` for full phone agent reference.

---

## Preferred write paths

| I want to change... | Use this | NOT this |
|---------------------|----------|----------|
| System prompt, model, temp, autonomy, memory, thinking | `relevance_patch_agent` | `relevance_save_agent_draft` with partial config |
| Name, description | `relevance_upsert_agent` | `relevance_save_agent_draft` with partial config |
| Attach tools | `relevance_attach_tools_to_agent` | Manual actions array edit |
| Rewrite complete actions array | Fetch-merge-save with `relevance_save_agent_draft` | Any other method |
| Tool steps/params | `relevance_upsert_tool` | Direct API call |
| `params_schema` (Variables tab) | Fetch-merge-save with `relevance_save_agent_draft` | `relevance_patch_agent` (does not support `params_schema`) |
| Phone runtime config | `relevance_patch_agent` with full `runtime` object, or UI | Any MCP write without verifying runtime after |

---

## Fetch-merge-save pattern (for `save_agent_draft` only)

Only needed when using `save_agent_draft` directly (rare -- prefer `patch_agent`):

```javascript
// 1. Fetch full config
const { agent } = await relevance_get_agent({ agentId: "x", summary: false });

// 2. Merge changes into the COMPLETE config
agent.model = "relevance-performance-optimized";

// 3. Save the FULL config
await relevance_save_agent_draft({ agentId: "x", config: agent });
```

---

## See Also

- `build-kit/phone-agents.md` -- full phone agent reference (runtime structure, voices, transcribers, hard-rule patterns)
- `build-kit/patterns/agent-variables.md` -- `params_schema` + `params` pattern (forces `save_agent_draft` use)
- `.claude/rules/PLATFORM_MECHANICS.md` § "Agent Write Operations"
- `.claude/rules/BUILD_PRACTICES.md` § "Agent Write Operations"
