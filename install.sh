#!/usr/bin/env bash
# install.sh — install regress-toolkit commands, agents, and templates into a project.
#
# Usage:
#   bash install.sh <project-dir> [--minimal|--mobile|--regress|--all] [--with-mcp]
#
# Examples:
#   bash install.sh ~/projects/my-android-repo --mobile
#   bash install.sh ~/projects/my-android-repo --all --with-mcp
#
# Profiles:
#   --minimal   universal commands only (9)
#   --mobile    universal + mobile (14)
#   --regress   universal + regress (17)
#   --all       universal + mobile + regress + agents (default)
#
# Flags:
#   --with-mcp  also run setup-mcp.sh (clones MCP server sources)
#   --target    install agents/commands into this dir (default: <project>/.claude)
#   --dry-run   show what would happen, do nothing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT=""
PROFILE="all"
WITH_MCP=0
DRY_RUN=0
TARGET=""

# --- arg parsing ------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --minimal|--mobile|--regress|--all) PROFILE="${1#--}"; shift ;;
    --with-mcp)                         WITH_MCP=1; shift ;;
    --dry-run)                          DRY_RUN=1; shift ;;
    --target)                           TARGET="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *)
      if [[ -z "$PROJECT" ]]; then PROJECT="$1"; shift
      else echo "Unknown arg: $1" >&2; exit 1; fi
      ;;
  esac
done

if [[ -z "$PROJECT" ]]; then
  echo "Error: project directory required" >&2
  echo "Usage: bash install.sh <project-dir> [--profile] [--with-mcp]" >&2
  exit 1
fi

# Expand ~ and resolve
PROJECT="${PROJECT/#\~/$HOME}"
if [[ ! -d "$PROJECT" ]]; then
  echo "Error: $PROJECT is not a directory" >&2
  exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd)"
TARGET="${TARGET:-$PROJECT/.claude}"

# --- helpers ---------------------------------------------------------------
say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
do_or_say() {
  if [[ "$DRY_RUN" -eq 1 ]]; then echo "    DRY: $*"; else eval "$@"; fi
}

# --- 1. announce -----------------------------------------------------------
say "regress-toolkit installer"
echo "    project: $PROJECT"
echo "    target:  $TARGET"
echo "    profile: $PROFILE"
echo "    with-mcp: $([[ $WITH_MCP -eq 1 ]] && echo yes || echo no)"
echo "    dry-run: $([[ $DRY_RUN -eq 1 ]] && echo yes || echo no)"
echo ""

# --- 2. copy commands ------------------------------------------------------
say "Installing commands → $TARGET/commands/"
do_or_say "mkdir -p \"$TARGET/commands\""

