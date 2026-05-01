# Architecture Patterns

Reusable architecture patterns for agent and knowledge design. Currently focused on CRM knowledge architecture.

## Contents

- `crm-knowledge-architecture.md` -- How to build and maintain instance-specific CRM knowledge: flat-table approach, skill-based architecture, loading strategies, migration path from embedded to external knowledge
- `claude-md-design-principles.md` -- The 10 source principles behind the layered CLAUDE.md system: philosophy-first design, operating pillars, cross-domain workflows, and breadcrumb navigation. Read first for the *why*
- `claude-md-best-practices.md` -- Practical application of the principles: three-level structure (root/directory/leaf), templates, anti-patterns, traversal design. Use as the working reference when writing or reviewing a CLAUDE.md
- `locale-knowledge-architecture.md` -- How to build locale-specific knowledge for multilingual agents: glossary design, locale guideline structure, LQA evaluation framework, language region coverage
- `parallel-tool-calls.md` -- Parallel Tool Calls (early-access feature): setup, threading-compatibility matrix, behaviour, response shape, sources
- `agent-variables.md` -- Agent variables (`params_schema` + `params`): how to make the Variables tab render, JSON example, why `patch_agent` won't work, save_agent_draft fetch-merge-save workflow
- `agent-write-operations.md` -- Full operations matrix (patch / upsert / attach-tools / save-draft), phone agent runtime safeguards, fetch-merge-save pattern, preferred-write-paths matrix
- `workforce-patterns.md` -- Mental model (graph not tree), type semantics (default vs chat), schedule capability, sub-agent approval propagation, wall-clock + dispatch limits, full edge configuration
- `system-prompts.md` -- Tiered structure, identity-framing examples, output-format selection, formatting elements (variables, comments, dividers, inline code), tool-pill UI insertion, action-ID retrieval, prompt-readability tradeoffs
- `placeholder-tools.md` -- `{{_placeholder.TOOL <name>}}` mechanics, UI integration, Invent origin, marketplace constraints, prompt-guidance pattern
- `error-debugging.md` -- Working backwards from symptoms to root cause, common symptom -> root-cause table

## What's Coming

Patterns to be documented as they emerge from real builds:
- Tool-suite patterns (OAuth consistency, intent input/output, fixed params)
- Multi-agent handoff patterns (workforce edges, threading, data flow)

To contribute a pattern, document it in a `.md` file here and open a PR with the `content:patterns` label.

## Routing

Come here when:
- Designing how an agent interacts with CRM data (HubSpot, Salesforce)
- Choosing between embedded knowledge and external knowledge tables
- Planning a knowledge architecture migration
- Designing locale knowledge for multi-language agents
- Understanding the layered CLAUDE.md approach used in this kit
- Writing or reviewing a CLAUDE.md file at any level

## See Also

- `build-kit/CLAUDE.md` -- build-kit hub
- `playbooks/use-cases/` -- use-case playbooks that apply these patterns
- `.claude/skills/agent-build-patterns/` -- design philosophy behind pattern decisions
