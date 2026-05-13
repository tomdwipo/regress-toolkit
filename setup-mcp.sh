#!/usr/bin/env bash
# setup-mcp.sh — clone and build the MCP servers referenced by .mcp.json.template.
#
# Usage:
#   MCP_DIR=~/mcp-servers bash setup-mcp.sh
#
# Servers handled:
#   - bitbucket-mcp     (Node)
#   - figma-mcp         (Node)
#   - jira-attachment   (Python, uv)
#   - video-to-image    (Python, uv, requires ffmpeg)
#   - atlassian         (uses npx mcp-remote@latest — nothing to clone)

set -euo pipefail

MCP_DIR="${MCP_DIR:-$HOME/mcp-servers}"
mkdir -p "$MCP_DIR"

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing dep: $1 (install before re-running)"
}

# --- preflight -------------------------------------------------------------
need git
need node
need npm
need npx

if ! command -v uv >/dev/null 2>&1; then
  warn "uv not found — Python MCPs (jira-attachment, video-to-image) will be skipped"
  warn "install: curl -LsSf https://astral.sh/uv/install.sh | sh"
  HAVE_UV=0
else
  HAVE_UV=1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  warn "ffmpeg not found — video-to-image MCP will fail at runtime"
  warn "macOS: brew install ffmpeg | Linux: apt-get install ffmpeg"
fi

# --- repo URLs (override via env if your forks live elsewhere) -------------
BITBUCKET_REPO="${BITBUCKET_REPO:-https://github.com/MatanYemini/bitbucket-mcp.git}"
FIGMA_REPO="${FIGMA_REPO:-https://github.com/GLips/Figma-Context-MCP.git}"
JIRA_ATTACHMENT_REPO="${JIRA_ATTACHMENT_REPO:-https://github.com/tomdwipo/jira-attachment-mcp.git}"
VIDEO_TO_IMAGE_REPO="${VIDEO_TO_IMAGE_REPO:-https://github.com/tomdwipo/video-to-image-mcp.git}"

clone_or_pull() {
  local name="$1" url="$2" dest="$MCP_DIR/$1"
  if [[ -d "$dest/.git" ]]; then
    say "[$name] updating"
    git -C "$dest" pull --ff-only || warn "[$name] pull failed; continuing"
  else
    say "[$name] cloning $url"
    git clone "$url" "$dest" || { warn "[$name] clone failed — set ${name^^}_REPO env var to override URL"; return 1; }
  fi
}

build_node() {
  local name="$1" dest="$MCP_DIR/$1"
  if [[ -f "$dest/package.json" ]]; then
    say "[$name] npm install + build"
    (cd "$dest" && npm install --silent && npm run build --if-present)
  fi
}

build_python() {
  local name="$1" dest="$MCP_DIR/$1"
  if [[ -f "$dest/pyproject.toml" ]]; then
    say "[$name] uv sync"
    (cd "$dest" && uv sync) || warn "[$name] uv sync failed"
  fi
}

# --- bitbucket -------------------------------------------------------------
clone_or_pull bitbucket-mcp "$BITBUCKET_REPO" && build_node bitbucket-mcp || true

# --- figma -----------------------------------------------------------------
clone_or_pull figma-mcp "$FIGMA_REPO" && build_node figma-mcp || true

# --- python MCPs (only if uv present) --------------------------------------
if [[ "$HAVE_UV" -eq 1 ]]; then
  clone_or_pull jira-attachment "$JIRA_ATTACHMENT_REPO" && build_python jira-attachment || true
  clone_or_pull video-to-image  "$VIDEO_TO_IMAGE_REPO"  && build_python video-to-image  || true
fi

say "Done. MCP_DIR = $MCP_DIR"
echo "    Update .mcp.json paths if MCP_DIR differs from ~/mcp-servers."
