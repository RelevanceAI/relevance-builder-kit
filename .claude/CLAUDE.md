# Claude Code Configuration

This directory contains Claude Code configuration: governance rules (auto-loaded) and slash-command skills.

## Contents

- `rules/` -- Governance rules and platform mechanics, auto-loaded every conversation
- `skills/` -- Slash-command skills for agent building, testing, deployment, and workflow
- `settings.json` -- Claude Code hooks and statusline config

## Connecting to Relevance AI

The kit connects to the Relevance AI platform via the official **remote MCP server** at `https://mcp.relevanceai.com` (configured in the kit's `.mcp.json`). Authentication is OAuth: run `/mcp` once and the browser handles login. No API keys, no local plugin, no submodule.

The remote MCP loads its operational skills on demand. They cover:

- Creating and configuring agents
- Building tools and transformations
- Multi-agent workforces
- Knowledge table CRUD
- Agent usage analytics
- Agent evaluations and test cases

These skills are not files in this repo. Claude loads them dynamically from the MCP server when the conversation needs them.

## Routing

Come here when:
- Understanding how Claude Code is configured
- Confirming the MCP target / authentication model
- Navigating the local slash-command skills

## See Also

- `CLAUDE.md` (root) -- repo overview and routing
- `playbooks/` -- use case playbooks (top level)
- `build-kit/` -- platform reference (top level)
- `.mcp.json` -- the MCP target (Relevance AI prod server)
