# Builds Index (Local)

> Personal index of agent builds. **This file is gitignored** -- it lives at `.local/builds.local.md` and never enters git history. Use it to track what you've built and what each build proved or learned.
>
> Bootstrap: `cp build-kit/templates/builds-index.local.template.md .local/builds.local.md`

## How to use

Add a row each time you complete a build. Include:

- **Build**: name of the build (matches `builds/{build-name}/`)
- **Agent / Workforce**: agent or workforce name + ID
- **Local docs path**: where the docs live under `builds/{build-name}/`
- **Patterns demonstrated**: 2-5 patterns this build uses or proves

If a build introduces a new reusable pattern, capture that pattern in `.claude/skills/agent-build-patterns/` so it can be applied to future builds.

## Builds

| Build | Agent / Workforce | Agent ID | Local docs path | Patterns demonstrated |
|-------|-------------------|----------|-----------------|-----------------------|
| _example_ | _Agent or Workforce Name_ | `xxxxxxxx-xxxx-...` | `builds/example-build/` | _e.g. Unit of Action, workforce pipeline, knowledge tables as glue_ |

## Decommissioned / archived

Move rows here when a build is wound down. Keep for reference; helps recall what was done historically.

| Build | Agent / Workforce | Decommissioned date | Reason | Notes |
|-------|-------------------|---------------------|--------|-------|

## Notes

- **No commits.** This file must NEVER be committed. Keep it under `.local/` (gitignored).
- **Cross-reference.** When recording a build, link to the local doc folder (`builds/{build-name}/agent.md`) so you can resume work from this index after a `/clear`.
