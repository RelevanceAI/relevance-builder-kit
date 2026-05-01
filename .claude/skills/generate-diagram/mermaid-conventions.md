# Mermaid Conventions for Relevance AI Diagrams

Standardized mapping from Relevance AI concepts to Mermaid shapes. Used as the transient intermediary format for FigJam generation via the Figma MCP `generate_diagram` tool.

**Important:** the Mermaid is not persisted. The FigJam file is the canonical artifact.

---

## Design Principles

1. **Top-down flow always.** Use `graph TD` for all diagrams (single agents and workforces). Vertical hierarchy reads naturally.
2. **Subgraphs as swim lanes.** Group nodes by phase / function (Input / Trigger, Research, Actions, Output / Integrations). Name sections by what they DO, not what they ARE.
3. **Color code by function.** Every node gets a color based on its role (see palette below). This is not optional. It's the primary visual cue.
4. **Action-oriented labels.** Use descriptive text that explains what the node DOES: "Search Google for prospect info" not just "Google Search". Squares with clear text, no fancy shapes.
5. **Simple connectors.** Plain arrows (`-->`), no labels on edges unless the routing is ambiguous. The flow should be obvious from the layout.
6. **Nested subgraphs for sub-agents.** When an agent delegates to tools or sub-agents, nest them inside the parent's subgraph.
7. **All nodes are rectangles.** Use `["Text"]` for everything. Consistency over shape variety. The color does the differentiation.

## Color Palette (mandatory)

Every node must be styled. Use these colors consistently:

```
%% Triggers / Inputs -- Purple / Lilac
style node fill:#C4B5FD,stroke:#7C3AED,color:#000

%% Agents / Core steps -- Green
style node fill:#6EE7B7,stroke:#059669,color:#000

%% Tools / Research -- Darker Green
style node fill:#34D399,stroke:#047857,color:#000

%% Actions / Outputs -- Orange
style node fill:#FDBA74,stroke:#EA580C,color:#000

%% Integrations / External -- Orange (same as outputs, they are actions)
style node fill:#FDBA74,stroke:#EA580C,color:#000

%% Post-processing / Follow-up -- Blue
style node fill:#93C5FD,stroke:#2563EB,color:#000
```

| Function | Color | When to use |
|----------|-------|-------------|
| Trigger / Input | Purple (`#C4B5FD`) | Entry points: webhooks, CSV uploads, CRM triggers |
| Agent / Core step | Green (`#6EE7B7`) | Agent nodes, main processing steps |
| Tool / Research | Darker Green (`#34D399`) | Tools the agent calls: search, scrape, enrich |
| Action / Output | Orange (`#FDBA74`) | Write operations: create email, generate report, save to DB |
| Integration / External | Orange (`#FDBA74`) | External systems: CRM, Notion, Slack, email platforms |
| Follow-up / Post-process | Blue (`#93C5FD`) | Reply handling, monitoring, post-outreach |

## Subgraph Conventions

Subgraphs represent **phases / swim lanes**, not just groupings:

- **Input / Trigger** -- how data enters the system
- **Main Agent** -- the core processing (nest sub-agents / tools inside)
- **Research** (nested) -- tools that gather information
- **Actions** -- what the agent produces (emails, reports, messages)
- **Output / Integrations** -- where results go (CRM, Notion, email platform)
- **Post-Processing** -- follow-up, reply handling

## Syntax Rules (Figma MCP requirements)

These rules are enforced by the Figma `generate_diagram` tool:

1. **All text in quotes.** Shape labels and edge labels must be quoted (e.g., `["Text"]`, `-->|"Edge"|`)
2. **No emojis.** The tool rejects emoji characters
3. **No `\n` newlines.** Use `<br>` inside quoted text if line breaks are needed
4. **Supported diagram types only:** `graph`, `flowchart`, `sequenceDiagram`, `stateDiagram`, `stateDiagram-v2`, `gantt`
5. **Always use `TD` direction.** Top-down for all diagrams
6. **Color styling is mandatory.** Style every node per the palette above
7. **Simple arrows only.** Use `-->` for flow, no labels unless routing is ambiguous

---

## Example Templates

### Single Agent

