# jira-attachment MCP

Download images and videos attached to Jira issues. Used by `/trd`, `/feature-report`, and any command that needs to look at a screenshot or screen recording from a ticket.

## Setup

```bash
git clone https://github.com/tomdwipo/jira-attachment-mcp.git ~/mcp-servers/jira-attachment
cd ~/mcp-servers/jira-attachment
uv sync
```

`uv` is required: https://docs.astral.sh/uv/getting-started/installation/

## `.mcp.json` stanza

```json
"jira-attachment": {
  "command": "{{UV_BIN}}",
  "args": [
    "run", "--directory", "{{MCP_DIR}}/jira-attachment",
    "python", "mcp_server.py"
  ],
  "env": {
    "JIRA_EMAIL": "{{JIRA_EMAIL}}",
    "JIRA_API_TOKEN": "{{JIRA_API_TOKEN}}",
    "JIRA_SITE": "{{JIRA_HOST}}",
    "JIRA_CLOUD_ID": "{{JIRA_CLOUD_ID}}"
  }
}
```

## Tools

| Tool                   | What it does                                          |
|------------------------|-------------------------------------------------------|
| `list_attachments`     | List files attached to an issue                       |
| `download_attachment`  | Download a single file by ID                          |
| `download_all_images`  | Download every `image/*` MIME attachment              |
| `download_all_videos`  | Download every `video/*` MIME attachment              |

## Auth

Same Atlassian API token as the `atlassian` MCP. Get it from https://id.atlassian.com/manage-profile/security/api-tokens.

## Common gotchas

- **`JIRA_CLOUD_ID` is required by some endpoints**, but the MCP can infer it from the site host on first call. If a call fails with 401, set the cloudId explicitly.
- **Downloaded files land in the project's working directory by default.** If the project has a tight `.gitignore`, attachments may be untracked but cluttering — add `.docs/jira-attachments/` to your ignore patterns.
