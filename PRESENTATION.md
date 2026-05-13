---
marp: true
theme: default
paginate: true
title: regress-toolkit
description: A drop-in Claude Code toolkit for mobile teams running gated workflows.
---

# regress-toolkit

A drop-in **Claude Code** toolkit for mobile teams running gated workflows.

22 commands · 10 agents · 5 MCP servers · 1 CLAUDE.md template

```bash
bash install.sh ~/projects/my-app --mobile --with-mcp
```

---

## Why does this exist?

Mobile teams shipping to production move slowly *for good reasons*:

- Crashes affect users immediately.
- App-store review is days, not minutes.
- Compliance (banking, health, fintech) is non-negotiable.

The "regress" pattern keeps that velocity sane:

> **Humans own the decisions. Machines own the toil.**

---

## The 6 human gates

```
   ┌──────────┐   ┌──────────┐   ┌──────────┐
   │ Gate 1   │ → │ Gate 2   │ → │ Gate 3   │
   │ Planning │   │ Start    │   │ Mid-work │
   └──────────┘   └──────────┘   └──────────┘
                                       │
                                       ▼
   ┌──────────┐   ┌──────────┐   ┌──────────┐
   │ Gate 6   │ ← │ Gate 5   │ ← │ Gate 4   │
   │ QA sign  │   │ Merge    │   │ Review   │
   └──────────┘   └──────────┘   └──────────┘
```

Machine **never** merges. Machine **never** signs off QA.

---

## What the machine does

| Phase           | Commands                                                      |
|-----------------|---------------------------------------------------------------|
| Plan            | `/trd`, `/mini-prd`, `/plan-first`, `/breakdown-design`       |
| Implement       | `/do-implementation`, `/design`, `/search`, `/search-smart`   |
| Document        | `/update-doc`, `/wireframe-image`, `/feature-report`          |
| Ticket / PR     | `/create-jira-task`, `/push-pr`                               |
| Quality + Prod  | `/quality-to-jira`, `/production-to-jira`, `/quality-publish-confluence` |
| QA handoff      | `/qa-align`                                                    |

---

## What the agents do

Specialists you can delegate to:

- `mobile-architect-advisor` — clean architecture, code review
- `compose-design-system` — Figma → Compose with design-system rules
- `mobile-data-domain-engineer` — repositories, domain models
- `android-gradle-debugger` — Gradle/AGP/dependency war stories
- `performance-optimizer` — memory, build time, APK size
- `security-compliance-officer` — mobile security + compliance
- `test-automation-engineer` — UI/unit/integration test strategy
- `code-quality-guardian` — lint, complexity, clean code
- `feature-orchestrator` — coordinates everything above

---

## The MCP stack

```
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│   atlassian     │   │    bitbucket    │   │     figma       │
│  Jira+Conf      │   │   PRs, diffs    │   │   design files  │
└─────────────────┘   └─────────────────┘   └─────────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Claude Code (local + remote)                   │
└─────────────────────────────────────────────────────────────┘
        ▲                     ▲
        │                     │
┌─────────────────┐   ┌─────────────────┐
│ jira-attachment │   │  video-to-image │
│  images+videos  │   │  ffmpeg frames  │
└─────────────────┘   └─────────────────┘
```

---

## CLAUDE.md — the brain

A single 40-KB-ceiling file containing:

1. **Quick Reference** — table of important paths.
2. **Build Commands** — flavors, tests, install.
3. **Coding Guidelines** — 7 rules every session reads.
4. **Commit Rules** — author, format, no AI attribution.
5. **Common Issues** — gotchas indexed by subject.
6. **Session Discipline** — 2 gates: lookup before answer, save before close.

Why the 40 KB ceiling? Because CLAUDE.md is loaded into every session's context window.

---

## Install in one shot

```bash
git clone https://github.com/tomdwipo/regress-toolkit.git
cd regress-toolkit

bash install.sh ~/projects/my-app --mobile --with-mcp
bash doctor.sh ~/projects/my-app
```

That's it. Open the project in Claude Code and try:

```
/plan-first "add a hello-world screen"
```

---

## Profiles

| Profile     | Commands | Agents | Best for                              |
|-------------|:--------:|:------:|---------------------------------------|
| `--minimal` |    9     |   0    | Any backend / web project              |
| `--mobile`  |   14     |  10    | Android / iOS                          |
| `--regress` |   17     |   0    | Teams adopting the gated regress flow  |
| `--all`     |   22     |  10    | Full mobile + regress                  |

Default = `--all`.

---

## Security posture

- **No tokens in git.** Templates ship with `{{PLACEHOLDER}}`; installer prompts user, writes real `.mcp.json` to *their* machine.
- **CI sanitiser.** Every PR is scanned for internal hostnames, project keys, and known token formats.
- **Deny-list in settings.** `git push --force`, `git reset --hard`, `rm -rf /`, `git branch -D` are blocked by default.

---

## Learn the pattern

| Reading order             | File                          |
|---------------------------|-------------------------------|
| 1. The story              | `docs/REGRESS-WORKFLOW.md`    |
| 2. The CLAUDE.md anatomy  | `docs/CLAUDE-MD-GUIDE.md`     |
| 3. The command catalogue  | `docs/HOW-TO-USE.md`          |
| 4. The MCP servers        | `mcp/*.md`                    |
| 5. The traps              | `docs/TROUBLESHOOTING.md`     |

---

## Questions?

- **Repo:** https://github.com/tomdwipo/regress-toolkit
- **Sister repo:** https://github.com/tomdwipo/claude-code-setup
- **Issues / PRs welcome.**

> Built to be cloned, studied, and adapted.
