# sovietrxiv

> A lightweight, powerful open-source CLI for exploring the **SovietRxiv** archive.

**This is a community downstream tool.**  
The real hero is the original project at **[https://sovietrxiv.org](https://sovietrxiv.org)** — they do the hard work of recovering, machine-translating, and hosting ~15,000 Soviet-era scientific papers from Russian journals (mostly *Doklady Akademii Nauk SSSR*).

This repo (`realityinspector/sovietrxiv`) gives you a fast, scriptable shell interface (`sovietrxiv.sh`) on top of their excellent public API.

---

## What You Get

`sovietrxiv.sh` is a single-file zsh tool (curl + jq) that lets you:

- Search the corpus with rich filters
- Harvest metadata locally for analysis
- Run fast offline meta-analysis
- Fetch full translated text and English PDFs
- Work politely with rate limits

Everything stays local and private. No heavy dependencies.

## Prominent Credit to the Original Work

**Please support the original project:**

- Visit: https://sovietrxiv.org
- They provide the data, translations, PDFs, and the public API
- This tool only exists because they made the API open and well-documented

This is **not** an official client. It is an independent exploration and analysis layer built for fun and research convenience as part of the [rxiv-fun](https://github.com/realityinspector/rxiv-fun) collection.

## Quick Start

```bash
git clone https://github.com/realityinspector/sovietrxiv.git
cd sovietrxiv

cp .env.example .env
# (optional but recommended) put your email in .env for 10× faster rate limits

chmod +x sovietrxiv.sh
./sovietrxiv.sh help
```

## Things You Can Do With the .sh

### 1. Get a feel for the collection

```bash
./sovietrxiv.sh stats
./sovietrxiv.sh publications
./sovietrxiv.sh subjects --top 8
```

### 2. Targeted search

```bash
# Search for specific concepts
./sovietrxiv.sh search "curvature tensor" -l 5

# Papers from a specific year range in Doklady
./sovietrxiv.sh search "" --pub doklady_akademii_nauk_sssr --from 1965-01-01 --to 1965-12-31 -l 3

# Title-only search
./sovietrxiv.sh search --field title "differential game" -l 4
```

### 3. Inspect individual papers

```bash
./sovietrxiv.sh get ru-197001.04419

# Full translated text (Markdown)
./sovietrxiv.sh text ru-197001.04419 | head -30

# Direct link to the English PDF
./sovietrxiv.sh pdf-url ru-197001.04419
```

### 4. Harvest for serious analysis (the killer feature)

Download paper metadata locally:

```bash
# Small test harvest
./sovietrxiv.sh harvest --pages 3 --limit 20

# Or go big (respect rate limits)
./sovietrxiv.sh harvest --all
```

Once you have `data/papers.jsonl`, you can do extremely fast local queries:

```bash
./sovietrxiv.sh meta years
./sovietrxiv.sh meta top-pubs 5
./sovietrxiv.sh meta count "tensor|gravity|relativity"
```

You can also pipe the JSONL to `jq` for anything you can imagine:
- papers per month
- most common words in abstracts
- export to CSV, etc.

### 5. One-liners

```bash
# Recent differential games papers
./sovietrxiv.sh search "differential game" --from 1969-01-01 -l 5

# How many 1970 papers mention "Fourier"?
./sovietrxiv.sh harvest --pages 2 --limit 50
./sovietrxiv.sh meta count "Fourier"
```

## Full Command List

| Command                    | What it does |
|----------------------------|--------------|
| `stats`                    | Overall numbers (chinaxiv + russiarxiv) |
| `publications`             | Journals with counts |
| `subjects [--top N]`       | Subject breakdown (mixed corpus) |
| `search [query] [flags]`   | Powerful search (default = russiarxiv) |
| `get <id>`                 | Full metadata for one paper |
| `text <id> [--save]`       | Get machine-translated full text |
| `pdf-url <id>`             | English PDF download link |
| `pdf <id> [file]`          | Download the English PDF |
| `harvest [flags]`          | Crawl and save metadata to `data/papers.jsonl` |
| `meta years`               | Papers per year (local) |
| `meta top-pubs [N]`        | Most common journals |
| `meta count "term"`        | Fast local count |
| `health`                   | API health |

**Useful search flags:**
- `-l, --limit N`
- `--from 1965-01-01 --to 1975-12-31`
- `--pub doklady_akademii_nauk_sssr`
- `--field title|abstract`
- `--has-full-text --has-pdf`

## Rate Limits & Being Polite

The API is public and generous:

- Anonymous: **30 requests/minute**
- With an email (`SOVIETRXIV_EMAIL=your@email.com`): **300 requests/minute**

Put your email in `.env` (example uses `sean@semantic-life.com` — feel free to use your own).

The script sleeps appropriately between harvest pages.

## Requirements

- macOS or Linux with `zsh`
- `curl`
- `jq` (the user has this installed)

## Why This Exists

The Soviet scientific literature from this period is incredibly rich and historically important. sovietrxiv.org has done heroic work making it accessible in English.

This little tool exists so researchers, historians, and the curious can easily:

- Search in ways the web UI doesn't support
- Bulk harvest for computational analysis
- Work entirely offline after the initial pull

## Example Use Case: Causal Graphs & Control Theory for Modern AI

See `examples/causal-ai-soviet/` for a complete, runnable case study.

It demonstrates using the tool to surface and analyze 1960s–1970 Soviet papers on:
- Feedback systems with interference
- Directed graph reachability & Markov processes on graphs
- Ideal observability (control-independent reconstruction)
- Structural decompositions and stability domains
- Differential games and variable-structure systems

These ideas map to SCMs, causal discovery, causal RL, identifiability, etc.

Run:
```bash
./examples/causal-ai-soviet/run_demo.sh
```

Also see the root `whitepaper.md` for the full hypothesis, detailed paper mappings, and swarm methodology.

## Author & Credits

**Tool author:** realityinspector (sean@semantic-life.com)  
Part of the [rxiv-fun](https://github.com/realityinspector/rxiv-fun) collection.

**All data, translations, and the API** are provided by the original **SovietRxiv** project:  
https://sovietrxiv.org

Please cite and support them if you use this material in research.

---

Enjoy exploring the Soviet scientific archive. 

If you build something interesting on top of this, feel free to open an issue or PR.