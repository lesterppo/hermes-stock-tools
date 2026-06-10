---
name: stock-research
description: Token-efficient stock deep-research + slide deck pipeline. Replaces 6-subagent workflow with a single data collection step + LLM synthesis.
---

# Stock Research Pipeline (Token-Efficient)

Replaces the old 6-subagent deep-research workflow for stocks.
Token savings: ~12M → ~500K input tokens (~24x reduction).

## Workflow (3 phases, ~5 turns)

### Phase 1: Collect Data (1 tool call, ~30s)
```bash
stock-data SYMBOL > /tmp/stock.json
```
Returns: financials (fin), chart data, 5× targeted web searches (20 results total).

### Phase 2: Synthesize (1-2 LLM turns)
Read `/tmp/stock.json` and synthesize into a deck-gen JSON spec at `/tmp/spec.json`.
Use the template structure from `deck-gen --template` but populate with real data:
- Slide 1 (title): from `financials`
- Slide 2 (exec-summary): bull/bear from `search.overview` + `search.catalysts`
- Slide 3 (company): from `search.overview` results
- Slide 4 (segments): write CSG/EISG or equivalent split manually
- Slide 5 (revenue): chart_data from `charts.revenue_annual`
- Slide 6 (margins): metrics from `financials`, chart from `charts.eps`
- Slide 7 (balance): from `financials` (debtToEquity, currentRatio, etc.)
- Slide 8 (stock): from `financials` (trailingPE, forwardPE, marketCap, etc.)
- Slide 9 (analysts): from `financials` (targetMeanPrice, recommendationKey)
- Slide 10 (industry): from `search.competitive` results
- Slide 11 (catalyst): from `search.catalysts` results
- Slide 12 (catalyst2): from `search.news` results
- Slide 13 (risks): from `search.overview` + `search.financials` (find negatives)
- Slide 14 (thesis): synthesis of all research

Each slide spec is ~5-15 lines of JSON. The full spec is ~150 lines.

### Phase 3: Deliver (1 tool call, ~5s)
```bash
deck-deliver /tmp/spec.json ~/research/SYMBOL-deck.html
```
Output: fully offline HTML slide deck.

## Token Comparison

| Approach | Subagents | Tool calls | Input tokens | Time |
|----------|-----------|------------|-------------|------|
| Old (TTMI) | 6 parallel | ~120 | ~12M | ~15 min |
| Old (KEYS) | 6 parallel | ~100 | ~10M | ~12 min |
| **New** | **0** | **3** | **~500K** | **~2 min** |

## Why This Works

- `fin` replaces 20+ web scraping calls for financial data
- `stock-data` replaces 6 subagents × 20 searches with 5 targeted ddgs queries
- `deck-gen` replaces 40KB of hand-written HTML with a 3KB JSON spec
- `deck-deliver` chains generation + inlining in one call
- The only LLM work is synthesis (Phase 2) — everything else is deterministic scripts
