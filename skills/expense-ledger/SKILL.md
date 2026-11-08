---
name: expense-ledger
description: >
  Turn a receipt / invoice / bill (image or PDF) into a structured, Schedule-C-categorized
  ledger entry — Claude reads the document with its own vision, extracts merchant/date/total/tax/
  line-items, picks the right US Schedule C category, and stores it in a local SQLite ledger via the
  `ledger` CLI. A self-hosted, no-web-app, no-external-LLM reimplementation of what TaxHacker does.
  Use when the user shares a receipt/invoice/bill and wants it logged, says "log this receipt",
  "add this expense", "track this for taxes", "what are my deductions", "schedule c", "export my
  expenses", "taxhacker", or wants a year-end deductible-expense worksheet. NOT for filing a return
  (that's aiwyn-tax / nonprofit-tax) — this is the bookkeeping/extraction layer that feeds it.
---

# expense-ledger — receipts → Schedule-C ledger (Claude is the extractor)

This skill replicates TaxHacker's core loop without its web app, database, or a paid vision LLM:
**Claude itself reads the receipt** and extracts the data; a tiny local CLI (`ledger`) owns the
SQLite store + Schedule-C export. Everything stays local under `~/.expense-ledger/`.

## The loop

1. **Read the document.**
   - **Image** (jpg/png/heic of a receipt): use the `Read` tool on the file — you can see it directly.
   - **PDF**: `Read` it directly if it's a clean digital PDF. For scanned/complex/multi-page PDFs,
     first convert with MinerU → markdown, then read that:
     `~/tools/mineru-md <file.pdf> /tmp/ledger-ocr && cat /tmp/ledger-ocr/*/auto/*.md`
     (MinerU is installed on this machine and the mini — see memory `reference_mineru_pdf_extraction`.)

2. **Extract these fields** (TaxHacker's schema, adapted). This is the accountant prompt — follow it:
   > You are an accountant. From the receipt/invoice, extract:
   > - `name` — short human summary of what was bought/paid for (required)
   > - `merchant` — vendor name, original spelling
   > - `issued_at` — date in **YYYY-MM-DD** (required)
   > - `total` — grand total as a number, no currency symbol (required)
   > - `currency` — ISO 4217 code (USD, EUR, …); default USD if unmarked
   > - `tax` — tax/VAT amount in the invoice currency, if shown
   > - `tax_rate` — tax rate percent 0–100, if shown
   > - `type` — `expense` (default) or `income`
   > - `category` — ONE Schedule C code from the list below
   > - `note` — anything useful (e.g. "client meal — <who>", "50% deductible")
   > - `items` — array of line items `{name, total, quantity}` for each product/line
   >
   > RULES: **Never make up information.** If a field isn't on the document, leave it out (blank).
   > Return one object.

3. **Pick the category** from the Schedule C list. Run `ledger categories` (or `ledger categories --json`)
   to see all 20+ codes with their IRS line and deductible %. Key ones:
   `meals` (Line 24b, **50% deductible**), `travel` (24a), `office_expense` (18 — software/SaaS/supplies),
   `advertising` (8), `car_truck` (9), `contract_labor` (11), `legal_professional` (17),
   `utilities` (25 — phone/internet), `education` (27a), `supplies` (22), `other` (27a),
   `personal` (NON-deductible). When unsure between two, pick the more specific line and note why.

4. **Store it.** Pipe the extracted JSON to the CLI:
   ```bash
   echo '{"merchant":"Cafe Roma","name":"Client lunch w/ J. Doe","issued_at":"2026-03-14",
          "total":42.50,"currency":"USD","tax":3.50,"category":"meals","type":"expense",
          "note":"business meal - 50% deductible","items":[{"name":"Lunch x2","total":42.50}]}' \
     | ledger add --stdin
   ```
   Always set `--source-file` (or `"source_file"`) to the original receipt path so it's traceable.
   For a quick manual add without an object: `ledger add --merchant X --name Y --total 12.5 --category office_expense --issued-at 2026-01-15`.

5. **Confirm to the user** what you stored (merchant, total, category + IRS line, deductible amount),
   and flag anything uncertain (ambiguous category, unreadable total) rather than guessing.

## The `ledger` CLI (on PATH; data at `~/.expense-ledger/ledger.db`)

| Command | Does |
|---|---|
| `ledger add --stdin` | add a transaction from a piped JSON object (preferred) |
| `ledger add --merchant … --total … --category … --issued-at …` | add via flags |
| `ledger list [--category --type --from --to --limit] [--csv]` | list transactions |
| `ledger search "<text>"` | full-text search (merchant/name/note/OCR text) |
| `ledger show <id>` | one transaction + its line items (JSON) |
| `ledger categories` | the Schedule C category map (code → line → deductible %) |
| `ledger schedule-c [--year 2026] [--csv]` | **the money report** — totals per IRS line, meals auto-halved |
| `ledger export [--from --to]` | full transaction CSV (for your CPA / tax software) |
| `ledger rm <id>` | delete a transaction |

Agent-native: every read command emits JSON when piped (or with `--json`); typed exit codes
(`0` ok, `2` usage, `3` not-found, `5` error). SQLite path overridable via `EXPENSE_LEDGER_DIR`.

## Year-end / "what are my deductions"

Run `ledger schedule-c --year <YYYY>` for a worksheet grouped by Schedule C line with the total
deductible (meals already reduced to 50%). `ledger schedule-c --year <YYYY> --csv > sched-c-<YYYY>.csv`
to hand to a CPA or into aiwyn-tax / nonprofit-tax. This is a **worksheet, not a filed return** — it
feeds the actual tax-prep skills; it doesn't replace them.

## Guardrails (this is tax data)
- **Never fabricate** an amount, date, merchant, or tax figure. If the total is unreadable, say so and
  ask — don't guess. (Same discipline as the document-fabrication rules in CLAUDE.md.)
- Deductibility hints (lines, 50% meals) are **bookkeeping aids, not tax advice.** For anything the user
  treats as a filing decision, defer to a tax professional / the tax-prep skills.
- Keep the original receipt file; store its path in `source_file` so every ledger row is auditable.

## Why this exists (not a web app)
TaxHacker is a self-hosted Next.js + Postgres web app whose "AI" is just a vision LLM + a fixed prompt +
a field schema. On Cloudflare it fails four ways (gpt-oss is text-only; not Pages-native; local-disk
uploads are ephemeral on CF Containers; CF's OpenAI-compat endpoint rejects vision images). Since
**Claude is already a vision model**, the whole app collapses to: this skill (the prompt+schema) + the
`ledger` CLI (the store+export). No server, no Postgres, no external LLM, no data leaving the machine.
