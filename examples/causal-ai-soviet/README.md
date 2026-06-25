# Example: Rediscovering Soviet-Era Causal Graph and Control Research for Modern AI

This directory contains a self-contained, easy-to-reproduce example demonstrating how to use the `sovietrxiv.sh` tool to explore the SovietRxiv corpus for historical research on **graphs, feedback systems, observability, Markov processes on structures, and control laws** — ideas that map surprisingly well to contemporary causal AI (structural causal models, d-separation, causal discovery, causal RL, identifiability under interventions, etc.).

## Why This Matters (Quick Hypothesis)
Soviet cybernetics and control theory papers from the late 1960s–1970 (especially in *Doklady Akademii Nauk SSSR*) contain sophisticated treatments of:
- Directed graphs and reachability/transitive closure (ancestry in causal graphs)
- Markov measures and entropy on path spaces of graphs (graphical models, conditional independence)
- Feedback with internal interference and information capacities (feedback in SCMs, info flow)
- "Ideal" observability independent of controls (identifiability under unknown policies/do-interventions)
- Structural decomposition of complex systems and stability domains (modular causal models, attraction basins as causal effects)
- Differential games with incomplete information and variable-structure systems (causal games, robust/hybrid causal models)

These predate or parallel Judea Pearl's foundational work but have seen little crossover into modern causal ML literature, likely due to language barriers and limited translations until projects like SovietRxiv.

This example shows how the tool makes it practical to surface and analyze such papers.

## Prerequisites
- macOS/Linux with `zsh`, `curl`, `jq`, `python3`
- (Recommended) Set `SOVIETRXIV_EMAIL=your@email.com` in the parent `.env` or env for faster 300/min rate limits (anonymous is 30/min)
- Run from the `sovietrxiv/` root directory

The example is designed to be **fast to re-run** (small limits, uses existing data where possible).

## How to Run (Easy Re-Creation)
From the `sovietrxiv/` directory:

```bash
cd /path/to/sovietrxiv   # e.g. cd ../sovietrxiv if you're in examples/...
chmod +x examples/causal-ai-soviet/run_demo.sh
./examples/causal-ai-soviet/run_demo.sh
```

The script will:
1. Demonstrate live searches using `sovietrxiv.sh` for relevant terms ("feedback", "graph", "markov", "observability", "structure", etc.).
2. Harvest a small focused batch of papers (if not already present).
3. Use Python to scan harvested data + pre-fetched key paper texts.
4. Print a concise report of the most promising papers + their potential AI applications.
5. Output a generated `findings/summary_report.md` for further use.

Expected runtime: 1-3 minutes (depending on rate limits and network).

## What the Example Produces
- Console output with search results and key excerpts.
- `findings/search_results.jsonl` (or updated papers).
- `findings/summary_report.md` — a markdown summary you can read or extend.
- References to full texts in `../data/texts/` (e.g. `ru-197001.08938.md`).

You can inspect raw data with:
```bash
jq '.title, .abstract[0:200]' findings/papers.jsonl | head -20
```

## Key Papers Highlighted in This Example
The demo focuses on these (and similar) IDs surfaced by systematic searches + harvesting. Full machine-translated texts are pre-fetched in the parent `data/texts/`:

- **ru-197001.08938** — Capacities of information systems with feedbacks and internal interference (spectral treatment of feedback + noise; info-theoretic causal capacities)
- **ru-197001.75216** — Economical construction of the transitive closure of a directed graph (efficient DAG reachability/ancestry)
- **ru-197001.37210** — Entropy of a shift and Markov measures in the path space of a countable graph (graph-structured Markov processes and entropy)
- **ru-197001.65870** — Ideally observable systems (control-independent state reconstruction — ideal for identifiability)
- **ru-197001.25427** + related — Fast matrix methods for transitive closure on graphs
- Others: structure of control laws for stability, differential games with incomplete info, variable structure/sliding modes, large-scale multiconnected systems with influence coefficients.

See the generated report and `whitepaper.md` (at repo root) for detailed mappings to causal AI.

## Customizing / Extending
Edit `run_demo.sh` or `analyze.py` to:
- Add more search terms
- Change `--limit` / `--pages` for broader harvest (use email for speed)
- Add new keyword filters in the Python analyzer
- Fetch full text for additional IDs: `../sovietrxiv.sh text <id> --save`

To start fresh:
```bash
rm -rf findings/
./run_demo.sh
```

## Reproducibility Notes
- All searches default to `source=russiarxiv` (Soviet-era papers).
- The underlying data comes from the public SovietRxiv API (https://sovietrxiv.org/api/docs).
- Texts are machine-translated; original PDFs linked in metadata.
- This example is intentionally small and focused for quick reproduction. For full research, harvest more pages and cross-reference with modern causal AI literature.

This demonstrates one powerful use of the `sovietrxiv.sh` explorer + harvester for "rediscovering" under-cited ideas.

For the broader findings and whitepaper, see the repo root `whitepaper.md`.