```mermaid
graph TD
    subgraph sg_input["Input"]
        inp1["User sends research query"]
    end

    subgraph sg_agent["Main Agent"]
        a1["Receive research request"]

        subgraph sg_research["Research"]
            t1["Search Google for topic"]
            t2["Summarise search results"]
        end

        a1 --> t1
        t1 --> t2
    end

    subgraph sg_output["Output"]
        out1["Save findings to Notion"]
    end

    inp1 --> a1
    t2 --> out1

    style inp1 fill:#C4B5FD,stroke:#7C3AED,color:#000
    style a1 fill:#6EE7B7,stroke:#059669,color:#000
    style t1 fill:#34D399,stroke:#047857,color:#000
    style t2 fill:#34D399,stroke:#047857,color:#000
    style out1 fill:#FDBA74,stroke:#EA580C,color:#000
```

### 2-Agent Workforce

```mermaid
graph TD
    subgraph sg_input["Input / Trigger"]
        inp1["List of leads from CSV"]
        inp2["Triggered leads from CRM"]
    end

    subgraph sg_main["Main Agent"]
        a1["Receive lead info"]

        subgraph sg_research["Research Agent"]
            t1["Do research on the prospect"]
            t2["Google Search"]
            t3["Extract website content"]
            t1 --> t2
            t1 --> t3
        end

        a1 --> t1

        a2["Create research report"]
        a3["Create outreach email"]
        t1 --> a2
        t1 --> a3
    end

    subgraph sg_output["Output"]
        out1["Upload to CRM"]
        out2["Upload to email platform"]
    end

    inp1 --> a1
    inp2 --> a1
    a2 --> out1
    a3 --> out2

    style inp1 fill:#C4B5FD,stroke:#7C3AED,color:#000
    style inp2 fill:#C4B5FD,stroke:#7C3AED,color:#000
    style a1 fill:#6EE7B7,stroke:#059669,color:#000
    style t1 fill:#34D399,stroke:#047857,color:#000
    style t2 fill:#34D399,stroke:#047857,color:#000
    style t3 fill:#34D399,stroke:#047857,color:#000
    style a2 fill:#FDBA74,stroke:#EA580C,color:#000
    style a3 fill:#FDBA74,stroke:#EA580C,color:#000
    style out1 fill:#FDBA74,stroke:#EA580C,color:#000
    style out2 fill:#FDBA74,stroke:#EA580C,color:#000
```

### Full Pipeline

```mermaid
graph TD
    subgraph sg_input["Input / Trigger"]
        inp1["List of leads on CSV"]
        inp2["Triggered leads from CRM"]
    end

    subgraph sg_main["Main Agent"]
        a1["Receive Lead Info"]

        subgraph sg_research["Research Agent"]
            r1["Do research on the prospect"]
            r2["Google Search"]
            r3["Extract Website Content"]
            r4["Read PDF"]
            r1 --> r2
            r1 --> r3
            r1 --> r4
        end

        a1 --> r1

        subgraph sg_outreach["Outreach"]
            o1["Create Research Report"]
            o2["Create Email Sequence"]
            o3["Create LinkedIn Message"]
        end

        r1 --> o1
        r1 --> o2
        r1 --> o3
    end

    subgraph sg_output["Output"]
        out1["Upload to CRM"]
        out2["Upload to Sales Automation<br>Platform"]
        out3["Send LinkedIn Message"]
    end

    subgraph sg_post["Post-Outreach"]
        post1["On prospect reply,<br>address questions and<br>book meeting"]
    end

    inp1 --> a1
    inp2 --> a1
    o1 --> out1
    o2 --> out2
    o3 --> out2
    o3 --> out3
    out1 --> post1
    out2 --> post1
    out3 --> post1

    style inp1 fill:#C4B5FD,stroke:#7C3AED,color:#000
    style inp2 fill:#C4B5FD,stroke:#7C3AED,color:#000
    style a1 fill:#C4B5FD,stroke:#7C3AED,color:#000
    style r1 fill:#34D399,stroke:#047857,color:#000
    style r2 fill:#34D399,stroke:#047857,color:#000
    style r3 fill:#34D399,stroke:#047857,color:#000
    style r4 fill:#34D399,stroke:#047857,color:#000
    style o1 fill:#FDBA74,stroke:#EA580C,color:#000
    style o2 fill:#FDBA74,stroke:#EA580C,color:#000
    style o3 fill:#FDBA74,stroke:#EA580C,color:#000
    style out1 fill:#FDBA74,stroke:#EA580C,color:#000
    style out2 fill:#FDBA74,stroke:#EA580C,color:#000
    style out3 fill:#FDBA74,stroke:#EA580C,color:#000
    style post1 fill:#93C5FD,stroke:#2563EB,color:#000
```
