# C1 — System Context

> Who runs regress-toolkit, and what does it touch.

regress-toolkit is **not a running service** — it is an *installer plus a content bundle*. It runs once (or on update), copies a "Claude Code brain" into a target project, optionally clones the MCP servers, and steps out of the way. Everything after that is the developer, Claude Code, and the MCP servers.

```
                        ┌───────────────────────────┐
                        │  Developer / Team Lead    │
                        │  adopts the regress flow  │
                        └─────────────┬─────────────┘
                          bash install.sh <dir>
                                      │
                                      ▼
        ┌──────────────────────────────────────────────────────┐
        │                  regress-toolkit                     │
        │  installer  (install.sh · setup-mcp.sh · doctor.sh)   │
        │  + content bundle  (22 commands · 10 agents ·         │
        │    3 skills · 4 templates · 6 MCP docs)               │
        └───────┬──────────────────────────────────┬───────────┘
        installs into                       clones + builds
                │                                  │
                ▼                                  ▼
   ┌─────────────────────────┐         ┌──────────────────────────┐
   │     Target project      │         │      MCP servers         │
   │  .claude/commands|agents │         │  atlassian · bitbucket   │
   │  .claude/skills          │         │  figma · jira-attachment │
   │  CLAUDE.md · .mcp.json   │         │  video-to-image          │
   └───────────┬─────────────┘         └────────────┬─────────────┘
               │  read by                          │  reached at runtime by
               ▼                                   ▼
        ┌─────────────┐                ┌──────────────────────────────┐
        │ Claude Code │ ───invokes───▶ │ Jira · Bitbucket · Figma ·   │
        │  (in repo)  │                │ Confluence                   │
        └─────────────┘                └──────────────────────────────┘
```

## Actors & systems

| Element | Type | Role |
|---------|------|------|
| Developer / Team Lead | person | Runs `install.sh`; afterwards uses the slash commands inside Claude Code |
| regress-toolkit | software system | Installer + content bundle — the subject of this model |
| Target project | software system | The developer's own repo (Android / web / backend). Receives `.claude/`, `CLAUDE.md`, `.mcp.json` |
| Claude Code | software system | CLI that reads the installed commands/agents/skills and drives the work |
| MCP servers | software system (×5) | Cloned by `setup-mcp.sh`; bridge Claude Code to external systems |
| Jira / Bitbucket / Figma / Confluence | external system | Reached **through** the MCP servers at runtime — never by the toolkit itself |

## Relationships

| From | To | Action | When |
|------|-----|--------|------|
| Developer | regress-toolkit | `bash install.sh <project-dir> [--profile] [--with-mcp]` | once / on update |
| regress-toolkit | Target project | Copies commands, agents, skills, `CLAUDE.md`; renders `.mcp.json` (mode 0600) | install time |
| regress-toolkit | MCP servers | `setup-mcp.sh` clones + builds 4 server repos into `$MCP_DIR` (`atlassian` needs no clone) | install time (`--with-mcp`) |
| Developer | Claude Code | Runs `/plan-first`, `/breakdown-design`, … inside the target project | daily |
| Claude Code | MCP servers | Tool calls (`mcp__atlassian__*`, `mcp__bitbucket__*`, …) | runtime |
| MCP servers | Jira / Bitbucket / Figma / Confluence | REST APIs, authed per-server | runtime |

## Boundary

The toolkit's responsibility **ends at install time** — it writes files and exits. It holds no daemon, no cron, no persistent state. Secrets live only in the target project's `.mcp.json` (git-ignored, mode 0600) and are never written into the toolkit repo itself; `templates/.mcp.json.template` ships with `{{PLACEHOLDER}}` tokens only.
