# CLAUDE.md Best Practices

Practical application of the layered CLAUDE.md system - three-level structure, templates, anti-patterns, and traversal design.

**Assumes the 10 principles in `claude-md-design-principles.md`.** That doc explains *why* each structural choice matters. This doc is the *how* - concrete shape of files at each level, with templates and failure modes. Read the principles first, then use this as the working reference.

---

## The Three Levels

Every repo using this pattern has three structural levels. Each level has a different job.

### Level 1 - Root CLAUDE.md (The Briefing)

**Job:** Give CC its identity, philosophy, and map of the entire repo.

This is the most important file. CC reads it first, every session. It should be complete enough that CC can think correctly without opening anything else.

Aim for 250-400 lines. Brevity is the wrong optimisation here - a 50-line routing hub forces CC to traverse before it can reason. A 300-line briefing gives it the mental model AND the map.

**Required sections (in order):**

1. **Identity** - Who CC is in this repo. Specific role, not generic. Shapes how CC approaches decisions.
2. **Philosophy** - The governing mindset before any routing.
3. **Paradigm Shifts** - Explicit mental model changes ("think THIS way, not THAT way").
4. **Operating Pillars** - Evaluation criteria, each with a question CC asks itself.
5. **Hard Rules** - Short, non-negotiable constraints. Also inlined next to the relevant section elsewhere.
6. **Session Start** - Mandatory protocol (numbered list with link to the full doc, not inlined).
7. **Routing** - Organised by domain. Table with area/key tools/status, plus query examples below.
8. **Cross-Domain Workflows** - Step-by-step breakdowns of the 4-5 most common multi-area tasks.
9. **Key Files Table** - Quick-reference for the 15-20 most important files across the whole repo.
10. **Proactive Documentation** - When/where to update docs after any change. Mandatory, not suggested.

---

### Level 2 - Directory CLAUDE.md (The Domain Hub)

**Job:** Tell CC what's in this directory, when to come here, and where to go next.

These are the routing nodes of the tree. Shorter than root (50-100 lines). Every directory that contains meaningful content should have one.

**Required sections:**

```
# {Directory Name}

One-sentence description of this directory's purpose and scope.

## Contents

Bulleted list or table of what's here. For sub-directories: list them with
a one-line purpose. For files: name + purpose. Always include item counts
when useful ("59 tips", "10 playbooks", "6 battle cards").

## Routing

Come here when:
- [Query type 1]
- [Query type 2]
- [Query type 3]

## See Also

- `path/to/file` -- one-line description
- `path/to/other` -- one-line description
```

The "Come here when:" list is the most important part. Write it from the user's perspective, not the directory's perspective. "How does Relevance AI compare to X?" not "For competitive information."

The "See Also" section closes loops - it's where you acknowledge adjacent areas CC might confuse this with. Always use exact file paths (`build-kit/integrations/` not "the integrations folder").

---

### Level 3 - Leaf CLAUDE.md (The Signpost)

**Job:** Orient CC immediately when it lands in a specific sub-directory.

These are shorter still (20-50 lines). They answer: what's here, why it exists, and where the full context lives.

Example pattern for a tools reference directory:

```
# Tool Reference

What it is: Platform tool step types, gotchas, icon URLs.

## Contents

- `tool-transformations.md` -- All available step types and valid configs
- `platform-tool-gotchas.md` -- Non-obvious behaviors that cause build failures
- `tool-icon-urls.md` -- Branded logo URLs for tool icons

## Routing

Come here when:
- Building a tool and unsure which step type to use
- Getting unexpected tool behavior (check gotchas first)
- Looking up an icon URL

## See Also

- `.claude/rules/PLATFORM_MECHANICS.md` -- Platform mechanics (state_mapping, template resolution)
```

---

## Content Rules

### Pointers, Not Duplication

Root CLAUDE.md: complete enough to operate from alone.

