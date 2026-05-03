# Slack

> **Slack** is a workplace chat platform. Relevance AI offers first-class, bidirectional Slack support: messages, threads, triggers, @mentions, buttons for tool approval, and unified alerts. Integrates via native OAuth.

Unlike most integrations, Slack is not "just another tool suite" -- it is a supported **interface** for interacting with agents, comparable to the chat UI itself. Build on native primitives before reaching for webhooks or custom apps.

## Why It Matters

Slack is the default comms surface for most GTM teams; any agent a customer interacts with conversationally lands here. Native Slack triggers turn any channel into an agent command line (summon via `@Relevance AI` or a keyword), and bidirectional threading keeps the conversation in-place without the agent needing an explicit send tool. Pair this with Slack Buttons for pending-tool approval and Agent Alerts for exception routing, and Slack becomes the full operator console.

## Common Use Cases

| Use case | Trigger | Agent behaviour |
|---|---|---|
| Channel triage / summariser | Slack trigger on channel (all messages or keyword) | Reads thread, summarises, routes |
| On-demand research | Slack trigger on `@Relevance AI` mention | Runs research tools, replies in thread |
| Approval workflow | Slack trigger + Slack Buttons (pending-tool approval) | Surfaces a tool request in Slack for approve/reject |
| Notifications / alerts | Agent Alerts (Escalated / Timed out / Tool failed) | Posts into a specified channel; supports mentions |
| Human-in-the-loop handoff | Slack trigger in thread continuation | Agent escalates to a human, human replies in thread, context continues |

Reference templates on the marketplace: **Pre-Meeting Prepper**, **Meeting Notetaker** (pairs with Recall AI), **Sam the Slack Channels Summarizer**, **Universal Send Slack Block Kit** -- see https://marketplace.relevanceai.com/integrations/slack.

---

## Decision: Native Slack vs Custom Slack App

**Default: native Slack for Agents** (the connector branded as `Relevance AI`). Use it unless you have a specific reason not to.

Use a **custom Slack app** (customer-owned bot persona) when:

- The customer wants their own bot branding ("@AcmeBot", not "@Relevance AI") in channels
- The customer's Slack Enterprise Grid policy blocks third-party bot installs
- You need scopes/behaviours not granted by the Relevance AI bot

Use **a generic webhook trigger + Slack Outgoing Webhooks** as a last resort (pre-native-trigger fallback). Pattern: Relevance custom webhook trigger with message template (`User: {{user_name}}`, `Thread: {{timestamp}}`, `Query: {{text}}`), map `timestamp` as the thread id. Slack side: enable "Outgoing webhooks" on the channel, paste the Relevance URL. Pair with `Slack Bot API Call` (not `Slack: Send Message`) for multi-channel + threading.

---

## 5-Minute Quick Start (Native Slack)

1. **Log in to Relevance AI** → **Integrations & API Keys** → **Slack** → **Add Integration**
2. In the Slack OAuth popup: sign in, select channels to grant access, click **Allow**
3. In target channel: `/invite @Relevance AI`. For DM triggers, the user must send the bot any message **first** -- otherwise their name won't appear in the DM dropdown
4. Open the agent → **Triggers** → **New trigger** → **Slack** → pick account, channel/DM, keyword (blank = trigger on every `@Relevance AI` mention, case-insensitive) → optional work-hours queue → **Setup trigger**
5. **Send a test message.** Live status updates appear in-thread; reply to continue the conversation

Canonical docs: https://relevanceai.com/docs/integrations/popular-integrations/slack

### Permission gate (DM triggers)

To trigger an agent via DM, the user needs **Editor or higher** permission on that agent. Viewer-only users will not see DM triggers fire.

---

## Interaction Patterns

### Pattern 1: Bidirectional threading (DEFAULT -- no Send tool needed)

