# Anatomy of a good CLAUDE.md

`CLAUDE.md` is the single file Claude Code auto-loads into every session in this project. It's the highest-leverage doc in the repo — every word costs context-window budget, so every word must earn its place.

The `templates/CLAUDE.md.template` in this repo is the skeleton. This guide explains *why* it's shaped the way it is.

## The 40-KB ceiling

Every session pays the CLAUDE.md cost. At 40 KB you're already eating ~10,000 tokens of the model's context window before any conversation starts. Above that, you're trading away the model's room to reason about your code.

Practical rule:

```bash
wc -c CLAUDE.md
# > 40000? compress the §Recent Updates section first, then prune anything
#          already externalised to .docs/common-issues/
```

## Section layout

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Project Overview        (2–3 lines, what the app does)   │
├─────────────────────────────────────────────────────────────┤
│ 2. Quick Reference         (table of important paths)       │
├─────────────────────────────────────────────────────────────┤
│ 3. Build Commands          (setup, build, test)             │
├─────────────────────────────────────────────────────────────┤
│ 4. Architecture            (module pattern, layer rules)    │
├─────────────────────────────────────────────────────────────┤
│ 5. Coding Guidelines       (the 7 rules)                    │
├─────────────────────────────────────────────────────────────┤
│ 6. Commit Rules            (author, format, no AI attrib.)  │
├─────────────────────────────────────────────────────────────┤
│ 7. Documentation Pattern   (.docs/YYYY/MM/DD/ structure)    │
├─────────────────────────────────────────────────────────────┤
│ 8. Mistake-Learning Pattern(read before, write after)       │
├─────────────────────────────────────────────────────────────┤
│ 9. Common Issues           (cross-cutting gotchas)          │
├─────────────────────────────────────────────────────────────┤
│ 10. Recent Updates         (one-liners, prune aggressively) │
└─────────────────────────────────────────────────────────────┘
```

Each section answers a question the model is about to ask.

## What goes in here vs. .docs/common-issues/

**Inline in CLAUDE.md**: cross-cutting gotchas every session needs. The `claude -p` runtime traps, the `set -euo pipefail` quirks, the Confluence full-replace rule. These are short and load every time.

**Externalised to `.docs/common-issues/<subject>.md`**: per-system detail. iOS-specific gotchas, Android-specific gotchas, Confluence publishing edge cases. Indexed in `CLAUDE.md` with a one-line reference; the model can fetch them on demand.

Why split? Because not every session needs every gotcha, but every session needs to *know they exist*.

## Session discipline gates

The template ships with two gates baked in:

1. **Lookup gate.** Before answering the first substantive question, pattern-match against the Common Issues index. If a known subject hits, answer from the cataloged pattern first.
2. **Save gate.** Before writing any new learning (correction landed, approach validated, gotcha revealed), save to CLAUDE.md or `.docs/common-issues/` — not to auto-memory.

These gates are the feedback loop. Without them the file rots and learning evaporates between sessions.

## Mistake-learning pattern

Three commands (`/do-implementation`, `/breakdown-design`, `/plan-first`) include an "Avoid Repeating Mistakes" block:

```markdown
## Avoid Repeating Mistakes

Before planning, read the Common Issues section in CLAUDE.md.

If you encounter a new mistake during planning, add it to CLAUDE.md
Common Issues with:
- What went wrong
- How it was fixed
```

The model reads on entry, writes on exit. Each session learns from previous sessions.

## What NOT to put in CLAUDE.md

- **Code that belongs in code.** If a `fun helper()` is referenced everywhere, write a real utility instead of explaining it in CLAUDE.md.
- **Decisions that should be ADRs.** Architectural decision records belong in `.docs/adr/`, not the auto-load doc.
- **Project status / sprint plans.** These rot in days. Use Jira or `.docs/<date>/`.
- **Team biographies.** Not Claude's problem.
- **Tokens or secrets.** Obvious, but worth saying.

## Tuning checklist

Before committing a CLAUDE.md change, ask:

- [ ] Is this *cross-cutting* — would three different sessions benefit?
- [ ] Is the why included? "Don't do X" is brittle; "Don't do X because Y" lets the model judge edge cases.
- [ ] Is `wc -c` still under 40000?
- [ ] If I added a Common Issues entry, did I link it from the Common Issues catalog?

If all four are yes, ship it. If any is no, externalise or trim.
