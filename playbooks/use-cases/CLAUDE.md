# Use-Case Playbooks

Agent architecture playbooks for common use cases. Each playbook covers when to use the pattern, architecture decisions, tools required, and common gotchas.

## Contents

### Full Playbooks
- `phone-agent.md` -- Synchronous voice interaction (BDR, intake, triage, verification)
- `meeting-intelligence.md` -- Capture, analyze, and act on meeting content

### Domain-Specific Playbooks
- `content-marketing-seo.md` -- Full SEO content pipeline: keyword research, cluster generation, article writing, visual assets, bulk refresh, G Suite default
- `form-testing-patterns.md` -- Synthetic form testing: Level 1-4 automation framework (HTTP POST, scripted browser, AI Browser, API-level), per-form routing registry, dummy-data hygiene

### Agent Pattern Guides
- `research-agent-patterns.md` -- Minimum tool usage, iterative rounds, confidence scoring, stop criteria, self-assessment
- `enrichment-agent-patterns.md` -- Audit trails, change summaries, tool chains, async webhooks, cost-aware enrichment
- `synthesis-agent-patterns.md` -- Gathering vs synthesis, CEO elevator test, executive briefing format, multi-source confidence
- `outreach-agent-patterns.md` -- Messaging principles, 3-message sequences, personalization hierarchy, CTA progression
- `interactive-agent-patterns.md` -- Conversational UX, progressive disclosure, no-tools agents, named personas, pre-flight checklists
- `multi-agent-orchestration.md` -- 7+1 generative principles, capability contracts, governance, testing framework, failure catalog
- `creative-pipeline.md` -- Separation of creative concerns, constrained randomness, multi-model cognitive matching
- `localisation-agent-patterns.md` -- Multi-language content generation: locale-native generation, glossary-driven QA, post-editing workforce, 16-language coverage

## How to Add a Playbook

1. Copy template: `build-kit/templates/use-case-playbook.template.md`
2. Save as `{use-case-name}.md` in this folder
3. Open a PR with the `content:use-case` label

## Routing

Come here when:
- Scoping a new build and need the right architecture pattern
- Looking for gotchas before building a specific agent type
- Comparing approaches (research vs enrichment vs synthesis)

## See Also

- `playbooks/CLAUDE.md` -- knowledge hub
- `.claude/skills/agent-build-patterns/` -- design philosophy behind these patterns
- `build-kit/agents/phone/phone-agents.md` -- deep phone agent reference
