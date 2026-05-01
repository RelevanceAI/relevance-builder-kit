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

## Worked example

See `builds/example/` for a populated reference build (agent.md, system-prompt.md, one tool doc). Copy its shape when starting your first build.