**This is the most important Slack fact.** With a native Slack trigger, agent replies route back to the same thread **automatically**. The platform stores `{slack_workspace_id, slack_channel_id, slack_thread_id, oauth_account_id}` in the sync item on inbound; the outbound reply uses the saved context. You do NOT need a `slack_send_message` tool attached.

- Works for: public channels, private channels, channel @mentions
- Reply-in-thread: agent's chain-of-thought renders as live status updates; final output is the thread reply
- Continuation: a human reply in the same thread re-triggers the agent with full context (matched via `thread_ts` → existing task)

### Pattern 2: Send-only notifications (no trigger)

Agent pushes messages into Slack without an inbound trigger. Four sending methods, all native:

1. **Slack DM** (Send Message tool) -- accepts UserID / ChannelID / email (email resolution uses `users:read.email` scope)
2. **Slack DM via Slack Notifications** -- agent-builder Notifications panel
3. **Slack Channel Message** (with `@mentions`) -- via Send Message tool to a channel ID
4. **Slack Channel Notifications** -- the legacy "escalate to manager" surface

For screenshots and walkthroughs of each pattern, refer to the agent-builder UI's own help surfaces or the Relevance AI marketplace examples.

### Pattern 3: AVOID -- trigger + Send Message tool on same agent

Known bug: an agent with a Slack trigger AND an attached Send Message tool fires **two replies** into the thread (auto-relay from the trigger + the explicit tool call). If you find yourself reaching for `slack_send_message` on a triggered agent, you almost certainly don't need it -- the trigger does the reply for you. A "don't auto-relay" config toggle is on the roadmap but not yet shipped.

**Rule of thumb:** if the agent has a Slack trigger, only attach a Send Message tool if you need to message a **different** channel/user than the trigger thread.

---

## Native Tool Steps

| Step | Purpose | Channel support | Native/Pipedream |
|---|---|---|---|
| `slack_message` | Send a Slack message | All | Native (Verified) |
| `slack_message_advanced` | Send with advanced formatting (Block Kit) | All | Native (Verified) |
| `slack_retrieve_message` | Fetch message by channel name | **Public channels only** | Native (Verified) |
| `slack_api_call` | Arbitrary Slack Web API call | All (via channel ID) | Native (Verified) |
| `slack_search_public_and_private` | Search across indexed messages | All where bot is a member | Native (Verified) |

Always pick the **Verified** step in the picker over Pipedream equivalents (`.claude/rules/BUILD_PRACTICES.md` "Always Prefer Native"). Detailed step references load on demand via the remote MCP's `managing-relevance-tools` skill.

### `slack_retrieve_message` -- public channels only

Resolves channels by name and **fails on private / group / DM channels** even if the OAuth account is a member. Error: `"No public Slack channel found with that name"`. Use `slack_api_call` with a hardcoded channel ID for anything else. See `.claude/rules/BUILD_PRACTICES.md` "Slack: `slack_retrieve_message` is Public-Channels-Only" for the full retrieval matrix.

### `slack_api_call` -- escape hatch for arbitrary Slack API

Generic wrapper around the Slack Web API. Use for:

- Private channel message retrieval: `GET /conversations.history?channel=G014V2KHYBY&limit=200&oldest={{oldest_ts}}`
- Thread fetching: `GET /conversations.replies?channel={{channel_id}}&ts={{thread_ts}}`
- User profile lookup: `GET /users.info?user={{user_id}}`
- User ID by email: `GET /users.lookupByEmail?email={{email}}`
- Channel listing: `GET /conversations.list?types=public_channel,private_channel&limit=200`

Channel IDs are stable -- safe to hardcode in tool step params.

---

## Channel ID Prefix Reference

The first letter of a Slack channel ID determines what retrieval step works:

| Prefix | Type | Retrieval step | Notes |
|---|---|---|---|
| `C...` | Public channel | `slack_retrieve_message` (by name) OR `slack_api_call` (by ID) | Both work; by-name is more robust to channel renames |
| `G...` | Private channel / group | `slack_api_call` only | `slack_retrieve_message` will 404 |
| `D...` | Direct message | `slack_api_call` only | DM channel IDs are user-specific |

