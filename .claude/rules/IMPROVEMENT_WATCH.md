# Improvement Watch

The kit's compounding-knowledge thesis depends on capturing what was learned in a session before it disappears. This rule tells Claude to watch for kit-worthy insights mid-flow, surface them inline, and let you convert them into a PR with a single word.

Pairs with the `/improve` skill (single-insight, mid-flow, one-shot to PR) and `/capture-learning` (multi-insight end-of-session retro). When in doubt about which to use, see "Routing" at the bottom.

---

## Trigger criteria (high-confidence only)

Surface a suggestion only when ALL of the following are true. Miss-rate is fine; false-positive rate is not.

1. **Concrete artefact backs the claim.** A specific tool result, error message, file change observed in this session, or unambiguous user statement of fact. "I'm pattern-matching on prior knowledge" is NOT evidence; training-data shadow does not count.
2. **The insight is operational.** It does at least ONE of: (a) names a specific failure mode, fix, or constraint, (b) adds a step to an existing workflow, or (c) clarifies a non-obvious-from-name behaviour. Anything fluffier than this fails.
3. **Reusable across builds.** Build-specific facts go in `builds/{build-name}/...`, not here.
4. **A clear primary home exists.** One file in `.claude/rules/`, `build-kit/`, `playbooks/`, `.claude/skills/agent-build-patterns/`, root `CLAUDE.md`, or the body of an existing skill is the obvious primary target. Secondary cross-references in other files are fine. If no clear primary stands out (suggesting a larger structural change like a new folder or doc reorg), defer to `/capture-learning` for a deeper dive.
5. **Not already in the docs.** Run a quick grep across `.claude/rules/`, `build-kit/`, `playbooks/`, and `.claude/skills/agent-build-patterns/` before surfacing. If you find related coverage, do not surface unless your insight is a clear refinement of an existing claim (the Gate 6 refinement path in the `/improve` skill).

**Anti-trigger.** Do NOT surface insights that are Claude's opinion, suggestion, or judgement call. Only observed facts. If the candidate is "I think this could be improved by X" or "it would be nice if Y", it does not pass.

If any trigger is shaky, do NOT surface a suggestion this turn.

---

## Surface protocol

When all five triggers are met, surface ONE line at the end of the assistant message. Exactly this format, no markdown decoration, no emoji:

> Improvement spotted: <one-line description>. Say `go` to capture and PR.

Hard limits:
- Max **one** suggestion per assistant turn.
- Never repeat the same suggestion within a session.
- Suppressed when the user says "keep it simple" or "quick task".
- Suppressed when the user is mid-flow on a focused build and an interruption would derail them.

---

## State write

When you surface a suggestion, ALSO append one line to `.local/session-improvements.local.md` so future sessions can pick up unfinished improvements. Use a single Bash call:

```bash
mkdir -p "$CLAUDE_PROJECT_DIR/.local" && \
printf 'PENDING\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "<one-line description>" \
  >> "$CLAUDE_PROJECT_DIR/.local/session-improvements.local.md"
```

The file is gitignored (the `.local/` pattern in `.gitignore`). One line per spotted suggestion. `/improve` deletes the PENDING line on successful capture.

---

## `go` disambiguation

If the user's NEXT message is one of `go`, `go ahead`, `do it`, `yes go`, OR starts with `/improve`, fire the `/improve` skill against the most recent PENDING line.

Otherwise treat the next message normally. The suggestion is no longer in "pending-go" state but stays as PENDING in the file for later capture.

If the user explicitly invokes `/improve <description>`, use the argument as the candidate even if there's a different PENDING line.

---

## Routing -- Improvement Watch vs other skills

| Situation | Use |
|---|---|
| Single insight, surfaced inline this session, one obvious canonical home | `/improve` |
| Multiple insights from a build, end-of-session retrospective | `/capture-learning` |
| Build-specific learning (binds to one build's `agent.md` or tool docs) | Edit `builds/{build-name}/...` directly, not this loop |

If a spotted improvement actually belongs in build docs, do NOT surface it as an Improvement Watch line. Handle it as a normal build-doc update per `DOC_RULES.md`.
