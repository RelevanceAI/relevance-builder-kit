---
name: capture-learning
description: Review a build or debug session, extract reusable learnings, and update the knowledge base or share with the wider community via PR. Use this skill at end of session, when the user says "what did I learn", "save this pattern", "document this discovery", "let's do a retro", "capture this before I forget", "update the knowledge base", or "share this back". Also use when someone wants to graduate a discovery into BUILD_PRACTICES.md, PLATFORM_MECHANICS.md, or agent-build-patterns.
---

## When to Use

Use this skill at the end of a build / debug session to:

- Extract reusable patterns from what worked
- Document anti-patterns from what failed
- Update `.claude/rules/` for future sessions
- Share validated learnings with anyone using the kit via a PR
- Create a knowledge trail that compounds over time

## Step 0: Choose Output Target

Before starting, decide where the learnings should go:

| Target | When to use | Process |
|--------|-------------|---------|
| **Local kit only** | Default. Learnings specific to your team's environment, naming conventions, or one build. Still being validated. | Phases 1-4 below, edits stay on a local-only branch |
| **Upstream PR** | Learnings validated across builds that would benefit any builder using the kit | Phases 1-2, then Phase 3b |

If unsure, start local. You can always promote to upstream later.

## The Process

### Phase 1: Session Review (Gather Facts)

Ask these questions about the session:

1. **What errors did we encounter?**
   - Error messages (exact text)
   - Where they occurred (which tool / step / agent)
   - What we initially thought caused them

2. **What actually fixed them?**
   - Root cause (often different from symptom location)
   - The actual solution applied
   - Why it worked

3. **What patterns emerged?**
   - Things that worked well (do more of)
   - Things that failed (avoid in future)
   - Surprising discoveries

4. **What's now validated?**
   - Hypotheses confirmed
   - Questions resolved
   - Patterns proven in practice

### Phase 2: Extract Learnings (Derive Principles)

For each significant discovery, derive the generalizable principle:

| Level | Question | Example |
|-------|----------|---------|
| **What** | What happened? | "UUID normalization step caused KeyError" |
| **Why** | Why did it happen? | "Python step returned wrong type" |
| **Principle** | What's the general rule? | "Test simple path before adding defensive code" |
| **Application** | When does this apply? | "Any time you're adding validation steps" |

**Learning Entry Template:**

```markdown
### [DATE] -- [Brief Title]

**Context:** What were you trying to do?

**Discovery:** What did you learn?

**Implication:** How does this change how we build agents?

**Tags:** #relevant #tags
```

### Phase 3: Update Knowledge Base

Graduate learnings directly to their canonical home. Don't accumulate in scratch files.

| Type of learning | Canonical file |
|-----------------|----------------|
| Platform mechanic or API behaviour | `.claude/rules/PLATFORM_MECHANICS.md` |
| Build preference or tool pattern | `.claude/rules/BUILD_PRACTICES.md` |
| Documentation or repo convention | `.claude/rules/DOC_RULES.md` |
| Agent design pattern | `.claude/skills/agent-build-patterns/` |
| Integration workaround | `build-kit/integrations/` |
| Reusable architecture pattern | `build-kit/patterns/` |
| Use-case playbook | `playbooks/use-cases/` |
| Tool transformation reference | `build-kit/tools/` |

Also update:

- Build-specific docs in `builds/{build-name}/` if the learning is build-specific (these stay local, not pushed upstream)

### Phase 3b: Upstream Learnings (PR back to the kit)

Use this when learnings are validated and would benefit anyone using the kit, not just your team.

1. **Present learnings for review** -- show extracted learnings grouped by target file:

   ```
   ## Proposed Learnings

   ### BUILD_PRACTICES.md
   - **New / Update**: [learning text]

   ### PLATFORM_MECHANICS.md
   - **New / Update**: [learning text]

   ### build-kit/integrations/<platform>.md
   - **New / Update**: [learning text]
   ```

   Use the graduation table from Phase 3 to pick the right file for each learning. Ask: "These are the learnings I extracted. Want me to add all of them, remove any, or adjust the wording?"

2. **Wait for user confirmation** before making any changes.

3. **Update the target files:**
   - Insert each learning into the correct section of its target file
   - If updating an existing bullet, replace it cleanly (in-place modify, not append, when the existing bullet is being refined)
   - If adding new bullets, place logically near related items
   - Do NOT reorganise or reformat unrelated content
   - **Scrub anything build-specific or environment-specific.** Generic patterns go upstream; specifics stay in `builds/`.

4. **Branch and commit:**
   - Create branch: `learnings/<short-descriptor>` (e.g. `learnings/oauth-selector-pattern`)
   - Commit only the learning changes with a clear message: `docs(learnings): <short title>`

5. **Push and open the PR:**
   - `git push -u origin <branch-name>`
   - `gh pr create --title "docs(learnings): <short title>" --body "<one-paragraph summary of what was captured and why>"`
   - If `gh` is not available, output the manual push command and the GitHub compare URL pattern so the user can open the PR through the browser.

### Phase 4: Verify Knowledge Trail

After updates, verify:

1. **Findable:** Could a future builder find this learning when facing a similar problem?
2. **Actionable:** Does it tell you what to DO, not just what happened?
3. **Generalisable:** Is it specific enough to be useful but general enough to apply elsewhere?
4. **Scrubbed:** No build-specific names, internal stack details, or one-environment quirks leaking into upstream content.

## Output Format

When invoked, produce:

```markdown
## Session Learnings Summary

### Errors Encountered & Fixes
| Error | Root Cause | Fix | Learning |
|-------|------------|-----|----------|
| ... | ... | ... | ... |

### Key Principles Derived
1. **[Principle Name]:** [One-line description]
   - When to apply: [Context]
   - Anti-pattern to avoid: [What not to do]

### Knowledge Base Updates Made
- [ ] PLATFORM_MECHANICS.md: [What was updated]
- [ ] BUILD_PRACTICES.md: [What was updated]
- [ ] agent-build-patterns/: [What was updated]
- [ ] Build docs (`builds/<name>/`): [What was updated, stays local]

### Resolved Questions
| Question | Answer |
|----------|--------|
| ... | ... |
```

## Composition with Other Skills

| Skill | Boundary |
|---|---|
| `/improve` | Single-insight, mid-flow, one-shot to PR. Substance-strict bar. Use mid-session, not end-of-session. |
| `IMPROVEMENT_WATCH.md` (rule) | Surfaces inline "Improvement spotted" lines during a session that route to `/improve`. `/capture-learning` is the multi-insight end-of-session counterpart. |

## Tags

#meta #knowledge-management #learning #documentation
