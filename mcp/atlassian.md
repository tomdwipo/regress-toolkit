# atlassian MCP

Provides Jira + Confluence read/write via Atlassian's hosted MCP endpoint.

## Setup

No clone required — the server is hosted by Atlassian. The `.mcp.json` template uses `npx mcp-remote@latest` to proxy to it.

```json
"atlassian": {
  "command": "npx",
  "args": [
    "mcp-remote@latest",
    "https://mcp.atlassian.com/v1/mcp"
  ]
}
```

## Auth

OAuth at first use. The first time you launch Claude Code with this MCP enabled, a browser tab opens and Atlassian asks you to authorise. The token is stored by `mcp-remote` locally — no need to put a secret in `.mcp.json`.

## Tools (Mac vs VPS)

This MCP exposes Atlassian's **camelCase** tool names: `getJiraIssue`, `searchJiraIssuesUsingJql`, `getConfluencePage`, `searchConfluenceUsingCql`, etc.

If you also use the **`mcp-atlassian` Python package** on a Linux box (a popular alternative), note that it ships **snake_case** names: `jira_get_issue`, `jira_search`, `confluence_get_page`, `confluence_search`. The two are **not interchangeable** — `--strict-mcp-config` will reject a mismatched name silently.

## Token file fallback

If you prefer a static-token setup (no OAuth dance), point this entry at the Python `mcp-atlassian` package instead:

```json
"atlassian": {
  "command": "/usr/local/bin/mcp-atlassian",
  "args": [
    "--jira-url", "https://{{JIRA_HOST}}",
    "--jira-username", "{{JIRA_EMAIL}}",
    "--jira-token", "{{JIRA_API_TOKEN}}",
    "--confluence-url", "https://{{JIRA_HOST}}/wiki",
    "--confluence-username", "{{JIRA_EMAIL}}",
    "--confluence-token", "{{JIRA_API_TOKEN}}"
  ]
}
```

Tool names become snake_case. Update your `settings.local.json` allowlist accordingly.

## Common gotchas

- **Token revocation.** When you rotate the Atlassian API token, the OAuth cache must be cleared: `rm -rf ~/.mcp-remote/` then re-launch.
- **Confluence `update_page` is full-replace.** Always read the full body first, modify only your target section, then send the complete body back.
- **Markdown round-trip flattens code fences.** A ` ```bash ` block becomes `Defaultbash# command…` when read via `contentFormat: "markdown"`. Use `"adf"` (Mac/managed) or `"storage"` (Python package) for rich pages.
