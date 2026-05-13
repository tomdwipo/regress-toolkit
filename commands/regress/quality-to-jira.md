# Quality-to-Jira Command

Read weekly quality report output, deduplicate findings against existing Jira tickets,
and create actionable Task tickets in Backlog with full field mapping.

Arguments: $ARGUMENTS

## Prerequisites

1. Check that `build/reports/quality-summary.json` exists in the project root.
   If it does NOT exist, stop and tell the user:
   "No quality report found. Run `./scripts/quality-report.sh` first."

2. Read the `date` field from `quality-summary.json`.
   Calculate days since that date compared to today.
   If the report is older than 7 days, WARN the user:
   "Report is from {date} ({N} days old). Run `./scripts/quality-report.sh` for fresh data?"
   Ask whether to proceed or stop. If user says proceed or if running non-interactively, continue.

## Step 1: Read Quality Reports

Read these files from the project root:

### Primary (structured data)
- `build/reports/quality-summary.json` — JSON with all metrics, counts, per-module coverage

### Detail reports (file paths + line numbers for ticket descriptions)
Only read reports for categories with non-zero findings in quality-summary.json:

- `build/reports/ui-overdraw/index.html` — if `staticAnalysis.uiOverdraw.fail > 0`
  Table rows: Screen File, Status (FAIL/WARN/PASS), Score, Patterns Detected, Module Path
- `build/reports/memory-leak/index.html` — if `staticAnalysis.memoryLeak.high > 0`
  Table rows: File, Status, Score, Patterns with line numbers (L:NNN format), Path
- `build/reports/storage-io/index.html` — if `staticAnalysis.storageIo.high > 0`
  Table rows: File, Status, Score, Patterns with line numbers (L:NNN format), Path
- `build/reports/battery-drain/index.html` — if `staticAnalysis.batteryDrain.high > 0 OR medium > 0`
  Table rows: File, Status, Score, Patterns with line numbers (L:NNN format), Path
- `build/reports/app-size/index.html` — if APK size concerns (totalMB > 100 or nativeMB > 50)
  Size by Category table + Native Libraries by ABI
- `app/build/reports/lint-results-developmentDebug.xml` — if `lint.errors > 0`
  XML: issue id, severity, message, category, file location

### Production data (if Production Intelligence Agent ran)
- `/tmp/auto-workflow/production/production-summary.json` — if this file exists, include its findings in the same dedup + ticket creation flow
- Production tickets use labels `["production-scan", "{category-in-kebab-case}"]` instead of `["quality-scan", "{category}"]`

### Play Policy detail reports (per module)
For each module with warnings > 0 in quality-summary.json playPolicy data:
- `{module}/build/reports/lint-results-debug.xml` — XML with issue id, severity, category, location

Play Policy modules to check: core-analytics, core-data, core-messaging, core-ui, core-utils, feature-account-group, feature-beneficiary, feature-biller, feature-lending, feature-login-qr, feature-mobile-token, feature-modules, feature-pending-task, feature-pin, feature-transaction-history, input-password, libs-permission

## Step 2: Group Findings Into Candidate Tickets

Parse the reports and group findings into candidate tickets using these rules:

### Grouping Rules

| Category | Source | Group By | Ticket Summary Format |
|----------|--------|----------|----------------------|
| LINT | lint XML | rule ID (e.g., `UnusedImport`) | `fix: lint {ruleId} in {module}` |
| PLAY_POLICY | per-module lint XML | check name (e.g., `TrustAllX509TrustManager`) | `fix: play policy {checkName} in {N} modules` |
| COVERAGE | quality-summary.json | per module with status=FAIL | `test: improve coverage for {module} ({current}% to {threshold}%)` |
| MEMORY_LEAK | memory-leak HTML | per file with HIGH severity | `fix: memory leak in {filename} ({patternType})` |
| UI_OVERDRAW | ui-overdraw HTML | per module (group FAIL screens by module path prefix) | `fix: UI overdraw in {module} ({N} screens)` |
| STORAGE_IO | storage-io HTML | per file with HIGH severity | `fix: storage I/O on main thread in {filename}` |
| BATTERY | battery-drain HTML | per file with HIGH/MEDIUM severity | `fix: battery drain pattern in {filename}` |
| SECURITY | play policy lint XML | per check (TrustAllX509TrustManager, SSLCertificateSocketFactory) | `fix: security {checkName} in {N} files` |
| M2M3_MIXING | play policy lint XML | per module with UsingMaterialAndMaterial3Libraries | `refactor: migrate {module} from M2 to M3` |
| APK_SIZE | app-size HTML | per optimization opportunity (ABI split, native libs, etc.) | `fix: reduce APK size - {opportunity}` |
| CRASH | production-summary.json | per crash issue | `fix: crash in {screenOrFile} affecting {N} users` |
| ANR | production-summary.json | per ANR pattern | `fix: ANR in {screenOrFile} ({anrRate}%)` |
| PERFORMANCE | production-summary.json | per trace/screen | `fix: slow {screen} ({p95}ms avg start)` |
| USER_FEEDBACK | production-summary.json | per review theme | `fix: user complaint — {theme} ({N} reviews)` |
| FUNNEL_DROP | production-summary.json | per funnel step | `fix: {funnelStep} drop-off ({dropPct}% loss)` |

