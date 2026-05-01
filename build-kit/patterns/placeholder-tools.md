# Placeholder Tools (`{{_placeholder.TOOL <name>}}`)

> **Scope:** Full mechanics, UI integration, runtime behaviour, marketplace constraints. Headline rule + decision triggers in `.claude/rules/PLATFORM_MECHANICS.md` § "Placeholder Tools" and `.claude/rules/BUILD_PRACTICES.md` § "Placeholder Tools".

---

## What it is

First-class syntax for reserving a tool slot in a system prompt without attaching the tool. The backend scans the prompt for `{{_placeholder.TOOL <name>}}` tokens on every run and auto-provisions an **ephemeral phantom tool** per match (never persisted to the actions array, separate mechanism from thinking-tool-style phantoms). The phantom tool has a mock echo transformation -- it returns whatever input it receives, useful for simulating the future shape of the agent before real tools are wired.

## UI integration

Each token renders as a "Connect" pill in the agent builder's system prompt editor. Clicking Connect opens the tool-search menu, matches by placeholder name, attaches the chosen tool, and rewrites `{{_placeholder.TOOL Send Email}}` -> `{{_actions.<new_action_id>}}` in the prompt automatically. A composable (`useReplaceAgentPromptPlaceholders`) drives the rewrite.

## Variable pipeline interaction

`{{_placeholder.TOOL <name>}}` is **not substituted** by the regular variable resolver. It stays raw text until a real tool connects. Safe to leave alongside `{{brand_guidelines}}` or other agent variables.

## Invent origin

Invent-generated agents use internal `[[[ tool ]]]` notation that serialises to this syntax. Every Invent agent ships with placeholder pills awaiting connection.

## Marketplace blocker

Agents with unresolved placeholders cannot publish to the marketplace. Validation rejects with `"Agent prompt contains placeholder tools"`. Connect everything before marketplace publish.

## Primary use case

Trial template agents, where future-version capabilities (image gen at v5, slide builder at v7, etc.) are telegraphed in the UI via Connect pills.

## Prompt guidance pattern

If the placeholder shouldn't fire yet, say so explicitly in the prompt, and label any output as preview (since the mock echoes input):

```
Only call {{_placeholder.TOOL Image Generation}} when the brief asks for a header image.
Otherwise ignore it. Any output from this tool is a preview placeholder until the real
image generator is connected.
```

## When NOT to use

- Marketplace publishing -- unresolved placeholders block the publish
- Production agents with SLAs -- mock echo returns nonsense, not real tool results

## See Also

- `.claude/skills/template-agent/` -- the design pattern for trial template agents that uses placeholders
- `.claude/rules/PLATFORM_MECHANICS.md` § "Placeholder Tools" / "Reserved Variable Prefixes"
