# System Prompts: Deep Reference

> **Scope:** Full system-prompt design guidance -- structure, identity framing, output format selection, formatting elements, tool reference rules, prompt-readability tradeoffs. Headline rules + the deploy-blocking constraints in `.claude/rules/BUILD_PRACTICES.md` § "System Prompts" (also enforced by `scripts/pre-tool-system-prompt-check.sh` and `scripts/lint-system-prompts.sh`).

---

## Tiered structure

Production prompts follow a tiered structure:

```
Identity / Mission
  Scope (what's in / out of bounds)
  Rules (behaviours, refusals, escalation)
  Tools (with {{_actions.ID}} pills inline)
  Workflow
  Output Templates
```

Always include a `# Scope` section that explicitly tells the agent to decline off-topic requests. Don't assume the tool set alone constrains behaviour -- without explicit scope guardrails, agents will helpfully answer anything.

---

## Opening identity sentence sets the entire mental model

The first sentence of the identity section determines how the agent frames its entire run. A singular framing ("your job is to read **a page**") primes one-at-a-time thinking throughout, even if the workflow section says otherwise. A batch framing ("your job is to read **all pages first**, then compare") primes holistic processing.

- **Default:** Lead with the correct unit of work. If the agent processes a list, say so in sentence one.
- **Anti-pattern:** "Your job is to read a single page's content and produce one finding record" then a workflow section that says "for each page, repeat." The identity wins; the loop instruction is ignored or misapplied.
- **Correct:** "Your job is to read every candidate page, compare them all against the Jira ticket in one pass, and produce a single findings table."

---

## Output format should match the consumer

Choose output format based on who (or what) reads the output -- not based on what feels structured.

- **Human reviewer as consumer:** Use markdown table with status icons (e.g., 🔴 / 🟡 / ✅), an executive summary above the table (2-3 plain-English sentences), and plain-language evidence and suggestions. Avoid JSON.
- **Downstream agent or tool as consumer:** Use clean JSON with a defined schema. Avoid markdown prose.
- **Hybrid output (code block containing JSON-like fields with prose) is a design smell.** It means the prompt was patched iteratively rather than designed. When you see this, rewrite as either a proper markdown table or clean JSON -- not both.

---

## Formatting elements

Use these formatting elements in every system prompt -- they are plain text that can be written via the API or the UI. More formatting is better for human consumption. The Relevance AI prompt editor also provides shortcuts for these (accessible via `/` or keyboard shortcuts), but the underlying format is just text in the prompt string.

