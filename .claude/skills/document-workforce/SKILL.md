---
name: document-workforce
description: Document a Relevance AI workforce and all its agents -- fetching config from the platform, creating local markdown docs. Use when the user says "document this workforce", "create docs for the workforce", "write up the workforce", or wants a full documentation package for a workforce and its agents. Also use when someone asks to document agents within a workforce context.
argument-hint: "[workforce name or ID]"
---

# Document Workforce

Generate comprehensive documentation for a Relevance AI workforce and all agents within it. Produces local markdown files following the `builds/` folder structure.

## When to Use

- User asks to document a workforce, pipeline, or multi-agent system
- User wants a full write-up of how a workforce operates
- User needs to hand off workforce knowledge to another person or team

## Prerequisites

- Active Relevance AI project must be set to the project containing the workforce

---

## Phase 1: Identify the Workforce

1. If the user provided a workforce ID, use it directly
2. If the user provided a name, call `relevance_list_workforces` and find the matching workforce
3. Confirm with the user: "Found workforce **{name}** (`{id}`). Proceeding."

## Phase 2: Gather Data

Fetch all data from the platform. Run these in parallel where possible:

### 2a. Workforce Graph
```
relevance_get_workforce(workforceId: "{id}")
```
Extract from the response:

- **Triggers:** type (manual/webhook), node IDs, webhook config
- **Agent nodes:** node_id, agent_id, name, model
- **Edges:** source, target, edge_type (forced-handover vs tool-call), threading_behavior, action_config (prompt_for_when_to_use, wait_for_completion)

### 2b. Agent Details

For each agent node in the graph, call in parallel:
```
relevance_get_agent(agentId: "{agent_id}", summary: false)
```

Extract from each agent:

- Agent ID, name, model, temperature, autonomy_limit
- System prompt (full text)
- Actions array (chain_id, title, action_behaviour, disabled status)
- Knowledge tables (knowledge_set IDs, usage_type)
- Notable config (fallback model, parallel_tool_calls, max_output_tokens, params)

## Phase 3: Determine Output Location

Ask the user or infer from context:

1. **Build folder:** what's the build called? (kebab-case, e.g. `lead-research`, `phone-receptionist`)

Target structure:
```
builds/{build-name}/
  workforce.md                      # Workforce graph, data flow, edges
  workforce-agents/
    {agent-name-kebab}.md           # One file per agent
```

## Phase 4: Create Local Documentation

### 4a. workforce.md

Must include:

- **Overview:** one-paragraph description of what the workforce does
- **IDs:** workforce ID, project ID, region
- **Status:** production / staging / draft, alert count if available, last run date
- **Data Flow Diagram:** ASCII art or text showing the agent graph with edge types
- **Triggers Table:** type, node ID, config details
- **Agents Table:** agent name, node ID, agent ID, model
- **Edges Table:** source, target, edge type, threading, label / purpose
- **Workflow Summary:** numbered steps describing the end-to-end flow
- **Knowledge Tables:** which tables are used, by whom, usage type
- **External Integrations:** what systems the workforce connects to

### 4b. Per-Agent Docs (workforce-agents/{agent-name-kebab}.md)

Each agent doc must include:

```markdown
# {Agent Name}

## Agent Config
- **Agent ID:** {id}
- **Model:** {model}
- **Temperature:** {temp}
- **Autonomy:** {limit} ({behaviour})
- **Memory:** Enabled / Disabled
- **Thinking:** Enabled / Disabled
- **Max output tokens:** {value}
- **Last updated by:** {name} ({date})

## Role
{One paragraph describing the agent's role in the workforce}

## Tools
| Tool | Chain ID | Behaviour | Status | Description |
|------|----------|-----------|--------|-------------|
{For each action in the actions array}

## Knowledge Tables
{Table of knowledge sets with usage type, or "None."}

## Workflow
{Numbered steps extracted from the system prompt}

## Output Format
{If the agent produces structured output (JSON), document the schema}

## Key Constraints
{Bullet list of rules / constraints from the system prompt}

## System Prompt
{Full system prompt text}
```

### Writing Guidelines

- Use the agent's system prompt as the primary source for workflow, constraints, and output format
- Extract action IDs referenced in the system prompt (e.g., `{{_actions.abc123}}`) and map them to the tools table
- Note any disabled tools explicitly
- Flag any discrepancies between workforce edges and system prompt references (e.g., agent references a delegation target but no edge exists)

## Phase 5: Verify

1. Read back each created local file to confirm completeness
2. Verify all IDs match the platform data
3. Check that the data flow diagram matches the actual edge configuration

## Output Summary

When complete, present:
```
## Documentation Created

### Local Files
- builds/{build-name}/workforce.md
- builds/{build-name}/workforce-agents/{agent-1}.md
- builds/{build-name}/workforce-agents/{agent-2}.md
- ...
```

---

## Reference: Edge Types

| Edge Type | Meaning |
|-----------|---------|
| `forced-handover` | Unconditional routing (typically trigger -> first agent) |
| `tool-call` | Agent can call the target as a tool (conditional, based on system prompt logic) |

## Reference: Threading Behaviors

| Threading | Meaning |
|-----------|---------|
| `always-same` | All messages in the same workforce task share one conversation thread |
| `always-new` | Each delegation starts a fresh conversation |

## Tags
#documentation #workforce #multi-agent #knowledge-management