---

## Slack Triggers -- Deep Dive

Slack triggers ride on the `external_relay` sync config (the same object originally used for notifications). One `slack_trigger` per agent -- if you need multiple, split into multiple agents or a workforce.

### Trigger conditions

| Condition | Shape | Notes |
|---|---|---|
| `keywords` | `{values: [...], config: {match_type: 'contains' \| 'exact', case_sensitive: bool}}` | Blank `keywords` = trigger on any `@Relevance AI` mention |
| `user_ids` | Array of Slack user IDs | Restrict to specific senders |
| `channels` | Array of Slack channel IDs | Restrict to specific channels |
| (implicit) | `@RelevanceAI` mention | Always triggers regardless of other conditions |

### Trigger scenarios

1. **Top-level keyword match** -- user posts a message containing the keyword in a watched channel
2. **In-thread keyword match** -- platform pulls thread context via `conversations.replies` before dispatching
3. **User reply in thread** -- matched via `thread_ts` against an existing task; re-triggers the same agent conversation with context
4. **Direct @mention** -- user tags `@Relevance AI` anywhere the bot is a member

### Advanced settings

| Setting | Effect |
|---|---|
| **Exclude Keywords** | Comma-separated blocklist; messages containing any exclude keyword are skipped |
| **No Agent Reply** | Run silently -- agent processes the message but posts nothing back to Slack |
| **Work Hours Queue** | Hold messages outside configured hours; process when hours start |

### Trigger payload -- known limitation

**Slack triggers truncate rich-text messages to plain text and only surface the first line in the payload.** If the source message has rich formatting (bold, bullets, code blocks), the agent receives a one-liner even when the visible message is long.

**Workaround:** use `thread_ts` / `ts` from the trigger payload to fetch the full message separately via `slack_retrieve_message` (public channels) or `slack_api_call` + `conversations.history` (private/group channels).

Documented in `.claude/rules/PLATFORM_MECHANICS.md` "Known Limitations".

---

## Message Formatting (Slack mrkdwn)

Slack uses its own mrkdwn dialect, NOT GitHub-flavoured markdown. Use these rules in agent prompts and tool templates.

| Element | Renders | Syntax |
|---|---|---|
| Bold | ✅ | `*bold*` (single asterisks, NOT `**bold**`) |
| Italic | ✅ | `_italic_` |
| Strike | ✅ | `~strike~` |
| Blockquote | ✅ | `> quoted line` |
| Emoji | ✅ | `:tada:` |
| Links | ✅ | `<https://example.com\|link text>` |
| Inline code | ✅ | `` `code` `` |
| Code block | ✅ | triple backticks |
| Headers (`#`) | ❌ | Use bold + newline instead |
| Dividers (`---`) | ❌ | Use blank line + invisible char |
| Markdown tables | ❌ | Use Block Kit or formatted code block |
| Bullets | ✅ | `- item` |

Spacing hack: the invisible char `U+200E` (LEFT-TO-RIGHT MARK) inserted on its own line adds vertical breathing room between sections without rendering as visible content.

For dense structured output, use **Block Kit** via `slack_message_advanced` -- Relevance provides a "Universal Send Slack Block Kit" marketplace tool as a reference.

For dense weekly summaries or status posts, combine these conventions with subteam mentions and threading.

---

## @Mentions and User Targeting

Tag a specific user by embedding raw Slack user ID syntax in the message body:

```
<@U12345678> please review this deal
```

In agent prompts, keep the user-ID map as a param/knowledge lookup rather than relying on the LLM to recall IDs:

```json
"params": {
  "team_members": [
    {"name": "Alice", "slack_id": "U00000000000", "email": "alice@example.com"}
  ]
}
```

Channel mentions: `<#C12345678|channel-name>`.

---

