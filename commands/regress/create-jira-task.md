# Create Jira Task Command

Create a Jira task ticket in the DS project for: $ARGUMENTS

## Instructions

1. Parse the arguments to extract:
   - **Summary**: Short task title (prefix with `fix:`, `feat:`, `refactor:`, `test:`, `docs:` as appropriate)
   - **Description**: Detailed description (if provided)
   - **Story Points**: Numeric value (default: 2 if not specified)
   - **Choose Appendix (v3)**: Benchmark IDs (if provided, e.g. "{{JIRA_KEY}}, {{JIRA_KEY}}")
   - **Sprint**: `active` (default — adds to the currently running sprint), `backlog` (skip sprint assignment), or an explicit sprint id

2. If arguments are unclear, ask the user for clarification before creating.

3. Create the ticket using the Jira MCP tools with these EXACT field mappings:

## Field Mapping (DO NOT SEARCH — use these directly)

| Field | API Field | Type | Required |
|-------|-----------|------|----------|
| Project | `DS` | projectKey | Yes |
| Issue Type | `Task` | issueTypeName | Yes |
| Assignee | `<caller_account_id>` (runtime lookup via `mcp__atlassian__atlassianUserInfo` — never hardcode another engineer's id) | assignee_account_id | Yes |
| **Story Points** (UI) | `customfield_10005` | number | Yes |
| Story point estimate | `customfield_10604` | number | Yes (same value as Story Points) |
| Choose Appendix (v3) | `customfield_11543` | multi-select array of `{id}` | **Required (never empty)** — default `[{id: "11507"}]` ({{JIRA_KEY}} Low) if uncertain |
| Story Points Type | `customfield_10796` | select | Optional |
| Story Point Type (v2) | `customfield_11312` | cascading select | Optional |
| **Sprint** | `customfield_10007` | number (sprint id) | Optional — **note: this org uses `_10007`, NOT the more common `_10010` / `_10020`** |

### Active Sprint Discovery (use when sprint:active is requested)

The active sprint id changes every ~2 weeks, so look it up at runtime:

1. Run `mcp__atlassian__searchJiraIssuesUsingJql` with `jql = "project = DS AND sprint in openSprints()"`, `fields = ["*all"]`, `maxResults = 1` (VPS: `mcp__atlassian__jira_search`).
2. From the response, read `fields.customfield_10007[0].id` — that's the active sprint id (an integer like `9122`).
3. Pass that integer to `customfield_10007` when assigning. The field accepts a single id (not an array) on edit.

Example active sprint payload shape:
```json
"customfield_10007": [{"id": 9122, "name": "DS Sprint 3 Q2 2026", "state": "active", "boardId": 403}]
```

If multiple open sprints exist (rare — usually means a forgotten sprint), prefer the one whose `endDate` is closest to today.

### Choose Appendix (v3) — Common AN- Benchmark IDs

**Low complexity:**
- {{JIRA_KEY}} (id: 11507): Adjust single stand-alone logic function
- {{JIRA_KEY}} (id: 11508): Create screen with max 5 static component (without integration)
- {{JIRA_KEY}} (id: 11509): Create single usecase data layer (remote data source) to API calling
- {{JIRA_KEY}} (id: 11510): Create single use case domain layer (usecase class) to data layer
- {{JIRA_KEY}} (id: 11511): Reproduce legacy crash from crashlytics
- {{JIRA_KEY}} (id: 11512): Event tracker in single screen
- {{JIRA_KEY}} (id: 11513): Create UI state logic with max 5 states
- {{JIRA_KEY}} (id: 11514): Integrate screens' navigation (max 3 screens)
- {{JIRA_KEY}} (id: 11515): Refactor or add 1 generic function
- {{JIRA_KEY}} (id: 11516): Refactor generic function unit test

**Medium complexity:**
- {{JIRA_KEY}} (id: 11560): Create custom component (max 5 custom attribute)
- {{JIRA_KEY}} (id: 11561): Create single screen with 1 recyclerview (max 3 component)
- {{JIRA_KEY}} (id: 11562): Create generic style of a component
- {{JIRA_KEY}} (id: 11563): Create a usecase from domain to data layer
- {{JIRA_KEY}} (id: 11564): Create data source class unit test (max 3 function)
- {{JIRA_KEY}} (id: 11565): Create repository unit test (max 3 function)
- {{JIRA_KEY}} (id: 11566): Integrate 1 class for webview (without research)

**High complexity:**
- {{JIRA_KEY}} (id: 11610): Create single screen with 1 recyclerview and components (max 3)
- {{JIRA_KEY}} (id: 11611): Create single screen of form (max 5 input field and 1 button)
- {{JIRA_KEY}} (id: 11612): Create custom component with logic and attributes (max 3)
- {{JIRA_KEY}} (id: 11613): Research simple technology
- {{JIRA_KEY}} (id: 11614): Research medium-big new technology (Medium complexity)
- {{JIRA_KEY}} (id: 11615): Install new technology after research
- {{JIRA_KEY}} (id: 11616): Create single screen with more than 1 dynamic view group

### Story Points Type Options (customfield_10796)
- SP Product (id: 10228)
- SP Tech Debt (id: 10229)

### Story Point Type (v2) Options (customfield_11312)
- Product (id: 10947)
- Domain User (id: 10948)
- Technical (id: 10949)
- Meeting (id: 11046)
- Other (id: 10950)

## Creation Steps

1. **Resolve assignee** — call `mcp__atlassian__atlassianUserInfo` once and use the returned `account_id`. Never hardcode another engineer's id.

2. **Resolve active sprint** (skip if user passed `sprint:backlog` or an explicit id) — call `mcp__atlassian__searchJiraIssuesUsingJql` with the query in §Active Sprint Discovery and read `customfield_10007[0].id`.

3. Use `mcp__atlassian__createJiraIssue` with:
   - `cloudId`: `{{JIRA_HOST}}`
   - `projectKey`: `DS`
   - `issueTypeName`: `Task`
   - `summary`: parsed from arguments
   - `assignee_account_id`: from step 1
   - `description`: parsed from arguments (use markdown contentFormat)
   - `contentFormat`: `markdown`
   - `additional_fields`: include `customfield_10005`, `customfield_10604`, and `customfield_11543` (required — never empty)

4. Then use `mcp__atlassian__editJiraIssue` to set:
   - `customfield_10005` (Story Points) — may not be available on the create screen.
   - `customfield_10007` (Sprint) — pass the sprint id as a number (e.g. `9122`), not an array. Skip this if user passed `sprint:backlog`.

5. Return the ticket URL and summary of fields set.

## VPS variant (snake_case)

This slash command is intended for local Mac use where the Atlassian MCP exposes camelCase tools (`createJiraIssue`, `editJiraIssue`, `atlassianUserInfo`, `assignee_account_id`). The same fields apply on VPS, but the **tool/param names differ**:

| Mac (camelCase) | VPS (snake_case) |
|---|---|
| `mcp__atlassian__createJiraIssue` | `mcp__atlassian__jira_create_issue` |
| `mcp__atlassian__editJiraIssue` | `mcp__atlassian__jira_update_issue` |
| `mcp__atlassian__getJiraIssue` | `mcp__atlassian__jira_get_issue` |
| `mcp__atlassian__searchJiraIssuesUsingJql` | `mcp__atlassian__jira_search` |
| `mcp__atlassian__addCommentToJiraIssue` | `mcp__atlassian__jira_add_comment` |
| `mcp__atlassian__atlassianUserInfo` | *(no equivalent)* — resolve assignee from `~/.claude/workflow-config.yaml :: issue_tracker.assignee` |
| top-level kwarg `assignee_account_id` | top-level kwarg **`assignee`** (string: email / displayName / accountId) |

The VPS API silently drops `assignee_account_id` (unknown kwarg) → empty Assignee on the ticket. Always use the table above when authoring agent prompts that run via `claude -p` on VPS.

## Example Usage

```
/create-jira-task fix: align RT/RW fields on KYC screen | sp:2 | appendix: {{JIRA_KEY}}(Low), {{JIRA_KEY}}(Low)
/create-jira-task feat: add balance validation to transfer | sp:3 | sprint:active
/create-jira-task refactor: extract common OTP module | sp:5 | appendix: {{JIRA_KEY}}(Low), {{JIRA_KEY}}(Medium) | sprint:backlog
/create-jira-task chore: bump Hilt to 2.59 | sp:1 | sprint:9122
```

Default behaviour when `sprint:` is omitted: **add to the active sprint** (`sprint:active`).
Use `sprint:backlog` to leave it in the backlog.

## Output Format

After creating, display:
```
Ticket: DS-XXXX (link)
Summary: ...
Story Points: X
Choose Appendix (v3): ...
Sprint: <sprint name> (id <N>) | or "Backlog (no sprint)"
Status: Backlog
```

> Note: status stays at **Backlog** even when added to an active sprint — sprint membership and workflow status are independent in this org's Jira. Only "Selected for Development" auto-enters the dev pipeline; do not auto-transition new tickets out of Backlog.