### Special Grouping Notes

- **SECURITY** is a subset of PLAY_POLICY: extract `TrustAllX509TrustManager` and `SSLCertificateSocketFactory` checks into their own SECURITY category. Do NOT also create a PLAY_POLICY ticket for them.
- **M2M3_MIXING** is a subset of PLAY_POLICY: extract `UsingMaterialAndMaterial3Libraries` warnings into their own M2M3_MIXING category. Do NOT also create a PLAY_POLICY ticket for them.
- **UI_OVERDRAW** groups by module prefix (e.g., all FAIL screens in `feature-lending/` = 1 ticket), NOT 1 ticket per screen.
- **COVERAGE** only creates tickets for modules with status=FAIL (below threshold).
- **LINT** only creates tickets if errors > 0 or significant new warnings (> 5 per rule).
- **APK_SIZE** only creates tickets if total APK > 100 MB or native libs > 50 MB.

For each candidate ticket, record:
- `category`: one of the 15 categories above
- `summary`: formatted summary string using the format from the table
- `files`: list of {path, lineNumbers[], pattern} extracted from detail reports
- `count`: number of occurrences/affected files
- `severity`: HIGH/MEDIUM/LOW based on the worst finding in the group
- `dedupKey`: "{category}::{module_or_rule}::{specific_identifier}" for matching against Jira

## Step 3: Deduplicate Against Jira

Search for existing quality-scan tickets using Atlassian MCP:

```
mcp__atlassian__jira_search:
  jql: project = DS AND labels IN ("quality-scan", "production-scan") AND status NOT IN (Done, Closed)
  fields: "summary,status,labels,description,created"
  limit: 100
```

If more than 100 results, paginate using `nextPageToken` until all are retrieved.

### Dedup Logic

For each candidate ticket, compare against the existing Jira tickets:

1. **MATCH by label + keyword**: An existing ticket matches if it has:
   - Same category in its labels (e.g., label "memory-leak" matches category MEMORY_LEAK)
   - AND same module name, rule ID, or filename keyword appears in its summary

2. **Decision per candidate**:
   - **No match found** → mark as **CREATE**
   - **Match found** → mark as **SKIP** (already tracked, no action needed)
   - If you can determine the count/severity changed from the existing ticket description → mark as **UPDATE** (add comment with new numbers)

## Step 4: Auto-Classify Jira Fields

Use this static mapping table to determine Story Points, Choose Appendix v3, and SP Type for each candidate:

### Field Mapping Table

