# Governance Rules

Mandatory rules auto-loaded by Claude Code on every conversation. These define documentation standards, build quality practices, and platform mechanics.

## Contents

- `DOC_RULES.md` -- Documentation structure, folder conventions, file naming, maintenance rules. Defines what docs are required and where they live
- `BUILD_PRACTICES.md` -- Consolidated build practices: system prompt structure, tool patterns, OAuth handling, state_mapping, testing, workforce patterns, integrations
- `PLATFORM_MECHANICS.md` -- Platform mechanics: API patterns, state_mapping, template resolution, agent write operations, workforce architecture, error handling
- `IMPROVEMENT_WATCH.md` -- Proactive detection rule: when and how to surface "Improvement spotted" suggestions inline so insights become PRs via `/improve` instead of dying in chat

## Routing

Come here when:

- Creating or updating documentation (DOC_RULES defines the standard)
- Building agents or tools (BUILD_PRACTICES defines quality patterns)
- Checking platform API behaviour or state_mapping rules (PLATFORM_MECHANICS)
- Wondering whether to surface a mid-flow improvement suggestion (IMPROVEMENT_WATCH)

## See Also

- `CLAUDE.md` (root) -- repo overview and routing
- `.claude/CLAUDE.md` -- knowledge-base hub
- `.claude/skills/agent-build-patterns/` -- design philosophy behind these rules
