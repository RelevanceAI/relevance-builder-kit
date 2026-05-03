# Parallel Tool Calls (Early Access)

**Status:** Early access, requires feature flag. Not yet generally available. Test thoroughly before using in production builds.

The headline rules for orchestrators sit in `.claude/rules/PLATFORM_MECHANICS.md` § "Workforce Architecture"; the full setup, threading-compatibility matrix, and behaviour notes live here.

---

## What it does

Enables agents and tools to execute concurrently instead of sequentially. Works for tool calls, sub-agent calls, or both simultaneously. The system provides 10 parallel execution slots -- extra calls queue until a slot frees.

---

## Setup

1. Confirm the early-access feature flags are enabled for your user (one for the builder surface, one for in-chat). Contact your Relevance AI account team if you need access.
2. On the agent: Advanced Settings > Language Model > toggle "Parallel Tool Calls" on
3. Update the agent prompt with instructions on what to call in parallel
4. Configure edge settings for sub-agents that should run in parallel:
   - Connection type: "AI connection"
   - Message template: "Full agent autonomy"
   - Approval mode: "Auto run"
   - Max auto-runs: "No limit"

---

## Behaviour

- Parent receives responses in the same format as non-parallel execution -- only execution handling changes
- Frontend flag controls behavior even when backend flag is on (safety mechanism)
- Concurrency settings still apply independently (no known conflicts)
- 10 parallel slots max -- any call beyond 10 queues until a slot opens

---

## Use cases

One-to-many workflows where sub-tasks are independent: account research across N accounts, lead prioritization, campaign generation for multiple personas. Eliminates the need for the knowledge table intermediary pattern (agent -> KT -> agent) in these scenarios.

---

## Limitations (early access)

- Requires per-user feature flag enablement; contact your Relevance AI account team for access
- Output token accumulation risk: if all parallel results return simultaneously, the parent agent's context may grow large. Monitor for output token limit issues with high-N parallel dispatches
- Not yet validated at scale in production builds

---

## Hard rule: parallel + threading compatibility

| Parallel Tool Calls | Edge threading | Behaviour |
|---|---|---|
| Off | `always-same` | Sequential, shared conversation |
| Off | `always-create-new` | Sequential, fresh instance per call |
| **On** | **`always-same`** | **RACE ERROR -- "can't call the same instance twice at the same time"** |
| On | `always-create-new` | Parallel, fresh instance per call |

If Parallel Tool Calls is enabled on an orchestrator, **every parallel-dispatched edge must be `always-create-new`**. With `always-same` threading, the same sub-agent instance is reused across calls -- parallel invocation attempts to call that single instance concurrently and errors out.

Rule of thumb from the platform team: *"For subagents, parallel invocation only makes sense when create-a-new-task is used."* A runtime auto-fallback to sequential when this config is detected is planned.

---

## Response shape

The parent receives all parallel sub-agent responses as a **single payload**, in the same format as non-parallel execution -- only the execution path differs. No need to handle a different output schema.

---

## Setting sequential back

There is no dedicated "sequential mode" switch. Sequential is simply "Parallel Tool Calls off" on the orchestrator. For parallel-default with occasional sequencing, express dependencies in the prompt (e.g. `<dependent_agent>` tags, as the chat orchestrator does).

---

## Sources

This pattern reference reflects platform-team guidance on the Parallel Tool Calls feature and its compatibility with sub-agent threading.
