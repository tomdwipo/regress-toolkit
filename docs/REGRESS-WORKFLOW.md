# The Regress Workflow

The "regress" pattern is a way to ship high-stakes mobile code at a steady pace without losing safety. It came out of a banking-app team that hits five constraints simultaneously:

1. Compliance reviews land on a fixed cadence (weekly cut).
2. Crashes in production cost real money for real customers.
3. Three environments (dev/staging/production) all need to stay green.
4. The team is too small to run a dedicated release engineer.
5. Claude Code is good enough to do the boring half — and only the boring half.

This doc explains the model. The commands and agents in this repo are the concrete implementation.

## North-star principles

The pattern rests on five non-negotiable principles. New work MUST NOT violate them. When they conflict, the lower-numbered principle wins.

1. **Human gates are sacred.** Machines never merge, never bypass code review, never sign off QA.
2. **Historian-first.** No phase reads what a prior phase didn't durably write. Memory is for *the next session*; the current session's artefacts live in files on disk.
3. **Interlocks.** PID-based locks, never two writers on the same resource (one branch, one PR, one Jira state machine).
4. **Alarm rationalization.** Findings deduplicate; HIGH severity is rare. Otherwise the human stops reading them.
5. **Deterministic replay.** Any phase must be re-runnable from stored inputs. You should be able to re-cut a release on a Monday from Friday's plan and get the same artefact.

## The 6 gates

```
   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │ Gate 1       │ → │ Gate 2       │ → │ Gate 3       │
   │ Planning     │   │ Start        │   │ Mid-work     │
   │ approval     │   │ control      │   │ feedback     │
   └──────────────┘   └──────────────┘   └──────────────┘
                                                │
                                                ▼
   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │ Gate 6       │ ← │ Gate 5       │ ← │ Gate 4       │
   │ QA sign-off  │   │ Merge        │   │ Code review  │
   │ + release    │   │ (human only) │   │              │
   └──────────────┘   └──────────────┘   └──────────────┘
```

### Gate 1 · Planning approval

**Command sequence:** `/trd` → `/plan-first` → `/breakdown-design` → `/create-jira-task`.

The human chooses among the options `/plan-first` generates. Machine never picks. Each command writes an artefact to `.docs/` so the next phase can re-read it.

### Gate 2 · Start control

Bug/Story tickets move to "In Progress" by the human (signals "yes, work on this"). Task tickets auto-transition when work actually begins (lower-risk).

### Gate 3 · Mid-work feedback

Humans add Jira comments. Claude reads them on the next context-gather. There's no "ping" — feedback is lazy-consumed at phase boundaries, not interrupt-driven.

### Gate 4 · Code review

Full PR review on the git provider. `/push-pr` opens the PR with rich context (Jira link, commit summary, screenshots). Reviewers comment normally.

### Gate 5 · Merge

**Human-only.** No automation merges PRs. Ever.

### Gate 6 · QA sign-off

`/feature-report` + `/qa-align` produce the QA handoff document. QA tests manually; QA decides ship or no-ship. Release tagging happens after QA gives the green light.

## What the machine does (and doesn't) own

| Action                                  | Human | Machine |
|----------------------------------------|:-----:|:-------:|
| Write/approve PRD                       |  Y    |         |
| Run `/trd`, `/plan-first`               |  Y    |   Y     |
| Choose plan option                      |  Y    |         |
| Move Bug/Story to In Progress           |  Y    |         |
| Move Task to In Progress                |       |   Y     |
| Gather context, implement, test         |       |   Y     |
| Commit, push, create PR                 |       |   Y     |
| Update Jira to done state               |       |   Y     |
| Review, approve, **merge** PR           |  Y    |         |
| Run `/feature-report`, `/qa-align`      |  Y    |   Y     |
| Manual QA + release decision            |  Y    |         |

## Why this beats "just let Claude merge"

- **Trust is built by human review, not by machine speed.** If reviewers ever stop reading the diffs because "Claude wrote it", the regress flow is dead.
- **Audit trails matter.** Every artefact on disk gives compliance / postmortems something to read.
- **Failures are recoverable.** Because every phase writes durable artefacts, you can re-run any single phase without losing the rest.

## How this repo implements the pattern

| Principle               | Implementation in this repo                                        |
|-------------------------|--------------------------------------------------------------------|
| Human gates are sacred  | `settings.local.json.template` has `git push --force`, merge ops on the deny list. |
| Historian-first         | Every command writes to `.docs/<date>/<feature>/`. Nothing relies on chat memory. |
| Interlocks              | Slash commands target one branch at a time; PR creation is a single bidirectional handoff. |
| Alarm rationalization   | `/quality-to-jira` and `/production-to-jira` dedupe before opening tickets. |
| Deterministic replay    | Inputs to each command (PRD URL, Jira ID, Figma node ID) are recorded in the artefact header. |

## Adopting the pattern

You don't have to use the whole stack. A reasonable adoption path:

1. **Start with `/plan-first` only.** Get used to choosing among options instead of "just build it".
2. **Add `/breakdown-design`.** Now the chosen option has a written plan.
3. **Add `/do-implementation` + `/push-pr`.** Now Claude executes and opens a PR.
4. **Add `/feature-report` + `/qa-align`.** Now QA gets a structured handoff.
5. **Optionally add `/quality-to-jira`, `/production-to-jira`.** Now signal becomes ticket.

The agents (`mobile-architect-advisor`, etc.) are orthogonal — you can use them at any step.
