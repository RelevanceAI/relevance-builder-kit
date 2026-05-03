# Starter Agent Anti-Patterns

> The reference library. Each anti-pattern has: signal (how you spot it), why it's bad, and what to do instead.

## Anti-Pattern → Rubric Point Map

If a starter agent fails a rubric point, scan the anti-patterns linked here first — most failures are one of these.

| Anti-pattern                              | Violates rubric point(s)                                       |
|-------------------------------------------|----------------------------------------------------------------|
| `forked-from-marketplace`                 | 1 (Built fresh)                                                |
| `json-envelope-wrapping-prose`            | 4 (Output format matches consumer)                             |
| `in-scope-out-of-scope-meta-framing`      | 3 (Role-first framing), 6 (Length discipline)                  |
| `actions-ID-injection-noise`              | 5 (Tool references natural language)                           |
| `tool-hoarding`                           | 7 (3-5 tools, each with clear purpose)                         |
| `thinking-tool-enabled`                   | 8 (No default-added tools that don't earn their place)         |
| `llm-tool-included-just-in-case`          | 8                                                              |
| `paid-tool-without-credits`               | 8                                                              |
| `redundant-research-tools`                | 7, 8                                                           |
| `list-order-as-priority`                  | 4 (Output format matches consumer — wrong output for v1)       |
| `cant-be-edited-without-the-builder`      | 11 (Editability test), 2 (Architecture layers)                 |
| `reference-examples-as-variables`         | 2 (Architecture layers — wrong layer for scaling content)      |
| `trigger-agent-sync-for-smoke-test`       | 12 (Smoke test via async pattern)                              |
| `roadmap-as-feature-list`                 | 9 (v0 -> vN journey, one constraint per version)               |

Rubric points 1-12 are listed in `SKILL.md` § "12-Point Design Rubric". The checklist version lives in `checklist.md`.

---

## `forked-from-marketplace`

**Signal:** the agent is a clone of a marketplace or Invent-generated agent. Tell-tale traces: unresolved `{{_placeholder.TOOL <name>}}` pills nobody configured, 10+ tools attached with most unused, generic prompt text like "You are an expert [X] strategist", hasn't been renamed for the actual use case.

**Why it's bad:**

- Marketplace agents are scoped for breadth across use cases, not depth in any one
- Placeholder tools inherit but rarely get connected. The UI stays cluttered with Connect pills indefinitely
- The prompt pretends to be production-ready but reads like a sales pitch to a generic AI Ops persona
- You inherit every design decision the Invent generator made, without knowing why
- Twice the prompt length of a clean build, typically 6,000+ chars of generic filler

**What to do instead:** build fresh via `relevance_upsert_agent`. Keep any sandbox as a reference (read its prompt, note what it's aiming at), but don't fork it. Clean slate gets you to v1 faster with half the prompt length.

---

## `json-envelope-wrapping-prose`

**Signal:** output is `{draft: "...", citations: [...], compliance_flags: [...], needs_review: [...]}` or similar. The draft itself is markdown or prose, wrapped in JSON.

**Why it's bad:**

- The end consumer (a human editor, a CMS) doesn't parse JSON. They copy-paste content
- The envelope structure fights the reader. They have to find the prose inside the JSON, then copy just that
- It's a design smell: you couldn't decide between human-consumer (markdown) and downstream-code-consumer (JSON), so you did both

**What to do instead:** pick one format. For content humans will edit and publish: clean markdown with a Sources section at the bottom. For structured data a downstream tool will parse: clean JSON with a defined schema, no prose. Never both.

---

## `in-scope-out-of-scope-meta-framing`

**Signal:** the system prompt contains sections like "In scope (v1):", "Out of scope (v1):", "Hard Rules:", "TBC v2:", "<!-- TBC -->" comments. It reads like an internal spec doc, not instructions to the agent.

**Why it's bad:**

- The agent doesn't know or care about "v1 scope". It reads the prompt verbatim and gets confused about whether scope is current or aspirational
- Anyone opening the prompt sees a spec, not a role definition. Signals "this is under construction" rather than "this is a tool ready to use"
- Version markers date the prompt instantly. As soon as v2 ships, the v1 scope section is wrong

**What to do instead:** write the prompt as instructions to the role. "You are a marketing content writer for [purpose]. You produce blog posts tailored to..." The agent's scope is what's in the prompt; if something's out of scope, don't mention it. Hard rules are fine in a short "Rules" section with 4-6 bullets, not 20.

---

## `actions-ID-injection-noise`

**Signal:** the prompt has `{{_actions.dd11beab5b71a9ea}}` references peppered throughout, or a "## Tool References" section at the bottom with a table of action IDs. Anyone who opens the prompt in the UI sees noise.

**Why it's bad:**

- Action IDs are implementation detail. Editors shouldn't have to read them
- The UI hostility compounds: editors open the prompt to tune tone of voice and have to scroll past action-ID tables
- `relevance_attach_tools_to_agent` with `inject_action_references: true` (the default) is the usual culprit. It auto-appends the tool reference block every time you attach

**What to do instead:** attach tools with `inject_action_references: false`. In the prompt, describe each tool by name and purpose in prose: "Use Perplexity web search to research current industry trends". The platform resolves the tool by the name mention; no ID required.

---

## `tool-hoarding`

**Signal:** 8, 10, 12 tools attached. Most used rarely or never. The agent is slower to decide what to call and more likely to hallucinate tool choices.

**Why it's bad:**

- Each tool in the tool list is a context tax on every agent turn. The agent reads the tool roster, weighs options, more tools = more tokens, more wavering
- Unused tools are noise for humans too. Anyone opening the agent config sees a pile of tools they don't know what to do with
- Redundancy hides: Perplexity + Google Search + Jina + Extract Text From URL all overlap in "web research". Pick one per job.

**What to do instead:** 3-5 tools, each mapped to one distinct retrieval or action. For each tool, be able to answer: "This tool is for the case where the agent needs to ___." If you can't name the case, drop the tool.

---

## `thinking-tool-enabled`

**Signal:** `thinking_tool: {enabled: true}` on the agent. Tool call traces show `Think` steps interleaved with real tool calls.

**Why it's bad:**

- Modern Claude models (Sonnet 4.5+, Opus 4.5+) reason inline without a dedicated tool
- Each Think step is a wasted round-trip. Latency added for no output quality gain
- The tool's output gets embedded in the conversation history, bloating context for later turns

**What to do instead:** set `thinking_tool.enabled: false`. Instruct the agent in the prompt: "Do not use any 'thinking' or 'scratchpad' tool. Reason through your approach directly in your response." Some agents are persistent. The explicit instruction helps.

---

## `llm-tool-included-just-in-case`

**Signal:** an "LLM" tool is attached to an agent whose job is drafting or writing. The tool is rarely called; when it is, the output is re-incorporated into the agent's response.

**Why it's bad:**

- The agent is itself an LLM. Wrapping another LLM tool inside it is redundant
- Extra cost, extra latency, extra chance of tone drift (the sub-LLM doesn't have the agent's system prompt context)
- Signals "I wasn't sure what to use". If you need the agent to pick from N options or do multi-step drafting, handle it in the prompt, not by delegating to another LLM

**What to do instead:** remove the LLM tool. If the agent truly needs to generate a structured sub-component (three title options, a JSON schema), describe the task in the prompt and let the agent do it directly. Keep the LLM tool in the back pocket only for cases where you genuinely want a different model (e.g. a cheap Haiku pass).

---

## `paid-tool-without-credits`

**Signal:** a paid third-party tool is attached (People Enrichment, Apollo, ZoomInfo, etc.) but the project doesn't have credits or an API key. The tool either silently fails or the agent never calls it.

**Why it's bad:**

- The agent prompt and config show a capability that doesn't work
- Anyone running it gets confused by an empty or error output

**What to do instead:** drop the paid tool. Find a cheaper native equivalent (e.g. Google Search + Extract Text From Website URL covers LinkedIn-style person research without a paid API). If a paid tool really is needed for the use case, get the credentials in place BEFORE shipping. Don't ship a broken capability.

---

## `redundant-research-tools`

**Signal:** two or more tools that do the same job. Classic combos: Perplexity + Google Search; Jina Reader + Extract Text From URL + Convert a file to text.

**Why it's bad:**

- Agent has to pick which to use; often picks inconsistently across runs
- You double your attack surface for "tool returns weird content" issues
- Anyone opening the config sees two tools with similar names and doesn't know when each fires

**What to do instead:** pick one per job. For web search: Google Search (finds LinkedIn URLs, handles general research). For reading a specific URL: Extract Text From Website URL. That pair covers search-then-read. Perplexity is great for some agents but it doesn't find LinkedIn URLs reliably. Don't stack it on top of Google.

---

## `list-order-as-priority`

**Signal:** the requirements listed four output types (emails, one-pagers, talking points, pitch outlines). You built v1 for emails because it was first.

**Why it's bad:**

- List order is rarely a priority signal. Lists capture what comes to mind, not what's most valuable
- Emails are a weak demo surface for brand voice. Short, generic, easy to dismiss. A blog post at 800 words makes brand voice undeniable
- Starting with the wrong format means v1 doesn't wow

**What to do instead:** when faced with a list of output types, ask: which format shows the build's value best, needs the least input data to demo, and maps to a tangible artefact? For content enablement, blog post > one-pager > email > social > talking points. Push back on requirements that default to email.

---

## `cant-be-edited-without-the-builder`

**Signal:** you hand the agent over. Someone asks "how do I change the tone?" and you have to walk them into the system prompt and find the right paragraph to edit.

**Why it's bad:**

- The user depends on the builder for every tune
- Velocity stalls between builder touchpoints
- Trust drops because the user can't reason about what controls what

**What to do instead:** tone, brand, compliance, and reference examples go in agent-level variables (`params_schema` with `is_fixed_param: true` + `default`). Edit the `default` value in the config drawer. One click, no prompt surgery. Run the editability test: change `tone_of_voice` to something deliberately different ("casual, pub-chat") and confirm the next output shifts.

---

## `reference-examples-as-variables`

**Signal:** 3, 5, 10 reference blog posts inlined as agent variables. Each paste bloats the prompt by ~2,000 characters.

**Why it's bad:**

- The prompt balloons. 4k -> 12k characters. The agent's context gets eaten by references rather than reasoning
- You can't weight retrieval. Every example is always in context even when irrelevant
- When you have 20 good examples, they can't fit in variables

**What to do instead:** reference examples live in a dedicated knowledge table (`example_content` or similar). The agent searches the KB by audience / topic before drafting, pulls the 1-2 most relevant as anchors, matches their structure. Scales to any number of examples and keeps the prompt tight.

---

## `trigger-agent-sync-for-smoke-test`

**Signal:** you call `relevance_trigger_agent_sync` during a smoke test. It "hangs" and returns "user rejected the tool use" but the task actually completed on the platform.

**Why it's bad:**

- `trigger_agent_sync` holds the MCP transport open for up to 120 seconds polling for completion
- OAuth token expiry or idle timeout drops the connection mid-call
- Claude Code surfaces dropped transport as a generic "user rejected" error. Misleading

**What to do instead:** use the async pattern. `relevance_trigger_agent` returns immediately with a conversation_id. Then `relevance_get_agent_task_summary` to retrieve the output once the task completes. Transport stays open for seconds per call, not minutes.

---

## `roadmap-as-feature-list`

**Signal:** your v0 -> vN roadmap reads "v2: add social posts. v3: add one-pagers. v4: add slides." Each version adds features, not answers a question.

**Why it's bad:**

- No gating. What tells you v2 is "done" and you can move to v3? Nothing.
- The roadmap doesn't show why each version matters. Just more features stacked on the last.
- You hit v4 with all features but terrible quality; no version forced you to stop and evaluate.

**What to do instead:** each version solves ONE constraint. Frame the constraint as a question: "Can the agent produce on-brand blog posts at all?" (v1). "Is the grounding actually from internal content?" (v2). "Does the voice hold across audiences?" (v3). Move only when the question passes in a live demo. Gates velocity honestly.
