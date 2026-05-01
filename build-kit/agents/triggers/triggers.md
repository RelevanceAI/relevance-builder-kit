# Agent Triggers

> **STUB.** Pending net-new content in Phase 3 of the build-kit restructure.

## Planned Coverage

- Trigger types: Schedule (cron), Webhook, Form, Chat, Slack
- Per-type config schema (cron expressions, webhook auth, form fields)
- How to create via MCP (`relevance_create_trigger`)
- How to enumerate via MCP (`relevance_list_agent_triggers`)
- How to delete via MCP (`relevance_delete_trigger`)
- Phantom tools as API documentation (`create_scheduled_trigger` step config)
- Trigger payload to system-prompt input mapping
- Cross-reference `__conversation_id`, `__mas_store_id` from `.claude/rules/PLATFORM_MECHANICS.md`
- Gotchas (schedule timezones, webhook authentication, form field validation)

## Until Then

- See `.claude/rules/PLATFORM_MECHANICS.md` § "Triggers & Inputs" for the existing one-paragraph summary
- See `.claude/rules/PLATFORM_MECHANICS.md` § "Phantom Tools: Never Persist in Actions" for the phantom-tool-as-API-docs pattern
