# Agent Triggers

How agents get work: schedule, webhook, form, chat, Slack triggers.

## Contents

- `triggers.md` -- (Stub) Trigger types, config schemas, MCP create/list/delete operations, payload-to-prompt mapping, gotchas

## Routing

Come here when:

- Configuring how an agent is invoked from outside Claude Code or the agent UI
- Setting up a scheduled (cron) agent
- Wiring a webhook or form to an agent
- Listing or deleting triggers via MCP

## See Also

- `build-kit/agents/CLAUDE.md` -- agents hub
- `.claude/rules/PLATFORM_MECHANICS.md` § "Triggers & Inputs" -- platform-wide trigger mechanics
- `.claude/rules/PLATFORM_MECHANICS.md` § "Phantom Tools: Never Persist in Actions" -- the phantom-tool-as-API-docs pattern (relevant for `create_scheduled_trigger`)
