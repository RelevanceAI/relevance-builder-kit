# Multi-Agent Orchestration Patterns

Patterns for designing multi-agent orchestrators that produce executive-grade intelligence from multiple data sources. Covers the 7+1 generative principles, two-phase cognitive model, capability contracts, governance, testing framework, and failure catalog.

## The Core Insight

A multi-agent intelligence system is not a search engine with extra steps. It is a research analyst with specialized assistants.

| Component | Knows... | Does NOT know... |
|-----------|----------|-------------------|
| Orchestrator | WHEN to use each source, how to combine results, what makes a good answer | HOW any source works internally, API patterns, tool mechanics |
| Sub-agent | HOW to query its domain, what data is available, what the gotchas are | WHEN to query itself, what other sources say, how to synthesize cross-source |

If your orchestrator contains domain logic, it is too thick. If your sub-agent synthesizes across sources, it is overstepping.

## Mental Model: Graph, Not Tree

A workforce is a **graph with arbitrary entry points**, not a parent-child tree. The edge `threading_behavior` expresses the *relationship* between two agents, not a hierarchy:

- **`always-same`** ("continue same task" in UI) = peer-to-peer communication, even when the receiver is functionally "a child". Used for follow-up, multi-round interactions.
- **`always-create-new`** ("start new task" in UI) = one-off delegation. Each invocation instantiates a fresh sub-agent. This is the Claude-Code-style subagent model.

Because threading is an edge property (not an agent property), the same sub-agent can be invoked under different configs by different parents. **Sub-agent prompts must therefore be context-agnostic** -- they cannot assume what context they inherit.

This framing has two immediate consequences:

1. **Design sub-agents as callable services, not child processes.** A sub-agent prompt that says "continuing from the parent's work..." is fragile -- it only works when the invoking edge is `always-same`. Write prompts that are complete on their own and treat inherited context as a bonus, not a dependency.
2. **Enforce one edge type per receiving agent.** The builder lets you connect two parents to the same child with different edge types (one `always-same`, one `always-create-new`), but this creates incoherent behaviour the sub-agent cannot reason about. Pick one per receiving agent.

**Source:** Relevance AI platform team guidance.

## The Two-Phase Cognitive Model

An orchestrator must operate in two structurally separated modes:

| Phase | Mindset | Optimizes For | Risk If Skipped |
|-------|---------|---------------|-----------------|
| 1: Gathering | Curious, expansive, follow every lead | Complete picture across all sources | Thin data, obvious gaps, premature conclusions |
| 2: Synthesis | Ruthless, reductive, opinionated | Actionable insight the reader can use immediately | Verbose data dump, no headline, no recommended action |

These mindsets are antagonistic. An agent that synthesizes while gathering truncates exploration prematurely. An agent that gathers while synthesizing produces walls of facts without interpretation.

**The fix is structural:** the orchestrator's prompt should have explicit Phase 1 / Phase 2 section headers with different instructions in each. The transition is a specific gate: the agent moves to Phase 2 only when it is confident the picture is complete.

**How to tell if your phases are actually separated:**
- Phase 1 evidence: the orchestrator queries the same sub-agent multiple times, with each round asking different questions based on what was learned
- Phase 2 evidence: the final output is significantly shorter than the raw data gathered, with an opinionated headline and recommended action

If your orchestrator queries each source once and immediately produces output, you have single-pass syndrome.

## The 7+1 Generative Principles

These are generative principles, not rules. A rule says "do X." A generative principle says "when facing any situation, the answer should optimize for Y."

### P1: Separate Gathering from Synthesis

Phase 1 (gathering) and Phase 2 (synthesis) are distinct cognitive modes that must never overlap. Gathering optimizes for completeness. Synthesis optimizes for compression.

**Structural enforcement:** Separate numbered sections in the prompt for each phase. Explicit transition language ("Once you have a complete picture, synthesize...").

### P2: User Intent Is Implicit

Users ask literal questions but need something deeper. "What's going on with {customer}?" means "help me feel prepared for my next interaction with {customer}."

**Structural enforcement:** A concrete mental model baked into the orchestrator's identity. Example: the "CEO Elevator Test" -- imagine the CEO stops you in an elevator and asks about this customer. You have 30 seconds. What do you say?

