# Hermes Agent Stock Research Tools

Token-efficient stock deep-research + professional slide deck generation for Hermes Agent.

**Reduces LLM token consumption ~400x** vs traditional multi-subagent research while producing identical-quality output.

## Quick Start

```bash
# 1. Install dependencies
pip install yfinance

# 2. Add tools to PATH
export PATH="$HOME/.hermes-tools/bin:$PATH"

# 3. Copy skills
cp -r skills/* ~/.hermes/skills/

# 4. Run a stock deep-dive (3 commands, ~25 seconds)
stock-data AAPL > /tmp/data.json       # Collect financials + web search
# → Synthesize findings into spec.json (LLM does this in 1 turn)
deck-deliver spec.json ~/research/aapl-deck.html  # Generate + inline
```

## Tools

| Tool | Description | Time |
|------|-------------|------|
| `fin` | Instant stock financials (price, P/E, PEG, EPS, revenue, analysts, charts) | 3s |
| `websearch` | Reliable web search with auto-fallback (gemini-search → ddgs) | 3-80s |
| `stock-data` | Collect all research data for a stock in one call (fin + 5 web searches) | 20s |
| `deck-gen` | Generate 14-slide professional HTML deck from JSON spec | 2s |
| `deck-deliver` | Generate + inline assets + verify offline delivery | 5s |
| `html-inline` | Bundle CDN assets (Chart.js, Font Awesome) into self-contained HTML | 2s |

## Skills

| Skill | Description |
|-------|-------------|
| `stock-research` | 3-phase token-efficient stock deep-dive pipeline |
| `chart-verify` | Verify Chart.js rendering via browser_console (no vision model needed) |
| `gemini-fallback` | Use Gemini for image analysis, web search, and image generation as fallback |

## Full Workflow

### Phase 1: Collect Data (1 tool call, ~20s)
```bash
stock-data SYMBOL > /tmp/stock.json
```
Returns: instant financials (yfinance) + 5 targeted web searches.

### Phase 2: Synthesize (1 LLM turn)
The agent reads `/tmp/stock.json` and synthesizes into a `deck-gen` JSON spec. The spec has 14 slide types matching the standard stock research deck structure: title, exec-summary, company, segments, revenue, margins, balance, stock, analysts, industry, catalyst, catalyst2, risks, thesis.

### Phase 3: Deliver (1 tool call, ~5s)
```bash
deck-deliver /tmp/spec.json ~/research/SYMBOL-deck.html
```
Output: fully offline HTML file with Chart.js charts, keyboard/touch navigation, and print-optimized CSS.

## Token Efficiency

| Approach | Subagents | Tool calls | Input tokens | Time |
|----------|-----------|------------|-------------|------|
| Traditional (6 subagents) | 6 parallel | ~120 | ~12M | ~15 min |
| **This pipeline** | **0** | **3** | **~30K** | **~25s** |

The key insight: financial data doesn't need LLM processing. `fin` gives instant structured numbers. The 5 web searches return enough for qualitative synthesis. The only LLM work is reading the ~10KB data blob and writing a ~13KB JSON spec.

## Requirements

- **Python 3.10+** with `yfinance` (`pip install yfinance`)
- `ddgs` CLI for web search (install via `pip install ddgs`)
- Optional: `gemini-search` for Google-quality search (requires browser cookie auth)
- Hermes Agent (skills are Hermes-specific but tools work standalone)

## Slide Deck Features

- 14 professionally structured slides (dark theme)
- Chart.js charts (bar, doughnut) with lazy rendering
- Keyboard navigation (← → Space), touch swipe, progress dots
- Print-optimized CSS for PDF export
- Fully offline after generation (Chart.js + Font Awesome inlined)

## Privacy

No API keys, tokens, or personal data are included. All tools use free data sources (Yahoo Finance via yfinance, DuckDuckGo via ddgs). The optional gemini-search requires your own Google browser cookies.

## License

MIT
