# Agent Prompt Design

System prompt structure, identity framing, formatting, agent variables, placeholder tools.

## Contents

- `system-prompts.md` -- Tiered structure, identity-framing examples, output-format selection, formatting elements (variables, comments, dividers, inline code), tool-pill UI insertion, action-ID retrieval, prompt-readability tradeoffs
- `agent-variables.md` -- `params_schema` + `params`: how to make the Variables tab render, JSON example, why `patch_agent` won't work, save_agent_draft fetch-merge-save workflow
- `placeholder-tools.md` -- `{{_placeholder.TOOL <name>}}` mechanics, UI integration, Invent origin, marketplace constraints, prompt-guidance pattern

## Routing

Come here when:

- Writing or restructuring a system prompt
- Designing the Variables tab for an agent (`params_schema` + `params`)
- Telegraphing future tool capabilities via placeholder tools (template / starter agents)

## See Also

- `build-kit/agents/CLAUDE.md` -- agents hub
- `build-kit/agents/agent-write-operations.md` -- how to deploy prompt changes (patch vs upsert vs save-draft)
- `.claude/rules/BUILD_PRACTICES.md` § "System Prompts" -- headline rules, no-markdown-tables enforcement
- `.claude/rules/PLATFORM_MECHANICS.md` § "Template Resolution Priority" -- how `{{var}}` resolves