### P3: The "So What?" Rule

Every fact in the output must connect to a risk, opportunity, or recommended action. If a fact does not pass the "so what?" test, it should not be in the output.

**Structural enforcement:** BAD/GOOD example pairs in the prompt:

- Bad: "ARR is $65k, renewal {date}" / Good: "Renewal at risk -- champion left, no replacement identified"
- Bad: "3 deals in pipeline" / Good: "$65k expansion stalled -- {blocker} needs exec intervention"
- Bad: "The {role} is supportive" / Good: "{Role} is a champion -- use them to get skeptics in the room"

### P4: Iterate Until Confident

The stopping condition for information gathering is confidence in picture completeness, not exhaustion of sources.

**Structural enforcement:** A PAUSE AND THINK meta-cognitive checkpoint between query rounds:
- "What would a {decision-maker} want to know that I don't have yet?"
- "Are there related {entities} I should check?"
- "What's missing from the picture?"

After adding PAUSE AND THINK, production queries consistently showed 2+ rounds with the primary source. One complex query triggered 9 tool calls.

### P5: Activate Agency

The quality of sub-agent output is determined by the quality of delegation. Prescriptive delegation produces narrow output. Agency-activating delegation produces rich, proactive output.

**Structural enforcement:** Every delegation ends with: "Let me know what else you think may be useful."

Evidence: with the agency-activating phrase, sub-agents spontaneously added "Risks and Opportunities" and "Noteworthy Suggestions" sections never explicitly requested. These contained the highest-value insights.

### P6: Thin Orchestrator, Fat Capabilities

The orchestrator knows WHEN to use capabilities. Capabilities know HOW to execute in their domain. Domain expertise lives entirely in the capabilities.

**Structural enforcement:** The orchestrator's prompt contains ZERO domain-specific API logic, query patterns, or tool mechanics. Adding a new data source means connecting a new sub-agent, not rewriting the orchestrator.

### P7: Graceful Degradation with Honesty

When a data source fails, the system proceeds with available data AND explicitly notes the gap. Silent omission is worse than crashing.

**Structural enforcement:** The response footer REQUIRES listing "Sources Used." If a source was not consulted, its absence is visible.

Multi-level degradation design:
1. Source completely unavailable: proceed with remaining sources, note gap
2. Source partially fails: use what is available, note limitation
3. Source returns empty: report "no results found," do not silently skip
4. All supplementary sources fail: produce valid output from primary source alone

### P8 (Meta): Structure Forces Behavior

Principles stated in documentation but not encoded in system architecture are aspirational, not operational. For every principle, ask: "What structural mechanism enforces this?"

| Enforcement Type | Reliability |
|-----------------|-------------|
| Documentation only | Low |
| Prompt instruction | Medium |
| Prompt with examples | High |
| Platform constraint (e.g., `always-ask` edge config) | Highest |

## Capability Contracts

### Single-Parameter Interface

Every sub-agent accepts exactly one parameter: a natural language `message` string. The orchestrator describes WHAT it needs. The sub-agent decides HOW to get it.

**Why:** Structured params (`entity_id`, `fields[]`) create tight coupling. The orchestrator must know the sub-agent's internal schema. Single `message` enables loose coupling -- sub-agents can be replaced without changing the orchestrator.

**Edge config requirement:** Every workforce edge must have `params_schema` with a required `message` property. Missing this is the most common first-call failure.

### Mode-Aware Output

Sub-agents that serve both an orchestrator AND direct users need two output modes:

**Sub-agent mode (feeding an orchestrator):** Return raw structured findings -- data retrieved, key people, timeline, issues, positive signals, notable quotes, anomalies, data gaps, confidence level. The orchestrator needs decomposable data it can cross-reference.

**Standalone mode (facing users directly):** Return a synthesized narrative -- opinionated headline, prioritized bullets, risk/opportunity flags, recommended action.

If a sub-agent pre-synthesizes when feeding an orchestrator, the orchestrator cannot cross-reference facts, weight conclusions against conflicting evidence, or identify contradictions between sources.

### Threading Decision Matrix

