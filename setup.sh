#!/usr/bin/env bash
# Setup Hermes Agent stock research tools
set -e

echo "=== Hermes Stock Research Tools Setup ==="

# Install yfinance (required for fin)
echo ""
echo "Installing Python dependencies..."
pip install yfinance 2>/dev/null || echo "  Note: yfinance install skipped (may already be installed or use: pip install yfinance)"

# Install ddgs (for websearch fallback)
pip install ddgs 2>/dev/null || echo "  Note: ddgs install skipped (may need: pip install ddgs)"

# Add tools to PATH
HERMES_TOOLS="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HERMES_TOOLS/bin"

echo ""
echo "Tools directory: $BIN_DIR"

# Make all tools executable
chmod +x "$BIN_DIR"/* 2>/dev/null || true

# Add to PATH if not already there
if ! grep -q "hermes-tools/bin" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Hermes Stock Research Tools" >> ~/.bashrc
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> ~/.bashrc
    echo "Added to ~/.bashrc"
fi

# Copy skills
SKILLS_DIR="$HOME/.hermes/skills"
mkdir -p "$SKILLS_DIR/devops"
cp -r "$HERMES_TOOLS/skills/"* "$SKILLS_DIR/devops/" 2>/dev/null || true
echo "Skills installed to $SKILLS_DIR/devops/"

# Pre-cache CDN assets for offline slide decks
mkdir -p "$HOME/.hermes/cache"
python3 -c "
from urllib.request import urlopen, Request
from pathlib import Path
import gzip

assets = {
    'chart.umd.min.js': 'https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js',
    'fontawesome.all.min.css': 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css',
}
cache = Path.home() / '.hermes' / 'cache'
cache.mkdir(parents=True, exist_ok=True)

for name, url in assets.items():
    path = cache / name
    if path.exists():
        print(f'  {name}: already cached ({path.stat().st_size:,} bytes)')
        continue
    print(f'  {name}: downloading...')
    req = Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urlopen(req, timeout=15) as resp:
        data = resp.read()
        if resp.headers.get('Content-Encoding') == 'gzip':
            data = gzip.decompress(data)
    path.write_bytes(data)
    print(f'  {name}: cached ({len(data):,} bytes)')
print('CDN assets cached.')
" 2>&1

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Quick test:"
echo "  fin AAPL          # Get Apple financials"
echo "  websearch 'test'  # Test web search"
echo ""
echo "For stock deep-dive:"
echo "  stock-data SYMBOL > /tmp/data.json"
echo "  # (LLM synthesizes spec from data)"
echo "  deck-deliver spec.json output.html"
