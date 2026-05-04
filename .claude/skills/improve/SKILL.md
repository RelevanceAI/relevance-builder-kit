---
name: improve
description: Capture a single mid-flow insight as a well-scoped repo PR. Highly opinionated - refuses ~half of invocations on a substance bar (actually happened, non-obvious, clear canonical home, no contradictions, in scope, reusable). Use when the user says `/improve`, says `go` immediately after Claude surfaced an "Improvement spotted" line, or says "capture this and PR", "raise this improvement", "PR this learning", "improve the kit with this". Do NOT use for end-of-session retros (use /capture-learning) or build-specific docs (edit builds/{build-name}/...).
---

## When to Use

Single-insight, mid-flow. The user has either:
- Just said `go` (or `go ahead` / `do it` / `yes go`) immediately after Claude surfaced an "Improvement spotted" line per `IMPROVEMENT_WATCH.md`, OR
- Explicitly invoked `/improve` (with or without an argument), OR
- Said something equivalent to "capture this and PR" / "raise this learning".

Do NOT fire for:
- Multi-insight retros -- route to `/capture-learning`.
- Build-specific learnings -- those live in `builds/{build-name}/...`, not the shared knowledge base.
- Behaviour changes (new skill, new hook, new script) -- out of scope for this skill, those need design judgement.

## The Bar (Substance-Strict)

The bar is the entire point of this skill. PRs that pass the bar should be safe to merge on sight. Expected refusal rate: ~50%. That is the feature.

7 hard gates. Any FAIL aborts the run with a specific reason. No retry loop -- if a gate fails, decline and let the user rephrase or route to a different tool.

| # | Gate | Check |
|---|---|---|
| 1 | Actually happened | Session evidence required (tool result, error message, user statement, observed behaviour). Theoretical-only insights FAIL. |
| 2 | Non-obvious | Grep the target area first. If a current doc already says it, FAIL with the citation. |
| 3 | Clear primary home | One file is the obvious primary target, even if secondary files need cross-references. A fix CAN span multiple files. FAIL only when no clear primary stands out -- that suggests a larger structural change (e.g. a new folder or a doc reorg) which is out of scope here. Route to `/capture-learning` for a deeper dive. |
| 4 | Adds concrete value | PASS if the entry does at least ONE of: (a) names a specific failure mode, fix, or constraint, OR (b) adds a step to an existing workflow, OR (c) clarifies a non-obvious-from-name behaviour. FAIL if it only restates what the file's heading already implies. |
| 5 | No silent contradiction | Distinguish contradiction from refinement. Contradiction = existing claim asserts the opposite of the new insight; FAIL and route to a separate resolution PR. Refinement = existing claim needs an added condition (e.g. "X works" becomes "X works only when Y"); PASS but the edit MUST modify the existing line in place rather than appending a duplicate. Handled in Phase 3. |
| 6 | Reusable across builds | Build-specific FAIL -- route to `builds/{build-name}/...` doc edit. Patterns that only apply to one team's environment, naming conventions, or stack also FAIL -- those stay local. |
| 7 | In scope | Target is a doc file under `.claude/rules/`, `build-kit/`, `playbooks/`, `.claude/skills/agent-build-patterns/`, a `CLAUDE.md` file, OR the body content of an existing skill (NOT skill frontmatter, NOT a new skill, NOT a hook or script). Out-of-scope FAIL with pointer to the right tool. |

## The Process

### Phase 1: Identify Candidate

Pick the candidate based on invocation:

| Invocation | Candidate source |
|---|---|
| `go` / `go ahead` / `do it` / `yes go` (within one turn of an Improvement spotted line) | Most recent PENDING line in `.local/session-improvements.local.md` |
| `/improve <description>` | The argument |
| `/improve` (no arg) | Most recent PENDING line, or ask the user if no PENDING entries |

If no candidate can be identified, ask the user: "What insight do you want to capture?" Do not guess.

### Phase 2: Run the Bar

Output the gate checklist with explicit PASS/FAIL/N/A and a one-line reason for each. Use this format:

```
Bar check for: <candidate description>

1. Actually happened       PASS  -- saw the error in tool run X / user statement Y
2. Non-obvious             PASS  -- grepped <target>; no existing coverage
3. Clear primary home      PASS  -- primary: PLATFORM_MECHANICS.md "Python Runtime Globals"; secondary cross-ref: BUILD_PRACTICES.md
4. Adds concrete value     PASS  -- names specific failure mode (region keyword silently shadows state_mapping)
5. No contradiction        PASS  -- adjacent docs consistent; no refinement needed
6. Reusable across builds  PASS  -- not build-specific or environment-specific
7. In scope                PASS  -- doc edit, primary file plus one cross-ref
```