- **Variables** (`{{variable_name}}`): Use variables to keep prompts clean and templatised. Extract repeated values, long reference text, or config that changes between environments into variables rather than inlining. UI shortcut: `CMD + \`
- **Comments** (`{{_comment.text}}`): Use the `{{_comment.your text here}}` syntax for human-readable annotations in the prompt editor. These ARE visible in the editor UI but are hidden from the LLM at runtime. UI shortcut: `CMD + /`. **Do NOT use HTML comments (`<!-- -->`)** -- they are NOT filtered and will be passed as literal text to the LLM.
- **Guardrails:** Use the preset guardrail blocks for common safety patterns rather than writing them from scratch.
- **Dividers** (`---`): Use horizontal rules to visually break the prompt into sections. Makes the prompt scannable and clean for anyone reviewing it.
- **Markdown boxes** (` ``` `): Use code blocks to display output examples, structured templates, or anything that is a literal format the agent should follow. Makes examples visually distinct from instructions.
- **Inline code** (single backticks `` ` ``): Wraps content as markdown inline code. The Relevance prompt editor styles inline code in **red** -- this is a syntax-highlighting colour, NOT a warning or unresolved-token indicator. Use backticks to highlight identifiers, field names, table names, short config values, or anything the reader should visually recognise as a code-like token (e.g. `lead_submissions`, `run_start_timestamp`). Don't avoid backticks because of the red -- it's intentional styling.

---

## Tool references

- Always reference tools using `{{_actions.ID}}` syntax, not just describing them by name.
- **Never wrap `{{_actions.ID}}` in markdown formatting.** Bare tokens render as a clickable tool pill showing the tool's display name. Wrapping in `` ` `` backticks prevents pill binding and shows the raw ID in code-style red. Wrapping in `**...**` bold may also break pill rendering. If you want the pill emphasised, the pill itself is already a visually distinct button -- don't try to bold or code-style it.
- Tools must be explicitly added to the system prompt with their own section.
- Each tool should have a dedicated entry documenting its purpose, parameters, and when to use it.
- The agent needs to see tools as first-class items in the prompt, not side mentions buried in workflow descriptions.

### Inserting tool pills in the UI

In the Relevance prompt editor, type `/` to open the slash menu, select "Tools", and pick the tool. The editor inserts the correct `{{_actions.ID}}` token under the hood and renders it as a pill. This is the canonical way to add tools from the UI side -- memorising action IDs is unnecessary.

### Getting action IDs

- Action IDs are NOT the tool's `studio_id` -- they're agent-specific, generated when tools are attached
- Use `relevance_get_agent_tools` after tools are attached to retrieve them
- Two-pass workflow for new tools: attach with PLACEHOLDER -> publish -> get IDs -> update prompt -> publish again

---

## Prompt readability: when to skip `{{_actions.ID}}` injection

The default `inject_action_references: true` on `relevance_attach_tools_to_agent` appends a `## Tool References` section at the bottom of the system prompt with an action-ID table. Convenient for agents you're building in bulk, but noisy for prompts a customer will open and edit.

**Default: `inject_action_references: false` AND inline `{{_actions.ID}}` pills inside the `# Your Tools` section of the prompt body.** This gives you the best of both: the auto-injected table is suppressed, AND the LLM still has deterministic tool bindings via the inline pills. Builders and prompt-editing teammates alike read the natural-language description next to a real clickable pill.

**Narrow exception:** pure prompt-editable template agents where the user is genuinely editing the prompt regularly -- you may drop the inline `{{_actions.ID}}` pills and rely on natural-language prose only (e.g. "Use Perplexity web search to research current industry trends"). The platform resolves these by name when the tool is attached. Use this only when the prompt is truly opened to tune tone / brand, not for one-time read access. If in doubt, keep the pills.

The auto-injected `## Tool References` table at the bottom is always banned (it's a markdown table). Hence the new default of `inject_action_references: false` with manual pills inline.

For build-time tool selection, you still reference `{{_actions.ID}}` in tool step params, workflow steps, or tool overrides regardless of which mode you pick.

---

## Markdown tables: banned in deployable prompts

Markdown tables flatten to pipe-noise inside the agent UI's prompt editor and add tokens the LLM has to parse for no upside. Convert every table to a bullet list before deploying. Example:

```
Before:                        After:
| Pattern | Use for |          - **Pattern A** -- 3-column icon cards.
|---|---|                        Use for 3 parallel benefits. Cap: 3 cards.
| A | 3-column |               - **Pattern B** -- stacked text cards.
| B | stacked |                  Short list of ideas (2 to 4).
```

Enforced at deploy time by `scripts/pre-tool-system-prompt-check.sh` (PreToolUse hook on `relevance_upsert_agent` / `relevance_patch_agent` / `relevance_save_agent_draft`). The hook blocks the deploy. Run `bash scripts/lint-system-prompts.sh` to catch earlier in `builds/**/system-prompt*.md`.

**Common copy-paste trap.** Tables ARE fine in `agent.md` (human docs); structured KB inventories often get copy-pasted from `agent.md` into `system-prompt.md` and the deploy now has tables. Re-format on the way in.

---

## See Also

- `.claude/rules/BUILD_PRACTICES.md` § "System Prompts" -- headline rules + the deploy-blocking constraints
- `.claude/rules/DOC_RULES.md` § "system-prompt.md and other deployable prompt files" -- file split between `agent.md` (human docs) and `system-prompt.md` (deployable)
- `build-kit/patterns/placeholder-tools.md` -- `{{_placeholder.TOOL}}` design pattern
- `build-kit/patterns/agent-variables.md` -- `params_schema` for the Variables tab
