# Builds

Your own agent and workforce builds live here, one folder per build.

## Convention

```
builds/
  {build-name}/
    agent.md            # Agent config, IDs, tools, workflow, design decisions
    system-prompt.md    # The deployable system prompt (deploys verbatim)
    tools/              # Tool docs (.md) and configs (.json)
    workforce/          # Workforce docs if applicable
```

`agent.md` is your build journal. It holds the agent ID, model, temperature, autonomy, full tool table with action IDs, knowledge tables, design decisions, and any workflow notes. Keep it current as the build evolves.

`system-prompt.md` is the actual text deployed to the agent's `system_prompt` field. Different rules apply to it than to `agent.md`. See `.claude/rules/DOC_RULES.md` for the formatting rules and lint hooks.

## Worked examples

- `builds/example/` -- single agent: company LinkedIn lookup. agent.md + system-prompt.md + one tool doc. Copy this shape for your first solo build.
- `builds/workforce-example/` -- multi-agent: lead research workforce with an orchestrator and two parallel research sub-agents. workforce.md + per-agent docs under `workforce-agents/`. Copy this shape for fan-out builds.

Both use placeholder IDs (`<agent-id-1>`, `<workforce-id>`, etc.) since they document structure, not deployments. Replace the placeholders the first time you adapt either as a starting point.