Sub-directory CLAUDE.md files: pointers, not content. They tell CC where depth lives, not what the depth is. Never duplicate content between levels - it creates silent contradictions.

Bad:
```
## State Mapping Rules

state_mapping keys are pre-declared by the runtime. Never use const or let
to declare a variable with the same name as a state_mapping key...
[200 lines of detail]
```

Good:
```
## State Mapping

Full patterns and gotchas: `.claude/rules/BUILD_PRACTICES.md` "state_mapping and Inter-Step Data Flow"
```

### Item Counts Signal Richness

Include counts when they communicate completeness. "59 tips", "10 use-case playbooks", "6 battle cards" tells CC (and humans) that there's real depth here. "Tips" alone does not.

### Query-First Routing

Write routing from what the user asks, not from what's in the folder:

Bad: "For information about competitive positioning and battle cards"
Good: "How does Relevance AI compare to [competitor]?"

CC resolves user questions, not folder descriptions.

---

## Traversal Design

### The Breadcrumb Contract

Every CLAUDE.md should let CC answer: "where do I go if I need more?" Every file should have a "See Also" that points up and sideways. Never a dead end.

Tree traversal:
- Root gives domain overview and points to domain CLAUDE.md
- Domain CLAUDE.md gives contents and points to files and sub-domains
- Leaf files have their own routing context

CC should never need to backtrack to root to find something - each level should give enough context to navigate forward.

### Every Directory Gets One

If a directory has meaningful content and CC might land in it, it gets a CLAUDE.md. No exceptions. Orphaned directories (no CLAUDE.md) create navigation dead ends.

This includes:
- `builds/` (build index, cold-start test)
- `scripts/` (script catalog, hook docs)
- Every sub-directory of `.claude/`
- Even small directories like `patterns/` and `templates/`

### The Cold-Start Test (Per Level)

After writing any CLAUDE.md, ask: "If CC read only this file, could it do its job correctly?" For root, that means operating at the right level with the right identity. For sub-directories, that means navigating to the right file without backtracking.

### Cross-Reference With Exact Paths

Always use exact file paths in references. Never relative descriptions.

Bad: "see the tools reference"
Good: "`build-kit/tools/platform-tool-gotchas.md`"

Bad: "the knowledge base"
Good: "`playbooks/use-cases/` -- 10 use-case playbooks"

Exact paths are executable. Descriptions require interpretation.

---

## Common Anti-Patterns

### The Routing-Only Root

A root CLAUDE.md that's just a table of links. CC reads it and knows where things are but not how to think. Result: correct navigation, wrong reasoning.

Fix: Add identity, philosophy, paradigm shifts, and pillars before the routing table.

### The Content-Heavy Sub-Directory

A sub-directory CLAUDE.md that duplicates content from rules or reference files. Result: two sources of truth that drift apart.

Fix: Pointer to the authoritative file. One line, exact path.

### Missing "See Also"

A file with no cross-references. CC can find it but can't navigate out of it.

Fix: Every CLAUDE.md ends with "See Also" that points to at least root and the nearest adjacent area.

### Orphaned Directories

A directory with content but no CLAUDE.md. CC traverses into it and has no routing context.

Fix: Add a CLAUDE.md. Even 20 lines is better than nothing.

### Overly Generic "Come Here When"

```
Come here when:
- You need integration information
```

vs.

```
Come here when:
- "How do I connect HubSpot?" -- build-kit/integrations/hubspot.md
- "What's the right state_mapping for a multi-step tool?" -- build-kit/tools/state-mapping.md
- "Can the agent process records in parallel?" -- build-kit/patterns/parallel-tool-calls.md
```

Generic routing is useless. Specific query patterns are navigable.

### Rules Only in One Place

A critical rule buried in a sub-file that only applies when CC reads that specific file. If it's truly critical, it's in root Hard Rules AND inline in the relevant section.

---

## The Anatomy of a Good "See Also"

