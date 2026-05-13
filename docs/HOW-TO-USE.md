# How to use the commands

Quick reference for what each slash command does and when to reach for it. For the full prompt of each command, read the matching `.md` file under `commands/`.

## A typical feature, end to end

```
┌────────────┐ /trd        ┌──────────────┐ /plan-first   ┌──────────────┐
│ PRD on     │────────────▶│ TRD-Foo.md   │──────────────▶│ Options A/B/C│
│ Confluence │             └──────────────┘               └──────┬───────┘
└────────────┘                                                   │
                                                          human picks
                                                                 ▼
┌────────────┐ /create-    ┌──────────────┐ /breakdown-   ┌──────────────┐
│ Jira       │ jira-task   │ Plan-Foo.md  │◀──────────────│ Option B     │
│ ticket     │◀────────────│              │  design       │              │
└────┬───────┘             └──────────────┘               └──────────────┘
     │
     │ Gate 2: human moves to In Progress
     ▼
┌────────────┐ /do-implementation ┌──────────────┐  /push-pr   ┌──────────┐
│ Branch     │───────────────────▶│ Commits      │────────────▶│ PR open  │
│ created    │                    │ + tests pass │             │  Gate 4  │
└────────────┘                    └──────────────┘             └────┬─────┘
                                                                    │
                                                  Gates 4 + 5: human review + merge
                                                                    ▼
┌──────────────┐ /feature-report  ┌──────────────┐  /qa-align    ┌──────────┐
│ Merged on    │─────────────────▶│ feature-     │──────────────▶│ QA       │
│ main         │                  │ report/      │               │ handoff  │
└──────────────┘                  └──────────────┘               └──────────┘
```

## Universal commands (any project)

### `/plan-first`

> "Give me a few options for X, simplest first, with pros/cons and a comparison matrix."

The first command in the pipeline. Refuses to start coding. Produces 2–4 options, asks you to choose. ASCII diagrams encouraged.

**When to use:** any non-trivial feature where the approach is unclear.

### `/breakdown-design`

> "Take Option B from /plan-first and write a step-by-step implementation plan."

Output: file paths, function signatures, code examples, test cases. Has explicit "Avoid Repeating Mistakes" gates referencing CLAUDE.md Common Issues.

**When to use:** after `/plan-first` produced a choice you want to execute.

### `/do-implementation`

> "Execute the plan in this file."

Reads the breakdown file, edits code, runs build, runs tests, surfaces failures. Stays in a tight loop until tests pass.

**When to use:** plan written, ready to ship.

### `/mini-prd`

> "Quick mini-PRD: goal, requirements, acceptance criteria."

Lighter weight than `/trd`. Use for small bugfixes or scoped changes that don't warrant a full TRD.

### `/trd`

> "Build a Technical Requirements Document from PRD + Figma + BE TRD + QA TRD + codebase."

Pulls inputs from Confluence (PRD), Figma (screens), and the codebase (existing patterns). Output lands in `.docs/trd/`.

### `/search`, `/search-smart`

> "Find me references to FooManager across the codebase."

`/search` is keyword-driven. `/search-smart` adds query rewriting and semantic similarity.

### `/update-doc`

> "Update the README to reflect the new flag I added."

Reads the diff, updates docs.

### `/wireframe-image`

> "Turn this design image into an ASCII wireframe."

Useful for sketching UIs into commit messages or PR descriptions.

## Mobile commands

### `/design`

> "Design a Compose screen following our design-system rules."

Reads `DESIGN_SYSTEM_RULES.md`, generates `*.kt` Compose code that respects the system.

### `/ui-test`

> "Compare the new screen against the benchmark screenshot."

Renders the screen, diffs against `benchmark/*.png`, surfaces mismatches.

### `/mobile-analysis`

> "Walk the mobile codebase and give me a summary."

Module map, dependency graph, hot spots, suspicious patterns.

### `/feature-report`

> "After implementation: produce a PRD-vs-code compliance matrix."

Output: `.docs/feature-report/{name}/{README, COMPLIANCE_MATRIX, RESPONSIBILITY_SPLIT, QA_ALIGNMENT, TICKETS}.md`.

### `/qa-align`

> "Compare what was built against the QA TRD and write a handoff doc."

The QA team reads this. Highlights deltas and known gaps.

## Regress commands

### `/deep-analysis`, `/full-analysis`

> "Read the whole repo and tell me what you found."

`/deep-analysis` focuses on a subsystem. `/full-analysis` covers the whole repo (slow, expensive — use rarely).

### `/create-jira-task`

> "Create a Jira ticket with the right fields."

Writes via `mcp__atlassian__createJiraIssue` with type, priority, story points, custom fields. Prompts you to choose assignee.

### `/prd-align`

> "Tracker of what the PRD says vs what was built."

Output is a checkboxed matrix you update over time.

### `/quality-to-jira`

> "Take the latest quality-scan summary and create one Jira ticket per finding (deduped)."

Reads `quality-summary.json`, fans out tickets.

### `/quality-publish-confluence`

> "Publish the quality report to Confluence."

Full-replace of the target Confluence page. Has a pre-flight check that rejects malformed bodies.

### `/production-to-jira`

> "Production-scan findings → Jira tickets."

Similar to `/quality-to-jira` but sourced from Crashlytics + Play Vitals + Sentry.

### `/push-pr`

> "Push current branch and open a PR with Jira context."

Detects ticket ID from branch name, fetches Jira summary, opens the PR with auto-populated description.

## Agents (delegate to a specialist)

Agents are invoked via the Agent tool from any session. Use when:

- The task has clear specialty boundaries.
- You want the work parallelised (multiple agents in one message).
- You want context-window protection on a long search.

See `agents/AGENT-DELEGATION-RULES.md` for routing guidance.
