# LinkedIn (via Unipile)

> **LinkedIn** is the primary channel for B2B outreach to senior decision-makers. Integrates with Relevance AI via **Unipile** (native `linkedin_action` transformation).

## Why It Matters

LinkedIn outreach is core to BDR/SDR agent builds. Understanding account-level limits is critical because exceeding them gets accounts restricted. The limits differ significantly between free and premium accounts.

## LinkedIn Account Limits

### Free Accounts

| Action | Monthly Limit | Notes |
|--------|--------------|-------|
| Connection requests (no note) | ~150/month | Send without a message to stay within this limit |
| Connection requests (with note) | 5/month | Severely limited. Avoid using notes on free accounts |
| InMail | 0 | Not available on free accounts |

**Default:** Send all connection requests WITHOUT notes on free accounts. 5/month is too few for any meaningful outreach volume.

### Premium / Sales Navigator Accounts

| Action | Monthly Limit | Notes |
|--------|--------------|-------|
| Connection requests (with note) | Higher limit (varies by tier) | Premium allows more notes per month |
| InMail | Varies by tier | Sales Navigator includes InMail credits |

**Note:** Exact premium limits vary by subscription tier and LinkedIn's evolving policies. Check current limits when scoping a build.

### General LinkedIn Limits (All Account Types)

- LinkedIn may restrict accounts that send too many connection requests too quickly (weekly velocity matters, not just monthly totals)
- Connection requests from accounts with low acceptance rates get throttled
- New accounts have lower limits than established ones

## Unipile Integration

### Provider

Unipile is the native LinkedIn integration on Relevance AI. It provides the `linkedin_action` transformation.

### OAuth Session Expiry

Unipile LinkedIn OAuth sessions expire approximately every 2 weeks. When expired:
- **Read actions** (Get Profile, Get Chats) may still work on cached data
- **Write actions** (Send Invitation, Start New Chat, Send Message) fail immediately
- Error: `"The account appears to be disconnected from the provider service"`

Re-authenticate at the Relevance AI Integrations page. Note: re-authentication creates a **new** `oauth_account_id`. All tools referencing the old ID will need updating.

### Connection Request Workaround (No Note)

The `linkedin_action` transformation requires the `message` property on Send Invitation at the platform level. To send a connection request without a note:

- Pass a **single space character** (`" "`) as the message
- This satisfies the platform validation while LinkedIn treats it as no note
- Empty string (`""`) and period (`"."`) are rejected by LinkedIn's API
- A feature request has been submitted to make `message` non-required

### Identifier Format

- **Send Invitation:** Use the LinkedIn **username** (e.g. `johndoe`), NOT the full URL. The transformation passes it directly to Unipile with no slug extraction
- **Get User Profile:** Accepts full URLs. The tool has a built-in slug extraction step

### InMail Body Formatting

InMail (available on Sales Navigator via `Start New Chat`) has its own formatting rules distinct from connection notes or DMs.

**Subject line** (the `title` param on `Start New Chat`):
- Target **25-50 chars**, design for mobile at **30-40 chars** - that's what the prospect sees in their inbox preview
- Always prospect-specific. Never generic ("Quick question", "Hi {{first_name}}" are throwaway lines)
- Store as a dedicated field on the contact record (e.g. `inmail_subject` in the knowledge table) so the agent writes it deliberately, not inline in the prompt

**Body** (the `text` param):
- Supports `\n\n` for **paragraph breaks** - LinkedIn renders them as paragraph separators. One per formula part keeps it scannable on mobile
- When char-counting, **exclude the `\n\n` separators** - they add ~6 chars of non-content per break. Count the content only
- **Under 400 chars = 22% higher response rate.** 400-500 chars is still a good range. Past 500 and response rate drops sharply
- No markdown. LinkedIn renders plain text only - asterisks and hashes show as literal characters

**Example:**
```
Subject: "Relevance AI for Amazon L7s"  (33 chars)

Body:
Saw your post on agent evaluation frameworks last week.

We're working with several GTM orgs at AWS on the same problem - happy to share what's working if useful.

Relevance AI is an agent builder focused on production reliability (not just prototyping).

Open to a 15-min call next week?
```
Body content: ~330 chars (excluding `\n\n` separators).

### Trigger Behavior

- `is_outreach_reply_only: true` only fires on replies to messages sent via `Start New Chat` / `Send Message`
- Connection request acceptance is NOT classified as outreach
- After acceptance, send the first DM via `Start New Chat` to establish outreach classification, then reply triggers work

## Common Integrations

| Integration | Trigger | Agent Action | Output |
|------------|---------|-------------|--------|
| BDR/SDR outreach | Scheduled or manual | Connection request (no note) + DM sequence after acceptance | Personalized LinkedIn outreach |
| Reply handling | LinkedIn reply trigger | Classify reply, draft response, book meeting | Automated conversation management |
| Profile enrichment | On-demand | Get Profile for connection status, role, signals | Contact research data |

## When to Use / When Not to Use

**Use LinkedIn outreach when:**
- Targeting senior decision-makers (CCOs, VPs, Directors)
- Email deliverability is uncertain
- Prospect is active on LinkedIn (recent posts, connections)

**Do not use when:**
- Prospect has no LinkedIn presence
- High-volume cold outreach (>150/month requires multiple accounts or premium)
- Prospect is in a region with low LinkedIn adoption
