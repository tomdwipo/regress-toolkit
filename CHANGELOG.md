# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial public release.
- 22 slash commands across `universal/`, `mobile/`, `regress/` profiles.
- 10 specialist agents (Android/iOS architecture, design system, performance, security, quality, testing).
- `install.sh` with `--minimal`, `--mobile`, `--regress`, `--all` profiles.
- `setup-mcp.sh` to clone and build 5 MCP servers (atlassian, bitbucket, figma, jira-attachment, video-to-image).
- `doctor.sh` post-install health check.
- `sanitize.sed` to scrub project-specific identifiers before publishing updates.
- Templates for `CLAUDE.md`, `.mcp.json`, `settings.local.json`.
- Marp-flavoured `PRESENTATION.md` doubling as plain-markdown onboarding.
- GitHub Actions CI: sanitiser check + bats smoke test on every PR.

## [0.1.0] — TBD

First tagged release.
