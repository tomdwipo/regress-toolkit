# C3 — Component

> Zooming into the content bundle: the regress workflow it encodes — 5 principles, 6 gates, and how commands and agents wire to them.

The toolkit's *files* are containers (C2). Their *meaning* is the **regress workflow** — a way to ship high-stakes mobile code at a steady cadence while keeping a human on every irreversible decision.

## The 5 north-star principles

Lower number wins on conflict.

| # | Principle | Enforced in the bundle by |
|---|-----------|---------------------------|
| 1 | **Human gates are sacred** — machine never merges | `settings.local.json.template` deny-lists `git push --force` + merge ops |
| 2 | **Historian-first** — no phase reads what a prior phase didn't durably write | every command writes to `.docs/<date>/<feature>/` |
| 3 | **Interlocks** — one writer per resource | commands target one branch / one PR at a time |
| 4 | **Alarm rationalization** — findings deduplicate | `/quality-to-jira`, `/production-to-jira` dedupe before filing tickets |
| 5 | **Deterministic replay** — re-runnable from stored inputs | command artefacts record their inputs (PRD URL, Jira ID, Figma node) |

## The 6 gates

```
   ┌──────────┐   ┌──────────┐   ┌──────────┐
   │ Gate 1   │ → │ Gate 2   │ → │ Gate 3   │
   │ Planning │   │ Start    │   │ Mid-work │
   │ approval │   │ control  │   │ feedback │
   └──────────┘   └──────────┘   └────┬─────┘
                                      ▼
   ┌──────────┐   ┌──────────┐   ┌──────────┐
   │ Gate 6   │ ← │ Gate 5   │ ← │ Gate 4   │
   │ QA       │   │ Merge    │   │ Code     │
   │ sign-off │   │ (human)  │   │ review   │
   └──────────┘   └──────────┘   └──────────┘
```

## Gate → command wiring

| Gate | Phase | Commands | Owner |
|------|-------|----------|-------|
| 1 | Planning approval | `/trd` → `/plan-first` → `/breakdown-design` → `/create-jira-task` | Human chooses the option; machine never picks |
| 2 | Start control | (Jira transition) | Human for Bug/Story; auto for Task |
| 3 | Mid-work feedback | (Jira comments, lazy-consumed at phase boundaries) | Human writes, Claude reads on next context-gather |
| 4 | Code review | `/push-pr` opens the PR with Jira context | Human reviews on the git provider |
| 5 | Merge | — | **Human only** — no automation merges, ever |
| 6 | QA sign-off | `/feature-report` + `/qa-align` | Human tests manually + decides ship / no-ship |

## Commands by profile

```
 universal/ (9)   plan-first · breakdown-design · do-implementation
                  mini-prd · trd · search · search-smart
                  update-doc · wireframe-image
 mobile/ (5)      design · ui-test · mobile-analysis
                  feature-report · qa-align
 regress/ (8)     deep-analysis · full-analysis · create-jira-task
                  prd-align · quality-to-jira · quality-publish-confluence
                  production-to-jira · push-pr
```

## Agents (orthogonal — usable at any gate)

| Agent | Domain |
|-------|--------|
| `android-gradle-debugger` | Gradle / AGP / dependency builds |
| `compose-design-system` | Figma → Compose, design-system enforcement |
| `mobile-architect-advisor` | Architecture, SOLID, code reviews |
| `mobile-data-domain-engineer` | Data + domain layers, repositories |
| `feature-orchestrator` | Multi-aspect feature coordination |
| `performance-optimizer` | Memory, build time, APK size, runtime perf |
| `security-compliance-officer` | Mobile security audits + compliance |
| `test-automation-engineer` | UI / unit / integration test strategy |
| `code-quality-guardian` | Lint, complexity, clean-code enforcement |

`AGENT-DELEGATION-RULES.md` tells Claude which agent owns which kind of task.

## Human vs machine

| Action | Human | Machine |
|--------|:-----:|:-------:|
| Write/approve PRD, choose plan option | Y | |
| Move Bug/Story → In Progress | Y | |
| Move Task → In Progress | | Y |
| Gather context, implement, test, commit, push, open PR | | Y |
| Update Jira to done state | | Y |
| Review, approve, **merge** | Y | |
| Manual QA + release decision | Y | |

## Adoption path

You don't have to use the whole stack at once: start with `/plan-first` only → add `/breakdown-design` → add `/do-implementation` + `/push-pr` → add `/feature-report` + `/qa-align` → optionally add `/quality-to-jira` + `/production-to-jira`. The agents are orthogonal and can be used at any step.
