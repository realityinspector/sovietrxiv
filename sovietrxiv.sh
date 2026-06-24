#!/usr/bin/env zsh
# sovietrxiv.sh - API explorer + crawler for https://sovietrxiv.org
# Tools for meta analysis and targeted search over Soviet-era translated papers.
#
# Requirements: curl, jq
# Usage: ./sovietrxiv.sh <command> [args...]
#        ./sovietrxiv.sh help
#
# Env:
#   SOVIETRXIV_EMAIL=sean@semantic-life.com     # for 300/min polite tier (or your email)
#   SOVIETRXIV_API_BASE=...  # override (default https://sovietrxiv.org/api/v1)
#   SOVIETRXIV_VERBOSE=1

set -euo pipefail

SCRIPT_DIR=${0:A:h}
cd "$SCRIPT_DIR"

API_BASE=${SOVIETRXIV_API_BASE:-https://sovietrxiv.org/api/v1}
EMAIL=${SOVIETRXIV_EMAIL:-${SOVIETRXIV_API_EMAIL:-}}
VERBOSE=${SOVIETRXIV_VERBOSE:-0}
DATA_DIR=${SOVIETRXIV_DATA_DIR:-data}
PAPERS_JSONL="$DATA_DIR/papers.jsonl"

mkdir -p "$DATA_DIR/pdfs" "$DATA_DIR/texts"

# --- helpers -----------------------------------------------------------------

log() { echo "$@" >&2; }
vlog() { [[ $VERBOSE == 1 ]] && log "$@" || true; }

have_jq() { command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required (brew install jq)" >&2; exit 1; }; }
have_curl() { command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required" >&2; exit 1; }; }

auth_header() {
  if [[ -n "$EMAIL" ]]; then
    printf '%s\n' "-H" "X-API-Email: $EMAIL"
  fi
}

curl_api() {
  # usage: curl_api METHOD ENDPOINT_PATH [extra curl args...]
  local method=$1 endpoint=$2; shift 2 || true
  local url="${API_BASE}${endpoint}"
  local cmd=(curl -sS -H "Accept: application/json")
  if [[ -n "$EMAIL" ]]; then
    cmd+=(-H "X-API-Email: $EMAIL")
  fi
  cmd+=(-X "$method" "$url")
  if [[ $# -gt 0 ]]; then
    cmd+=("$@")
  fi
  vlog "→ ${cmd[*]}"
  "${cmd[@]}"
}

rate_info() {
  # Parse last headers if we captured them. Simple helper for display.
  # Callers can capture headers separately when needed.
  :
}

pretty_paper_row() {
  # stdin: one paper json
  jq -r '
    [.id, (.date // "????-??-??"), (.title // "")[0:70], 
     (if .has_full_text then "T" else "-" end),
     (if .has_pdf then "P" else "-" end),
     (.source // "ru")] | @tsv' \
  | awk -F'\t' '{printf "%-18s %-10s %-70s %s %s %s\n", $1, $2, $3, $4, $5, $6}'
}

# Build query string for /papers. Positional q optional.
build_papers_query() {
  local q="${1:-}"; shift || true
  local qs=()
  [[ -n "$q" ]] && qs+=("q=$(printf %s "$q" | jq -Rr @uri)")
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit|-l)        qs+=("limit=${2}"); shift ;;
      --cursor)          qs+=("cursor=$(printf %s "$2" | jq -Rr @uri)"); shift ;;
      --source)          [[ "$2" != "all" ]] && qs+=("source=$(printf %s "$2" | jq -Rr @uri)"); shift ;;
      --from|--from_date) qs+=("from_date=$2"); shift ;;
      --to|--to_date)     qs+=("to_date=$2"); shift ;;
      --pub|--publication) qs+=("publication=$(printf %s "$2" | jq -Rr @uri)"); shift ;;
      --field|--search_field) qs+=("search_field=$2"); shift ;;
      --subject)         qs+=("subject=$(printf %s "$2" | jq -Rr @uri)"); shift ;;
      --has-full-text|--has_full_text) qs+=("has_full_text=true") ;;
      --has-pdf|--has_pdf) qs+=("has_pdf=true") ;;
      --has-figures|--has_figures) qs+=("has_figures=true") ;;
      --lang|--original_language) qs+=("original_language=$2"); shift ;;
      *) ;;
    esac
    shift || true
  done
  local joined=""
  if [[ ${#qs[@]} -gt 0 ]]; then
    joined="?"$(IFS='&'; echo "${qs[*]}")
  fi
  echo "$joined"
}

# Fetch one page, return {data, next_cursor, total, ...} as json
papers_page() {
  local qs; qs=$(build_papers_query "$@")
  local api_path="/papers${qs}"
  local headers_file=$(mktemp)
  local body
  body=$(curl_api GET "$api_path" -D "$headers_file" )
  if [[ $VERBOSE == 1 ]]; then
    grep -i 'x-ratelimit' "$headers_file" >&2 || true
  fi
  rm -f "$headers_file"
  echo "$body"
}

print_header() {
  printf "%-18s %-10s %-70s %s %s %s\n" "ID" "DATE" "TITLE" "T" "P" "SRC"
  printf '%*s\n' 120 | tr ' ' '-'
}

# --- commands ----------------------------------------------------------------

cmd_help() {
  cat <<EOF
sovietrxiv.sh — explorer + crawler for SovietRxiv (russiarxiv)

Usage:
  ./sovietrxiv.sh <command> [options]

Core:
  help                     this help
  health                   ping API
  stats                    /stats (totals by source)
  subjects [--top N]       list subjects (corpus-wide)
  publications             list journals
  search [QUERY] [flags]   search papers (default source=russiarxiv)
  get <id>                 full metadata for paper
  text <id> [--save]       full text (markdown). --save writes to data/texts/
  pdf-url <id>             english pdf url
  pdf <id> [outfile]       download pdf (defaults to data/pdfs/<id>.pdf)

Crawler / Local Meta:
  harvest [flags]          crawl pages and append to data/papers.jsonl
                           flags: --all (until done), --pages N, --limit 100,
                                  --source russiarxiv (default), --out DIR
  meta years               paper counts by year (local jsonl)
  meta top-pubs [N]        top publications
  meta count <query>       fast local count of papers matching (simple contains)

Search flags (passed to API):
  -l, --limit N
  --source russiarxiv|chinaxiv|all
  --from YYYY-MM-DD  --to YYYY-MM-DD
  --pub KEY
  --field title|author|abstract
  --has-full-text --has-pdf --has-figures
  --lang ru

Env vars:
  SOVIETRXIV_EMAIL=sean@semantic-life.com   polite pool (300/min)
  SOVIETRXIV_API_BASE
  SOVIETRXIV_VERBOSE=1

Examples:
  ./sovietrxiv.sh stats
  ./sovietrxiv.sh search "differential game" -l 5 --from 1968-01-01
  ./sovietrxiv.sh harvest --all
  ./sovietrxiv.sh meta years
  ./sovietrxiv.sh get ru-197001.82500 | jq .
  ./sovietrxiv.sh text ru-196001.31449
EOF
}

cmd_health() {
  curl_api GET /health | jq .
}

cmd_stats() {
  curl_api GET /stats | jq .
}

cmd_subjects() {
  local top=${1:-20}
  [[ "$1" == "--top" && -n "${2:-}" ]] && top=$2
  curl_api GET /subjects | jq -r --argjson n "$top" '
    .subjects[:$n] | .[] | "\(.count)\t\(.name)" ' | column -t -s $'\t'
}

cmd_publications() {
  curl_api GET /publications | jq .
}

cmd_search() {
  local q=""
  local args=()
  if [[ $# -gt 0 && "$1" != -* ]]; then
    q="$1"; shift
  fi
  # default source to russiarxiv unless user overrides
  local has_source=0
  for a in "$@"; do [[ "$a" == "--source" || "$a" == "-source" ]] && has_source=1; done
  if [[ $has_source -eq 0 ]]; then
    args+=(--source russiarxiv)
  fi
  args+=("$@")

  local qs; qs=$(build_papers_query "$q" "${args[@]}")
  local resp; resp=$(curl_api GET "/papers${qs}")
  local total; total=$(echo "$resp" | jq -r '.total // 0')
  echo "Total matching: $total (showing up to $(echo "$resp" | jq -r '.limit'))"
  print_header
  echo "$resp" | jq -c '.data[]' | while read -r p; do
    echo "$p" | pretty_paper_row
  done
  local nextc; nextc=$(echo "$resp" | jq -r '.next_cursor // empty')
  if [[ -n "$nextc" ]]; then
    echo ""
    echo "(more results available; use --cursor or harvest for bulk)"
    vlog "next_cursor: $nextc"
  fi
}

cmd_get() {
  local id=$1
  [[ -z "$id" ]] && { log "usage: get <paper_id>"; exit 1; }
  curl_api GET "/papers/${id}" | jq .
}

cmd_text() {
  local id=$1; shift || true
  local save=0
  [[ "${1:-}" == "--save" ]] && save=1
  local out; out=$(curl_api GET "/papers/${id}/text")
  # Use python to robustly extract (API json sometimes contains raw controls)
  local body_md wc
  body_md=$(python3 -c '
import sys, json
d=json.load(sys.stdin)
print(d.get("body_md",""), end="")
' <<< "$out")
  wc=$(python3 -c '
import sys, json
print(json.load(sys.stdin).get("word_count","?"))
' <<< "$out")
  if [[ $save -eq 1 ]]; then
    local f="$DATA_DIR/texts/${id}.md"
    printf "%s" "$body_md" > "$f"
    log "saved $f (word_count=$wc)"
  else
    printf "%s\n" "$body_md"
  fi
}

cmd_pdf_url() {
  local id=$1
  local meta; meta=$(curl_api GET "/papers/${id}")
  local u; u=$(echo "$meta" | jq -r '.english_pdf_url // .pdf_url // empty')
  if [[ -z "$u" ]]; then
    # fall back to following the redirect without download
    u=$(curl -sI -o /dev/null -w '%{redirect_url}' "${API_BASE}/papers/${id}/pdf" || true)
  fi
  echo "$u"
}

cmd_pdf() {
  local id=$1; shift || true
  local outfile=${1:-"$DATA_DIR/pdfs/${id}.pdf"}
  local url
  url=$(cmd_pdf_url "$id")
  if [[ -z "$url" || "$url" == "null" ]]; then
    log "No PDF URL for $id"
    return 1
  fi
  log "Downloading $url -> $outfile"
  curl -sSL -o "$outfile" "$url"
  ls -lh "$outfile"
}

# --- harvest / crawler -------------------------------------------------------

# Dedup helper: check if id already in jsonl
already_have() {
  local id=$1
  [[ -f "$PAPERS_JSONL" ]] && grep -q "\"id\":\"$id\"" "$PAPERS_JSONL" 2>/dev/null && return 0
  return 1
}

cmd_harvest() {
  have_jq
  mkdir -p "$DATA_DIR"

  local max_pages=999999
  local pages=0
  local limit=100
  local source="russiarxiv"
  local extra_args=()
  local do_all=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all) do_all=1 ;;
      --pages) max_pages=$2; shift ;;
      --limit) limit=$2; shift ;;
      --source) source=$2; shift ;;
      --out) DATA_DIR=$2; PAPERS_JSONL="$DATA_DIR/papers.jsonl"; mkdir -p "$DATA_DIR"; shift ;;
      *) extra_args+=("$1") ;;
    esac
    shift || true
  done

  if [[ "$source" != "all" ]]; then
    extra_args+=(--source "$source")
  fi

  log "Harvest starting → $PAPERS_JSONL (source=$source, limit=$limit)"
  [[ -n "$EMAIL" ]] && log "Using polite email (300/min)" || log "Anonymous (30/min) — consider setting SOVIETRXIV_EMAIL"

  local cursor=""
  local total_seen=0
  local first_total=""

  while [[ $pages -lt $max_pages ]]; do
    local args=()
    [[ -n "$cursor" ]] && args+=(--cursor "$cursor")
    args+=(--limit "$limit" "${extra_args[@]}")

    local resp
    resp=$(papers_page "" "${args[@]}")

    local count; count=$(echo "$resp" | jq '.data | length')
    [[ -z "$first_total" ]] && first_total=$(echo "$resp" | jq -r '.total // "?"')

    if [[ "$count" -eq 0 ]]; then
      log "No more results."
      break
    fi

    # Clean append of new papers only
    local pagefile
    pagefile=$(mktemp)
    echo "$resp" | jq -c '.data[]' > "$pagefile"

    if [[ -f "$PAPERS_JSONL" ]]; then
      # only append ids not already present
      jq -r '.id' "$PAPERS_JSONL" | sort -u > "${pagefile}.existing"
      jq -r '.id' "$pagefile" | sort | comm -23 - "${pagefile}.existing" | while read -r newid; do
        jq -c --arg id "$newid" 'select(.id == $id)' "$pagefile" >> "$PAPERS_JSONL"
      done
      rm -f "${pagefile}.existing"
    else
      cat "$pagefile" >> "$PAPERS_JSONL"
    fi
    local added
    added=$(wc -l < "$pagefile")
    rm -f "$pagefile"

    total_seen=$((total_seen + count))
    pages=$((pages+1))
    log "page $pages: +$added seen (file now has $( [[ -f $PAPERS_JSONL ]] && wc -l < "$PAPERS_JSONL" || echo 0 ))"

    cursor=$(echo "$resp" | jq -r '.next_cursor // empty')
    if [[ -z "$cursor" ]]; then
      log "Cursor exhausted."
      break
    fi

    # be nice
    if [[ -n "$EMAIL" ]]; then
      sleep 0.4
    else
      sleep 2
    fi
  done

  local final_count=0
  [[ -f "$PAPERS_JSONL" ]] && final_count=$(wc -l < "$PAPERS_JSONL")
  log "Harvest complete. $final_count records in $PAPERS_JSONL"
}