| Sub-Agent Type | Threading | Reasoning |
|----------------|-----------|-----------|
| Data retrieval (read-only, multi-round) | `always-same` | Follow-up queries reference previous results |
| Document retrieval (read-only) | `always-same` | Benefits from context on follow-up |
| Communication search (iterative) | `always-same` | Needs memory of what was already searched |
| Write-back (creates records, sends messages) | `always-create-new` | Stateless. Context accumulation is a liability for writes. |

**Context window trade-off:** `always-same` threading accumulates conversation history. For typical queries (single entity, 2-3 rounds), this stays within limits. For complex queries touching 10+ entities, accumulated context can degrade silently.

**Response visibility trade-off:** with `always-create-new`, the orchestrator sees **only the sub-agent's final response text** -- no tool outputs, no intermediate reasoning, no artifacts. If the orchestrator needs URLs, file IDs, or structured values from the sub-agent's tool runs, the sub-agent's prompt must mandate embedding them in the final response (e.g. *"Your response MUST end with: **DOCX URL:** [exact URL from save tool]"*). With `always-same`, the orchestrator sees the full turn-by-turn history.

### Parallel Dispatch and Threading Compatibility

**Hard rule:** if Parallel Tool Calls is enabled on the orchestrator, every parallel-dispatched edge **must** be `always-create-new`. Pairing parallel dispatch with `always-same` threading causes a runtime race (the same sub-agent instance cannot be called twice simultaneously).

| Parallel Tool Calls | Edge threading | Behaviour |
|---|---|---|
| Off | `always-same` | Sequential, shared conversation |
| Off | `always-create-new` | Sequential, fresh instance per call |
| **On** | **`always-same`** | **Runtime race error** |
| On | `always-create-new` | Parallel, fresh instance per call |

Parent receives all parallel sub-agent responses as a **single payload** in the same format as non-parallel execution -- only the execution path differs. 10 parallel slots shared across all tool calls and sub-agent calls (5 Google searches + 5 sub-agents fills it).

Full mechanics and setup: `.claude/rules/PLATFORM_MECHANICS.md` "Parallel Tool Calls".

### Confidence Framework

Sub-agents must communicate reliability, not just findings. The orchestrator needs to know how much weight to give each source.

| Level | Criteria | Orchestrator Should... |
|-------|----------|----------------------|
| High | Multiple data points agree across multiple methods | Trust as primary signal |
| Medium-High | Comprehensive data from one method OR cross-validated from two | Strong supplementary signal |
| Medium | Moderate data from one method | Directional insight only; seek confirmation |
| Medium-Low | Limited results, single method | Flag as tentative |
| Low | Minimal data, expected sources missing | Report the gap; do not draw conclusions |

## Scale and Reliability Guardrails

Production orchestrators have hard numerical ceilings. Above these, quality degrades silently or runtimes fail.

| Dimension | Ceiling | Source / Rationale |
|---|---|---|
| Sub-agents per orchestrator (design clarity) | 5-7 | Instructions bloat and routing quality drops past this |
| Sequential sub-agent dispatch (reliability) | 5-10 calls | Reliable up to ~10 in a single run; degrades past that |
| Parallel execution slots (concurrency) | 10 shared | Shared across tools + sub-agents |
| Workforce task wall-clock | ~15 minutes | Observed runtime cap |
| Tool calls per agent | <52 | Tool-list overhead grows with every additional tool |
| Fan-out items before decoupling | >20 | Persist to knowledge table, decouple via scheduled triggers |

**Practical implication:** if your orchestrator's happy path involves more than 10 sequential sub-agent invocations or more than 20 items to process, do not rely on in-memory orchestration. Options (in order of complexity):

1. **Parallel Tool Calls** -- collapses 10 sequential calls into parallel ones (requires `always-create-new` on every dispatched edge; see Parallel Dispatch and Threading Compatibility above)
2. **Tool-as-trigger** -- upstream agent writes rows to a knowledge table, each row triggers a downstream agent task asynchronously
3. **Split the workforce** -- research workforce completes and returns, outreach workforce picks up via webhook or scheduled trigger

## Dispatch Pattern Decision

Choose based on volume, per-item complexity, and interdependence:

