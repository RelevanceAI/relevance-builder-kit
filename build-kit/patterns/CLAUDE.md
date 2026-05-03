# Documentation Patterns

Reusable patterns for documentation infrastructure and cross-cutting troubleshooting. Agent and workforce build patterns moved to `build-kit/agents/` and `build-kit/workforces/` in the May 2026 restructure.

## Contents

- `claude-md-design-principles.md` -- The 10 source principles behind the layered CLAUDE.md system: philosophy-first design, operating pillars, cross-domain workflows, breadcrumb navigation. Read first for the *why*
- `claude-md-best-practices.md` -- Practical application of the principles: three-level structure (root/directory/leaf), templates, anti-patterns, traversal design. Use as the working reference when writing or reviewing a CLAUDE.md
- `error-debugging.md` -- Working backwards from symptoms to root cause. Common symptom -> root-cause table. Cross-cutting (agents, tools, workforces)

## Routing

Come here when:

- Writing or reviewing a CLAUDE.md file at any level
- Understanding the layered CLAUDE.md approach used in this kit
- Working backwards from a confusing error to a root cause

## See Also

- `build-kit/CLAUDE.md` -- build-kit hub
- `build-kit/agents/` -- single-agent build patterns (prompt, tools, knowledge, triggers)
- `build-kit/workforces/` -- multi-agent orchestration patterns
- `playbooks/` -- use-case playbooks
- `.claude/skills/agent-build-patterns/` -- design philosophy behind pattern decisions
