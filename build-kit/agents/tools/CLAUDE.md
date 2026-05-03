# Agent Tools

Platform tool reference: API documentation, transformation steps, gotchas, sandbox auth, configuration details for tools attached to agents.

## Contents

- `state-mapping.md` -- Inter-step data flow: state_mapping mechanics, three access patterns (`steps` global, state_mapping value, template injection), variable shadowing, JS built-in collisions, supported template syntax
- `tool-transformations.md` -- Hard-won lessons about tool transformation steps: providers, valid configs, step types
- `platform-tool-gotchas.md` -- Non-obvious behaviors for platform-provided transformations: things you only learn by getting burned
- `sandbox-auth.md` -- Tool sandbox auth asymmetry: Python `authorization` runtime global vs JS sandbox (no global), `chains_*` secret pattern, header format, unresolved-secret guards
- `parallel-tool-calls.md` -- Parallel Tool Calls (early-access feature): setup, threading-compatibility matrix, behaviour, response shape
- `tool-icon-urls.md` -- Known-working branded logo URLs for integration tools (use in the `emoji` field)
- `voice-generation.md` -- Voice generation guide (ElevenLabs): TTS settings for natural speech by mode (podcast, narration, character)
- `ai-browser.md` -- AI Browser (Airtop) reference: browser automation steps, form-filling patterns, limitations, alternatives

## Routing

Come here when:

- Building a tool and need to check available transformation steps
- Debugging a tool that's behaving unexpectedly (check gotchas first)
- state_mapping issues
- Configuring voice generation or tool icons
- Building browser automation or form-filling tools (`ai-browser.md`)
- Enabling parallel tool calls

## See Also

- `build-kit/agents/CLAUDE.md` -- agents hub
- `build-kit/agents/knowledge/knowledge-tables.md` -- knowledge table CRUD reference
- `build-kit/integrations/` -- external platform guides (auth, endpoints) for integration-specific tools
- `.claude/rules/PLATFORM_MECHANICS.md` -- platform mechanics (state_mapping, template resolution)
- `.claude/rules/BUILD_PRACTICES.md` § "Tools" -- tool building standards (OAuth, JS steps, naming)
