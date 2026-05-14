# regress-toolkit

> A drop-in **Claude Code** toolkit modeled on a real mobile-banking team's regress branch workflow — 22 slash commands, 10 specialist agents, 5 MCP servers, and a CLAUDE.md template — installable into any project with one command.

## Quickstart (copy-paste)

```bash
git clone https://github.com/tomdwipo/regress-toolkit.git
cd regress-toolkit
bash install.sh ~/projects/my-app --mobile --with-mcp
```

Replace `~/projects/my-app` with **your own project's path**. That's the whole install.

Then verify and try your first command:

```bash
bash doctor.sh ~/projects/my-app           # health check
cd ~/projects/my-app
claude                                      # open Claude Code in your project
# inside Claude Code:
/plan-first "add a hello-world screen"
```

### Prerequisites

| Tool       | Used for                              | Install                                              |
|------------|---------------------------------------|------------------------------------------------------|
| `git`      | clone this repo + your project         | most systems have it; otherwise [git-scm.com](https://git-scm.com) |
| `node`+`npm`| Bitbucket + Figma MCPs                | [nodejs.org](https://nodejs.org)                     |
| `uv`       | Python MCPs (jira-attachment, video-to-image) | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `ffmpeg`   | video-to-image MCP                     | `brew install ffmpeg` / `apt-get install ffmpeg`     |
| `jq`       | `doctor.sh` health check               | `brew install jq` / `apt-get install jq`             |
| Claude Code| running the commands                   | [claude.com/claude-code](https://claude.com/claude-code) |

Skip whichever you don't need — the installer warns but doesn't block.

## Why this repo exists

The "regress" workflow is a mobile-engineering pattern for high-stakes apps: every change passes through 6 human gates (plan → start → mid-work feedback → code review → merge → QA sign-off), backed by Claude Code commands that automate the boring half (search, design, docs, Jira tickets, PR drafting) while keeping humans on the hard half (decisions and merges). This repo extracts the playbook so anyone can study it or adopt it.

**Philosophy (≤15 words):** bundle the regress-branch Claude brain — commands, MCPs, CLAUDE.md — into one drop-in installer.

## Other install variants

```bash
# Minimal — universal commands only (works for any backend/web/mobile)
bash install.sh ~/projects/my-app --minimal

# Mobile without auto-cloning MCP sources (do it yourself later)
bash install.sh ~/projects/my-app --mobile

# Regress flow only (planning + ticketing + PR commands, no mobile agents)
bash install.sh ~/projects/my-app --regress

# Everything (default if you omit the flag)
bash install.sh ~/projects/my-app --all --with-mcp

# Dry run — show what would happen, change nothing
bash install.sh ~/projects/my-app --all --dry-run
```

## Profiles

| Profile     | Commands         | Agents | Use for                                  |
|-------------|:----------------:|:------:|------------------------------------------|
| `--minimal` | 9 universal      | 0      | Any project (backend, web, mobile)       |
| `--mobile`  | 9 + 5 mobile     | 10     | Android / iOS                            |
| `--regress` | 9 + 8 regress    | 0      | Teams adopting the gated regress flow    |
| `--all`     | 22 commands      | 10     | Mobile + regress + agents (default)      |

Default (no flag) = `--all`.

## Install flow

```
┌──────────────────────────────────────────────────────────────────┐
│ bash install.sh <project-dir> [--profile] [--with-mcp]           │
└──────────────────────────────────────────────────────────────────┘
        │
        ▼
  ┌────────────┐    ┌─────────────────┐    ┌──────────────────┐
  │ 1. Detect  │ →  │ 2. Copy commands│ →  │ 3. setup-mcp.sh  │
  │   OS+deps  │    │   to .claude/   │    │  clone MCPs      │
  └────────────┘    └─────────────────┘    └────────┬─────────┘
                                                    │
       ┌────────────────────────────────────────────┘
       ▼
  ┌────────────────────┐   ┌─────────────────────┐   ┌──────────────┐
  │ 4. Prompt tokens   │ → │ 5. Write .mcp.json  │ → │ 6. doctor.sh │
  │ (never to git!)    │   │   to project root   │   │   verify ✓   │
  └────────────────────┘   └─────────────────────┘   └──────────────┘
```

## What gets installed

### Universal commands (all profiles)

| Command              | What it does                                                          |
|----------------------|-----------------------------------------------------------------------|
| `/plan-first`        | Multiple implementation options before coding (simplest first)        |
| `/breakdown-design`  | Detailed step-by-step plan with code examples                          |
| `/do-implementation` | Execute implementation following spec + plan documents                 |
| `/mini-prd`          | Mini PRD: goal, requirements, acceptance criteria                      |
| `/trd`               | Technical Requirements Document builder                                |
| `/search`            | Advanced codebase search                                               |
| `/search-smart`      | Intelligent contextual search                                          |
| `/update-doc`        | Update docs based on code changes                                      |
| `/wireframe-image`   | ASCII wireframe from a design mockup image                             |

### Mobile commands (`--mobile` / `--all`)

| Command             | What it does                                                |
|---------------------|-------------------------------------------------------------|
| `/design`           | Design Compose screens following engineering principles      |
| `/ui-test`          | Screenshot benchmark comparison testing                      |
| `/mobile-analysis`  | Complete mobile codebase analysis                            |
| `/feature-report`   | Post-implementation feature report                           |
| `/qa-align`         | QA handoff alignment document                                |

### Regress commands (`--regress` / `--all`)

| Command                       | What it does                                            |
|-------------------------------|---------------------------------------------------------|
| `/deep-analysis`              | Deep codebase understanding                              |
| `/full-analysis`              | Complete codebase analysis                               |
| `/create-jira-task`           | Create Jira tickets with field mapping                   |
| `/prd-align`                  | PRD/TRD alignment tracker                                |
| `/quality-to-jira`            | Quality findings → Jira tickets                          |
| `/quality-publish-confluence` | Publish quality report to Confluence                     |
| `/production-to-jira`         | Production scan findings → Jira tickets                  |
| `/push-pr`                    | Push branch + open PR with Jira context                  |

### Agents (`--mobile` / `--all`)

| Agent                          | Specialty                                              |
|--------------------------------|--------------------------------------------------------|
| `mobile-architect-advisor`     | Clean architecture, SOLID, code reviews                |
| `mobile-data-domain-engineer`  | Data + domain layers, repositories                     |
| `compose-design-system`        | Figma → Compose, design-system enforcement             |
| `feature-orchestrator`         | Multi-aspect feature coordination                       |
| `android-gradle-debugger`      | Gradle / AGP / dependency debugging                    |
| `performance-optimizer`        | Memory, build time, APK size, runtime perf             |
| `security-compliance-officer`  | Mobile security audits + compliance                    |
| `test-automation-engineer`     | UI / unit / integration test strategy                  |
| `code-quality-guardian`        | Lint, complexity, clean-code enforcement               |

Plus `AGENT-DELEGATION-RULES.md` — guidance on routing tasks between agents.

### MCP servers

| Server            | Tool family                                              | Auth                            |
|-------------------|----------------------------------------------------------|---------------------------------|
| `atlassian`       | Jira + Confluence read/write (managed remote)            | OAuth at first use              |
| `bitbucket`       | PRs, comments, diffs                                     | API token + email               |
| `figma`           | File reads, component renders                            | Personal access token           |
| `jira-attachment` | Download images/videos from Jira tickets                 | API token (shared with atlassian) |
| `video-to-image`  | Extract frames from Jira video attachments               | None (uses local ffmpeg)         |

See [`mcp/`](mcp/) for per-server setup notes.

## Templates

| File                                       | Purpose                                              |
|--------------------------------------------|------------------------------------------------------|
| `templates/CLAUDE.md.template`             | Starter `CLAUDE.md` (~8 KB, 40 KB ceiling)           |
| `templates/CLAUDE.md.example`              | Reference example — full ~40 KB CLAUDE.md from a real mobile project (sanitised). Read this to see what a mature CLAUDE.md looks like. |
| `templates/.mcp.json.template`             | `.mcp.json` with `{{PLACEHOLDER}}` tokens            |
| `templates/settings.local.json.template`   | Pre-approved tool allowlist (399 lines, accumulated)  |

## Skills

The `skills/` folder ships 3 example Claude Code skills you can use or adapt:

| Skill            | What it does                                                         |
|------------------|----------------------------------------------------------------------|
| `agp-9-upgrade`  | Recipes for migrating Android Gradle Plugin to 9.x (KSP, kapt, Paparazzi, BuildConfig) |
| `edge-to-edge`   | Edge-to-edge UI migration helper for Android 15+ defaults             |
| `r8-analyzer`    | R8/ProGuard rule analysis: redundant rules, keep-rule impact, reflection-safety guidance |

Installed automatically with `--mobile` or `--all` profile. Each skill has a `references/your-project-context.md` placeholder for you to fill in with project-specific notes.

## Documentation

| Doc                                 | What it covers                                              |
|-------------------------------------|-------------------------------------------------------------|
| [`PRESENTATION.md`](PRESENTATION.md)| Marp-flavoured slide deck (renderable to PDF/HTML)          |
| [`presentation/`](presentation/)    | Full 25-min seminar deck — HTML + speaker notes (Bahasa/English) |
| [`docs/c4/`](docs/c4/)              | C4 architecture model (ASCII) — context → container → component → code |
| [`docs/REGRESS-WORKFLOW.md`](docs/REGRESS-WORKFLOW.md) | What the regress flow is and why it exists |
| [`docs/HOW-TO-USE.md`](docs/HOW-TO-USE.md)            | Per-command walkthroughs                  |
| [`docs/CLAUDE-MD-GUIDE.md`](docs/CLAUDE-MD-GUIDE.md)  | Anatomy of a good CLAUDE.md               |
| [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)  | Common issues + fixes                     |

## Repository layout

```
regress-toolkit/
├── README.md                        ← you are here
├── PRESENTATION.md                  ← Marp slides + plain markdown
├── LICENSE                          ← MIT
├── CHANGELOG.md
├── CONTRIBUTING.md
│
├── install.sh                       ← one-shot installer
├── setup-mcp.sh                     ← MCP source cloner
├── doctor.sh                        ← post-install health check
├── sanitize.sed                     ← strip identifiers before publishing
├── sync-from-source.sh              ← pull latest from a private fork
│
├── commands/
│   ├── universal/   (9 .md)
│   ├── mobile/      (5 .md)
│   └── regress/     (8 .md)
├── agents/          (10 .md)
├── skills/          (3 example skills: agp-9-upgrade, edge-to-edge, r8-analyzer)
├── templates/       (CLAUDE.md.template, CLAUDE.md.example, .mcp.json, settings.local.json)
├── mcp/             (5 .md — per-server install notes)
├── docs/            (4 .md — workflow, how-to, CLAUDE.md guide, troubleshooting)
│   └── c4/          (C4 architecture model — ASCII, 4 levels + nav)
├── presentation/    (HTML seminar deck + speaker notes)
└── tests/           (bats install smoke test)
```

## Security

- **No tokens in commits.** `sanitize.sed` is mandatory pre-push; CI fails if any forbidden pattern reappears in tree.
- **`.mcp.json` is `.gitignore`d.** Only `templates/.mcp.json.template` ships, with `{{PLACEHOLDER}}` for every secret.
- **Templates only.** `settings.local.json` and any `.env` are git-ignored by default.

## License

MIT — see [LICENSE](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: keep secrets out, run `bats tests/`, no AI attribution in commits.
