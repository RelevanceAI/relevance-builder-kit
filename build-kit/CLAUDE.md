# Technical Reference

Deep technical reference material organised by what you're building: agents, workforces, evals, integrations, documentation patterns, templates. This is the "how" to playbooks/'s "what".

## Sub-directories

- `agents/` -- Everything about a single agent: prompt design, tools, knowledge, triggers, phone agents, write operations
- `workforces/` -- Multi-agent orchestration: edge configuration, lifecycle, setup gotchas
- `evals-and-monitoring/` -- Platform evals (test suites, evaluators, LLM-as-judge, tool simulation), Analytics, OpenTelemetry observability
- `integrations/` -- External platform guides: HubSpot, Salesforce, Outreach, Clay, Avoma, SalesLoft, Slack, ZoomInfo, LinkedIn, SharePoint
- `patterns/` -- Documentation patterns: layered CLAUDE.md design, error-debugging
- `templates/` -- Markdown templates for use-case playbooks, locale guides, product knowledge

## Routing

Come here when:

- Designing or modifying an agent (prompt, tools, knowledge, triggers, phone) -- start in `agents/`
- Building or debugging a workforce -- start in `workforces/`
- Setting up evals or production monitoring -- start in `evals-and-monitoring/`
- Connecting an external integration (HubSpot, Salesforce, etc.) -- `integrations/`
- Writing or reviewing a CLAUDE.md, working backwards from a confusing error -- `patterns/`
- Creating new documentation and need a template -- `templates/`

## See Also

- `.claude/CLAUDE.md` -- knowledge base hub
- `playbooks/` -- use-case playbooks
- `.claude/rules/PLATFORM_MECHANICS.md` -- platform mechanics (API patterns, state_mapping)
- `.claude/rules/BUILD_PRACTICES.md` -- build standards (testing, OAuth, system prompt structure)
