# Documentation

Human-readable documentation for kit onboarding and workflow reference. Claude Code reads CLAUDE.md files at each level of the kit. These docs are for humans browsing the kit or getting started.

## Contents

- `getting-started.md` -- 30-minute setup guide (prerequisites, kit setup, first build)
- `advanced-usage.md` -- Power-user reference (session management, slash commands, debugging)

## Routing

Come here when:

- Onboarding a new user
- Looking for human-readable guides (not Claude-consumable knowledge)

## See Also

- `CLAUDE.md` (root) -- kit overview and routing
- `setup.sh` (kit root) -- interactive first-time setup script
- `.claude/skills/setup/` -- redirect skill that points users at `setup.sh`
- `.claude/rules/` -- governance rules auto-loaded by Claude Code
