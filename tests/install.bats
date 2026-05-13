#!/usr/bin/env bats
# install.bats — smoke tests for install.sh
#
# Runs in CI on Ubuntu. Verifies that --dry-run produces expected file moves
# and that a real install copies the right number of commands per profile.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TMP="$(mktemp -d)"
  mkdir -p "$TMP/project"
}

teardown() {
  rm -rf "$TMP"
}

@test "install.sh requires a project dir" {
  run bash "$ROOT/install.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"project directory required"* ]]
}

@test "install.sh --minimal installs 9 universal commands" {
  run bash "$ROOT/install.sh" "$TMP/project" --minimal --target "$TMP/project/.claude"
  # Installer reads from stdin for token prompts; in non-tty mode read returns
  # immediately with empty strings, which is fine for this smoke test.
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  count=$(ls "$TMP/project/.claude/commands/" | wc -l | tr -d ' ')
  [ "$count" -eq 9 ]
}

@test "install.sh --mobile installs 14 commands + 10 agents + 3 skills" {
  run bash "$ROOT/install.sh" "$TMP/project" --mobile --target "$TMP/project/.claude"
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  cmd_count=$(ls "$TMP/project/.claude/commands/" | wc -l | tr -d ' ')
  agent_count=$(ls "$TMP/project/.claude/agents/" | wc -l | tr -d ' ')
  skill_count=$(ls "$TMP/project/.claude/skills/" | wc -l | tr -d ' ')
  [ "$cmd_count" -eq 14 ]
  [ "$agent_count" -eq 10 ]
  [ "$skill_count" -eq 3 ]
}

@test "install.sh --regress installs 17 commands (universal + regress)" {
  run bash "$ROOT/install.sh" "$TMP/project" --regress --target "$TMP/project/.claude"
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  count=$(ls "$TMP/project/.claude/commands/" | wc -l | tr -d ' ')
  [ "$count" -eq 17 ]
}

@test "install.sh --all installs 22 commands + 10 agents + 3 skills" {
  run bash "$ROOT/install.sh" "$TMP/project" --all --target "$TMP/project/.claude"
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  cmd_count=$(ls "$TMP/project/.claude/commands/" | wc -l | tr -d ' ')
  agent_count=$(ls "$TMP/project/.claude/agents/" | wc -l | tr -d ' ')
  skill_count=$(ls "$TMP/project/.claude/skills/" | wc -l | tr -d ' ')
  [ "$cmd_count" -eq 22 ]
  [ "$agent_count" -eq 10 ]
  [ "$skill_count" -eq 3 ]
}

@test "install.sh --dry-run does not create files" {
  run bash "$ROOT/install.sh" "$TMP/project" --minimal --dry-run --target "$TMP/project/.claude"
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  [ ! -d "$TMP/project/.claude/commands" ]
}

@test "install.sh drops CLAUDE.md template when missing" {
  run bash "$ROOT/install.sh" "$TMP/project" --minimal --target "$TMP/project/.claude"
  [ -f "$TMP/project/CLAUDE.md" ]
  grep -q "{{PRODUCT_NAME}}" "$TMP/project/CLAUDE.md"
}

@test "install.sh respects existing CLAUDE.md" {
  echo "custom" > "$TMP/project/CLAUDE.md"
  run bash "$ROOT/install.sh" "$TMP/project" --minimal --target "$TMP/project/.claude"
  [ "$(cat "$TMP/project/CLAUDE.md")" = "custom" ]
}

@test "no well-known token-shaped strings in tree" {
  # Universal token shapes only — no company-specific patterns here.
  TOKEN_RE='ATATT3xFfGF0[A-Za-z0-9_=-]{20,}|figd_[A-Za-z0-9_-]{20,}|gho_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[A-Z0-9]{16}'
  run bash -c "grep -rE \"$TOKEN_RE\" '$ROOT/commands' '$ROOT/agents' '$ROOT/templates' '$ROOT/skills' '$ROOT/presentation' '$ROOT/docs' '$ROOT/mcp' 2>/dev/null"
  [ "$status" -ne 0 ]
}

@test "doctor.sh detects missing project files cleanly" {
  run bash "$ROOT/doctor.sh" "$TMP/project"
  # No .claude yet — expect failures but a clean run
  [[ "$output" == *"doctor:"* ]]
}
