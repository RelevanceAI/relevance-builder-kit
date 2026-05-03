# Phone Agents

Synchronous voice agents: voice configuration, latency management, prompt engineering for spoken output, compliance, post-call processing.

## Contents

- `phone-agents.md` -- Three-phase architecture, prompt engineering for voice, voice provider selection, runtime config (`first_message_mode`, transcribers, silence timeouts), latency budget, compliance (recording consent, AI disclosure), MCP-write gotchas (the `runtime` field wipe)

## Routing

Come here when:

- Building a phone agent (BDR, intake, triage, verification)
- Tuning voice settings (provider, voice, transcriber)
- Diagnosing latency issues
- Modifying a phone agent via MCP and worrying about the `runtime` field

## See Also

- `build-kit/agents/CLAUDE.md` -- agents hub
- `build-kit/agents/agent-write-operations.md` -- the runtime-field write gotcha specific to phone agents
- `playbooks/use-cases/phone-agent.md` -- use-case playbook (when to build a phone agent)
- `.claude/rules/PLATFORM_MECHANICS.md` § "Phone Agent Runtime Config"