```
## See Also

- `CLAUDE.md` (root) -- repo overview and routing
- `.claude/CLAUDE.md` -- knowledge base hub
- `.claude/rules/BUILD_PRACTICES.md` -- build quality rules these skills enforce
```

Three types of cross-references:
1. **Up** - root or parent CLAUDE.md (always include)
2. **Sideways** - adjacent area CC might confuse this with
3. **Down** - the specific file for depth on the most common question

Keep it to 3-5 items. A "See Also" with 10 items is noise. Pick the links that prevent the most common navigation failures.

---

## Maintaining the System

### When to Update

| What changed | Update where |
|-------------|-------------|
| New directory added | Add CLAUDE.md to the new directory; update parent Contents section |
| New key file added | Update parent CLAUDE.md Contents; update root Key Files if it's critical |
| Pattern or rule changed | Update the authoritative file; grep for related references and resolve |
| New cross-domain workflow emerges | Add to root Cross-Domain Workflows section |
| Item count changed | Update the count in the relevant CLAUDE.md |

### Fast vs Slow Content

Some content changes frequently. Mark it:

```
{{_comment.Competitive intelligence: date-stamp assertions, check recency before presenting}}
**As of 2026-Q1:** Competitor X does not support workflow orchestration.
```

Stable architectural patterns don't need dates. Pricing, competitive positioning, and product features do.

For the full contradiction-resolution priority chain, see `.claude/rules/DOC_RULES.md` "Contradiction Handling".

---

## Template: Root CLAUDE.md

```markdown
# {Repo Name}

You are a {specific role identity}. {One-sentence mission}.

{One paragraph: what this repo is and why it exists as a knowledge base}

---

## Philosophy

### {Core principle 1}
{Why it matters, what it changes about how CC works}

---

## Paradigm Shifts

1. **{Mental model shift}** - {Old way} vs {new way}. {Why the shift matters for this context}
2. ...

---

## Operating Pillars

### 1. {Pillar Name}

{What it means in practice}

> When {designing/building/writing}, always ask: **"{Question that embeds the pillar}"**

---

## Hard Rules

- **{Rule}:** {Constraint}
- **{Rule}:** {Constraint}

---

## Session Start

1. `{mandatory command}` - {what it does}
2. {next step}

Full protocol: `{path to full doc}`

---

## Where to Go

| Area | Key Skills/Tools | Status |
|------|-----------------|--------|
| {Domain} | `/{skill}` | Active |

- "{User query}" -> `{exact file path}`
- "{User query}" -> `{skill command}`

---

## Common Cross-Domain Workflows

### {Most Common Task}

1. **{Step}** -> `{file path}` for {what you get}
2. ...

---

## Key Files

| File | Purpose |
|------|---------|
| `{path}` | **{Category}** - {one-line purpose} |

---

## Proactive Documentation

| What changed | Update where |
|-------------|-------------|
| {Event} | `{file path}` |
```

---

## Template: Sub-Directory CLAUDE.md

```markdown
# {Directory Name}

{One sentence: what this directory is and what distinguishes it from adjacent areas}

## Contents

- `{sub-dir}/` -- {purpose, item count if useful}
- `{file.md}` -- {purpose}

## Routing

Come here when:
- "{Specific user query}" -- see `{file}`
- "{Another query}" -- see `{file}`
- You need {thing} for {purpose}

## See Also

- `CLAUDE.md` (root) -- repo overview and routing
- `{parent/CLAUDE.md}` -- {parent hub name}
- `{adjacent/area}` -- {what's there that users might confuse with this}
```

---

## See Also

- `claude-md-design-principles.md` -- The 10 source principles (SoloStack origin). Read first for the *why*
- `CLAUDE.md` (root) -- Reference implementation of the root pattern
- `.claude/rules/DOC_RULES.md` -- Broader documentation standards (folder structure, naming, contradiction handling, maintenance)
- `builds/CLAUDE.md` -- Example of a directory CLAUDE.md with build index and cold-start test
