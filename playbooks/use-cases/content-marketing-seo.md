# Content Marketing and SEO

A workforce that automates the full content marketing pipeline - from keyword research through article generation, visual asset creation, and CMS publishing - for teams that need to scale content output without scaling headcount.

## When to Use

- You have a content marketing or SEO function with a backlog the team can't keep up with
- Keyword research, content clusters, or article production volume are pain points
- Rigid workflow tools (n8n, Make) keep breaking every time content formats or strategy changes
- A large back-catalogue of articles is going stale as trends shift
- Multiple people need to contribute feedback before content goes live

## When Not to Use

- No content marketing function exists - this pattern is the wrong fit
- A simple one-off blog post generator is enough - this workforce is overkill, build a single agent instead
- The CMS has no API and no G Suite alternative is acceptable - the default output layer won't work
- The focus is primarily paid marketing (no SEO intent)

## Default Architecture

An 11-agent workforce. Keyword research and cluster planning feed into a one-to-many dispatch pattern, where each article is processed independently by the article generation sub-workforce.

```
[Trigger: keyword / topic input]
         |
         v
[Keyword Research Agent]
  - Google Autocomplete expansion (~200 queries)
  - Moz metrics enrichment
  - Search intent classification (informational vs commercial)
         |
         v
[Cluster Planning Agent]
  - Generates 15-20 article titles per topic
  - Prioritizes based on custom scoring (not Moz black-box)
         |
         v
[One-to-many dispatch: one task per article]
         |
         +----> [Article Research Agent]
         |           - Bulk SERP scrape (top 10 results)
         |           - Meta title/description analysis
         |           - Winning content pattern extraction
         |           v
         |      [Article Writing Agent]
         |           - Generates article matching winning format
         |           - Format-aware (listicle / informational / comparison)
         |           v
         |      [Visual Asset Agent]
         |           - Header image (exact aspect ratio, logo, text)
         |           - Supporting images (Pinterest, infographics)
         |           - Image alt tags linked to keyword research
         |           v
         |      [CMS Publishing Agent]
         |           - Creates Google Doc (default)
         |           - Updates Google Sheets tracking row to complete
         |           v
         |      [Slack Notification Agent] (optional)
         |           - Posts draft link to team channel
         |           - Monitors thread for comments
         |           - Triggers article update based on feedback
         |
         +----> [Bulk Refresh Workflow] (parallel path)
                    - Takes existing article URL/content
                    - Re-runs keyword research, competitive analysis
                    - Extends, re-optimises, updates images and alt tags
```

**Variations:**
- **Different CMS when:** You use Webflow, WordPress, or Squarespace -- swap the CMS Publishing Agent's output step for the relevant API. G Suite is the default because it requires no special access and is universally demoed.
- **Without cluster planning when:** You want to generate individual articles on demand -- trigger directly at the Article Research Agent, skip keyword research and cluster steps.
- **Without Slack feedback when:** You are running autopilot overnight batch -- remove Slack step, set all results to draft status for manual review.

## Key Design Decisions

- **G Suite as default CMS:** Google Docs for article output and Google Sheets for completion tracking. Chosen over Webflow / WordPress / Squarespace because any user can follow a demo without needing access to a specific CMS. Sheets tracking also gives a clean visual of article status in the demo.

- **Agents over n8n for this use case:** Content formats (listicle, informational, comparison page) each require different research approaches, different outlines, and different competitive analysis. Branching this explicitly in a workflow tool means rebuilding every time strategy shifts or a new format is added. The agent makes these micro-decisions dynamically. The number of permutations makes rigid branching impractical.

- **Google Autocomplete API over Answer The Public:** The Google Autocomplete API is free. Answer The Public charges for the same functionality. The agent expands a seed query to ~200 variants by prepending every letter of the alphabet and interrogative terms (how, what, where, why, when, who). Use this for initial keyword discovery before enriching with Moz metrics.

- **Custom keyword prioritization over Moz priority score:** Moz has a built-in priority score but it is a black box. Users can't see how it weights competing signals. The agent lets you define your own prioritization logic after pulling raw Moz metrics, which is a meaningful differentiator for teams that have hit the ceiling of off-the-shelf SEO tools.

