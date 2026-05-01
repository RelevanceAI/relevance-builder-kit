# Technical Reference

Deep technical reference material: API documentation, integration guides, architecture patterns, doc templates, and monitoring. This is the "how" to playbooks/'s "what".

## Contents

### Sub-directories

- `tools/` -- Platform tool reference: knowledge table API, transformation steps, tool gotchas, icon URLs, voice generation
- `integrations/` -- External platform guides: HubSpot, Salesforce, Outreach, Clay, Avoma, SalesLoft, Slack, ZoomInfo, LinkedIn, SharePoint (auth, endpoints, quick start)
- `templates/` -- Markdown templates for consistent documentation (use-case playbooks, locale guides, product knowledge)
- `patterns/` -- Reusable architecture patterns (CRM knowledge design, layered CLAUDE.md design principles, workforce patterns, agent variables, error debugging)

### Top-level files

- `phone-agents.md` -- Phone agent best practices: three-phase pattern, voice config, latency management, pitfalls
- `evals-and-monitoring.md` -- Platform evals, Analytics dashboards, OpenTelemetry observability, quality measures

## Routing

Come here when:

- Building a tool and need API specifics or gotcha avoidance
- Connecting an external integration (HubSpot, Salesforce, etc.)
- Creating new documentation and need a template
- Setting up evals or monitoring for an agent
- Building a phone agent

## See Also

- `.claude/CLAUDE.md` -- knowledge base hub
- `playbooks/` -- use-case playbooks
- `.claude/rules/PLATFORM_MECHANICS.md` -- platform mechanics (API patterns, state_mapping)
