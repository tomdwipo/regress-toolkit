#!/usr/bin/env bash
# sync-from-source.sh — pull latest commands/agents from a source repo and re-sanitise.
#
# Usage:
#   SOURCE_REPO=~/projects/my-regress bash sync-from-source.sh
#
# Expects $SOURCE_REPO/.claude/commands and $SOURCE_REPO/.claude/agents.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_REPO="${SOURCE_REPO:-}"

if [[ -z "$SOURCE_REPO" || ! -d "$SOURCE_REPO/.claude" ]]; then
  echo "Set SOURCE_REPO=<path-to-source>/your-project (must contain .claude/)" >&2
  exit 1
fi

UNIVERSAL=(plan-first breakdown-design do-implementation mini-prd trd search search-smart update-doc wireframe-image)
MOBILE=(design ui-test mobile-analysis feature-report qa-align)
REGRESS_PROFILE=(deep-analysis full-analysis create-jira-task prd-align quality-to-jira quality-publish-confluence production-to-jira push-pr)

echo "==> Wiping commands/ and agents/"
rm -rf "$SCRIPT_DIR/commands/universal" "$SCRIPT_DIR/commands/mobile" "$SCRIPT_DIR/commands/regress" "$SCRIPT_DIR/agents"
mkdir -p "$SCRIPT_DIR/commands/universal" "$SCRIPT_DIR/commands/mobile" "$SCRIPT_DIR/commands/regress" "$SCRIPT_DIR/agents"

echo "==> Copying from $SOURCE_REPO/.claude/"
for f in "${UNIVERSAL[@]}";       do cp "$SOURCE_REPO/.claude/commands/$f.md" "$SCRIPT_DIR/commands/universal/"; done
for f in "${MOBILE[@]}";          do cp "$SOURCE_REPO/.claude/commands/$f.md" "$SCRIPT_DIR/commands/mobile/";    done
for f in "${REGRESS_PROFILE[@]}"; do cp "$SOURCE_REPO/.claude/commands/$f.md" "$SCRIPT_DIR/commands/regress/";   done
cp "$SOURCE_REPO/.claude/agents/"*.md "$SCRIPT_DIR/agents/"

SED_FILE="$SCRIPT_DIR/.sanitize.sed.local"
if [[ ! -f "$SED_FILE" ]]; then
  echo "[!] $SED_FILE missing — falling back to the generic sanitize.sed template." >&2
  echo "    For real sanitisation, copy sanitize.sed to .sanitize.sed.local and fill in patterns." >&2
  SED_FILE="$SCRIPT_DIR/sanitize.sed"
fi

echo "==> Running sed -f $SED_FILE"
find "$SCRIPT_DIR/commands" "$SCRIPT_DIR/agents" -type f -name '*.md' -print0 \
  | xargs -0 sed -Ei.bak -f "$SED_FILE"
find "$SCRIPT_DIR/commands" "$SCRIPT_DIR/agents" -name '*.bak' -delete

echo "==> Running scripts/check-leaks.sh"
bash "$SCRIPT_DIR/scripts/check-leaks.sh" || {
  echo "LEAKS detected — fix .sanitize.sed.local / .leak-patterns.local before committing." >&2
  exit 1
}
echo "==> CLEAN. Review with: git diff commands/ agents/"
