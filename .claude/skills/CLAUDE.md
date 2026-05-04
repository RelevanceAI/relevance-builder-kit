# Skills

Slash-command skills for the agent build lifecycle. Invoke with `/{skill-name}`. Each skill directory contains a SKILL.md with full instructions.

## Build Lifecycle

| Skill | Command | What it does |
|-------|---------|-------------|
| agent-build-patterns | `/agent-build-patterns` | Design philosophy, 8 patterns (Unit of Action, Note Step, plus 6 system design), contracts, architecture |
| template-agent | `/template-agent` | Design rubric, checklist, and anti-patterns for a clean starter agent |
| eval | `/eval` | Auto-generate eval test cases, run platform evals, golden sets, gate criteria |
| agent-optimiser | `/agent-optimiser` | Analyze a Relevance AI agent or workforce for config, prompt, tool, and credit issues. Recommend ranked optimizations |
| document-workforce | `/document-workforce` | Document a workforce and all its agents from platform config |
| setup | `/setup` | Redirects to the interactive `bash setup.sh` script (run in terminal) for first-time kit setup |

## Knowledge and Compounding

| Skill | Command | What it does |
|-------|---------|-------------|
| improve | `/improve` | Capture a single mid-flow insight as a well-scoped PR. Substance-strict bar, refuses ~half its invocations. Pairs with the `IMPROVEMENT_WATCH.md` rule |
| capture-learning | `/capture-learning` | End-of-session retro: extract reusable learnings, update knowledge base or PR |

## Routing

Come here when:

- Starting any agent build (read agent-build-patterns first)
- Designing a starter v1 agent (template-agent)
- Testing or evaluating an agent (eval)
- Optimising an existing agent (agent-optimiser)
- Documenting a build (document-workforce)
- Capturing a learning mid-flow (improve) or end-of-session (capture-learning)
- Looking for a slash command

## See Also

- `CLAUDE.md` (root) -- repo overview and routing
- `.claude/CLAUDE.md` -- knowledge-base hub
- `.claude/rules/BUILD_PRACTICES.md` -- build quality rules these skills enforce
- `.claude/rules/IMPROVEMENT_WATCH.md` -- the rule that surfaces mid-flow improvement candidates