- **Exact-dimension image generation:** Generating header images at exact pixel dimensions (e.g. 1200x628 for OG images) with logo and text overlay is technically hard to get AI image models to do consistently. This workforce has solved that pattern using Nano Banana Pro and other current image models. Don't underplay this. Most users assume it isn't possible with AI generation.

## Tools Required

| Tool | Purpose | Notes |
|------|---------|-------|
| Google Autocomplete API | Keyword expansion from seed queries | Free API - no key required. Returns what people are currently searching for |
| Moz API | Keyword metrics (volume, difficulty, opportunity) | Paid API. Pull raw metrics and apply custom scoring - don't use Moz priority score directly |
| Google Search / SERP scraper | Top 10 result analysis per keyword | Used for winning content pattern extraction and search intent classification |
| Image generation (Nano Banana Pro) | Header images, Pinterest assets, infographics | Must handle exact aspect ratios and text/logo overlay - test this first |
| Google Docs (native) | Article output | Default CMS output layer |
| Google Sheets (native) | Article completion tracking | One row per article, status updated as workforce progresses |
| Slack (native) | Team feedback loop on drafts | Optional - enables async human review before finalising |

## Knowledge Tables

| Table | Purpose | Key Fields |
|-------|---------|------------|
| Article Queue | Tracks articles through the pipeline | keyword, status, doc_url, cluster, publish_date |
| Keyword Research | Stores enriched keyword data per run | keyword, volume, difficulty, intent, moz_metrics, autocomplete_variants |

## Implementation Checklist

1. Start with a single article generation path (no cluster planning, no one-to-many) - validate output quality before scaling
2. Set up G Suite OAuth and confirm Docs + Sheets write access
3. Build and test the Google Autocomplete tool in isolation - verify it expands to 200+ variants
4. Integrate Moz API if you have a Moz key; otherwise use Autocomplete + SERP scraping for initial builds
5. Build the SERP scraper tool - test that it returns top 10 results with meta title/description for a given keyword
6. Build the article writing agent with explicit format instructions (test listicle and informational separately)
7. Build and test visual asset generation - validate exact dimension output before attaching to workforce
8. Add the Google Sheets tracking update as the final step in the article path
9. Add cluster planning agent and connect one-to-many dispatch
10. Add bulk refresh path as a separate trigger (same agents, different entry point)
11. Add Slack feedback loop last - it's optional and adds complexity

## Failure Modes and Gotchas

- **Writing model quality is the make-or-break variable:** Early versions of this workforce failed because the writing models weren't good enough to follow detailed formatting instructions. Always test the article writing agent with the latest models before building the rest of the workforce around it. A workforce that produces mediocre articles at scale is worse than a single good article.

- **One-to-many dispatch and context accumulation:** When the cluster planning agent dispatches 15-20 articles, it must fire them one at a time - not produce a single planning response covering all 20. A single planning response for 20 articles will hit output token limits mid-pipeline. See `BUILD_PRACTICES.md` "Batch vs Fan-Out" for the full pattern.

- **Image generation aspect ratios:** Getting exact pixel dimensions with logo and text consistently requires prompt engineering investment. Don't assume it works out of the box - test the visual asset agent independently across 10+ generations before connecting it to the pipeline.

- **Moz priority score is opinionated:** Customers who already use Moz may push back on using the priority score. Lead with "we pull the raw metrics and you decide how to prioritize" - this is the correct framing and the actual differentiator vs using Moz directly.

- **Refresh vs generate framing for demos:** For customers with large existing content libraries, the bulk refresh angle lands harder than generation. Generating new articles feels obvious; automatically keeping 500 existing articles up to date with changing trends and new keywords is the problem nobody has solved.

## Demo Notes

- Pair the workforce with a written usage guide and a walkthrough video so non-builders can run it
- Lead with the cluster creation flow for "art of the possible" demos - 11 agents working together on a single brief is a strong visual
- For SEO-literate audiences: the Google Autocomplete expansion, custom keyword scoring, and search intent classification will get the strongest reactions - these are things they've wanted to automate for years
- For marketing generalist audiences: lead with the Slack feedback loop and bulk refresh - tangible problems they've felt personally

## Related Files

- `playbooks/use-cases/creative-pipeline.md` -- related patterns for creative and generative content workflows
- `playbooks/use-cases/multi-agent-orchestration.md` -- architecture patterns for the one-to-many dispatch used in cluster generation
- `build-kit/integrations/` -- Google Workspace integration guides