## Slack Buttons -- Pending-Tool Approval

Relevance supports surfacing an agent's pending tool call as an interactive Slack message with **Approve** / **Reject** buttons. Toggle on the Slack trigger: enables the operator to approve/reject tool requests directly in Slack without switching to the Relevance UI.

Use cases: CRM writes, outbound email sends, CRM status changes, any action where you want a human in the loop but don't want context-switching overhead.

---

## Alerts & Notifications (as of 2025-12-04)

The **Agent Alerts** system unifies the older "Escalations" and "External Relays" surfaces. Configure under agent build settings → **Alerts** tab. Slack is one channel option alongside email.

Alert rules fire on:

- **Escalated** -- agent explicitly escalates a task
- **Timed out** -- task exceeds runtime limits
- **Unrecoverable error** -- task crashes with no retry path
- **Repeated tool failures** -- tool fails N times in a row

Source: https://relevanceai.com/changelog/agent-alerts-real-time-monitoring-and-notifications-for-your-ai-agents

**Limitation:** cannot dynamically route notifications to different channels based on agent logic. If routing is required, build a custom notification tool that takes `channel_id` as a param and bypass the Alerts system.

---

## Custom Slack App Setup

When a customer wants a branded bot (not "@Relevance AI"), create a Slack App in their workspace and connect it as a custom OAuth integration. Required bot-token scopes:

| Scope | Why |
|---|---|
| `chat:write` | Post messages |
| `chat:write.public` | Post to channels without an explicit invite |
| `channels:read` **or** `channels:join` | List / auto-join public channels |
| `users:read.email` | Resolve users by email |
| `im:write` | Send DMs |
| `im:read` | Read DM threads (required for bidirectional DM threading) |

Messages Tab: enable **"Allow users to send Slash commands and messages from the messages tab"** in the Slack app's App Home settings -- without this, DMs to the bot don't deliver.

Known scope gap: the Send Message tool's **Reply-by-UserID / Reply-by-Email** paths are currently broken pending an `im:write` scope re-submission to the Slack marketplace. **Reply-by-ChannelID works.** Track internally before promising two-way DM with email/UserID inputs.

If a customer reports "Slack replies stopped working", the first-line fix is almost always re-OAuth with explicit `chat:write`, `channels:read`, `im:write`, `im:read` checked.

---

## OAuth -- Build Rules

Apply the universal OAuth rules from `.claude/rules/BUILD_PRACTICES.md`:

- Set OAuth account to **"Set Manually"** by default -- never auto-set
- **Never hardcode** `oauth_account_id` in tool step params. Make it a top-level input param in `params_schema`, add to `state_mapping` as `params.oauth_account_id`, reference as `{{oauth_account_id}}` in the step:

```json
"oauth_account_id": {
  "metadata": {"content_type": "oauth_account", "is_fixed_param": true},
  "type": "string",
  "title": "OAuth Account"
}
```

- Use the **same** Slack OAuth account across a tool suite -- don't mix the native Relevance AI bot and a custom app in the same agent unless necessary
- For autonomous execution, set a `default` value for `oauth_account_id` so the agent doesn't enter `pending-approval` -- see `.claude/rules/BUILD_PRACTICES.md` "Fixed Params and Agent Autonomy"

---

## Data Residency

Slack sends every event to a single global webhook (Slack only supports one endpoint per app). Relevance runs US / EU / AU regions; a US-based routing table maps `workspace_id → region` and forwards events to the correct data plane. If a customer in a regulated industry asks where their Slack message data lands, the answer is: the region their workspace is registered to on Relevance AI, regardless of the global Slack webhook entry point.

---

## Debugging Checklist

When Slack "isn't working", check in this order -- most common failures first:

