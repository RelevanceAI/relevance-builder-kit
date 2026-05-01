# Skills

Slash-command skills for the agent build lifecycle. Invoke with `/{skill-name}`. Each skill directory contains a SKILL.md with full instructions.

## Build Lifecycle

| Skill | Command | What it does |
|-------|---------|-------------|
| agent-build-patterns | `/agent-build-patterns` | Design philosophy, Unit of Action, 6 system design patterns, contracts, architecture |
| template-agent | `/template-agent` | Design rubric, checklist, and anti-patterns for a clean starter agent |
| eval | `/eval` | Auto-generate eval test cases, run platform evals, golden sets, gate criteria |
| agent-optimiser | `/agent-optimiser` | Analyze a Relevance AI agent or workforce for config, prompt, tool, and credit issues. Recommend ranked optimizations |
| generate-diagram | `/generate-diagram` | Generate FigJam architecture diagram from agent / workforce URL |
| document-workforce | `/document-workforce` | Document a workforce and all its agents from platform config |
| setup | `/setup` | First-time kit setup (MCP, OAuth, statusline) |

## Routing

Come here when:

- Starting any agent build (read agent-build-patterns first)
- Designing a starter v1 agent (template-agent)
- Testing or evaluating an agent (eval)
- Optimising an existing agent (agent-optimiser)
- Documenting a build (document-workforce, generate-diagram)
- Looking for a slash command

## See Also

- `CLAUDE.md` (root) -- repo overview and routing
- `.claude/CLAUDE.md` -- knowledge-base hub
- `.claude/rules/BUILD_PRACTICES.md` -- build quality rules these skills enforce
