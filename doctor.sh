#!/usr/bin/env bash
# doctor.sh — verify a project is wired correctly for regress-toolkit.
#
# Usage:
#   bash doctor.sh [project-dir]
#
# Checks:
#   - .claude/commands present
#   - .claude/agents present (if installed)
#   - CLAUDE.md present and under 40000 chars
#   - .mcp.json present and parseable
#   - host CLIs: node, npm, npx, git, jq, uv (warn), ffmpeg (warn)
#   - MCP server binaries reachable

set -uo pipefail

PROJECT="${1:-$(pwd)}"
PROJECT="${PROJECT/#\~/$HOME}"

PASS=0; FAIL=0; WARN=0

ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; PASS=$((PASS+1)); }
warn() { printf '\033[1;33m[!!]\033[0m %s\n' "$*"; WARN=$((WARN+1)); }
fail() { printf '\033[1;31m[x ]\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }

# --- structural checks -----------------------------------------------------
if [[ -d "$PROJECT/.claude/commands" ]]; then
  N=$(find "$PROJECT/.claude/commands" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
  ok ".claude/commands present ($N commands)"
else
  fail ".claude/commands missing"
fi

if [[ -d "$PROJECT/.claude/agents" ]]; then
  N=$(find "$PROJECT/.claude/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
  ok ".claude/agents present ($N agents)"
else
  warn ".claude/agents missing (ok if you installed --minimal/--regress)"
fi

if [[ -f "$PROJECT/CLAUDE.md" ]]; then
  SZ=$(wc -c < "$PROJECT/CLAUDE.md" | tr -d ' ')
  if [[ "$SZ" -lt 40000 ]]; then
    ok "CLAUDE.md present ($SZ chars, under 40000)"
  else
    warn "CLAUDE.md is $SZ chars — over 40000 budget. Trim before next session."
  fi
else
  fail "CLAUDE.md missing"
fi

if [[ -f "$PROJECT/.mcp.json" ]]; then
  if command -v jq >/dev/null 2>&1; then
    if jq -e '.mcpServers | keys' "$PROJECT/.mcp.json" >/dev/null 2>&1; then
      SERVERS=$(jq -r '.mcpServers | keys[]' "$PROJECT/.mcp.json" | paste -sd, -)
      ok ".mcp.json parseable (servers: $SERVERS)"
    else
      fail ".mcp.json present but invalid JSON or missing .mcpServers"
    fi
  else
    ok ".mcp.json present (jq missing — cannot deep-verify)"
  fi
else
  warn ".mcp.json missing — run install.sh again or copy templates/.mcp.json.template manually"
fi

# --- host CLI checks -------------------------------------------------------
for c in node npm npx git; do
  if command -v "$c" >/dev/null 2>&1; then ok "$c on PATH ($(command -v $c))"; else fail "$c missing"; fi
done

if command -v jq >/dev/null 2>&1; then ok "jq on PATH"; else warn "jq missing (needed for doctor + scripts)"; fi
if command -v uv >/dev/null 2>&1; then ok "uv on PATH"; else warn "uv missing (Python MCPs won't run)"; fi
if command -v ffmpeg >/dev/null 2>&1; then ok "ffmpeg on PATH"; else warn "ffmpeg missing (video-to-image MCP will fail)"; fi

# --- MCP server binaries ---------------------------------------------------
if command -v jq >/dev/null 2>&1 && [[ -f "$PROJECT/.mcp.json" ]]; then
  while IFS= read -r path; do
    [[ -z "$path" || "$path" == "null" ]] && continue
    if [[ -e "$path" ]]; then ok "MCP path exists: $path"
    else warn "MCP path missing: $path (run setup-mcp.sh)"; fi
  done < <(jq -r '.mcpServers | to_entries[] | .value.args[]? | select(test("^/"))' "$PROJECT/.mcp.json" 2>/dev/null | sort -u)
fi

# --- summary ---------------------------------------------------------------
echo ""
echo "doctor: $PASS ok, $WARN warn, $FAIL fail"
[[ "$FAIL" -eq 0 ]]
