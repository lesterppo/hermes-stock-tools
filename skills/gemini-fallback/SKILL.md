---
name: gemini-fallback
description: Use Gemini for image analysis, web search with AI synthesis, and image generation — as fallback when the primary model lacks vision or search capabilities.
---

# Gemini Fallback: Image Analysis, Search, Generation

Trigger when:
- `browser_vision` fails (DeepSeek models: "unknown variant image_url")
- You need Google-quality web search with AI synthesis
- You need image generation and the primary model can't do it
- You need to analyze an image and the current model has no vision

## Prerequisites

Cookie auth via `browser_cookie3` extracts `__Secure-1PSID` from Chrome/Firefox.
If cookies expire, open `gemini.google.com` in browser to refresh.
All dependencies installed system-wide (loguru, browser_cookie3, gemini-webapi).

Location: `~/gemini-cli/gemini.py` (symlinked as `~/.local/bin/gemini-cli`)
Wrapper: `~/.local/bin/gemini-search` (Google Search via Gemini grounding)
Diagnostic reference: `references/timeouts.md` — smoke test, cookie recovery, debugging recipes

## Image Analysis (fallback when browser_vision fails)

```bash
cd ~/gemini-cli && timeout 90 python3 gemini.py --json -m flash \
  -i /path/to/image.png "Describe what you see in detail"
```
Timeout: 90s (image upload 20-40s + inference 10-30s).

**Multiple images:**
```bash
cd ~/gemini-cli && timeout 90 python3 gemini.py --json -m pro \
  -i before.png -i after.png "What changed between these two?"
```

**From browser_vision failure (workflow):**
1. `browser_vision` fails on DeepSeek → note the screenshot_path from error msg
2. Run: `cd ~/gemini-cli && timeout 90 python3 gemini.py --json -m flash -i <screenshot_path> "<question>"`
3. Read `text` field from JSON output for the analysis

## Web Search with AI Synthesis

**Via websearch wrapper (recommended):**
```bash
websearch "query"          # Auto-fallback: gemini (80s) → ddgs (3s)
websearch "query" -j -n 3  # JSON, 3 results
```

**Direct gemini-search (when you want control):**
```bash
gemini-search "query" -t 60       # 60s timeout for gemini-cli
gemini-search "query" -m pro -t 80  # Pro model, 80s
```
Output: `{"q":"query","r":[{title,url,snippet}],"a":"AI synthesis","c":N}`

## Image Generation (Gemini Imagen)

```bash
cd ~/gemini-cli && timeout 120 python3 gemini.py --json -m flash \
  -q "Generate a professional dark-themed slide background with circuit board pattern"
```
Generated image URLs appear in the `images` field of JSON output.

## Model Selection

- `-m flash` — Fast, default for most tasks
- `-m pro` — Better reasoning, slower
- `-m thinking` — Deep reasoning, slowest
- `--thinking basic|plus|extended` — Thinking tier (with pro/thinking)

## Pitfalls

- **Cookie exhaustion:** 4-6 rapid queries trigger rate limits → everything times out. Fix: wait 60s or refresh gemini.google.com in browser. The session will silently hang — every command times out with no error. Run `cd ~/gemini-cli && timeout 15 python3 gemini.py --json -m flash -q "1+1"` — if this times out, cookies are exhausted. Refresh and wait 60s.
- **Search grounding latency:** 40-55s normal. Never set timeout below 50s for gemini-cli. Use ddgs (2-5s) for speed. If gemini-search consistently times out, it's not auth — the `-t` flag is too low.
- **Image upload latency:** 20-40s upload + 10-30s inference = 60-90s total. Use `timeout 90` from the shell.
- **Always use --json flag** for machine-parseable output.
- **Subagents can't write files:** Return analysis text in summary, not files.

## Timeout Reference

| Operation | Shell timeout | gemini-cli -t | Total | Notes |
|-----------|--------------|---------------|-------|-------|
| Simple query ("1+1") | 15s | n/a | 3-8s | Fast path, no search |
| Search grounding | 80s | 50s | 40-55s | Google search + AI synthesis |
| Image analysis (1 img) | 90s | n/a | 60-90s | Upload 20-40s + inference |
| Image generation | 120s | n/a | 60-120s | Imagen 4 via Flash
