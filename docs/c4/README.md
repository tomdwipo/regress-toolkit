# C4 Architecture — regress-toolkit

> The [C4 model](https://c4model.com) at four zoom levels: from "who runs it" down to "what one file looks like". Read top to bottom.

| Level | File | Answers |
|-------|------|---------|
| C1 | [c1-context.md](c1-context.md) | Who runs the toolkit, and what does it touch? |
| C2 | [c2-container.md](c2-container.md) | What are the moving parts inside the repo? |
| C3 | [c3-component.md](c3-component.md) | How do the 5 principles, 6 gates, 4 profiles, and commands/agents wire together? |
| C4 | [c4-code.md](c4-code.md) | What does one command, one agent, one install step actually look like? |

Every diagram here is ASCII — it diffs cleanly in git and renders in any terminal, matching the toolkit's terminal-first nature. The model mirrors the layout of the private source repo this toolkit is extracted from, so the two stay mentally in sync for `sync-from-source.sh`.

## The one-paragraph version

regress-toolkit is **not a running service**. It is an *installer plus a content bundle*: `install.sh` copies a "Claude Code brain" — 22 slash commands, 10 agents, 3 skills, 4 templates — into a target project, optionally clones 5 MCP servers, runs a health check, and exits. Everything after that is the developer, Claude Code, and the MCP servers acting inside the target project. The content bundle encodes one idea: the **regress workflow** — ship high-stakes mobile code at a steady cadence while keeping a human on every irreversible decision (6 gates, 5 north-star principles).
