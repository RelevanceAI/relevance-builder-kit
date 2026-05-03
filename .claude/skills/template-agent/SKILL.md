---
name: template-agent
description: Design and build a clean starter agent for any new use case. Use this skill when starting a new build, when someone asks "how should I build my first agent for X?", "what goes in a v1 agent?", "how do I avoid ending up with a generic stock-template-looking agent?", or when sanity-checking before shipping. Covers the 12-point design rubric, architecture layers (variables vs knowledge tables vs tools vs placeholders), the v0 to vN roadmap pattern, build-fresh-not-fork principle, system prompt anti-patterns, tool selection rules, smoke test via async pattern. Pairs with `/agent-build-patterns` for general design philosophy.
---

## When to Use

- Starting a new agent build for any use case. You need a clean v1.
- You've explored a marketplace or Invent-generated agent and you're about to build the real one.
- You're tempted to fork an existing generic agent. Read this first.
- You've built a v1 and want to sanity-check it against the rubric.

## What a Starter Agent Is (and Is Not)

A **starter agent** is the day-1 v1 you stand up for a new use case. Its job is to:

1. Produce a usable first output within the first 30 minutes of running it
2. Be editable through variables, knowledge table rows, and Connect pills without needing prompt surgery
3. Make the roadmap visible. The agent itself shows where the build is headed
4. Ship clean. No spec-doc framing, no meta-language, no placeholder noise

It is **not**:

- A forked marketplace agent renamed for your use case
- An Invent-generated agent with `{{_placeholder.TOOL}}` pills nobody has wired up
- A prompt that reads like "v1 scope, v2 TBC, out of scope for now"
- A JSON-envelope output that has to be parsed before it's useful

If your starter agent reads like an internal spec document, you built the wrong thing.

## 12-Point Design Rubric

A starter agent should pass all 12 to ship. See `checklist.md` for the tactical version. The principles behind each:

### Architecture

1. **Built fresh via MCP.** Not forked from a marketplace or Invent-generated agent. Clean slate = half the prompt length and no legacy baggage. See anti-pattern `forked-from-marketplace`.
2. **Architecture layers match content type.**
   - **Variables** (`params_schema` with `is_fixed_param: true` + `default`): stable, always-in-context content the user will edit (brand, tone of voice, compliance rules, a few reference examples)
   - **Knowledge tables**: scaling retrievable content (product facts, industry insights, past examples beyond 2-3 rows, templates)
   - **Tools**: purposeful actions (research, extract, parse, generate). Each tool earns its slot.
   - **Placeholder tools** (`{{_placeholder.TOOL <name>}}`): roadmap slots for future capabilities. Render as Connect pills in the UI. See `BUILD_PRACTICES.md` § "Placeholder Tools".

### System Prompt

3. **Write the prompt as instructions to the role, not to the build process.** Open with "You are a [role] for [purpose]". No version markers. No "In scope / Out of scope / Hard Rules" meta-bullets. The agent doesn't know it's a starter.
4. **Output format matches the consumer.** Markdown for humans (copy-paste to a doc / CMS). Structured JSON for downstream automation. Never both (JSON wrapping prose is a design smell).
5. **Tool references are natural language.** Describe tools by name and purpose in prose: "Use Perplexity to research industry trends". Not `{{_actions.XXX}}` injection. Attach with `inject_action_references: false`.
6. **Length discipline.** Target under 4,000 characters post-substitution. If your prompt is 6k+, you've got spec-doc framing or filler. Cut.

### Tools

7. **3-5 tools, each with a clear purpose.** Default marketplace agents ship with 10 tools, most unused. Each tool in a starter must map to one distinct retrieval or action. See anti-pattern `tool-hoarding`.
8. **No default-added tools that don't earn their place.** Drop these almost always:
   - **LLM tool**: pointless when the agent writes directly
   - **Thinking / scratchpad tool**: superseded pattern; modern Claude models reason inline
   - **Paid tools without credits**: e.g. People Enrichment when you don't have an API key
   - **Redundant research tools**: Perplexity + Google Search both attached. Pick one.

### Roadmap

9. **v0 -> vN journey, one constraint per version.** Each version answers one question. Move only when the question passes live. Realistic endpoint for an early build is v4 or v5. Aspirational v10 is often a workforce: that's a later conversation.
10. **Future capability telegraphed via placeholder tools.** For v5 / v7 capabilities not in v1 (e.g. image generation, slides), use `{{_placeholder.TOOL <name>}}`. The Connect pill in the UI shows where future tools will slot in.

### Test

11. **Editability test.** A non-builder should be able to edit a variable (say, the tone of voice) or add a KB row and see the output shift without you in the room. If only the builder can tune it, the starter has failed.
12. **Smoke test via async pattern.** Use `relevance_trigger_agent` + `relevance_get_agent_task_summary`. **Do NOT use `trigger_agent_sync` over MCP.** Transport drops mid-poll (120s) and surfaces as a misleading "user rejected" error.

## Build Flow

The order matters. Output format constrains everything downstream — pick it first.