# --- meta analysis (local) ---------------------------------------------------

ensure_harvested() {
  if [[ ! -f "$PAPERS_JSONL" ]]; then
    log "No local data found at $PAPERS_JSONL"
    log "Run: ./sovietrxiv.sh harvest --all"
    exit 1
  fi
}

cmd_meta() {
  local sub=${1:-}; shift || true
  case "$sub" in
    years|by-year)
      ensure_harvested
      jq -r '.date[0:4] // "????"' "$PAPERS_JSONL" \
        | sort | uniq -c | sort -nr | awk '{printf "%s %6d\n", $2, $1}'
      ;;
    top-pubs|pubs)
      ensure_harvested
      local n=${1:-10}
      jq -r '.publication // "unknown"' "$PAPERS_JSONL" \
        | sort | uniq -c | sort -nr | head -"$n" | awk '{printf "%6d  %s\n", $1, $2}'
      ;;
    count)
      ensure_harvested
      local q=${1:-}
      if [[ -z "$q" ]]; then
        wc -l < "$PAPERS_JSONL"
        return
      fi
      # very simple "search": case-insensitive contains on raw line
      # (good enough; for real use jq contains on title+abstract)
      grep -i "$q" "$PAPERS_JSONL" | wc -l
      ;;
    *)
      log "meta subcommands: years, top-pubs [n], count [query]"
      ;;
  esac
}

# --- main --------------------------------------------------------------------

main() {
  have_curl
  have_jq

  local cmd=${1:-help}
  shift || true

  case "$cmd" in
    help|h|-h|--help)          cmd_help ;;
    health)                    cmd_health ;;
    stats)                     cmd_stats ;;
    subjects)                  cmd_subjects "$@" ;;
    publications|pubs)         cmd_publications ;;
    search|s)                  cmd_search "$@" ;;
    get)                       cmd_get "$@" ;;
    text)                      cmd_text "$@" ;;
    pdf-url|pdfurl)            cmd_pdf_url "$@" ;;
    pdf)                       cmd_pdf "$@" ;;
    harvest|crawl)             cmd_harvest "$@" ;;
    meta)                      cmd_meta "$@" ;;
    *)
      log "Unknown command: $cmd"
      cmd_help
      exit 1
      ;;
  esac
}

# Only run main if script is executed (not sourced)
if [[ $ZSH_EVAL_CONTEXT == toplevel* || -z ${ZSH_EVAL_CONTEXT:-} ]]; then
  main "$@"
fi
