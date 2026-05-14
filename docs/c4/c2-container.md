# C2 — Container

> The moving parts inside the regress-toolkit repo, and what each one produces.

```
   regress-toolkit/
   ┌────────────────────────── INSTALLER ──────────────────────────┐
   │  install.sh          orchestrates the 8-step install          │
   │  setup-mcp.sh        clones + builds 4 MCP server repos        │
   │  doctor.sh           post-install health check                │
   │  sync-from-source.sh maintainer: pull from private + sanitise  │
   └───────────────────────────────┬───────────────────────────────┘
                                   │ copies
   ┌─────────────────────── CONTENT BUNDLE ────────────────────────┐
   │  commands/   universal/9  mobile/5  regress/8   = 22 .md       │
   │  agents/     9 agents + AGENT-DELEGATION-RULES.md              │
   │  skills/     agp-9-upgrade · edge-to-edge · r8-analyzer        │
   │  templates/  CLAUDE.md(.template/.example) · .mcp.json ·       │
   │              settings.local.json                              │
   │  mcp/        6 per-server setup docs                          │
   └───────────────────────────────┬───────────────────────────────┘
                                   │ guarded by
   ┌─────────────────────── LEAK-PREVENTION ───────────────────────┐
   │  sanitize.sed / .leak-patterns.local   forbidden patterns     │
   │  scripts/check-leaks.sh                pre-push tree scan     │
   │  scripts/install-pre-push-hook.sh      wires the git hook     │
   └───────────────────────────────────────────────────────────────┘
                                   │
                                   ▼  install.sh writes into target
   ┌──────────────────────── TARGET PROJECT ───────────────────────┐
   │  .claude/commands/   .claude/agents/   .claude/skills/         │
   │  .claude/settings.local.json                                  │
   │  CLAUDE.md           (root, only if absent — never clobbered)  │
   │  .mcp.json           (root, rendered from template, 0600)     │
   └───────────────────────────────────────────────────────────────┘
```

## Containers

| Container | Kind | Responsibility |
|-----------|------|----------------|
| `install.sh` | bash | Arg-parse profile/flags → copy commands + agents + skills → drop `CLAUDE.md` + `settings.local.json` templates → prompt for tokens + render `.mcp.json` → optional `setup-mcp.sh` → run `doctor.sh` |
| `setup-mcp.sh` | bash | Clone + build `bitbucket-mcp`, `figma-mcp` (Node) and `jira-attachment`, `video-to-image` (Python/uv) into `$MCP_DIR`; `atlassian` needs no clone (`npx mcp-remote`) |
| `doctor.sh` | bash | Verify `.claude/commands`, `.claude/agents`, `CLAUDE.md` (< 40 000 chars), `.mcp.json` parseable, host CLIs present, MCP binaries reachable |
| `sync-from-source.sh` | bash | Maintainer-only: wipe `commands/` + `agents/`, re-copy from a private `SOURCE_REPO`, run `sed -f .sanitize.sed.local`, then `check-leaks.sh` |
| `commands/` | content | 22 slash-command `.md` files, split into the 3 profile folders |
| `agents/` | content | 9 specialist agent `.md` files + `AGENT-DELEGATION-RULES.md` |
| `skills/` | content | 3 example Claude Code skills (each a folder with a `references/` placeholder) |
| `templates/` | content | Starter `CLAUDE.md`, full `.example`, `.mcp.json` with `{{PLACEHOLDER}}`s, tool allowlist |
| `mcp/` | content | One setup doc per MCP server |
| leak-prevention | config + bash | `sanitize.sed` + git-ignored `.leak-patterns.local`; `check-leaks.sh` blocks push on any forbidden pattern |

## The 8-step install pipeline

```
 [1]  announce       profile · target · flags
 [2]  copy commands  universal + (mobile | regress | both) → .claude/commands/
 [3]  copy agents    only --all | --mobile                 → .claude/agents/
 [3b] copy skills    only --all | --mobile                 → .claude/skills/
 [4]  CLAUDE.md      template → project root  (skip if exists)
 [5]  settings       settings.local.json template → .claude/
 [6]  .mcp.json      prompt tokens → render template → chmod 600
 [7]  setup-mcp      optional (--with-mcp): clone MCP servers
 [8]  doctor.sh      health check, non-fatal
```

`--dry-run` echoes every step instead of executing it. `--target` overrides the default `<project>/.claude` install location.

## Profiles → containers

| Profile | commands/ | agents/ | skills/ |
|---------|-----------|:-------:|:-------:|
| `--minimal` | universal (9) | — | — |
| `--mobile` | universal + mobile (14) | 10 | 3 |
| `--regress` | universal + regress (17) | — | — |
| `--all` (default) | all 22 | 10 | 3 |