```
1. Read any existing sandbox agent the user has
   -> understand their mental model
   -> do NOT fork; note what they're thinking

2. Decide output type for v1   <-- DO THIS FIRST. Format constrains tools, KB, prompt structure.
   See "Output Format Decision Tree" below.

3. Pick 3-5 tools, each mapped to one purpose
   -> drop LLM, thinking, paid-without-credits, redundant research

4. Design the data architecture
   -> variables for brand / tone / compliance (stable, always in context)
   -> knowledge tables for product facts, templates, examples (scales)
   -> placeholders for future capabilities (roadmap visibility)

5. Write the prompt as instructions to a role
   -> Identity line opens
   -> sections for Brand / Tone / Compliance (variables)
   -> "How You Work" with Tools subsection (natural language)
   -> Output format (markdown-fenced for humans)
   -> Reference Examples pointer (KB, not inline)
   -> Hard rules (few, plain)

6. Create via MCP
   -> relevance_upsert_agent for name + description + prompt
   -> relevance_patch_agent for model, temperature, thinking_tool disabled, variables
   -> relevance_create_knowledge_table + relevance_add_knowledge_rows
   -> relevance_attach_tools_to_agent with inject_action_references: false

7. Smoke test (async pattern)
   -> relevance_trigger_agent with a real brief
   -> relevance_get_agent_task_summary to verify output

8. Ship
   -> roadmap doc + checklist captured in builds/{build-name}/
   -> editability and smoke tests both passed
```

### Output Format Decision Tree (Step 2)

Get this wrong and the rest of the build compensates for it. Walk it before picking tools.

```
Who consumes the agent's output?
  │
  ├─ A human who copies / pastes / publishes it
  │    (writer, editor, sales rep, content manager)
  │    │
  │    └─ Markdown. Clean fenced sections. Sources block at the end.
  │       NO JSON envelope. NO {draft, citations, flags} wrapper.
  │       (See anti-pattern: json-envelope-wrapping-prose)
  │
  ├─ A downstream tool / agent / system that parses it
  │    (CRM update, next agent in workforce, automation step)
  │    │
  │    └─ Structured JSON with a defined schema. No prose. No mixed content.
  │
  ├─ Both ("the human reviews then it goes to a tool")
  │    │
  │    └─ This is a workforce, not one agent. The first agent produces clean
  │       markdown for review; the second consumes the approved version into
  │       structured data. Don't try to satisfy both consumers in one output.
  │
  └─ Don't know yet
       │
       └─ Pick markdown. Easier to add a structured-output downstream agent
          later than to extract a usable doc from a JSON envelope nobody loves.
```

**Pick before tool selection.** A markdown-output agent often needs Google Search + Extract Text + a knowledge-table read. A JSON-output agent often needs different tools (CRM lookup, structured enrichment) — and a much shorter prompt because there's no prose-style writing to constrain.

**Pick before data architecture.** Reference examples in a markdown agent live in a knowledge table the agent reads to anchor voice. Reference examples in a JSON agent live in a knowledge table the agent reads to anchor schema choices. Different tables, different rows, different prompt sections.

**If a stakeholder lists 4 output types** (emails, one-pagers, talking points, pitch outlines), pick the one that demos the build's value best — usually the longest-form, most-skeptical-stakeholder-friendly artefact. See anti-pattern `list-order-as-priority`.

### Placeholder Tool Verification (Step 6)

When you've used `{{_placeholder.TOOL <name>}}` in the prompt to reserve roadmap slots (rubric point 10), verify they're working as expected before you ship.

```
1. Open the agent in the platform UI
   → URL: https://app.relevanceai.com/agents/{region}/{project}/{agentId}/edit

2. In the system prompt editor, find each {{_placeholder.TOOL <name>}}
   → It should render as a "Connect" pill (greyed-out tool slot with the name visible)
   → If it renders as raw text, check the syntax: exactly two curly braces,
     one underscore, "TOOL" in caps, single space before the name
   → Common typo: {{_placeholder.tool <name>}} (lowercase "tool") renders as text

3. In the agent config drawer, scan tools list
   → Real attached tools show as connected with their action ID
   → Placeholders should NOT appear in the tools list — they're prompt-only
     reservations until a real tool is connected

4. Run a smoke test brief that does NOT trigger the placeholder capability
   → Use relevance_trigger_agent + relevance_get_agent_task_summary
   → Verify: agent does NOT call the placeholder. The mock-echo response
     would surface as a tool call with empty / echo'd content
   → If the agent calls the placeholder anyway, your prompt's "When to use"
     guidance for that tool is too eager. Tighten the conditions.

5. (Optional) Run a brief that WOULD trigger the placeholder
   → The mock-echo phantom tool returns a placeholder response
   → Confirm: agent receives the response and continues gracefully (or stops
     with a clear "this capability isn't connected yet" message, depending
     on how the prompt handles it)
   → This is your "before connecting the real tool" baseline behaviour
```

Avoid placeholders entirely if the agent is going to the marketplace — validation rejects `"Agent prompt contains placeholder tools"`. See `build-kit/agents/prompt/placeholder-tools.md` for full mechanics.

## Files in this skill

- `SKILL.md` -- this file: the design rubric and process
- `checklist.md` -- the pre-ship tactical checklist
- `anti-patterns.md` -- the anti-patterns library with examples

## Related

- `/agent-build-patterns` -- general design philosophy (Unit of Action, constraint-per-version, etc.)
- `.claude/rules/BUILD_PRACTICES.md` -- general agent design rules (variables, tools, state_mapping, eval)
- `.claude/rules/PLATFORM_MECHANICS.md` -- API patterns, write operations, placeholder tools