| Scenario | Pattern | Rationale |
|---|---|---|
| 2-15 items, complex per-item analysis, items interact | **Batch** -- one sub-agent receives full list, iterates internally | Sub-agent reasons holistically; no orchestrator context accumulation |
| 15+ items OR simple per-item action, items independent | **Fan-out** -- orchestrator dispatches one-at-a-time | Each item gets fresh context; avoids orchestrator context bloat |
| Independent parallel work (account research, lead prio) | **Parallel Tool Calls** with `always-create-new` | Collapses wall-clock; requires compatible threading |
| >20 items or anticipated >15-min wall-clock | **Decouple via knowledge table + trigger** | Keeps each task within platform ceilings |

**Fan-out anti-pattern:** never emit a single orchestrator response that enumerates the plan for all N items ("*I'll now research all 7 contacts. Here's the plan: Contact 1: ... Contact 2: ...*"). Verbose sub-agent replies (often 1000+ words each) accumulate in orchestrator context, and the planning turn itself can exceed the output token limit mid-pipeline. Dispatch one-at-a-time.

**Batch anti-pattern:** sending 40+ items to a single batch agent. Context fills up, per-item quality degrades on later items, tool output size limits may truncate.

For full batch-vs-fan-out rationale and examples: `.claude/rules/BUILD_PRACTICES.md` "Workforce / Orchestrator Patterns".

## Governance and Permissions

### Differentiated Trust Pattern

| Operation Type | Permission | Threading |
|----------------|------------|-----------|
| Read from structured data | `never-ask` (auto-invoke) | `always-same` |
| Read from documents | `never-ask` | `always-same` |
| Read from communications | `never-ask` | `always-same` |
| Write to any external system | `always-ask` (require human approval) | `always-create-new` |

**Two layers of write protection:**
1. Prompt-level: the orchestrator's prompt instructs it to wait for user confirmation
2. Platform-level: the edge config uses `always-ask`, which gates on user approval even if the prompt is ignored

**Why both:** Prompts can be circumvented by capable models. Platform constraints cannot. Defense in depth.

### Approval in Workforces: Known Gotchas

Sub-agent approval is the single largest source of production bugs in workforces.

**Current state:**

- Three edge-level approval modes: **Auto run** (`never-ask`), **Approval required** (`always-ask`), **Let agent decide** (prompt-driven)
- Sub-agent approvals propagate up to the top-level workforce task view automatically (`SubagentApprovalPropagation` flag was removed; this is now default)
- Nested sub-agent approvals also propagate via `agent_chain` tracking
- Approvals appear in a batched UI at the bottom of the task view

**Persistent production issue:** the "subagents in workforce cannot wait for approval" warning still surfaces on some AI Edge connections. Workarounds in descending reliability order:

1. **Webhook-separate the agents.** Most reliable, loses single-task-view UX. Each workforce runs independently and posts to the next via webhook.
2. **Put the approval-requiring tool on the parent agent.** Loses modularity but keeps approval in one task. Viable when the approval is infrequent.
3. **Tool-as-trigger.** Works when the upstream step is 100% deterministic and needs no error handling -- the upstream tool writes rows, downstream agent picks them up one-by-one via trigger.
4. **Built-in escalate tool.** Last resort. The parent agent does not wait for the escalation to resolve -- it reports back "sub-agent has escalated" and continues. Do not use when the orchestrator needs the approved result for its next step.

**Required in every production handoff:** test the approval path end-to-end. Do not assume approval propagation works just because the edge is configured. See `.claude/rules/PLATFORM_MECHANICS.md` "Sub-agent approval propagation" for platform-mechanic detail.

### HTTP-Level Permission Model

For CRM agents specifically, governance maps cleanly to HTTP methods:

| Action Type | Confirmation Required |
|-------------|----------------------|
| GET requests | No |
| POST to search/batch-read endpoints | No (read-only despite POST) |
| POST to create a record | Yes |
| PATCH to update a record | Yes |
| DELETE to remove a record | Yes |
| Bulk modify > 100 records | Double-check |

Categorizing by HTTP method is more robust than maintaining a whitelist of "safe" endpoints. New endpoints automatically inherit the right governance.

## Source Hierarchy Design

