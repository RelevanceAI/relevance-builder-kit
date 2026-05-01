# Starter Agent Pre-Ship Checklist

> Run through this before shipping any new starter agent. A starter agent should pass all 12 checks before you call it done.

## Before you start

- [ ] You've read any existing sandbox or marketplace agent for the same use case (if there is one) and understood its approach without forking it
- [ ] You've chosen the v1 output type based on which format shows the build's value best, not list-order from the requirements
- [ ] You've confirmed you will build fresh via MCP, not fork a marketplace / Invent-generated agent

## Architecture

- [ ] **1. Built fresh** via `relevance_upsert_agent`. Zero inheritance from a marketplace or Invent template.
- [ ] **2. Data layered correctly:**
  - [ ] Agent variables (`params_schema` with `is_fixed_param: true` + `default`) hold brand, tone, compliance, and optionally a small number of stable reference examples
  - [ ] Knowledge tables hold product facts, industry content, and scaling reference examples (>2-3 rows)
  - [ ] Tools are purposeful, not defaults
  - [ ] Placeholder tools (`{{_placeholder.TOOL <name>}}`) reserve slots for v5+ capabilities

## System Prompt

- [ ] **3. Role-first framing.** Opens with "You are a [role] for [purpose]". No version markers, no "In scope / Out of scope" bullets, no TBC comments.
- [ ] **4. Output format matches consumer.** Markdown (for humans, copy-paste) OR JSON (for downstream code). Never both.
- [ ] **5. Tool references are natural language.** Zero `{{_actions.XXX}}` injections. Attach tools with `inject_action_references: false`.
- [ ] **6. Under 4,000 characters** post-substitution.

## Tools

- [ ] **7. Three to five tools**, each with a clear single purpose
- [ ] **8. Default-tool smell check passed:**
  - [ ] No **LLM** tool (agent writes directly)
  - [ ] No **thinking / scratchpad** tool (`thinking_tool.enabled: false`)
  - [ ] No **paid tools** that can't run (e.g. People Enrichment without credits)
  - [ ] No **redundant research tools** (e.g. Perplexity + Google both attached)

## Roadmap

- [ ] **9. v0 -> vN roadmap** written, with one constraint per version. Realistic near-term endpoint captured. Aspirational endpoint (often a workforce) captured.
- [ ] **10. Future capability telegraphed** via `{{_placeholder.TOOL <name>}}` for v5+ tools (image gen, slide gen, etc.)

## Test

- [ ] **11. Editability test run:** change a variable (e.g. tone of voice) and confirm output shifts accordingly
- [ ] **12. Async smoke test passed:**
  - [ ] Used `relevance_trigger_agent` (async) + `relevance_get_agent_task_summary`. NOT `trigger_agent_sync`
  - [ ] Output matches the expected format (markdown fenced, Sources section, etc.)
  - [ ] No em dashes in output
  - [ ] No LLM filler ("delve into", "tapestry", "game-changer", etc.)
  - [ ] Placeholder tools NOT called unless the brief explicitly asked for their capability
  - [ ] Grounded claims cited; no invented facts

## Documentation

- [ ] `builds/{build-name}/agent.md` has: agent_id, model, temperature, autonomy, full tool + KB + variable list, smoke test result
- [ ] `roadmap.md` exists and shows v0 -> vN
- [ ] `system-prompts/v1.md` captures the live prompt for reference
- [ ] `test-sets/v1-golden-set.md` has 3-5 test cases with evaluator rules
- [ ] Tool and KB sub-docs capture the attached tools / knowledge tables

## Before going live

- [ ] You can open the agent in the platform UI and see the structure (variables in the config drawer, Connect pills for placeholders, KB rows searchable)
- [ ] You've verified at least two different briefs produce usable output
- [ ] The agent's agent_id, knowledge_set names, and placeholder tools are captured in local docs

## If any check fails

Don't ship. Common fixes:

| Check that failed | Usual fix |
|---|---|
| 3. Role-first framing | Delete the "In scope / Hard Rules" meta-bullets. Rewrite as prose instructing the role. |
| 4. Output format | Pick one format. Drop the JSON envelope if you want humans to consume it. |
| 5. Tool references | Re-attach tools with `inject_action_references: false`. Rewrite prompt to describe tools by name in prose. |
| 7. Tool count | List each tool. For each, name the specific retrieval or action it serves. Cut tools that don't have one. |
| 9. Roadmap | Each version gets one constraint question. Write them down. If a version doesn't have one, it shouldn't exist. |
| 12. Smoke test | If the output has em dashes, LLM filler, or JSON envelope, rewrite the prompt sections that allowed it. |