copy_profile() {
  local dir="$1"
  if [[ -d "$SCRIPT_DIR/commands/$dir" ]]; then
    for f in "$SCRIPT_DIR/commands/$dir"/*.md; do
      [[ -f "$f" ]] || continue
      do_or_say "cp \"$f\" \"$TARGET/commands/\""
    done
  fi
}

copy_profile universal
case "$PROFILE" in
  minimal) ;;
  mobile)  copy_profile mobile ;;
  regress) copy_profile regress ;;
  all)     copy_profile mobile; copy_profile regress ;;
esac

# --- 3. copy agents (only for --all or --mobile) ---------------------------
if [[ "$PROFILE" == "all" || "$PROFILE" == "mobile" ]]; then
  say "Installing agents → $TARGET/agents/"
  do_or_say "mkdir -p \"$TARGET/agents\""
  for f in "$SCRIPT_DIR/agents"/*.md; do
    [[ -f "$f" ]] || continue
    do_or_say "cp \"$f\" \"$TARGET/agents/\""
  done
fi

# --- 3b. copy skills (only for --all or --mobile) --------------------------
if [[ "$PROFILE" == "all" || "$PROFILE" == "mobile" ]] && [[ -d "$SCRIPT_DIR/skills" ]]; then
  say "Installing skills → $TARGET/skills/"
  do_or_say "mkdir -p \"$TARGET/skills\""
  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    do_or_say "cp -R \"$skill_dir\" \"$TARGET/skills/$skill_name\""
  done
fi

# --- 4. drop CLAUDE.md template if none exists -----------------------------
if [[ ! -f "$PROJECT/CLAUDE.md" ]]; then
  say "Installing CLAUDE.md template → $PROJECT/CLAUDE.md"
  do_or_say "cp \"$SCRIPT_DIR/templates/CLAUDE.md.template\" \"$PROJECT/CLAUDE.md\""
else
  warn "CLAUDE.md already exists — skipping (compare with $SCRIPT_DIR/templates/CLAUDE.md.template manually)"
fi

# --- 5. settings.local.json template ---------------------------------------
if [[ ! -f "$TARGET/settings.local.json" ]]; then
  say "Installing settings.local.json template → $TARGET/settings.local.json"
  do_or_say "cp \"$SCRIPT_DIR/templates/settings.local.json.template\" \"$TARGET/settings.local.json\""
else
  warn "settings.local.json already exists — skipping"
fi

# --- 6. .mcp.json prompts + render -----------------------------------------
say "Setting up .mcp.json"
if [[ -f "$PROJECT/.mcp.json" ]]; then
  warn ".mcp.json already exists at $PROJECT/.mcp.json — skipping (delete it first to regenerate)"
else
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "    DRY: would prompt for tokens and render $PROJECT/.mcp.json"
  else
    echo "    You'll be prompted for tokens. Press Enter to leave a value blank for now."
    read -r -p "    Jira email: " JIRA_EMAIL || JIRA_EMAIL=""
    read -r -p "    Jira API token: " JIRA_API_TOKEN || JIRA_API_TOKEN=""
    read -r -p "    Jira host (e.g. acme.atlassian.net): " JIRA_HOST || JIRA_HOST=""
    read -r -p "    Jira cloudId (UUID, optional): " JIRA_CLOUD_ID || JIRA_CLOUD_ID=""
    read -r -p "    Bitbucket email: " BITBUCKET_EMAIL || BITBUCKET_EMAIL=""
    read -r -p "    Bitbucket API token: " BITBUCKET_API_TOKEN || BITBUCKET_API_TOKEN=""
    read -r -p "    Figma access token (optional): " FIGMA_ACCESS_TOKEN || FIGMA_ACCESS_TOKEN=""
    read -r -p "    MCP servers directory [default: ~/mcp-servers]: " MCP_DIR || MCP_DIR=""
    MCP_DIR="${MCP_DIR:-$HOME/mcp-servers}"
    UV_BIN="$(command -v uv 2>/dev/null || echo "$HOME/.local/bin/uv")"

    sed \
      -e "s|{{JIRA_EMAIL}}|$JIRA_EMAIL|g" \
      -e "s|{{JIRA_API_TOKEN}}|$JIRA_API_TOKEN|g" \
      -e "s|{{JIRA_HOST}}|$JIRA_HOST|g" \
      -e "s|{{JIRA_CLOUD_ID}}|$JIRA_CLOUD_ID|g" \
      -e "s|{{BITBUCKET_EMAIL}}|$BITBUCKET_EMAIL|g" \
      -e "s|{{BITBUCKET_API_TOKEN}}|$BITBUCKET_API_TOKEN|g" \
      -e "s|{{FIGMA_ACCESS_TOKEN}}|$FIGMA_ACCESS_TOKEN|g" \
      -e "s|{{MCP_DIR}}|$MCP_DIR|g" \
      -e "s|{{UV_BIN}}|$UV_BIN|g" \
      "$SCRIPT_DIR/templates/.mcp.json.template" > "$PROJECT/.mcp.json"
    echo "    .mcp.json rendered at $PROJECT/.mcp.json (mode 0600)"
    chmod 600 "$PROJECT/.mcp.json"
  fi
fi

# --- 7. optional MCP source clone ------------------------------------------
if [[ "$WITH_MCP" -eq 1 ]]; then
  say "Running setup-mcp.sh (clones MCP server sources)"
  do_or_say "MCP_DIR=\"${MCP_DIR:-$HOME/mcp-servers}\" bash \"$SCRIPT_DIR/setup-mcp.sh\""
fi

# --- 8. health check -------------------------------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  say "Running doctor.sh"
  bash "$SCRIPT_DIR/doctor.sh" "$PROJECT" || warn "doctor.sh reported issues — review above"
fi

echo ""
say "Done. Next steps:"
echo "    1. Open $PROJECT in Claude Code"
echo "    2. Try: /plan-first \"add a hello-world screen\""
echo "    3. If MCP servers aren't built yet:  bash $SCRIPT_DIR/setup-mcp.sh"
