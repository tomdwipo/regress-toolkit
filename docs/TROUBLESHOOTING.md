# Troubleshooting

Real gotchas from running this toolkit in production. Indexed by symptom.

## Install / setup

### `install.sh` exits with "project directory required"

You passed flags but no project path. Path comes first:

```bash
# WRONG
bash install.sh --mobile ~/projects/my-app

# RIGHT
bash install.sh ~/projects/my-app --mobile
```

### `setup-mcp.sh` fails on `uv sync` for jira-attachment or video-to-image

`uv` isn't on PATH. Install it:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
exec $SHELL -l   # reload PATH
```

Then re-run `bash setup-mcp.sh`.

### `doctor.sh` reports "MCP path missing"

The `.mcp.json` was rendered before `setup-mcp.sh` ran (or to a different `MCP_DIR`). Two fixes:

1. Re-run `setup-mcp.sh` with the same `MCP_DIR` your `.mcp.json` points at.
2. Edit `.mcp.json` paths to match wherever the MCPs actually live.

### CLAUDE.md is over 40 KB

You started from the template but accumulated context. Trim §Recent Updates first; if still over, move per-system detail to `.docs/common-issues/<subject>.md` and replace it with a one-line link.

## Runtime / Claude Code

### "Tool not found: `mcp__atlassian__searchJiraIssuesUsingJql`"

Two possible causes:

1. You're using the **Python `mcp-atlassian` server** which exposes snake_case names (`jira_search`). Update `settings.local.json` allowlist accordingly.
2. You're using the **managed Atlassian MCP** (camelCase) but `--strict-mcp-config` is silently rejecting the call. Verify by running `claude --mcp-debug` and inspecting startup logs.

### `set -euo pipefail` + bare `claude -p` = script hangs forever

Any non-zero exit kills the script via `set -e` before retry logic runs. Always:

```bash
claude -p "..." || IMPL_EXIT=$?
if [[ "$IMPL_EXIT" -ne 0 ]]; then
  # handle the retry
fi
```

### `pgrep -f <token>` in a polling loop deadlocks

The poll's own `pgrep` cmdline matches the token, so the loop never exits. Pick a token that doesn't appear in your `claude -p` invocation, or use a PID file:

```bash
claude -p "..." & echo $! > /tmp/claude.pid
while kill -0 "$(cat /tmp/claude.pid)" 2>/dev/null; do sleep 1; done
```

## MCP-specific

### atlassian: "Failed to read confluence page" but URL works in browser

Confluence uses 9–10 digit page IDs. Make sure you pass the **page ID**, not the URL slug. The URL is `…/pages/3910303771/Page-Title` — pass `3910303771`.

### bitbucket: `add_reviewer` returns 400 "user not found"

You passed a username. The API wants the Atlassian **account ID** (UUID-like). Look it up: Bitbucket UI → Profile → Manage account → Account ID.

### figma: `get_image_render` returns nothing

Token scope is wrong. The PAT needs `file_content:read` *and* the file must be in a team the token can access. Personal files don't always work with team tokens.

### jira-attachment: downloads land in the wrong directory

The MCP downloads to the current working directory of the `uv run` subprocess. If that's surprising, pass an explicit `output_dir` argument in your prompt.

### video-to-image: hangs on `video_info`

The video file is huge (≥100 MB) or stored on slow disk. Move it to local SSD first, or use `extract_frame_at_timestamp` with a known timestamp instead of letting the MCP scan the whole file.

## CLAUDE.md / context

### Claude keeps forgetting our coding rules

Two failure modes:

1. **They aren't in CLAUDE.md.** Add them under §Coding Guidelines.
2. **They are, but CLAUDE.md is over 40 KB.** The system truncates aggressively past that; rules in the lower half of the file are lost. Trim.

### Claude saved something to memory that's now wrong

Memory files live at `~/.claude/projects/<project-hash>/memory/`. Either:

1. Tell Claude "forget X" — it should update or delete the relevant file.
2. Open the file directly and edit.

Memory is per-project; deleting it doesn't affect other projects.

## Confluence / Jira

### "Confluence page came back as `Defaultbash# command…`"

Markdown round-trip flattened a fenced code block. Re-fetch with `contentFormat: "adf"` (Mac/managed MCP) or `"storage"` (Python MCP), edit the structured body, write back the same format.

### Quality report keeps re-publishing last week's data

Your weekly pipeline failed mid-run, left a stale `quality-summary.json`, and the publish step doesn't check freshness. Add a guard:

```bash
SUMMARY_DATE=$(jq -r .date quality-summary.json)
TODAY=$(date -u +%Y-%m-%d)
if [[ "$SUMMARY_DATE" != "$TODAY" ]]; then
  echo "Stale summary ($SUMMARY_DATE vs $TODAY); refusing to publish" >&2
  exit 1
fi
```

## CI / sanitiser

### CI generic token scan fails

The token-shape scan (universal Atlassian/Figma/GitHub/Slack/OpenAI/AWS key prefixes) found a long credential-looking string. Rotate the credential, scrub the file, and re-push.

### Pre-push hook blocks a push with "LEAK DETECTED"

A pattern from your local `.leak-patterns.local` reappeared in a tracked file. Run the scanner manually to see the line:

```bash
bash scripts/check-leaks.sh
```

Fix the offending file (use `.sanitize.sed.local` substitutions to clean it, or hand-edit), then re-push. If the match is a deliberate documentation example, tighten the pattern in `.leak-patterns.local` to be more specific.

### Bats test fails: "expected 9 commands in universal/, got 8"

You added or removed a command without updating `tests/install.bats` counts. Adjust the count, or restore the missing file.

## When all else fails

1. Re-read this doc.
2. Run `bash doctor.sh` on the project.
3. Open an issue: include `doctor.sh` output and the offending command/prompt.
