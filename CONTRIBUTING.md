# Contributing

Thanks for taking the time to look at this. Here's how to keep contributions safe and easy to merge.

## Ground rules

1. **No secrets in commits.** Universal token shapes (Atlassian, Figma, GitHub, Slack, OpenAI, AWS) are blocked by CI. Company-specific identifiers are blocked **locally** via a pre-push hook (see below). The public repo carries no project-specific pattern list.
2. **Templates only.** Real `.mcp.json` and `settings.local.json` are git-ignored. Only `templates/*.template` files ship.
3. **Test the installer.** Any change to `install.sh`, `setup-mcp.sh`, or `doctor.sh` should pass `bats tests/install.bats` locally before opening a PR.
4. **Commit message style.** `type(scope): short summary` — types are `feat`, `fix`, `docs`, `chore`, `test`, `refactor`. No AI attribution.

## One-time setup for maintainers

```bash
git clone https://github.com/tomdwipo/regress-toolkit.git
cd regress-toolkit

# 1. Copy the leak-pattern template to its local-only counterpart and fill in
#    YOUR project's identifiers (org name, hosts, IPs, etc.) that must never
#    appear in a public commit. The .local file is gitignored.
cp .leak-patterns.local.example .leak-patterns.local
$EDITOR .leak-patterns.local

# 2. (Optional) Build a real sanitiser by copying the template and adding
#    your own substitutions. .sanitize.sed.local is also gitignored.
cp sanitize.sed .sanitize.sed.local
$EDITOR .sanitize.sed.local

# 3. Install the pre-push hook so any forbidden pattern aborts `git push`.
bash scripts/install-pre-push-hook.sh
```

## Local development loop

```bash
# Manual leak scan (the hook runs this on push)
bash scripts/check-leaks.sh

# Run install in a throwaway dir
mkdir -p /tmp/rt-test && bash install.sh /tmp/rt-test --minimal

# Run the test suite
bats tests/
```

## Adding a new command

1. Drop the `.md` into `commands/{profile}/`.
2. Make sure all references to hosts, project keys, and workspaces use `{{PLACEHOLDER}}` form.
3. Add a row in `README.md` under the matching profile table.
4. Update `CHANGELOG.md` under `[Unreleased]`.

## Adding a new MCP server

1. Add `mcp/{name}.md` with install steps + token format.
2. Append a stanza to `templates/.mcp.json.template`.
3. Add a clone branch in `setup-mcp.sh`.
4. Update `doctor.sh` health check.
