# CLAUDE.md Design Principles

Principles for structuring CLAUDE.md files in a layered repo. Extracted from SoloStack's company-as-repo template and adapted for the agent builder context.

## Source

- SoloStack whitepaper: https://trysolostack.com/whitepaper/
- SoloStack repo: github.com/Michaelrecycle/solostack-boilerplate (677-line root CLAUDE.md)
- Michael's three-level structure guidance (company -> department -> function)

## The 10 Principles

### 1. Philosophy Before Routing

The first thing CC reads should establish HOW TO THINK, not WHERE TO GO. Mental model alignment comes before navigation. SoloStack dedicates 30% of the root file to philosophy and paradigm shifts before any routing.

**Applied:** Root CLAUDE.md opens with identity, philosophy, paradigm shifts, and operating pillars - all before the routing section.

### 2. Identity Assignment

Give CC a strong role identity it operates from. SoloStack uses "You are the CEO of this company." The identity shapes how CC approaches every task - not just what it does, but how it thinks about decisions.

**Applied:** "You are an agent builder using Relevance AI. This kit is your workspace and your knowledge base."

### 3. Operating Pillars

Define evaluation criteria that everything is measured against. Not rules (which say what to do) but pillars (which say what to optimize for). SoloStack has 6: Attribution, Repurposement, Cross-Department, Automation, Ownership, Context. Each includes a question to ask when designing.

**Applied:** operating pillars (Reliability, Separation of Concerns, Auditability, Customer Value, Use Native Capability). Each with a "when designing, always ask" prompt.

### 4. Paradigm Shifts

Explicit mental model changes - "think THIS way, not THAT way." These are more powerful than instructions because they change how CC reasons, not just what it does. SoloStack has 7 paradigm shifts like "business problems become coding problems" and "departments are directories."

**Applied:** 7 paradigm shifts like "agents are employees, not chatbots" and "unit of action is how you sleep at night."

### 5. Rich Routing

Don't just say "go to X." Say what's there, what tools are available, and what status it's in. SoloStack's routing table has 4 columns: what user asks about, department, key tools available, status (Active/Starter/Planned).

**Applied:** Domain-based routing with status and tools columns, plus query examples under each domain.

### 6. Cross-Domain Workflows

Show how areas interact for common tasks. The most valuable work often spans multiple domains. SoloStack includes step-by-step breakdowns of multi-department workflows like "Pull leads from CRM and send LinkedIn connection requests."

**Applied:** cross-domain workflow examples like new build, resuming after break, debugging production agent.

### 7. Key Files Table

A single quick-reference for the 15-20 most important files across the whole repo. Saves CC from traversing when it needs a known file. SoloStack has a 20-row key files table at the bottom of the root.

**Applied:** Key files table with the most important files and one-line purposes.

### 8. Proactive Documentation

When/how/where to update docs, made mandatory. SoloStack: "If you built it, changed it, or broke it - document it. Every session should leave the docs better than it found them."

**Applied:** Mandatory documentation section with triggers and locations.

### 9. Completeness Over Brevity

The root should be complete enough that CC can operate correctly from reading just this one file. A 50-line routing hub forces CC to traverse before it can think. A 250-line briefing gives it the mental model AND the map.

**Applied:** Root expanded from a routing hub to a full briefing with identity, philosophy, paradigm shifts, pillars, routing, and key files.

### 10. Inline Warnings

Gotchas right next to the thing they affect, not in a separate file. SoloStack puts warnings inline: "Never use `npx tsx -e` with local imports" right in the scripts section.

**Applied:** Hard rules and critical warnings in the relevant sections, not gathered in a separate warnings file.

## When to Apply These Principles

- Creating a new CLAUDE.md at any directory level
- Reviewing an existing CLAUDE.md for effectiveness
- Restructuring the repo's knowledge hierarchy
- Onboarding a new team to the CLAUDE.md pattern