| Finding Type | SP | Choose Appendix v3 IDs (multi-select) |
|---|---|---|
| LINT (single file, 1 rule) | 1 | `[{id: "11507"}]` {{JIRA_KEY}} Low |
| LINT (multi-file, 1 rule) | 2 | `[{id: "11515"}, {id: "11516"}]` {{JIRA_KEY}} Low + {{JIRA_KEY}} Low |
| PLAY_POLICY (per check) | 2 | `[{id: "11507"}, {id: "11516"}]` {{JIRA_KEY}} Low + {{JIRA_KEY}} Low |
| COVERAGE (add tests, coverage >= 30%) | 2 | `[{id: "11516"}]` {{JIRA_KEY}} Low |
| COVERAGE (new test class, coverage < 30%) | 3 | `[{id: "11564"}, {id: "11565"}]` {{JIRA_KEY}} Med + {{JIRA_KEY}} Med |
| MEMORY_LEAK (per file) | 2 | `[{id: "11515"}, {id: "11516"}]` {{JIRA_KEY}} Low + {{JIRA_KEY}} Low |
| UI_OVERDRAW (per module) | 2 | `[{id: "11507"}]` {{JIRA_KEY}} Low |
| STORAGE_IO (per file) | 2 | `[{id: "11515"}, {id: "11516"}]` {{JIRA_KEY}} Low + {{JIRA_KEY}} Low |
| BATTERY (per file) | 2 | `[{id: "11515"}]` {{JIRA_KEY}} Low |
| SECURITY (per check) | 3 | `[{id: "11515"}, {id: "11516"}]` {{JIRA_KEY}} Low + {{JIRA_KEY}} Low |
| M2M3_MIXING (per module) | 5 | `[{id: "11562"}]` {{JIRA_KEY}} Med |
| APK_SIZE (per opportunity) | 3 | `[{id: "11615"}]` {{JIRA_KEY}} High |
| CRASH (HIGH — >100 users) | 3 | `[{id: "11508"}]` {{JIRA_KEY}} High |
| CRASH (MEDIUM — 10-100 users) | 2 | `[{id: "11507"}]` {{JIRA_KEY}} Low |
| CRASH (LOW — <10 users) | 1 | `[{id: "11507"}]` {{JIRA_KEY}} Low |
| ANR | 3 | `[{id: "11508"}, {id: "11516"}]` {{JIRA_KEY}} High + {{JIRA_KEY}} |
| PERFORMANCE (app start) | 2 | `[{id: "11515"}]` {{JIRA_KEY}} Medium |
| PERFORMANCE (screen render) | 2 | `[{id: "11515"}]` {{JIRA_KEY}} Medium |
| USER_FEEDBACK | 2 | `[{id: "11507"}]` {{JIRA_KEY}} Low |
| FUNNEL_DROP | 2 | `[{id: "11507"}]` {{JIRA_KEY}} Low |

### Fixed Fields (all tickets)
- Story Points Type (`customfield_10796`): `{id: "10229"}` (SP Tech Debt)
- Story Point Type v2 (`customfield_11312`): cascading select with `parent: {id: "10949"}` (Technical)
- **Assignee (top-level `assignee` kwarg)**: Resolve at runtime via `Read` on `~/.claude/workflow-config.yaml` → `issue_tracker.assignee` (email). Pass that exact string as the top-level `assignee` parameter. MUST match the ticket's reporter (API token owner). Do NOT hardcode an email — the framework is portable. NEVER `assignee_account_id`, NEVER inside `additional_fields`.
- Project: `DS`
- Issue Type: `Task`
- Content format: `markdown`
- **Choose Appendix v3 (`customfield_11543`): REQUIRED — never empty.** Use the mapping table above; default `[{id: "11507"}]` ({{JIRA_KEY}} Low) if no match.

## Step 5: Create Jira Tickets

For each candidate marked as **CREATE**:

### 5a. Create the ticket

Use `mcp__atlassian__jira_create_issue` with:
- `projectKey`: `DS`
- `issueTypeName`: `Task`
- `summary`: the formatted summary from Step 2
- `assignee`: `<email read at runtime from ~/.claude/workflow-config.yaml :: issue_tracker.assignee>` — top-level kwarg, NOT `assignee_account_id`, NOT nested under `additional_fields`
- `contentFormat`: `markdown`
- `description`: use this template, filled with actual data from the findings:

```
## Quality Finding

**Category:** {category}
**Severity:** {severity}
**Source:** Weekly Quality Report Week {weekNumber} ({date})
**Report Branch:** {branch}

## Details

**Affected files:** {count}

| File | Line(s) | Pattern |
|------|---------|---------|
| `{path}` | {lines} | {pattern description} |

(Include up to 20 files. If more, add "... and {N} more files")

## Suggested Fix

{Use the appropriate template below based on category}

## Acceptance Criteria

- [ ] Fix applied to all listed files
- [ ] No new lint warnings introduced
- [ ] Unit tests pass
- [ ] Quality report shows improvement in next run

---
*Auto-generated by /quality-to-jira from Week {weekNumber} report*
```

- `additional_fields`:
  - `customfield_10604`: {SP value from mapping}
  - `customfield_11543`: {array of Appendix IDs from mapping}
  - `customfield_10796`: `{id: "10229"}`
  - `customfield_11312`: `{parent: {id: "10949"}}`
  - `labels`: `["quality-scan", "{category-in-kebab-case}"]`

### Suggested Fix by Category

