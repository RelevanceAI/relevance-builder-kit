# Documentation Structure Rules

This kit uses a per-build documentation structure with isolation between builds:

- `builds/` -- Per-build documentation and context (your own work)
- `docs/` -- Human-readable onboarding and reference docs
- `.claude/skills/` -- Slash-command skill files
- `.claude/rules/` -- Governance rules (this directory)
- `playbooks/` -- Use-case patterns
- `build-kit/` -- Deep reference material

---

## Guiding Principles

1. **Single Source of Truth.** Every doc lives in exactly one place. If unsure where something goes, ask rather than create a second copy.

2. **Cold-Start Test.** After every build / modify session, ask: "Could I resume this work next week reading only local files, with zero MCP calls?" If no, the docs are incomplete. Fix before ending the session.

3. **One Retrieval Intent Per File.** If Claude would answer materially different questions from different parts of a file, split it. Each file should pass the test: "If Claude only read this one file, would it give a useful, accurate, bounded answer?"

4. **No Silent Contradictions.** Never let conflicting docs coexist without explicit resolution. When updating a fact that exists elsewhere, check for and resolve contradictions. See "Contradiction Handling" below.

---

## Authoring Principles for Knowledge Content

These apply to all files in `playbooks/`, `.claude/rules/`, and `build-kit/`. The primary consumer of these files is Claude Code, not humans browsing.

### Write Explicit Assertions

State facts directly. Claude extracts better answers from clear statements than from hedged narrative.

- Good: "Use phone agents when the workflow requires synchronous voice interaction with a single clear outcome."
- Bad: "Phone agents can be helpful in a range of situations depending on context and requirements."

### Structure for Extraction

- Put important facts in bullets or tables, not buried in prose paragraphs
- Use consistent section headings across files of the same type
- Avoid ambiguous headings like "Overview" or "Notes" repeated across files
- Define acronyms locally in each file: do not assume prior context

### Be Specific About Boundaries

Every knowledge file should state what it covers AND what it does not cover:

- "When to use" and "When not to use" sections are mandatory in playbooks and product docs
- Gotchas must be specific failure modes with context, not generic warnings
  - Good: "If the phone agent calls multiple tools synchronously before speaking, turn latency exceeds 8 seconds and the interaction breaks."
  - Bad: "Latency can be a problem."

### Use the Default/Variation Pattern

For prescriptive guidance, use this structure:

- **Default:** The recommended approach
- **Variation A when:** condition that changes the recommendation
- **Variation B when:** different condition
- **Do not use if:** disqualifying conditions

This gives Claude a base recommendation plus conditional adaptation for different contexts.

### Cross-Reference Precisely

- Use exact file paths: `build-kit/agents/phone/phone-agents.md`, not "see the phone agent docs"
- Link to specific sections when referencing large files
- Reference reusable components (tools, templates, schemas) instead of duplicating them

### Contradiction Handling

When knowledge files disagree, Claude follows this priority: `.claude/rules/` > `build-kit/` > `playbooks/`.

To prevent silent contradictions:

- When updating a fact, grep for the same topic in other files and resolve conflicts
- Use explicit conflict markers when the same topic has different answers in different scopes
- If deprecating previous guidance, state it: "Previously this approach was recommended; the current pattern is X because Y."

### Fast-Changing vs Stable Content

Not all knowledge decays at the same rate. Treat these differently:

| Change rate | Domains | Guidance |
|-------------|---------|----------|
| Fast (monthly) | platform features, integration APIs | Date-stamp key assertions. Verify before high-confidence claims |
| Medium (quarterly) | product capabilities, integration patterns | Review when encountered |
| Slow (yearly+) | use-cases, design patterns, build-kit | Update when architecture patterns shift |

---

## Build Documentation Protocol

1. **CONTEXT:** Confirm which build you're working on
2. **LOAD:** Read `builds/{build-name}/agent.md` and relevant tool docs
3. **WORK:** Execute the task
4. **UPDATE:** Update agent.md and tool docs with any changes (IDs, configs, decisions)
5. **VERIFY:** Run the cold-start test

---

## Folder Structure

