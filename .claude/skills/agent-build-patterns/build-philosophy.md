# Build Philosophy

> **The lens for evaluating every build decision.** This page maps Relevance AI engineering principles to applied build practice, defines the three-layer architecture, and lays out the design discipline that keeps patterns from becoming dogma.

## Core Principles

| Principle | What It Means In Practice |
|-----------|--------------------------|
| **No Tools Fail** | Every tool handles edge cases explicitly. Empty inputs, missing fields, API timeouts all produce a clear message, never a silent failure. Test failure paths *before* success paths. |
| **Built for Future** | Parameterize everything. Tomorrow's run will look slightly different to today's. Use variables, not literals. |
| **Quality Above Cost** | Use the best model for the job. Don't downgrade to save credits unless the budget requires it. A wrong answer is more expensive than a slow one. |
| **Agents are Employees** | Write system prompts like onboarding docs for a new hire. Include what to do, what NOT to do, escalation paths, and examples of good output. |
| **Modular Design** | One tool does one thing. One agent handles one domain. Compose via workforces. Never build a "god agent" that does everything. |
| **Cut Costs** | After the build works, optimize. Move deterministic logic from LLM to code steps. Cache repeated lookups. But never optimize *before* it works. |
| **Faster than Fast** | Parallel where possible. If two tools don't depend on each other, run them in parallel. Measure latency, surface it. |

## Three Layers of Architecture

Every build should be decomposable into three layers:

### Layer 1: Data Flow

Where data comes from, how it moves, where it lands.

- **Sources:** CRM webhooks, scheduled triggers, manual input, meeting platforms
- **Movement:** API calls, knowledge table reads / writes, tool chaining
- **Destinations:** CRM updates, Slack notifications, email, dashboards

> **Ask:** "Can I draw the data flow on a whiteboard in under 60 seconds?"
> If no, the architecture is too complex. Simplify.

### Layer 2: Decision Logic

Where decisions are made and by whom (LLM vs code).

- **Code steps:** deterministic branching, field mapping, data transformation
- **LLM steps:** ambiguous classification, content generation, summarization
- **Business rules:** centralized in one tool, not scattered across agents

> **Ask:** "If I change a business rule, how many files do I touch?"
> If more than one, centralize.

### Layer 3: Action Execution

What actually happens in the external world.

- **Write operations:** CRM updates, email sends, Slack messages
- **Unit of action:** one entity per execution. Never batch writes in the same agent task.
- **Audit trail:** every write operation traceable back to the trigger event.

> **Ask:** "If this action fails halfway, what state is the data in?"
> If unclear, add checkpoints.

---

## Design Discipline: Avoiding Force-Fitting

Patterns are tools, not mandates. Apply these checks before committing to a design.

**The Self-Doubt Protocol (3 checks before finalizing any design):**

1. **Pattern-fit check:** "Am I using this pattern because it fits the problem, or because it is the pattern I know best?" If you reach for the same architecture every time regardless of the problem shape, you are force-fitting.
2. **Repackaging test:** "If I swap the use case, does this design still work unchanged?" If yes, you made a template, not a design. Templates are generic. Designs are shaped by specific constraints.
3. **Mismatch alert:** "What about this specific situation would make a textbook pattern fail?" Every real deployment has at least one constraint that bends the default approach: data quality, team size, integration limitations, approval culture. Name it before it surprises you.

**When to break patterns:**

- The constraint genuinely invalidates a pattern's assumption (e.g., Unit of Action assumes tools can be decomposed, but some legacy APIs bundle operations)
- Following the pattern would add complexity without adding value for this specific build
- The pattern was designed for a different scale (e.g., workforce orchestration patterns applied to a single-agent demo)

**When NOT to break patterns:**

- "It's just a demo" (demos become pilots)
- "I asked for it this way" (requirements describe symptoms, not architectures)
- "It's faster to skip this" (technical debt compounds faster than you think)