1. **Re-OAuth the Slack connection** -- Integrations page → Slack → Reconnect. Older installs don't pick up scope updates automatically.
2. **Bot is in the channel** -- `/invite @Relevance AI` (or the customer's bot name). The bot can't read channels it's not in.
3. **DM dropdown empty?** -- user needs to send the bot any message first. Tell the customer to DM the bot once, then retry trigger setup.
4. **Editor+ permission on the agent** -- DM triggers require the user to have Editor rights on the target agent.
5. **Email mismatch** -- Slack identity email and Relevance AI account email must match for channel visibility + user resolution.
6. **Rich text truncation** -- if the trigger payload looks one-liner-ish, refetch the full message via `slack_api_call` + `conversations.history`.
7. **Double replies?** -- agent has both a Slack trigger and a `slack_send_message` tool attached; remove the tool unless it's posting to a different channel.
8. **Private channel retrieval failing?** -- switch from `slack_retrieve_message` to `slack_api_call` with a hardcoded channel ID.
9. **Custom app DMs not delivering** -- "Allow users to send Slash commands and messages from the messages tab" not enabled in App Home settings.
10. **Scope errors (`missing_scope`)** -- re-OAuth with the full scope list in "Custom Slack App Setup" above.

---

## Known Limitations (summary)

- Slack triggers collapse rich-text messages to plain text, surface only first line (`PLATFORM_MECHANICS.md` "Known Limitations")
- `slack_retrieve_message` is public-channels-only (`BUILD_PRACTICES.md` "Slack")
- One `slack_trigger` per agent -- workaround: workforce with multiple agents
- Cannot dynamically route notifications to different channels based on runtime logic -- workaround: custom send tool
- Send Message reply-by-Email / reply-by-UserID currently broken; reply-by-ChannelID works
- Trigger + Send Message tool on the same agent produces double replies
- DMs don't appear in trigger dropdown until user messages bot at least once
- Slack API rate limits apply (channel listing + profile lookups are Tier 4: 100+ per minute)

---

## Reference Implementations

- `playbooks/use-cases/synthesis-agent-patterns.md` -- Slack-sourced data synthesis with source attribution

Marketplace templates: https://marketplace.relevanceai.com/integrations/slack

Tool icon URL: `https://upload.wikimedia.org/wikipedia/commons/d/d5/Slack_icon_2019.svg` (`build-kit/agents/tools/tool-icon-urls.md`).

---

## Glossary

| Term | Definition |
|---|---|
| `thread_ts` | Slack timestamp of the parent message in a thread; primary key for thread continuity |
| `channel_id` | Stable identifier for a channel. Prefix: `C` (public) / `G` (private) / `D` (DM) |
| `workspace_id` | Slack workspace (team) identifier. Used by Relevance for region routing |
| `external_relay` | The sync config object Slack triggers ride on; one per agent |
| mrkdwn | Slack's markdown dialect (see "Message Formatting") |
| Block Kit | Slack's structured message format for rich layouts -- use `slack_message_advanced` |
| Bot token | `xoxb-...` -- used by Slack apps; scopes determine capabilities |
| User token | `xoxp-...` -- impersonates a user. Relevance is piloting user-token support for search scenarios |

---

## Further Reading

**Official (public)**
- Slack integration docs: https://relevanceai.com/docs/integrations/popular-integrations/slack
- Slack landing page: https://relevanceai.com/slack
- Changelog -- two-way replies (2025-07-06): https://relevanceai.com/changelog/chat-with-your-ai-agent--and-get-replies--in-slack
- Changelog -- Agent Alerts (2025-12-04): https://relevanceai.com/changelog/agent-alerts-real-time-monitoring-and-notifications-for-your-ai-agents

**Related kit content**
- `.claude/rules/BUILD_PRACTICES.md` -- OAuth rules, `slack_retrieve_message` gotcha, public-vs-private channel matrix
- `.claude/rules/PLATFORM_MECHANICS.md` "Known Limitations" -- rich-text truncation
- The remote MCP loads `managing-relevance-agents` (native trigger mechanics) and `managing-relevance-tools` (all native step names) on demand
