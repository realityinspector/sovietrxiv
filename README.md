# sovietrxiv

**Author:** realityinspector (sean@semantic-life.com)

API crawler, harvester, and shell explorer for **SovietRxiv** (https://sovietrxiv.org).

- 15k+ English-access Soviet-era scientific papers (russiarxiv source)
- Machine translated + some original English
- Powered by the public unified ChinaRxiv/RussiaRxiv/SovietRxiv API

## Quick Start

```bash
cd sovietrxiv
cp .env.example .env
# edit .env with your email (sean@semantic-life.com recommended for polite pool)
chmod +x sovietrxiv.sh

./sovietrxiv.sh help
./sovietrxiv.sh stats
./sovietrxiv.sh search "gravity" --limit 5
./sovietrxiv.sh search --publication doklady_akademii_nauk_sssr --from 1965-01-01 -l 2
```

## The Explorer (sovietrxiv.sh)

A pure zsh + curl + jq tool (jq installed) for interactive use, meta-analysis, and search.

### Commands

| Command                  | Description |
|--------------------------|-------------|
| `stats`                  | Overall API + source counts (chinaxiv + russiarxiv) |
| `subjects [--top N]`     | List subjects (note: mixed corpus) |
| `publications`           | List journals/publications |
| `search <q> [flags]`     | Full-text + field search with filters |
| `get <paper_id>`         | Full metadata for one paper |
| `text <paper_id>`        | Get translated full text (Markdown) |
| `pdf-url <paper_id>`     | Print English PDF URL |
| `pdf <paper_id> [file]`  | Download English PDF (default: data/pdfs/<id>.pdf) |
| `harvest [flags]`        | **Crawler**: paginate and save all matching metadata to local JSONL for offline meta |
| `meta years`             | Count papers by year (requires prior `harvest`) |
| `meta top-pubs`          | Top publications by count (from local) |
| `meta count <q>`         | Fast count of local matches for query (grep+ jq) |
| `health`                 | API health check |

### Search Flags (most map directly to API)

- `-l, --limit N` (1-100)
- `--source russiarxiv|chinaxiv|all` (default: russiarxiv for this tool)
- `--from YYYY-MM-DD` / `--to YYYY-MM-DD`
- `--pub, --publication KEY`
- `--field title|author|abstract` (search_field)
- `--has-full-text` / `--has-pdf` / `--has-figures`
- `--lang ru|zh|en`

Query `q` is full-text search across fields (or restricted by `--field`).

Example advanced:
```bash
./sovietrxiv.sh search "differential games" --from 1969-01-01 -l 10
./sovietrxiv.sh search --field title "classification" --pub doklady_akademii_nauk_sssr
```

### Meta Analysis & Local Tooling

Run the crawler once (or incrementally):

```bash
# Harvest ~15k russiarxiv papers (uses polite limits if SOVIETRXIV_EMAIL set)
./sovietrxiv.sh harvest --all --out data/

# Then fast local analysis (no API calls)
./sovietrxiv.sh meta years
./sovietrxiv.sh meta count "relativity|gravity|tensor"
./sovietrxiv.sh meta top-pubs
```

Harvest saves:
- `data/papers.jsonl` — one paper summary per line (enriched with fetched date)
- Resume safe: will skip already seen IDs on re-run.

### Full-Text + PDF Harvesting (optional)

```bash
# Fetch full text for a paper
./sovietrxiv.sh text ru-197001.82500 > data/texts/ru-197001.82500.md

# Bulk download a few PDFs (be nice)
for id in $(jq -r .id data/papers.jsonl | head -5); do
  ./sovietrxiv.sh pdf "$id"
done
```

### Rate Limits & Etiquette

- Anonymous: 30 req/min
- With `SOVIETRXIV_EMAIL=sean@semantic-life.com` (or your email) in env: 300 req/min (polite pool)
- All responses return `X-RateLimit-*` headers (script prints remaining on verbose)

Harvest will auto-sleep 2s between pages (or less with email). Respect it.

### API Notes

Base: `https://sovietrxiv.org/api/v1`

Key endpoints used:
- `GET /papers` — search + list + cursor pagination
- `GET /papers/{id}`
- `GET /papers/{id}/text`
- `GET /papers/{id}/pdf` (redirect)
- `GET /stats`, `/subjects`, `/publications`, `/health`

See https://sovietrxiv.org/api/docs for full interactive spec (Swagger).

Paper IDs look like `ru-197001.82500` (year+month + seq).

## Project Layout

```
sovietrxiv/
├── sovietrxiv.sh     # the main explorer + crawler (zsh)
├── README.md
├── .env.example
├── .gitignore
└── data/             # created by harvest (gitignored)
    ├── papers.jsonl
    └── pdfs/
```

## Creating / Updating GitHub Repo

This is set up as `realityinspector/sovietrxiv` (public).

**Author:** realityinspector

To recreate / fork:
```bash
gh repo create realityinspector/sovietrxiv --public --source=. --remote=origin --push
```

## Future / Ideas

- Full text + figure bulk harvest mode
- Local sqlite index for fast search
- Export to csv / zotero / bibtex
- Simple web UI for this corpus
- Cross rxiv-fun tools (compare with arxiv etc.)

Part of the rxiv-fun collection by realityinspector.

CC BY 4.0 on the underlying data per API.

## Example One-Liners

```bash
# Latest 3 physics-ish soviet papers (note: subjects are sparse for ru data)
./sovietrxiv.sh search "" --from 1970-01-01 -l 3

# Count doklady papers mentioning "nuclear"
./sovietrxiv.sh harvest --all
./sovietrxiv.sh meta count "nuclear" | jq .

# Get direct PDF link
./sovietrxiv.sh pdf-url ru-196001.31449
```

Enjoy exploring the Soviet scientific archive.