- **LINT**: Fix the `{ruleId}` lint violation. Check each listed file and apply the recommended fix from the lint documentation.
- **PLAY_POLICY**: Address `{checkName}` Play Policy violation to ensure Google Play compliance.
- **COVERAGE**: Add unit tests for `{module}` to bring instruction coverage from {current}% to {threshold}% (gate requirement). Focus on uncovered branches and edge cases.
- **MEMORY_LEAK**: Fix memory leak pattern in `{filename}`: {pattern}. Ensure proper lifecycle cleanup, avoid holding Context in ViewModel/Singleton, use WeakReference where appropriate.
- **UI_OVERDRAW**: Reduce GPU overdraw in `{module}` screens. Remove unnecessary background layers, flatten nested Surfaces/Scaffolds, avoid drawBehind where not needed.
- **STORAGE_IO**: Move {pattern} off the main thread. Use coroutines (Dispatchers.IO) or WorkManager for disk operations. Replace runBlocking with suspending calls.
- **BATTERY**: Fix battery drain pattern: {pattern}. Release WakeLock properly, use JobScheduler instead of AlarmManager, avoid GPS polling.
- **SECURITY**: Replace TrustAllX509TrustManager with proper certificate validation. Use network security config for debug builds only. Never trust all certificates in production.
- **M2M3_MIXING**: Migrate `{module}` from Material 2 to Material 3 components. Replace M2 imports with M3 equivalents.
- **APK_SIZE**: Specific recommendation based on finding (enable ABI splits, compress native libs, remove unused assets, etc.)

### 5b. Set Story Points UI field (HARD REQUIREMENT — verify, do NOT skip)

`customfield_10005` ("Story Points" UI column the board renders) is NOT on the
DS project create screen, so the 5a create call CANNOT set it. You MUST run a
follow-up `jira_update_issue` immediately after every create. Do NOT collapse this
into 5a, do NOT skip it because "SP is already on customfield_10604" — those
are TWO DIFFERENT FIELDS:

- `customfield_10604` (Story point estimate) — API/system field, settable on create
- `customfield_10005` (Story Points UI) — board column field, post-create edit only

For EVERY ticket created in 5a (without exception), do BOTH steps below:

**Step 5b-i — set the field**

Use `mcp__atlassian__jira_update_issue` with:
- `issue_key`: the key returned from step 5a (e.g., {{JIRA_KEY}})
- `fields`: `'{"customfield_10005": <SP value from mapping — same number passed to customfield_10604>}'`

**Step 5b-ii — verify and re-emit if null**

Use `mcp__atlassian__jira_get_issue` with:
- `issue_key`: the same key
- `fields`: `"customfield_10005,customfield_10604"`

If the response shows `customfield_10005` is null/missing, re-emit step 5b-i.
If still null after the second attempt, log a WARNING in the output summary
("SP UI Set: NO — manual fix needed"). NEVER claim a ticket is complete with
`customfield_10005` null — Sprint Mover capacity calc reads this field, not 10604.

Past incident: 4 production-scan tickets ({{JIRA_KEY}}..{{JIRA_KEY}}) created 2026-04-28
all had `customfield_10005=null` because the LLM treated 5b as optional after
seeing `customfield_10604` was set. Operator backfilled manually. This step is
why the verify-and-retry pattern is mandatory.

### 5c. Processing order

Process candidates in this priority order:
1. SECURITY (highest priority — compliance risk)
2. MEMORY_LEAK (stability risk)
3. STORAGE_IO (ANR risk)
4. BATTERY (user experience)
5. LINT (code quality)
6. PLAY_POLICY (store compliance)
7. COVERAGE (test gaps)
8. UI_OVERDRAW (performance)
9. M2M3_MIXING (tech debt)
10. APK_SIZE (lowest priority)

## Step 6: Update Existing Tickets

For each candidate marked as **UPDATE**:

Use `mcp__atlassian__jira_add_comment` with:
- `issue_key`: the matching existing ticket key
- `comment`:

```
**Quality Report Update — Week {weekNumber} ({date})**

| Metric | Previous | Current | Delta |
|--------|----------|---------|-------|
| Count | {old_count} | {new_count} | {diff} |
| Severity | {old_severity} | {new_severity} | {change} |

{If count increased: "Issue is growing — consider prioritizing."}
{If count decreased: "Partial improvement detected — keep going."}

---
*Auto-updated by /quality-to-jira*
```

## Step 7: Output Summary

After processing all candidates, print a summary table:

```
## Quality to Jira Results (Week {weekNumber}, {date})

| Action | Ticket | Category | SP |
|--------|--------|----------|----|
| CREATED | DS-XXXX {summary} | {category} | {sp} |
| SKIPPED | DS-XXXX (already exists) | {category} | - |
| UPDATED | DS-XXXX (comment added) | {category} | - |

**Totals:** {N} created ({total_sp} SP), {N} skipped, {N} updated

All new tickets are in Backlog. Move to "Selected for Development" when ready
for auto-workflow to pick them up.
```

Print this table even if 0 tickets were created (shows dedup is working correctly).
If no findings at all, print: "No actionable findings in quality report. All clean!"