Any multi-source intelligence system needs a clear source hierarchy:

| Priority | Source Type | Role | When to Query |
|----------|-----------|------|---------------|
| Primary | Structured data (CRM, database) | Identity, commercial truth, factual foundation | Always first, iterate until comprehensive |
| Supplementary | Curated documents (plans, wikis) | Strategic context, qualitative depth | After primary foundation is established |
| Real-time | Communications (Slack, email) | Live signals, sentiment | After structured sources establish the reference frame |
| Write-back | Any system that modifies state | Persisting findings | Only on explicit user consent |

**Why this order matters -- the "loud customer" bias:** If you query an unstructured source before establishing the reference frame from a structured source, results are weighted by message volume, not business importance. High-ARR quiet customers get missed; noisy low-value accounts dominate.

## Orchestrator Prompt Template

Based on the reinforcement chain pattern, an orchestrator prompt should contain:

1. **IDENTITY** -- Persona + dual mandate via concrete metaphor
2. **MISSION** -- One-line two-phase summary
3. **SOURCE HIERARCHY** -- Ranked sources with rationale
4. **GATHERING: PRIMARY SOURCE** -- Start broad, PAUSE AND THINK, query specifically based on gaps
5. **GATHERING: SUPPLEMENTARY SOURCES** -- Scoped by what primary source revealed
6. **SYNTHESIS** -- Opinionated headline, 3-5 prioritized bullets, risk/opportunity flags, recommended action
7. **TONE CALIBRATION** -- BAD/GOOD pairs
8. **SPECIAL CASES** -- Modified workflows for specific query types
9. **ERROR HANDLING** -- Never silently omit, note gaps explicitly
10. **RESPONSE FOOTER** -- Sources consulted, sources missing, suggested next steps
11. **REINFORCEMENT** -- Bookend restating persona and quality bar

**Prompt reinforcement chains:** The prompt is not a flat list. It contains four chains where multiple sections interact: Persona Bookend (identity + reinforcement), Gathering Workflow (hierarchy + primary + supplementary), Output Quality (synthesis structure + tone calibration), Completeness Assurance (error handling + response footer).

## Model Selection Strategy

Concentrate reasoning cost at the orchestration layer. Sub-agents execute domain-specific tasks where quality is bounded by tools and data, not model reasoning.

| Layer | Model Choice | Temperature |
|-------|-------------|-------------|
| Orchestrator | Premium reasoning model | 0 (deterministic) |
| Sub-agents | Fast, cost-efficient model | Varies by domain |

## Failure Catalog

### Infrastructure Failures

**Missing params_schema on edge:** First call fails with validation error. The edge looks configured but is missing the schema that tells the platform how to format the message. Add `params_schema` with required `message` to every tool-call edge.

**`additionalProperties: false` on a tool-call edge:** 100% sub-agent-call failure with `"Studio Params Validation Error: must NOT have additional properties {\"additionalProperty\":\"_subagent_params\"}"`. The platform auto-injects a `_subagent_params` field that a strict schema rejects. Fix: set `additionalProperties: true` (or omit it -- true is default) and rely on the edge's `prompt_for_when_to_use` + the orchestrator's prompt rules to constrain the LLM's payload. Never use `additionalProperties: false` as a defence-in-depth on sub-agent edges. See `.claude/rules/PLATFORM_MECHANICS.md` "Workforce Architecture > Never use `additionalProperties: false` on a tool-call edge's `params_schema`".

**`relevance_update_workforce` merges edge fields, does not replace:** If you try to remove a field by omitting it from an update, the old value persists. To flip a previously-set field off, explicitly set it to the new value (e.g. `additionalProperties: true`, not omission). Applies to any field under `action_config.params_schema`.

**Data format mismatch between APIs:** Search API returns IDs in one format, retrieval API expects another. Add a normalization step in the sub-agent's tool pipeline.

**Token scope mismatch:** Some API calls work but others fail with permission errors. Different endpoints may require different token scopes. Document required token type and scopes per sub-agent.

### Capability Failures

**Pagination truncation:** Results appear complete but are truncated at default page size. Sub-agents must own pagination internally -- the orchestrator should not know about it (P6).

