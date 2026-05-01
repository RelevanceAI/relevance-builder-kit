---
name: generate-diagram
description: Generate a FigJam architecture diagram from a Relevance AI agent or workforce URL/ID. Pass an agent URL, workforce URL, or ID and get back a FigJam link. Use when the user says "/generate-diagram", "generate a diagram", "create a diagram", "visualize this".
argument-hint: "[agent/workforce URL or ID]"
---

# Generate Diagram

Generate a FigJam architecture diagram from a Relevance AI agent or workforce. Pass a URL or ID, get back a FigJam link.

## When to Use

- User says `/generate-diagram <url>` or `/generate-diagram <id>`
- User wants to visualize an agent or workforce architecture
- User provides a FigJam URL and wants it refreshed from current platform state

## Key Concept

The **FigJam file is the canonical artifact**: what people view, share, and reference. Mermaid is a transient intermediary used only to generate / update the FigJam content. The FigJam URL linkage is stored in `agent.md` or `workforce.md` so future runs target the same diagram.

---

## Phase 0: Prerequisites

Check that the Figma MCP server is available by looking for the `generate_diagram` tool.

**If the Figma MCP is NOT available:**

```
The Figma MCP server is required but not connected.

Install it with:
  claude mcp add --transport http figma https://mcp.figma.com/mcp

Then restart Claude Code and re-run /generate-diagram.
```

Stop here. Do not proceed without the Figma MCP.

**If available**, continue to Phase 1.

---

## Phase 1: Determine Mode and Target

1. **Identify the target:**
   - If the user provided an agent / workforce name or ID, use it
   - Otherwise check the active build's docs in `builds/`
   - If still unclear, ask the user what to diagram

2. **Detect target type:**
   - If the ID matches a workforce, this is a **workforce diagram**
   - If the ID matches a single agent, this is a **single agent diagram**
   - If unsure, call `relevance_list_workforces` and `relevance_list_agents` to resolve

3. **Check for existing FigJam linkage:**
   - Read the relevant `agent.md` or `workforce.md`
   - Look for a `## Workflow Diagram` section with a FigJam URL
   - If found: this is an **update**. Inform the user the existing diagram will be regenerated.
   - If not found: this is a **new diagram**

4. **Confirm with the user:** "I'll generate a {workforce / agent} diagram for **{name}**. {Creating new / Updating existing FigJam}. Proceed?"

---

## Phase 2: Gather Architecture Data

### For a Workforce

**2a. Get the workforce graph:**
```
relevance_get_workforce(workforceId: "{id}")
```
Extract:

- **Triggers:** type, node IDs, config
- **Agent nodes:** node_id, agent_id, name
- **Edges:** source, target, edge_type (forced-handover vs tool-call), threading_behavior

**2b. Get each agent's details (parallel):**
For each agent node, call in parallel:
```
relevance_get_agent(agentId: "{agent_id}", summary: false)
relevance_get_agent_tools(agentId: "{agent_id}")
```
Extract per agent:

- Agent name, model
- Tool names (from actions array or get_agent_tools)
- Knowledge tables (knowledge_set IDs, usage_type)
- External integrations (OAuth-based tools, API calls)

### For a Single Agent

```
relevance_get_agent(agentId: "{agent_id}", summary: false)
relevance_get_agent_tools(agentId: "{agent_id}")
```
Extract:

- Agent name, model
- All tools with names
- Knowledge tables
- External integrations
- Workflow steps from system prompt (if discernible)

---

## Phase 3: Build Mermaid

Read `mermaid-conventions.md` in this skill folder for the visual language reference.

### Diagram Direction

- **Workforces:** `graph TD` (top-down: shows orchestration hierarchy)
- **Single agents:** `graph LR` (left-right: shows tool flow)

### Construction Rules

1. **All shape and edge text must be in quotes** (e.g., `["Text"]`, `-->|"Edge Text"|`)
2. **No emojis** in Mermaid syntax
3. **No `\n` for newlines.** Use `<br>` inside quoted text if needed
4. **Use color styling sparingly.** Only to distinguish agent subgraphs
5. Follow the shape conventions from `mermaid-conventions.md`

### Workforce Diagram Structure

```mermaid
graph TD
    %% Triggers
    trig{{"Webhook Trigger"}}

    %% Agent subgraphs with their tools
    subgraph sg_orchestrator["Orchestrator"]
        orch(["Orchestrator Agent"])
    end

    subgraph sg_researcher["Research Agent"]
        a1["Research Agent"]
        t1("Google Search")
        t2("Web Scraper")
        a1 --> t1
        a1 --> t2
    end

    %% Data layer
    subgraph sg_data["Data"]
        k1[("Contacts")]
        k2[("Research Results")]
    end

    %% Integrations
    subgraph sg_integrations["Integrations"]
        ext1[/"HubSpot"/]
    end

    %% Edges
    trig -->|"forced-handover"| orch
    orch -.->|"tool-call"| a1
    a1 ...>|"reads"| k1
    a1 ...>|"writes"| k2
    a1 ...>|"syncs"| ext1
```

### Single Agent Diagram Structure

```mermaid
graph LR
    a1["Agent Name"]

    subgraph sg_tools["Tools"]
        t1("Tool 1")
        t2("Tool 2")
    end

    subgraph sg_data["Data"]
        k1[("Knowledge Table")]
    end

    a1 --> t1
    a1 --> t2
    a1 ...>|"reads"| k1
```

---

## Phase 4: Push to FigJam

Call the Figma MCP `generate_diagram` tool:

```
generate_diagram(
  name: "{Agent / Workforce Name} -- Architecture",
  mermaidSyntax: "{the constructed Mermaid string}",
  userIntent: "Generate a FigJam workflow diagram for the {name} {agent / workforce} on Relevance AI"
)
```

**Important:** the tool returns a FigJam URL. Save this URL: it's needed for Phase 5.

Present the URL to the user as a clickable markdown link:
```
Diagram created: [View in FigJam]({url})
```

**Note on updates:** the `generate_diagram` tool creates a new diagram each time. For updates, generate the new diagram, provide the URL to the user, and update the linkage in docs. If the user wants to replace content in an existing FigJam file, they should use the Figma UI to copy the generated nodes into their existing file.

---

## Phase 5: Update Linkage in Docs

Add or update a `## Workflow Diagram` section in the relevant doc file:

### For workforce diagrams in `workforce.md`:

```markdown
## Workflow Diagram
- **FigJam:** {url}
- **Last updated:** {YYYY-MM-DD}
```

### For agent diagrams in `agent.md`:

```markdown
## Workflow Diagram
- **FigJam:** {url}
- **Last updated:** {YYYY-MM-DD}
```

If the doc file doesn't exist yet, inform the user and suggest running `/document-workforce` first to create the full documentation, then re-run `/generate-diagram`.

---

## Output Summary

When complete, present:
```
## FigJam Diagram Generated

- **Target:** {name} ({agent / workforce})
- **FigJam:** [{url}]({url})
- **Docs updated:** {path to agent.md or workforce.md}

Open the link above to view and share the diagram.
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Figma MCP not connected | Print install instructions, stop |
| Agent / workforce not found | Ask user to confirm the ID or active project |
| Mermaid syntax rejected by Figma | Check for unsupported diagram types or syntax errors, fix and retry once |
| No agent.md / workforce.md exists | Warn user, suggest `/document-workforce` first, still generate diagram |
| Large workforce (10+ agents) | Simplify by grouping similar agents, warn user about complexity |

## Tags
#figma #figjam #diagram #workflow #visualization #mermaid
