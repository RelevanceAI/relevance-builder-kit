# Integration Reference

Guides for external platforms commonly used in builds. Each file covers auth, key endpoints, quick start, and glossary.

## Contents

| Platform | File | Auth Method |
|----------|------|-------------|
| Avoma | `avoma.md` | API key |
| Clay | `clay.md` | Webhook (bidirectional) |
| HubSpot | `hubspot.md` | OAuth or API key |
| LinkedIn | `linkedin.md` | OAuth |
| Outreach.io | `outreach.md` | Native OAuth |
| Salesforce | `salesforce.md` | Native OAuth + SOQL triggers |
| SalesLoft | `salesloft.md` | API key |
| Slack | `slack.md` | Native OAuth (bidirectional triggers, threads, buttons) |
| ZoomInfo | `zoominfo.md` | PKI certificate |
| SharePoint | `sharepoint.md` | Microsoft OAuth |

- `template.md` -- Template for adding new integration guides

## How to Add an Integration

Copy `template.md` and fill in the bracketed placeholders. Follow the patterns in `.claude/rules/BUILD_PRACTICES.md` (Integrations section): prefer native integrations, same OAuth account across a tool suite.

## Routing

Come here when:

- Connecting an external system to Relevance AI
- Looking up auth method or API endpoints for a specific platform
- Building integration tools and need the quick-start guide

## See Also

- `build-kit/CLAUDE.md` -- build-kit hub
- `.claude/rules/BUILD_PRACTICES.md` -- integration build rules (prefer native, OAuth consistency)
- `build-kit/tools/` -- tool-building reference for the Relevance AI side
