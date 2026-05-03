# ZoomInfo Integration

> **ZoomInfo** is a B2B data enrichment platform providing contact details, firmographics, and technographics. Integrates with Relevance AI via PKI certificate authentication (API key).

## Why It Matters

ZoomInfo is the most common enterprise enrichment data source. The integration is one-way (Relevance reads from ZoomInfo, never writes back) and low-risk from a security perspective. However, the PKI authentication is non-standard and the most common source of setup failures.



## API Version Limitations

Relevance AI currently supports only ZoomInfo's **legacy APIs**. The newer ZoomInfo API versions offer more queryable parameters but are not yet integrated.

**Current status:**
- Legacy APIs only -- functional but limited parameter options
- New APIs available but unsupported -- more query flexibility, unexplored integration
- No timeline for new API support

For customers asking about specific query capabilities, check if the limitation is due to legacy API constraints rather than a Relevance AI restriction.
## Authentication

ZoomInfo uses PKI certificate-based authentication with three components:

1. **ZoomInfo Client ID** -- UUID format: `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`
2. **ZoomInfo Email** -- the admin email that generated the API key (NOT a regular salesperson account)
3. **ZoomInfo Private Key** -- must include the header and footer:

```
-----BEGIN PRIVATE KEY-----
XXXXXXXXX
-----END PRIVATE KEY-----
```

### Common Auth Failure

If any of the three components is incorrect, you get a **jwt error**. The most common mistakes:
- Using a salesperson's email instead of the admin email that generated the key
- Omitting the `-----BEGIN PRIVATE KEY-----` / `-----END PRIVATE KEY-----` wrapper
- Using the wrong client ID format

API docs: https://docs.zoominfo.com/docs/authentication

## Security Profile

ZoomInfo has a straightforward security story for customer conversations:

| Aspect | Detail |
|--------|--------|
| Data flow | One-way only (Relevance AI > ZoomInfo). No data sent back. |
| Data access | Public enrichment data only (company info, contact details, professional data) |
| IP allowlisting | Not supported by ZoomInfo |
| Risk classification | Low -- no sensitive data exposure, no customer data transmission |
| Key rotation | Annual rotation recommended for enterprise customers |
| Service accounts | Dedicated accounts for production, no shared admin accounts |

### Security Q&A for Customer Conversations

**"How does authentication work?"** -- PKI certificates with private key, account email, and client secret. No standard API keys.

**"Is data flowing from our systems to ZoomInfo?"** -- No. One-way retrieval only.

**"What data is accessed?"** -- Standard business enrichment data available to all ZoomInfo customers: company information, contact details, professional data.

**"Can we implement IP allowlisting?"** -- No, ZoomInfo does not provide IP-based access control.

## Common Integrations

| Integration | Trigger | Agent Action | Output |
|------------|---------|-------------|--------|
| Contact enrichment | New lead in CRM | Query ZoomInfo for contact details | Phone, email, LinkedIn URL, job title |
| Account research | Pre-call preparation | Query ZoomInfo for company data | Employee count, revenue, tech stack |
| Lead scoring | Batch enrichment | Enrich leads with firmographic data | Company size, industry, location |

## Gotchas

- The admin email that generated the key is NOT necessarily the same as a salesperson's ZoomInfo login
- Private key must include the BEGIN/END wrapper lines
- jwt errors always mean one of the three auth components is wrong
- ZoomInfo has API rate limits -- use the "enrich last" pattern (qualify first, enrich finalists)
- No write operations -- ZoomInfo is strictly read-only enrichment

## Related Files

- `playbooks/enrichment-agent-patterns.md` -- Enrichment patterns (cost-aware, tool chains)
- `build-kit/integrations/salesforce.md` -- Salesforce (common upstream for enrichment triggers)
- `build-kit/integrations/clay.md` -- Clay (alternative/complementary enrichment)
