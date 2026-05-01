# Creative Pipeline Patterns

Patterns for building agents that generate varied, high-quality creative output reliably at scale -- not just once, but every time. Covers separation of creative concerns, constrained randomness, multi-model cognitive matching, and temperature as semantic control.

## When to Use

- Building image generation pipelines (marketing visuals, product mockups, social media assets)
- Any system that must produce hundreds of unique outputs from the same pipeline
- Creative content that needs variety across runs, not convergence on "best"

## When Not to Use

- One-off creative tasks (a single LLM call is fine)
- Non-creative generation (data processing, structured output)
- Pipelines where consistency across outputs is more important than variety

## The Core Problem: Creative Convergence

LLMs are remarkably good at creative tasks -- once. Ask again and again, and outputs converge. The model has favorites. It reaches for the same metaphors, compositions, and "interesting" choices.

For one-off tasks, this is fine. For a system producing hundreds of unique outputs, it is fatal. Output #47 looks like output #12 looks like output #3.

## Pattern 1: Separation of Creative Concerns

A single creative prompt asks the LLM to do too many things at once: understand the subject, make stylistic choices, write copy, compose the layout, maintain consistency. When one model handles all simultaneously, it makes trade-offs you cannot control.

**The fix:** Break the pipeline into specialized steps, each with a single cognitive job.

```
Single-step (what most people build):
  Input -> [One LLM: understand + style + write + compose + generate] -> Output

Multi-step (what actually works at scale):
  Input -> [Understand subject] -> [Inject variety] -> [Interpret creatively]
        -> [Write copy] -> [Assemble deterministically] -> [Generate image]
```

### The 6-Step Pipeline

Each step exists because combining it with another degraded quality:

| Step | Cognitive Job | Why Separate |
|------|--------------|--------------|
| Character distillation | Compress input into a vivid description | If combined with art direction, the model optimizes for "drawable" traits rather than "truthful" traits |
| Variety injection | Randomly select from curated creative options | Must be non-LLM (Python) to avoid convergence |
| Creative interpretation | Craft scene descriptions from random selections | Needs high creativity (temp 0.8). Combined with copywriting, both suffer |
| Copywriting | Generate titles, stats, flavor text | Different skill than visual imagination. A model strong at description may write flat copy |
| Assembly | Combine art direction + copy into a single prompt | Must be deterministic (temp 0). Any creativity here introduces drift |
| Image generation | Produce the final image | Dedicated image model |

### When to Add a Step

| Signal | Action |
|--------|--------|
| Outputs converge on the same style/tone | Extract the style decision into its own step |
| Quality of one element degrades when another improves | Give each element its own step with its own model/temp |
| You need deterministic assembly from creative components | Add a temp-0 assembly step between creation and generation |
| A specific decision must be non-LLM (randomization, lookup) | Add a code step |

### When NOT to Add a Step

More steps = more latency, more cost, more debugging. Do not split a step unless you can point to a concrete quality problem it solves. A 3-step pipeline that works is better than a 6-step pipeline where 3 steps are unnecessary.

## Pattern 2: Constrained Randomness (The Director's Menu)

The most transferable pattern in creative pipelines. Solves convergence without sacrificing quality.

### The Problem with LLM Selection

When you give an LLM a menu of creative options and ask it to "pick the most interesting one," it converges:

```
Menu: [12 artistic styles]
LLM picks: Disney Pixar (30%), Ghibli (25%), Low-Poly (15%), everything else (30%)

After 100 runs: 70% of outputs use 3 of 12 styles.
```

The LLM is not random -- it has learned which options are "good" and gravitates toward them.

### The Fix: Random Selection then Creative Interpretation

Split the decision into two parts:

1. **Selection (code, not LLM):** Python randomly picks one option from each creative category. Every option has equal probability.

2. **Interpretation (LLM, high creativity):** The LLM receives the random selections as inspiration, not instructions. It adapts, combines, and reinterprets them. Bad combinations get smoothed out; good combinations get amplified.

```python
# Step 1: Pure randomness (Python)
import random

STYLES = ["Disney Pixar", "Ghibli", "Botanical", "8-Bit", "Sunday Comic",
          "Claymation", "Candy Pop", "Sticker Bomb", "Papercut", "Retro Futurist",
          "Low-Poly", "Watercolor"]

selected = {
    "style": random.choice(STYLES),
    "composition": random.choice(COMPOSITIONS),
    # one selection per category
}
```

```
# Step 2: Creative interpretation (LLM, temp 0.8)
"You've been randomly assigned: Style={style}, Composition={composition}, ...
Use these as INSPIRATION. Adapt them to fit the subject. You can reinterpret
freely -- the random selections are a creative starting point, not a constraint."
```

### Why This Works

| Approach | Variety | Quality | Control |
|----------|---------|---------|---------|
| LLM picks freely (no menu) | Low -- converges on favorites | High per-output | None |
| LLM picks from menu | Medium -- still has favorites | High | Some |
| Random selection, used verbatim | High | Low -- bad combinations happen | Full |
| **Random selection then LLM interprets** | **High** | **High -- LLM smooths bad combos** | **High** |

Randomness provides variety. The LLM provides quality. Neither can do both alone.

### Designing Your Menu