```
relevance-builder-kit/
  CLAUDE.md                      # Root briefing (identity, philosophy, routing)
  playbooks/                     # Use-case playbooks (research, outreach, phone, enrichment, etc.)
  build-kit/                     # Deep reference material
    agents/                      # Single-agent reference
      prompt/                    # System prompt design, agent variables, placeholder tools
      tools/                     # Tool transformations, state-mapping, gotchas, sandbox auth, voice, AI Browser
      knowledge/                 # Knowledge tables (CRUD), CRM + locale knowledge architecture
      triggers/                  # Schedule, webhook, form, chat, slack triggers
      phone/                     # Phone agent best practices
      agent-write-operations.md  # MCP write ops (patch / upsert / save-draft) cross-cutting
    workforces/                  # Multi-agent orchestration: edges, setup, lifecycle
    evals-and-monitoring/        # Test suites, evaluators, LLM-as-judge, tool simulation, analytics, observability
    integrations/                # Integration guides (HubSpot, Salesforce, etc.)
    patterns/                    # CLAUDE.md design principles + best practices, error-debugging
    templates/                   # Doc templates
  .claude/
    rules/                       # Governance + platform mechanics (auto-loaded)
      DOC_RULES.md               # This file
      BUILD_PRACTICES.md         # Build practices
      PLATFORM_MECHANICS.md      # Platform API patterns, state_mapping
    skills/                      # Slash-command skills
  builds/                        # Your own build docs
    {build-name}/
      agent.md                   # Agent config, IDs, tools, workflow
      system-prompt.md           # Deployable system prompt
      tools/                     # Tool docs and configs
      workforce/                 # Workforce docs if applicable
  docs/                          # Human-readable docs
    getting-started.md           # Onboarding
    advanced-usage.md            # Power-user reference
  scripts/                       # Setup and quality-gate scripts
```

---

## Build Doc Requirements

### agent.md (MANDATORY for every build)

This is a **human-readable doc**. Markdown tables, code fences, and structured prose are encouraged for scannability. The deployable system prompt itself does NOT live here. It lives in `system-prompt.md` (see next section), which has stricter formatting rules.

Must include:

- Agent ID, model, temperature, autonomy
- Complete tool table with BOTH studio IDs AND action IDs (the `{{_actions.ID}}` values)
- Workforce context (if applicable): workforce ID, node ID, edge type, threading
- Knowledge tables read from and written to
- Key design decisions and workflow summary
- Pointer to where the system prompt lives (typically `./system-prompt.md`)

### system-prompt.md and other deployable prompt files

A separate file from `agent.md`. Holds the actual text that gets deployed to the agent's `system_prompt` field. Lives next to `agent.md`, or under a `system-prompts/` subdirectory for versioned files (`system-prompts/v1.md`, etc.).

**Different rules apply.** This text is consumed by the LLM at runtime AND opened in the agent UI's prompt editor by anyone tuning the agent. The constraints below are enforced by `scripts/pre-tool-system-prompt-check.sh` (PreToolUse hook on agent-write MCP tools) and `scripts/lint-system-prompts.sh` (CLI lint).

#### File-type contrast

- **`agent.md`** -- audience: humans reading docs. Markdown tables: encouraged. Tool references: document studio IDs + action IDs in tables.
- **`system-prompt.md`** -- audience: the LLM at runtime + humans editing in the agent UI. Markdown tables: avoid (use bullets / prose). Tool references: inline `{{_actions.ID}}` pills.

#### Rules for deployable prompt files

1. **No markdown tables.** Tables flatten to pipe-noise inside the agent UI's prompt editor and add tokens the LLM has to parse for no upside. Convert to bullet lists. Example:

   ```
   Before:                        After:
   | Pattern | Use for |          - **Pattern A** -- 3-column icon cards.
   |---|---|                        Use for 3 parallel benefits. Cap: 3 cards.
   | A | 3-column |               - **Pattern B** -- stacked text cards.
   | B | stacked |                  Short list of ideas (2 to 4).
   ```

2. **Tool references use bare `{{_actions.ID}}` pills.** Each tool the agent uses gets an explicit pill in the prompt body (typically inside a `# Your Tools` section). Bare tokens render as clickable tool pills in the UI; wrapping in backticks or `**bold**` breaks the pill binding (see `BUILD_PRACTICES.md` "Tool References").

