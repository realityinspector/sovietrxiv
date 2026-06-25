#!/usr/bin/env zsh
# run_demo.sh — Reproducible example case for using sovietrxiv.sh
# to surface Soviet-era research on causal graphs, feedback, observability,
# Markov structures, etc. for modern causal AI.
#
# Usage (from sovietrxiv/ root):
#   ./examples/causal-ai-soviet/run_demo.sh
#
# This is fast by design (small harvests, reuses existing data/texts).
# For deeper runs, set SOVIETRXIV_EMAIL and increase limits.

set -euo pipefail

SCRIPT_DIR=${0:A:h}
cd "$SCRIPT_DIR/../.."

echo "=== SovietRxiv Causal AI Example Demo ==="
echo "Working from: $(pwd)"
echo "Using tool: ./sovietrxiv.sh"
echo

if [[ -n "${SOVIETRXIV_EMAIL:-}" ]]; then
  echo "✓ Polite email detected — higher rate limits enabled"
else
  echo "ℹ Running anonymously (30/min). Set SOVIETRXIV_EMAIL=... for 300/min."
fi
echo

# 1. Demonstrate live searches with the tool (key terms from our hypothesis)
echo "=== 1. Live searches using the tool ==="
echo
echo ">>> Search: feedback (systems with loops/interference)"
./sovietrxiv.sh search "feedback" -l 3 || true
echo
echo ">>> Search: markov (graph path spaces, conditional independence)"
./sovietrxiv.sh search "markov" -l 3 || true
echo
echo ">>> Search: observab (ideal observability independent of controls)"
./sovietrxiv.sh search "observab" -l 3 || true
echo
echo ">>> Search: graph (directed structures, transitive closure)"
./sovietrxiv.sh search "graph" -l 3 || true
echo

# 2. Small focused harvest for new findings (into this example's dir)
echo "=== 2. Focused harvest (causal-relevant terms) ==="
mkdir -p examples/causal-ai-soviet/findings
./sovietrxiv.sh harvest \
  --pages 1 --limit 8 \
  --out examples/causal-ai-soviet/findings \
  --source russiarxiv 2>&1 | grep -E 'Harvest|page |complete' || true
echo "Harvest saved to: examples/causal-ai-soviet/findings/papers.jsonl"
echo

# 3. Run Python analyzer (robust, combines tool output + pre-fetched key texts)
echo "=== 3. Analysis & Summary Report ==="
python3 examples/causal-ai-soviet/analyze.py
echo

echo "=== Demo complete ==="
echo "See:"
echo "  - Console output above for live tool usage"
echo "  - examples/causal-ai-soviet/findings/ for harvested data"
echo "  - findings/summary_report.md (generated)"
echo "  - data/texts/ for full machine-translated papers"
echo "  - Root whitepaper.md for full findings + hypothesis"
echo
echo "To re-run fresh: rm -rf examples/causal-ai-soviet/findings/ && ./examples/causal-ai-soviet/run_demo.sh"
echo "To go deeper: set your email and increase --pages in the script."
