# figma MCP

Read Figma files, fetch component metadata, render nodes as images.

## Setup

```bash
git clone https://github.com/GLips/Figma-Context-MCP.git ~/mcp-servers/figma-mcp
cd ~/mcp-servers/figma-mcp
npm install
npm run build
```

## `.mcp.json` stanza

```json
"figma": {
  "command": "node",
  "args": ["{{MCP_DIR}}/figma-mcp/dist/index.js"],
  "env": {
    "FIGMA_ACCESS_TOKEN": "{{FIGMA_ACCESS_TOKEN}}"
  }
}
```

## Auth

1. https://www.figma.com/settings → **Personal access tokens**
2. **Generate new token** — scopes: `file_content:read`, `file_metadata:read`, `library_content:read`.
3. Paste into `.mcp.json`. Token format is `figd_...`.

## Tools

| Tool              | What it does                                       |
|-------------------|----------------------------------------------------|
| `get_file`        | Whole file JSON                                    |
| `get_file_nodes`  | A specific node (frame, component) by id           |
| `get_image_render`| Render a node as PNG/JPG/SVG                       |
| `get_components`  | List components + variants in a file               |

## Common gotchas

- **Figma file IDs vs node IDs.** A URL `figma.com/design/<FILE_ID>/...?node-id=12-34` exposes both; node IDs are colon-separated internally (`12:34`) but URL-encoded with a dash.
- **Token scope creep.** A token with `file_content:write` is dangerous — `/design` and `/wireframe-image` only need read scopes.
- **Image render is rate-limited.** Cache the PNG locally; don't re-render the same node every session.