3. **No em dashes or en dashes.** Use commas, full stops, parentheses, or the double-hyphen `--` if you want a long-dash effect. This is a hard rule in `CLAUDE.md`; it's enforced specifically on system prompts because they get deployed verbatim.

4. **`BEGIN PROMPT` / `END PROMPT` markers.** Wrap the deployable text in these markers when the file also contains preamble notes. The lint scans only what's between the markers, so preamble can use tables / dashes safely.

5. **Snippet substitution variables (`{{snippets.foo}}`, `{{_knowledge.bar}}`, `{{_placeholder.TOOL Name}}`)** are fine: they resolve at runtime and don't render as broken pills.

#### Why the split

`agent.md` documents how the agent is built for the next person who picks it up. `system-prompt.md` IS the agent's behaviour. Mixing rules means reference content (rate tables, KB inventories, pattern libraries) gets copy-pasted from `agent.md` into the prompt and the prompt UX degrades. Keeping them distinct lets each file optimise for its real consumer.

#### Verifying

Run `bash scripts/lint-system-prompts.sh` before deploying any prompt change. The hook also runs automatically on `relevance_upsert_agent` / `relevance_patch_agent` / `relevance_save_agent_draft` and blocks the deploy on violations.

### Tool Docs

**Every attached tool needs a local `.md` doc, not just custom tools.**

| Tool type | Required files |
|-----------|---------------|
| Custom tools | `.json` (config) + `.md` (docs) |
| Platform-native tools (LinkedIn, Google Search, etc.) | `.md` only (you don't own the config) |

Tool docs must include:

- Studio ID and action ID
- Purpose and when the agent calls it
- Input params and output format
- Integration details (OAuth accounts, API endpoints)

### Workforce Docs

Must include:

- Workforce ID
- All agent IDs + node IDs
- All edges with type (forced-handover vs tool-call) and threading
- Data flow diagram
- Knowledge tables
- Standalone agents that interact with the workforce but aren't in the graph

---

## File Naming

### Build Directories

- `{build-name}/` -- lowercase, hyphens (e.g., `lead-research/`, `phone-receptionist/`)

### Tools

- `{tool_name}.json` -- machine-readable config (custom tools only)
- `{tool_name}.md` -- human-readable docs (all tools)
- Keep `.json` and `.md` in sync

### Local-Only Files

- `.local` prefix or `.local/` directory -- gitignored, never committed
- Use for: credentials, scratch files, test results

---

## Maintenance Rules

### When to Update Build Docs

| Event | Update |
|-------|--------|
| Agent created | Create agent.md with all mandatory fields |
| Tool attached / modified | Update tool table in agent.md + tool doc |
| System prompt changed | Update prompt in agent.md and system-prompt.md |
| Workforce modified | Update workforce doc |
| New knowledge table | Add to agent.md |
| Design decision made | Add to design decisions section |

### When to Update Reference Knowledge

| Event | Update |
|-------|--------|
| Platform behavior discovered | `.claude/rules/PLATFORM_MECHANICS.md` |
| New build pattern identified | `.claude/skills/agent-build-patterns/` |
| New agent type built successfully | Consider adding to `playbooks/` |
| Best practice proved in production | `build-kit/` relevant file |

---

## Release Notes & Playbook Templates

### Release Notes

When deploying a major or critical change to production, add a release note to the build's change log:

```markdown
### v{X.Y} -- {YYYY-MM-DD}

**What changed:** [1-2 sentence summary]
**Why:** [Business reason or stakeholder request]
**Impact:** [What users will notice]
**Testing:** [Eval pass rate, key test results]
```

### Build Playbook Template

For complex builds, create a playbook in the build's docs folder:

```markdown
# {Build Name} Playbook

## Quick Start
- What this agent does (1 paragraph)
- How to trigger it
- Expected output format

## Common Scenarios
| Scenario | What happens | Expected time |
|----------|-------------|---------------|
| [Happy path] | [Description] | [Time] |
| [Edge case] | [Description] | [Time] |

## Troubleshooting
| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| [Error] | [Cause] | [Solution] |

## Escalation
- When to escalate: [conditions]
- Owner: [from agent.md]
```
