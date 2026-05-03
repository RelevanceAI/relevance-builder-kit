# Agent Knowledge

Knowledge tables (CRUD reference) and architectural patterns for designing what an agent knows.

## Contents

- `knowledge-tables.md` -- Complete API reference for knowledge table operations: flat paths, endpoints, CRUD, pagination, filtering (Format A vs Format B), Python helpers
- `crm-knowledge-architecture.md` -- How to build and maintain instance-specific CRM knowledge: flat-table approach, skill-based architecture, loading strategies, migration path from embedded to external knowledge
- `locale-knowledge-architecture.md` -- How to build locale-specific knowledge for multilingual agents: glossary design, locale guideline structure, LQA evaluation framework, language region coverage

## Routing

Come here when:

- Setting up knowledge table CRUD operations (create, read, update, delete rows)
- Designing how an agent interacts with CRM data (HubSpot, Salesforce)
- Choosing between embedded knowledge and external knowledge tables
- Planning a knowledge architecture migration
- Designing locale knowledge for multi-language agents

## See Also

- `build-kit/agents/CLAUDE.md` -- agents hub
- `build-kit/agents/tools/state-mapping.md` -- inter-step data flow (used by KT tools)
- `.claude/rules/PLATFORM_MECHANICS.md` § "Knowledge Sets" -- usage types, filter syntax in native steps
- `.claude/rules/BUILD_PRACTICES.md` § "Knowledge Table Tools" -- mandatory pre-build checklist