- **Curate aggressively.** Every option should produce good output when combined with any other option. If an option only works with specific companions, remove it.
- **Name options vividly.** "The Claymation (Aardman)" gives the LLM rich creative reference. "Style A" gives nothing.
- **Size categories for needed variety.** High-variety dimensions get more options (9-20). Supporting dimensions can have fewer.
- **Test combinations, not individual options.** The failure mode is not "bad option" -- it is "bad combination." Run 20-30 random combinations and check for clashes.

## Pattern 3: Multi-Model Cognitive Matching

Different creative tasks have different cognitive profiles. Using one model for everything means every step gets a compromise.

| Cognitive Task | What "Good" Looks Like | Model Trait Needed |
|----------------|----------------------|-------------------|
| Character understanding | Grounded, truthful | Strong reasoning, moderate creativity |
| Creative interpretation | Surprising, vivid | High creativity, visual vocabulary |
| Copywriting | Witty, concise, good wordplay | Strong language play |
| Assembly/composition | Faithful to inputs, no drift | Instruction-following, deterministic |
| Image generation | Visual quality, prompt adherence | Dedicated image model |

**Start with one model.** Only introduce a second when you can point to a specific step where output quality drops. Add models one at a time as quality ceilings are hit.

## Pattern 4: Temperature as Semantic Control

Temperature is not a "creativity dial." In a pipeline, each value maps to a specific cognitive mode:

| Temperature | Cognitive Mode | Used For |
|-------------|---------------|----------|
| 0 | Deterministic assembly | Combining components faithfully. No interpretation, no drift. |
| 0.5 | Grounded creativity | Understanding and distilling input data. Creative enough for interesting angles, grounded enough to stay truthful. |
| 0.6 | Structured creativity | Copywriting. Creative within constraints (character limits, tone). |
| 0.8 | Maximum creative latitude | Art direction and scene description. This step should surprise you. |

### Assembly Must Be Temp 0

The most important temperature decision. The assembly step takes creative art direction + creative copy and combines them into a single prompt.

If assembly has ANY temperature > 0, it will "improve" the creative choices -- adding details, changing descriptions, smoothing rough edges. This sounds helpful but is destructive: the art director and copywriter made specific choices for specific reasons. Assembly should be a faithful compiler, not an editor.

**Symptom of wrong assembly temperature:** The generated image does not match the art direction. Details drift. Specific styles soften into generic versions.

## Pattern 5: Dual-Tier Output from One Pipeline

If your system needs two quality tiers (free vs premium, draft vs final), do not build two pipelines. Build one with a tier gate.

| Aspect | Basic Tier | Premium Tier |
|--------|-----------|-------------|
| Art direction | Hardcoded plain styling | Full creative interpretation of random menu selections |
| Copywriting | Same content, same writer | Same content, same writer |
| Assembly | Same template, constrained layout | Same template, enhanced layout |

**Why this works:**
- Contrast sells the premium tier. If basic is also good, contrast collapses.
- Same pipeline = same reliability. One set of failure modes.
- Copy stays consistent. Only visual treatment differs.

## Building Your Pipeline

1. **Identify creative dimensions:** What are the independent creative choices? (Style, composition, color, typography, imagery, tone.) Each becomes a menu category.
2. **Curate your menu:** 8-20 named options per dimension. Test that random combinations produce acceptable output.
3. **Design pipeline steps:** Start minimal: understand input, inject variety, interpret creatively, generate output. Add steps only when you hit a quality ceiling.
4. **Match models and temperatures:** Understanding at 0.5, creative interpretation at 0.7-0.9, assembly at 0, generation with dedicated model.
5. **Test at scale:** Generate 20-30 outputs and check: Are they visually distinct? Does quality stay high? Do any combinations fail?

## Common Failure Modes

| Failure | Symptom | Root Cause | Fix |
|---------|---------|-----------|-----|
| Creative convergence | Outputs look similar despite different inputs | LLM selecting from menu (has favorites) | Extract selection to code (Pattern 2) |
| Quality cliff | Most outputs great, occasional terrible ones | Bad menu combinations | Test combinations, remove problematic options |
| Copy/visual mismatch | Witty text with serious visuals | Single model doing both tasks | Separate copywriting from art direction |
| Prompt drift | Generated output does not match direction | Assembly step has temperature > 0 | Set assembly to temp 0 |
| Pipeline too slow | User waits too long | Too many steps | Merge steps without distinct failure modes; parallelize |
| Tier contrast too weak | Basic and premium look similar | Basic tier still going through creative pipeline | Hardcode basic tier's creative choices |

## Discovered Mechanisms

- **Each pipeline separation was motivated by a specific failure mode.** If you cannot name the failure mode a step prevents, you probably do not need that step.
- **The evolution from v5 (single prompt) to v7 (6-step pipeline) was driven by observation.** v5: decent but repetitive. v6: extracted art direction with LLM selection, but model still had favorites (same 3 styles chosen 60% of the time from menu of 9). v7: randomization extracted from LLM entirely -- variety went up dramatically while quality stayed high or improved.
- **Randomness provides variety, the LLM provides quality.** Neither can do both alone. This is the fundamental insight.

## Related Files

- `playbooks/use-cases/multi-agent-orchestration.md` -- Multi-agent patterns (model selection, phase separation)
- `.claude/skills/agent-build-patterns/build-philosophy.md` -- Code Over LLM pattern (relevant to randomization steps)
- `.claude/rules/BUILD_PRACTICES.md` -- Tool step naming and temperature conventions
