# Seminar deck — "How LLMs Work & Why This Framework Exists"

A 25–30 minute seminar that walks through:

1. What an LLM actually is (next-token predictor, blank slate per session).
2. Why CLAUDE.md, slash commands, agents, and MCP servers are *all just text* in the context window.
3. The **RPI pattern** that shapes every command in this toolkit.
4. A live demo of `/trd` → `/plan-first` → `/breakdown-design` → `/create-jira-task` on a real feature.

## Files

| File                 | Format                | Purpose                                     |
|----------------------|-----------------------|---------------------------------------------|
| `index.html`         | Standalone HTML deck  | Open in a browser. Arrow keys to navigate.  |
| `SPEAKER_NOTES.md`   | Markdown              | Per-slide speaker script (Bahasa Indonesia + English mix). |

## How to view

```bash
# Just open the HTML in your browser
open presentation/index.html        # macOS
xdg-open presentation/index.html    # Linux
start presentation/index.html       # Windows

# Or serve locally for keyboard navigation reliability
python3 -m http.server 8000 --directory presentation/
# then visit http://localhost:8000
```

## How to present

1. Read through `SPEAKER_NOTES.md` once — it tells the story slide-by-slide.
2. Open `index.html` full-screen in a browser.
3. Use arrow keys to navigate.
4. Total runtime is ~25–30 min for 26 slides.

## What's redacted

The original deck included internal product screenshots and was exported to PDF and PPTX. For the public release:

- Screenshots are replaced with `[Internal screenshot redacted]` placeholders.
- PDF and PPTX exports are not committed (they contained unsanitisable embedded text).
- Product/company names are replaced with `{{ORG_NAME}}` style placeholders.

If you want to re-export the sanitised HTML to PDF or PPTX yourself:

```bash
# PDF via headless Chrome
google-chrome --headless --print-to-pdf=presentation/exports/deck.pdf \
  --no-pdf-header-footer presentation/index.html

# PPTX via reveal-pptx-export or similar tools — your mileage may vary.
```

## Adapting the deck

The HTML is hand-written, not generated. To adapt for your own team:

1. Find/replace `{{ORG_NAME}}`, `{{PRODUCT_NAME}}`, `{{APP_CODE}}` with your values.
2. Swap the redacted screenshots for your own.
3. Edit `SPEAKER_NOTES.md` to match your slides.

The conceptual content (LLM mechanics, RPI pattern, gates) is generic — only the demo slides need company-specific updates.