**Pre-synthesized sub-agent output:** Orchestrator synthesis sounds like it is quoting one sub-agent. The sub-agent returned a narrative instead of structured data. Fix with mode-aware output.

**Context window pressure (silent degradation):** Results become subtly incomplete in long conversations. No error is thrown. The most dangerous failure class because there is no detection mechanism. Mitigate by accepting the trade-off for typical cases and considering context summarization for long conversations.

### Orchestration Failures

**Single-pass syndrome:** Thin, surface-level synthesis. The orchestrator queries each source once and moves to synthesis. Fix with PAUSE AND THINK checkpoints + explicit phase separation.

**Data dump output:** Wall of facts without interpretation. Fix with identity framing (analyst, not search engine) + BAD/GOOD example pairs.

**Constrained delegation:** Sub-agents return only what was literally asked. Fix by appending "Let me know what else you think may be useful" to every delegation.

**Ungrounded supplementary search:** Portfolio queries return irrelevant results weighted by volume. Fix by querying structured source FIRST to establish entity universe.

**Cross-source attribution failure:** Synthesis includes facts without attribution. Fix with required response footer listing sources.

**Planning all items in one response before dispatching:** The orchestrator emits "I'll now process all 7 items. Here's the plan for each: Item 1: ... Item 2: ..." before making any sub-agent call. This single response can exceed the output token limit and pollutes orchestrator context with the full plan. Fix: instruct the orchestrator to dispatch one-at-a-time, or enable Parallel Tool Calls with `always-create-new` edges.

**Parallel + always-same race:** Parallel Tool Calls enabled on the orchestrator, but one or more dispatched edges use `always-same` threading. Runtime errors with "can't call the same instance twice at the same time." Fix: change the edge to `always-create-new`, or disable Parallel Tool Calls on the orchestrator.

**Orchestrator summarizing sub-agent outputs:** Natural LLM behaviour is to compress verbose sub-agent replies before the next turn. This destroys the evidence needed for synthesis. Fix: explicit "preserve, don't summarize" instruction in the orchestrator prompt + structured (not narrative) sub-agent output so the orchestrator has discrete fields to reference.

**Incoherent graph -- mixed edge types into the same sub-agent:** Two parents connect to the same sub-agent with different threading configs (one `always-same`, one `always-create-new`). The sub-agent prompt cannot reason about what context it inherits. Fix: one edge type per receiving sub-agent across all invocations.

**Model flakiness at the sub-agent layer:** Some cheaper models (observed: gpt-5-mini) produce inconsistent sub-agent invocation behaviour in workforces. If sub-agents hang or fail to return to the parent reliably, try a more capable model before debugging the graph.

### Silent Failures (Most Dangerous)

| Failure | Why Dangerous |
|---------|--------------|
| Context window pressure | Results look normal but are subtly incomplete |
| Single-pass syndrome | Output looks plausible even when thin |
| Attribution failure | Synthesis appears coherent even when facts are misattributed |

Design your system to fail loudly: require source attribution, add iteration depth requirements, consider context health checks.

## Quality Gates

Run all five before deploying:

**Gate 1: Multi-Source Routing** -- Primary source queried first. At least 2 remaining sources consulted. Correct order per hierarchy.

**Gate 2: Multi-Round Iteration** -- 2+ rounds with primary source. Follow-up queries differ from initial (evidence of gap identification).

**Gate 3: Output Quality (CEO Elevator Test)** -- Opinionated headline. 3-5 prioritized bullets. Risk/opportunity flags. Specific recommended action.

**Gate 4: Graceful Degradation** -- Source failure noted explicitly. Synthesis still actionable. Response footer lists what failed.

**Gate 5: Agency Activation** -- At least one sub-agent returns supplementary insights not explicitly requested.

**Gate 6: Platform Compliance** -- Every `tool-call` edge has a non-empty `params_schema` (required `message` property). If Parallel Tool Calls is on, every dispatched edge is `always-create-new`. Approval paths tested end-to-end, not assumed. Happy path runs under the 15-minute workforce wall-clock. Smoke test runs via `relevance_trigger_workforce`, not `trigger_agent_sync` on the orchestrator directly.

## Output Quality Rubric

