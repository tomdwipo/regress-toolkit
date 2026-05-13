#!/usr/bin/env bash
# check-leaks.sh — local pre-push leak detector.
#
# Reads forbidden regex patterns from `.leak-patterns.local` (gitignored).
# Greps the tree (or just the diff against origin/main) for matches.
# Exits non-zero on any hit so a pre-push hook can block the push.
#
# Usage:
#   bash scripts/check-leaks.sh              # scan whole tree
#   bash scripts/check-leaks.sh --diff       # scan only staged + unpushed changes
#   bash scripts/check-leaks.sh --hook       # quiet mode for git hook
#
# Setup:
#   cp .leak-patterns.local.example .leak-patterns.local
#   $EDITOR .leak-patterns.local
#   bash scripts/install-pre-push-hook.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATTERNS_FILE="$ROOT/.leak-patterns.local"
MODE="tree"
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --diff) MODE="diff"; shift ;;
    --hook) MODE="diff"; QUIET=1; shift ;;
    *)      echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ ! -f "$PATTERNS_FILE" ]]; then
  if [[ "$QUIET" -eq 0 ]]; then
    echo "==> No .leak-patterns.local found — skipping leak scan."
    echo "    To enable: cp .leak-patterns.local.example .leak-patterns.local"
  fi
  exit 0
fi

# Build a pipe-joined regex from non-comment, non-empty lines of the patterns file.
REGEX="$(grep -vE '^\s*(#|$)' "$PATTERNS_FILE" | paste -sd'|' -)"
if [[ -z "$REGEX" ]]; then
  [[ "$QUIET" -eq 0 ]] && echo "==> .leak-patterns.local has no active patterns — skipping."
  exit 0
fi

case "$MODE" in
  tree)
    [[ "$QUIET" -eq 0 ]] && echo "==> Scanning entire working tree for forbidden patterns"
    HITS="$(grep -rEin \
        --exclude-dir=.git --exclude-dir=node_modules \
        --exclude=".leak-patterns.local" --exclude=".sanitize.sed.local" \
        "$REGEX" "$ROOT" 2>/dev/null || true)"
    ;;
  diff)
    [[ "$QUIET" -eq 0 ]] && echo "==> Scanning staged + unpushed changes for forbidden patterns"
    BASE="$(git -C "$ROOT" merge-base HEAD origin/main 2>/dev/null || echo "")"
    if [[ -z "$BASE" ]]; then
      # First push or no remote — fall back to whole tree
      HITS="$(grep -rEin \
          --exclude-dir=.git --exclude-dir=node_modules \
          --exclude=".leak-patterns.local" --exclude=".sanitize.sed.local" \
          "$REGEX" "$ROOT" 2>/dev/null || true)"
    else
      DIFF="$(git -C "$ROOT" diff "$BASE"..HEAD --no-color || true)"
      # Scan ADDED lines only — deletions of forbidden patterns are healthy.
      # `^\+[^+]` matches diff "+" lines while excluding the "+++ b/file" header.
      HITS="$(printf '%s\n' "$DIFF" | grep -E '^\+[^+]' | grep -Ei "$REGEX" || true)"
    fi
    ;;
esac

if [[ -n "$HITS" ]]; then
  echo "" >&2
  echo "::: LEAK DETECTED — push blocked :::" >&2
  echo "$HITS" >&2
  echo "" >&2
  echo "Fix the offending lines (or update .leak-patterns.local if the match is a false positive) and re-run." >&2
  exit 1
fi

[[ "$QUIET" -eq 0 ]] && echo "==> CLEAN — no forbidden patterns found."
exit 0
