# datadog MCP (optional)

The regress branch additionally uses Datadog's MCP for production observability. It's not installed by default because most learners won't have a Datadog account. Add it manually if you want it.

## Setup

Install Datadog's official MCP CLI:

```bash
# Method varies by Datadog edition; the binary is shipped via their setup docs:
# https://docs.datadoghq.com/bits_ai/mcp_server/setup/

# Typical install (check current docs first):
curl -fsSL https://raw.githubusercontent.com/DataDog/datadog-mcp/main/install.sh | sh
```

## `.mcp.json` stanza

```json
"datadog": {
  "type": "stdio",
  "command": "{{HOME}}/.local/bin/datadog_mcp_cli",
  "args": [],
  "env": {}
}
```

The CLI authenticates via your Datadog session (browser OAuth on first launch). No API keys in `.mcp.json`.

## Useful skills

This MCP exposes "skills" rather than raw tools — load them with `load_datadog_skill`:

- `datadog/traces`
- `datadog/logs`
- `datadog/metrics`
- `datadog/rum`
- `datadog/visualizations` (charts)

Always load a domain skill **before** running queries; results are dramatically better with the skill loaded.

## Common gotchas

- **Site URLs differ.** `us1`, `us3`, `us5`, `eu1` — pick the one matching your Datadog account or queries return empty.
- **Env tag is full-word.** `env:production`, `env:development`, `env:staging` (not `prod`/`dev`/`stg`).
- **Live mode.** For real-time queries set `WF_DATADOG_QUERY_MODE=live` in the MCP env.