Score each dimension 1-5. Target: 4.0+ average.

| Dimension | 1 (Broken) | 3 (Acceptable) | 5 (Excellent) |
|-----------|-----------|-----------------|---------------|
| Headline | Missing or neutral | Present, somewhat opinionated | Bold, specific, drives narrative |
| Prioritization | Data dump, no ordering | 3-5 bullets with context | Every bullet earns its place |
| Interpretation | Facts without meaning | Some facts connected to implications | Every fact has business meaning |
| Risk/Opportunity | Missing | Present but generic | Specific, tied to measurable impact |
| Recommended Action | Missing or "follow up" | Concrete but not time-bound | Names people/teams, has urgency |
| Source Coverage | Single source, no attribution | Multiple sources, some attribution | All sources with gaps noted |
| Confidence | No uncertainty acknowledgment | Some hedging | Explicit about known vs uncertain vs unknown |

Scoring: 1.0-2.0 = broken (do not deploy), 2.1-3.0 = functional but not useful, 3.1-4.0 = acceptable for internal use, 4.1-5.0 = production-grade.

## Test Scenarios

1. **Single Entity Deep Dive:** "What's going on with {entity}?" -- exercises routing, iteration, output quality, agency
2. **Degraded Source:** Any query with one source disconnected -- exercises graceful degradation
3. **Portfolio Query:** "Top {N} {entities} by {criterion}" -- exercises source ordering (structured first)
4. **Comparison Query:** "Which {entities} are similar to {entity}?" -- exercises cross-entity reasoning
5. **Write-Gate Enforcement:** Any query then confirm save -- verifies write agent only fires after explicit approval

## Acceptance Tests (Behavioral)

```
TEST multi_source_routing:
  GIVEN a standard entity query
  THEN primary_agent.call_count >= 2
  AND supplementary_agent.call_count >= 1
  AND output CONTAINS "Sources:"

TEST iteration_depth:
  GIVEN a standard entity query
  THEN primary_agent.messages[0] != primary_agent.messages[1]
  AND primary_agent.call_count >= 2

TEST output_quality:
  GIVEN any query
  THEN output CONTAINS opinionated_headline
  AND output.bullet_count <= 5
  AND output CONTAINS risk OR opportunity
  AND output CONTAINS recommended_action

TEST graceful_degradation:
  GIVEN supplementary_source = disconnected
  THEN output CONTAINS synthesis
  AND output MENTIONS gap

TEST write_gate:
  GIVEN any query without user save confirmation
  THEN write_agent.call_count == 0
```

Behavioral tests matter more than output tests. Output-only tests check whether text LOOKS good. Behavioral tests check whether the orchestrator ACTED correctly.

## Adding a New Sub-Agent

1. Build independently -- test in isolation first
2. Define the capability contract: unique value, source hierarchy position, read/write, mode-aware output
3. Configure the edge: `tool-call`, threading per read/write, `params_schema` with required `message`, domain-specific routing guidance
4. Update the orchestrator's source hierarchy in the prompt
5. Test against the quality gates

What you do NOT need to change: the orchestrator's domain logic (it has none), the other sub-agents (they are independent), or the synthesis structure.

## Related Files

- `playbooks/use-cases/synthesis-agent-patterns.md` -- Synthesis patterns (CEO Elevator Test, So What rule)
- `.claude/skills/agent-build-patterns/build-philosophy.md` -- Separate Finding from Doing principle
- `.claude/rules/BUILD_PRACTICES.md` "Workforce / Orchestrator Patterns" -- Batch vs fan-out rules, autopilot rules, micro-agent anti-pattern, dead-end status clarity
- `.claude/rules/PLATFORM_MECHANICS.md` "Workforce Architecture" -- Graph vs tree model, edge types, threading, approval propagation, wall-clock limit, sequential reliability ceiling, Parallel Tool Calls compatibility rule
- The `managing-relevance-workforces` skill is loaded on demand by the remote MCP for platform-level workforce concepts, composition patterns, and debugging

## Sources

This playbook consolidates platform-team guidance on workforce design, parallel execution, sequential reliability, and the soft caps observed at scale. Reach out via the Relevance AI community or support if you want to dig deeper.
