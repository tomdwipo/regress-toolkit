#!/usr/bin/env bash
# install-pre-push-hook.sh — wire scripts/check-leaks.sh into .git/hooks/pre-push.
#
# After running this, every `git push` runs check-leaks.sh --hook and
# aborts the push on a hit.
#
# Safe to re-run (idempotent).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/.git/hooks/pre-push"

if [[ ! -d "$ROOT/.git" ]]; then
  echo "Error: $ROOT is not a git repo" >&2
  exit 1
fi

mkdir -p "$ROOT/.git/hooks"

cat > "$HOOK" <<'HOOK'
#!/usr/bin/env bash
# pre-push hook installed by regress-toolkit/scripts/install-pre-push-hook.sh
ROOT="$(git rev-parse --show-toplevel)"
exec bash "$ROOT/scripts/check-leaks.sh" --hook
HOOK

chmod +x "$HOOK"
echo "==> Installed pre-push hook at $HOOK"

if [[ ! -f "$ROOT/.leak-patterns.local" ]]; then
  echo ""
  echo "[!] No .leak-patterns.local yet — the hook will run but skip checks."
  echo "    Set it up with:"
  echo "      cp .leak-patterns.local.example .leak-patterns.local"
  echo "      \$EDITOR .leak-patterns.local"
fi
