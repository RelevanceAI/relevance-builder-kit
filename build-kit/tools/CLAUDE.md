# Tool Reference

Platform tool reference - API documentation, transformation steps, gotchas, and configuration details for building tools on Relevance AI.

## Contents

- `knowledge-tables.md` -- Complete API reference for knowledge table operations: flat paths, endpoints, CRUD, pagination, filtering
- `tool-transformations.md` -- Hard-won lessons about tool transformation steps (send_email, etc.): providers, valid configs, step types
- `platform-tool-gotchas.md` -- Non-obvious behaviors for platform-provided transformations: things you only learn by getting burned
- `state-mapping.md` -- Inter-step data flow: state_mapping mechanics, three access patterns (`steps` global, state_mapping value, template injection), variable shadowing, JS built-in collisions, supported template syntax
- `sandbox-auth.md` -- Tool sandbox auth asymmetry: Python `authorization` runtime global vs JS sandbox (no global), `chains_*` secret pattern, header format, unresolved-secret guards
- `tool-icon-urls.md` -- Known-working branded logo URLs for integration tools (use in the `emoji` field)
- `voice-generation.md` -- Voice generation guide (ElevenLabs): TTS settings for natural speech by mode (podcast, narration, character)
- `ai-browser.md` -- AI Browser (Airtop) reference: browser automation steps, form-filling patterns, limitations, and alternatives

## Routing

Come here when:
- Building a tool and need to check available transformation steps
- Debugging a tool that's behaving unexpectedly (check gotchas first)
- Setting up knowledge table CRUD operations
- Configuring voice generation or tool icons
- Building browser automation or form-filling tools (check ai-browser.md)
- state_mapping issues (also check `.claude/rules/PLATFORM_MECHANICS.md`)

## See Also

- `build-kit/CLAUDE.md` -- build-kit hub
- `.claude/rules/PLATFORM_MECHANICS.md` -- platform mechanics (state_mapping, template resolution)
- `.claude/rules/BUILD_PRACTICES.md` -- tool building standards (OAuth, JS steps, naming)
