# bitbucket MCP

Bitbucket Cloud REST wrapper — list PRs, fetch diffs, post comments, create PRs.

## Setup

```bash
# Cloned automatically by setup-mcp.sh if BITBUCKET_REPO is unset
git clone https://github.com/MatanYemini/bitbucket-mcp.git ~/mcp-servers/bitbucket-mcp
cd ~/mcp-servers/bitbucket-mcp
npm install
npm run build
```

## `.mcp.json` stanza

```json
"bitbucket": {
  "command": "node",
  "args": ["{{MCP_DIR}}/bitbucket-mcp/dist/index.js"],
  "env": {
    "BITBUCKET_API_TOKEN": "{{BITBUCKET_API_TOKEN}}",
    "BITBUCKET_EMAIL": "{{BITBUCKET_EMAIL}}"
  }
}
```

## Auth

Create an App Password at https://bitbucket.org/account/settings/app-passwords/ with scopes:

- `repository:read`
- `pullrequest:read`
- `pullrequest:write`
- `account:read`

Use your **Atlassian account email** (often a different domain from your Bitbucket username).

## Tools

| Tool                   | What it does                                  |
|------------------------|-----------------------------------------------|
| `list_prs`             | List open PRs in a repo                       |
| `get_pr`               | Fetch PR metadata, description, reviewers     |
| `get_diff`             | PR diff (unified, paginated)                  |
| `add_comment`          | Top-level PR comment                          |
| `add_reviewer`         | Add a reviewer by Atlassian account ID         |
| `approve_pr`           | Approve a PR (requires permission)            |
| `merge_pr`             | Merge (DO NOT call from automation)           |
| `update_pr`            | Edit title, description, reviewers            |
| `create_pr`            | Open a new PR                                 |
| `list_members`         | List workspace members                        |

## Common gotchas

- **Account ID vs username.** `add_reviewer` expects the Atlassian *account ID* (UUID-like), not the Bitbucket username. Look it up via Bitbucket UI → Profile → Manage account → Account ID.
- **`merge_pr` should never be in automation allowlists.** Human-only gate.
- **Rate limits.** Cloud is ~1000 req/hour. The MCP doesn't auto-retry — surface errors instead.
- **Workspace vs repo_slug.** Most tools take both. The workspace is the URL slug (`bitbucket.org/<workspace>/...`), not the workspace display name.