If ANY gate is FAIL: stop. Output a clean refusal naming which gate(s) failed, why, and where the user should go instead. Example refusals:

- Gate 3 fail: "No clear primary home -- this could plausibly go in `BUILD_PRACTICES.md`, `PLATFORM_MECHANICS.md`, or `build-kit/agents/tools/state-mapping.md` with no obvious primary. That suggests a larger structural change (a doc reorg or new section). Run `/capture-learning` for a deeper dive."
- Gate 4 fail: "Restates what the section heading already implies. Adds nothing concrete -- no specific failure mode, no workflow step, no behaviour clarification. Skip or rephrase to anchor on a specific gotcha."
- Gate 5 contradiction fail: "Contradicts `<file>:<section>` which says `<X>` while the new insight says `<not X>`. Resolve in a separate PR before adding this."
- Gate 6 fail: "Build-specific (mentions `<build-name>` or relies on `<environment-detail>`). Belongs in `builds/<build-name>/agent.md`, not the shared knowledge base."

Note: Gate 5 *refinements* PASS the bar but change Phase 3's edit strategy (in-place modify, not append).

### Phase 3: Draft and Apply

When all gates PASS:

1. **Draft the entry.** Tight, repo-style. Follow the target file's existing format (bullets, sections, prose). Hard rules:
   - No em dashes (use `--`, commas, or full stops).
   - No markdown tables inside system-prompt files (irrelevant here unless target IS a system-prompt.md, in which case Gate 7 likely failed anyway).
   - Match the file's existing voice and section depth.
   - State the rule first, then the why, then the how-to-apply (per `DOC_RULES.md` body-structure conventions).
2. **Edit the primary file (and any secondary cross-references).** Single `Edit` call where possible. Place new content at the logically correct location -- near related items, at the end of a list, or in a new subsection if no obvious neighbour. **For Gate 5 refinements: modify the existing assertion in place rather than appending a duplicate.** If secondary files need a cross-reference, add a one-line pointer (e.g. "See `<primary file>:<section>`") rather than duplicating content.
3. **Branch.** `docs/improve-<short-slug>` (3-5 word slug, kebab-case, derived from the candidate). Branch off current `main`.
4. **Commit.** Message: `docs(improve): <short title>` followed by a one-line body explaining what was captured.
5. **Delete the PENDING line.** Remove the matching entry from `.local/session-improvements.local.md` so it does not get re-surfaced. Use a quoted heredoc with a Python triple-quoted string so the description's content (quotes, backslashes, shell metacharacters) cannot break the call. Substitute `<<<DESC>>>` with the exact one-line description before running:
   ```bash
   python3 - <<'PY'
   import os, pathlib
   desc = """<<<DESC>>>"""
   path = pathlib.Path(os.environ['CLAUDE_PROJECT_DIR']) / '.local/session-improvements.local.md'
   if path.exists() and desc:
       lines = [l for l in path.read_text().splitlines() if not (l.startswith('PENDING') and desc in l)]
       path.write_text('\n'.join(lines) + ('\n' if lines else ''))
   PY
   ```

### Phase 4: Push and Open the PR

After committing on the new branch:

1. **Push:** `git push -u origin <branch-name>`
2. **Open the PR:** `gh pr create --title "docs(improve): <short title>" --body "<one-paragraph what+why>"`
3. **Surface the URL** to the user with a one-line summary:

> Captured: <one-line description>. PR: <url>.

If `gh` is not available, output the manual git push command and the GitHub compare URL pattern (`https://github.com/<owner>/<repo>/compare/main...<branch>`) so the user can open the PR through the browser.

## Refusal Output Format

When the bar fails, the response should be a clean message with no excess apology. Pattern:

```
Cannot capture this improvement.

Failed gates:
- Gate <N>: <reason>

Suggested next step: <pointer to the right tool or a rephrase>.
```

No retry loop. If the user wants to try again, they can rephrase or use a different skill.

## Composition with Other Skills

| Skill | Boundary |
|---|---|
| `/capture-learning` | End-of-session multi-insight retros. `/improve` routes here when Gate 3 fails (no clear canonical home). |

## Hard Constraints

- Never edit a skill's YAML frontmatter (description, name). Skill discoverability is a design decision, not a content edit. If you spot a frontmatter issue, mention it in the PR body for human review and continue with the body-only edit.
- Never create a new skill, hook, or script via this skill -- those need design judgement that lives outside this loop.
- Never add to `builds/{build-name}/...` from this skill -- that is per-build doc territory.
- Never bypass the bar to "just get the insight in" -- if it does not pass, decline. Volume is not the goal; trust per PR is.

## Tags

#meta #knowledge-management #self-improvement #pr
