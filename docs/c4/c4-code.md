# C4 — Code

> The deepest zoom: what one command, one agent, and one install step actually look like.

## Anatomy of a command (`commands/**/<name>.md`)

A command is **plain markdown** — no YAML frontmatter. Claude Code reads the whole file as the prompt when the user types `/<name>`.

```
 # <Title> Command            ← human-readable name

 <instruction prose>          ← what Claude should do
 ... $ARGUMENTS ...           ← placeholder for the user's args

 ## Avoid Repeating Mistakes  ← shared convention across commands
 Before <phase>, read CLAUDE.md Common Issues.
 If a new mistake happens, append it there.
```

Example — `commands/universal/plan-first.md` (21 lines): a title, the "give me options, simplest first" instruction carrying `$ARGUMENTS`, and the mistake-learning footer. Every command is small and declarative — the intelligence is in Claude, the file just frames the task.

## Anatomy of an agent (`agents/<name>.md`)

An agent **does** have YAML frontmatter, then a system-prompt body.

```
 ---
 name: mobile-architect-advisor
 description: Use this agent when ... <examples with Context/user/assistant>
 model: sonnet
 color: blue
 ---

 You are a Principal Mobile Engineer ...   ← system-prompt body
```

`AGENT-DELEGATION-RULES.md` carries `name` + `description` only — no `model` / `color`, because it is routing guidance, not an invokable agent.

## Token placeholders

Files that ship to a public repo never contain secrets or identifiers. Placeholders are filled at install time, or by the maintainer's sanitiser.

| Placeholder | Lives in | Filled by |
|-------------|----------|-----------|
| `{{JIRA_EMAIL}}`, `{{JIRA_API_TOKEN}}`, `{{JIRA_HOST}}`, `{{JIRA_CLOUD_ID}}`, `{{BITBUCKET_*}}`, `{{FIGMA_ACCESS_TOKEN}}` | `templates/.mcp.json.template` | `install.sh` step 6 prompts → `sed` render → `.mcp.json` (chmod 600) |
| `{{MCP_DIR}}`, `{{UV_BIN}}` | `templates/.mcp.json.template` | `install.sh` from `$MCP_DIR` / `command -v uv` |
| `{{PRODUCT_NAME}}` | `agents/*.md`, templates | left generic in the public repo; the adopting team sets a project-specific value |

## install.sh — step internals

```
 arg parse ──▶ resolve PROJECT  (expand ~, must be a real dir)
           └─▶ TARGET = PROJECT/.claude   (or --target override)
 copy_profile(universal)  always
   + case PROFILE in mobile | regress | all → copy_profile(...)
 agents + skills          copied only when PROFILE ∈ {all, mobile}
 CLAUDE.md / settings     copied only if absent  (never clobber)
 .mcp.json                skipped if present; else prompt → sed-render → chmod 600
 --with-mcp ──▶ setup-mcp.sh        --dry-run ──▶ do_or_say echoes, writes nothing
```

## The maintainer loop

```
 private source repo ──sync-from-source.sh──▶ wipe + re-copy commands/ agents/
                                            │
                                            ▼
                          sed -f .sanitize.sed.local   (strip identifiers)
                                            │
                                            ▼
                          scripts/check-leaks.sh       (block on any leak)
                                            │
                                       git push
```

`check-leaks.sh` scans the whole working tree against `.leak-patterns.local`; a single match exits non-zero and blocks the push. `install-pre-push-hook.sh` wires this scan into a local `pre-push` git hook so it runs automatically.
