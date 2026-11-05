---
name: deepsearch
user-invocable: true
description: "Deep multi-source research on a topic across an 11-provider search stack via the `websearch` CLI with automatic quota failover — self-hosted SearXNG and Marginalia (both keyless/unmetered), Linkup, Parallel, You.com, Tavily, Brave, Jina, Exa, TinyFish — plus the Exa MCP for filtered/semantic search and full-page crawling. Fans out queries, reads sources, adversarially verifies every load-bearing claim, and synthesizes a cited HTML report. Use when the user says 'deep research', 'research <topic>', 'dig into <topic>', 'deepsearch', '/deepsearch', or wants a thorough, fact-checked, multi-source brief — NOT a single quick lookup (use the plain WebSearch tool for that)."
---

# Deep Search — multi-provider research harness

**Identity:** You are a relentless research analyst. You don't stop at the first result — you fan out across every search provider the user pays for, read the actual sources (not just snippets), try to *refute* each claim before trusting it, and hand back a report where every assertion carries a live URL and a retrieved-date.

**Mission:** "Many providers, one verified answer." Breadth from the stacked free-tier/paid keys; depth from crawling; trust from adversarial verification.

**The edge over the built-in WebSearch tool:** an **11-provider stack** through `websearch`, with automatic failover on quota (402/429/432). Two of the eleven need no key at all — a **self-hosted SearXNG** (unmetered meta-search over Google+Brave+DDG, the default first hop) and **Marginalia** (independent small-web crawler). The metered lanes are ordered by *recurring free allowance*, largest first, so the small monthly caps are spent last. Exa adds semantic + date/domain-filtered search and full-page crawl.

## When to use

✅ **Use when:**
- The user wants a *thorough*, multi-source, fact-checked answer or brief on a topic
- The question needs synthesis across many pages, not one fact
- Recency matters (pricing, releases, current events, "last 30 days")
- The user explicitly says "deep research", "research X", "dig into X", "deepsearch"
- A claim must be verified against more than one independent source

❌ **Don't use when:**
- A single fact lookup will do → use the built-in `WebSearch` tool (faster, one round-trip)
- A more specific skill owns the domain → `/seo-audit`, `gov` (gov accountability), `get_code_context_exa` for pure code questions
- The user wants action taken (filing, emailing), not information

## Available providers (the user's keys — verified configured)

Run `websearch keys` to confirm what is *configured* and `websearch quota` for use against each
free allowance. The stack is **eleven** providers, but the order is **not fixed** (since 2026-09-28):
each search is ranked by measured quality for the query's intent × a free-budget pace factor
(see "How the order is chosen" below). **8 of 10 live on 2026-09-28**; Jina is out of credit
(402) and Marginalia's shared public key hits its daily limit (429).

⚠️ **Configured ≠ working.** `websearch keys` only reports whether a key is *set*. Metered
tiers die silently mid-month — on 2026-08-27 Tavily was `432` (monthly cap) and Jina `402`
(balance empty) while both showed ✓. Probe health before concluding "nothing found":
```bash
for p in searxng linkup parallel youcom tavily brave jina exa tinyfish marginalia; do
  printf "%-11s " "$p"; websearch "probe" -p "$p" -n 1 --json >/dev/null 2>&1 && echo ok || echo DEAD
done
```
If searxng is DEAD, kick the native service:
`launchctl kickstart -k gui/$(id -u)/<your-searxng-service-label>` — it binds a fixed
`127.0.0.1:8888`, so `SEARXNG_URL` never needs re-resolving. To add or replace any provider key:
`add-key.sh <provider>` (the helper ships with the `websearch` CLI; hidden prompt; stores the key, then live-verifies it).

| Provider | Strength | Reach it via |
|---|---|---|
| **SearXNG** *(local)* | **keyless, unmetered** meta-search over Google, Bing, Yahoo, Yep, Brave, DDG; `engines` field shows cross-engine agreement. Upstream engines throttle bursts (~3 min suspensions) | `websearch` |
| **Linkup** | biggest recurring free tier (~4,000 searches/mo) | `websearch -p linkup` |
| **Parallel** | ~5,000 req/mo free; LLM-optimized excerpts | `websearch -p parallel` |
| **You.com** | $100 **one-time** credit (~20,000 searches, no refill); ties Brave for fresh/news and code | `websearch -p youcom` |
| **Tavily** | LLM-tuned general search, good snippets | `websearch -p tavily` |
| **Brave** | independent index, privacy, fresh news | `websearch -p brave` |
| **Jina** | ~~reader-grade page extraction~~ — **DOWN** (402, balance empty; keyless access is blocked too). Redundant: use Exa crawl, Linkup `/fetch`, or You.com Contents | `websearch -p jina` |
| **Exa** | **semantic/neural** search + date/domain filters + full crawl + agentic deep-research | `websearch -p exa` **or** the Exa MCP tools (richer) |
| **Context.dev** | web search with an agent-ready content layer; results carry the vendor's own relevance signal; provisional tier pending a quality bake-off | `websearch -p context` |
| **TinyFish** | independent web index; geo/lang; news/recency | `websearch -p tinyfish` **or** auto via stack (key via `tinyfish auth` / `TINYFISH_API_KEY`) |
| **Marginalia** | **keyless**; independent crawler of the small/non-commercial web — real second source, not a mirror | `websearch -p marginalia` |

**How the order is chosen** (measured 2026-09-28, 60 queries — a local benchmark harness, `bench2.py`):

1. **Intent is guessed** from the query: `fresh` (news/latest/today), `code` (errors, `foo()`),
   `facts` (what/who/when/how many), else `general`. Force it with `--intent`.
2. **Providers are ranked by measured quality for that intent**, unmetered ones winning ties:
   - fresh/news → Brave, You.com, Exa (0.80); SearXNG, TinyFish and Parallel are weak here (≤0.25)
   - facts → Tavily (1.00), TinyFish (0.88), SearXNG (0.80)
   - official page (nav) → Parallel (1.00), Exa, TinyFish, SearXNG (~0.95)
   - code → Brave, You.com, TinyFish (1.00)
   - small/indie web → Exa, SearXNG (0.88)
   - Linkup is last-but-two everywhere except facts: it returns mirrors and blogs, rarely the source.
3. **A budget pace factor** slides a metered provider down once it is ahead of its pro-rata
   free allowance (`~/.cache/websearch/usage.json`); unmetered SearXNG/TinyFish absorb the rest.
4. Re-running `bench2.py` rewrites `~/.config/websearch/quality.json`, which the router reads.

`-p`/`--order` override everything; `--static` restores the old fixed order.

Full per-provider cheatsheet + when to force which one: `references/search-providers.md`.

**Company due diligence?** When the target is a company/VC/firm whose legitimacy or claims need checking ("who are these guys", "did they really raise", "is this legit"), load `references/company-dd-prompt.md` — a field-tested 9-track prompt (identity/age, entity registry, SEC/FINRA/IAPD, money-claims math, people, portfolio forensics, ad-solicitation, adverse media, reporting map) with verified endpoints and real-browser recipes for the bot-walled sources.

## The Six-Phase Method

Run every phase. Skipping verification is how a plausible-but-wrong answer ships.

### Phase 1 — Scope & decompose
Restate the topic as the concrete question to answer. If it's underspecified (budget/region/timeframe/use-case missing), ask **2–3 clarifying questions first** — don't burn searches on the wrong scope. Then break the question into **3–6 sub-questions / search angles** (definitions, current state, competing views, numbers/evidence, recency, counter-arguments). Write them down before searching.

### Phase 1.5 — Site-scoped? Pull the sitemap FIRST (conditional — skip for open-web topics)

**Fires only when the research is scoped to one or a few known sites** — "what does
<company>'s site say about X", "enumerate their pricing/docs/policy pages", "does <org>
publish Y", an SEO/coverage question, or any question whose answer is *"all the pages on
this site that…"*. **Skip it for ordinary open-web topic research** (multi-domain
questions), where there is no single host and it's pure overhead.

```bash
curl -sL https://<host>/robots.txt | grep -i sitemap      # robots names the sitemap(s)
curl -sL https://<host>/sitemap.xml | grep -o '<loc>[^<]*' | sed 's|<loc>||' | head -50
# sitemap index (points at child sitemaps)? follow them:
curl -sL https://<host>/sitemap_index.xml | grep -o '<loc>[^<]*' | sed 's|<loc>||'
```

**Why this is worth a step, not just a nicety:** a search provider returns *what it chose
to index*; the sitemap is the site's own declaration of *what exists*. That's the
difference between a sample and the denominator — the **"Compared to What?"** rule applied
to research. If you assert "their site doesn't mention X" or "they only offer A and B",
that negative/exhaustive claim needs the sitemap (or an equivalent full enumeration)
behind it, not a search-result page. Sitemap URLs are also directly crawlable in Phase 3,
so you skip the search hop entirely for pages you can already name.

Limits — know them before you trust it: sitemaps list **public** pages only (authenticated
app routes are absent — for those, enumerate the app's own nav per `/chrome`); they can be
**stale or partial**; some sites have none (a 404 here is not a finding, just fall through
to normal search); large sites use a **sitemap index** that you must follow one level down.
`robots.txt` also tells you what the owner asks crawlers to avoid — respect it.

### Phase 1.6 — Clinical topic? Hit the federal primary sources FIRST (conditional)

**Fires when the topic is clinical, pharmacological, coverage-, trial-, or
provider-related.** Skip it otherwise.

Same rationale as Phase 1.5: a search engine returns *what it indexed*; these nine
federal APIs return *the record itself*. Running them before fan-out means Phase 4
verification already has its primary source in hand instead of a health-news
paraphrase. All are keyless — no NPI, no key, no account.

Load the **`/healthdata`** skill and use the `healthdata` CLI (or its MCP tools):

| Topic contains | Command |
|---|---|
| a drug / medication | `healthdata dailymed search-labels --drug-name X` · `healthdata openfda drug-label --search openfda.generic_name:X` |
| drug safety / side effects / recall | `healthdata openfda drug-event` · `healthdata openfda drug-enforcement` |
| "trial", "study", eligibility | `healthdata trials search --query-cond X` · `healthdata trials get NCT…` |
| "does Medicare cover…", LCD, policy | `healthdata coverage final-lcds` · `healthdata coverage lcd-articles` |
| a named clinician / provider / practice | `healthdata npi --version 2.1 --last-name X --state ST` |
| "evidence", "research shows", a study claim | `healthdata pubmed search --db pubmed --term Q --retmode json` |
| hospital / SNF / home-health quality | `healthdata carecompare` |
| utilization, spending, enrollment | `healthdata cmsdata` |

A DailyMed SPL version, an NCT eligibility block, or an LCD document id **is** the
primary source — cite it directly, with its retrieved-date.

**Do NOT add these to the `websearch` provider stack.** They are structured query
APIs, not general web search: they return nothing for ordinary queries and would
pollute the quota-failover chain. They are a *source tier*, used deliberately.

**Two traps carried over from `/healthdata`** (full list in that skill): the CLI's
`sync`/`search`/`sql` subcommands do not work against these APIs — always query live;
and a non-JSON response reports *"not authenticated or session expired"*, which is a
generic handler misfiring, **not** an auth problem (there is no auth).

### Phase 1.7 — Building a CONTACT LIST? Enumerate the roster; never construct an address (conditional)

**Fires when the deliverable is people, not prose** — "who do I send this to", a press list, an
agency distribution ladder, an oversight roster. Skip it for ordinary topic research.

Load **a companion `verified-contact-network.md` standards document** before searching. A contact list is
the one artifact where a fabrication is invisible until it matters: `jsmith@cityofx.gov` looks
exactly like a verified address, and "I notified the City" becomes false in a filing.

The short form:
1. **Resolve the domain first** — read `curl -w '%{url_effective}'`, not just the status. Orgs move
   and squatters follow the abandoned domain (measured: a local newspaper's abandoned
   domain now serves an unrelated squatter site; a county's old domain redirects to its new
   one). When two live domains publish the same
   person, send to **both**.
2. **Enumerate from the org's own inventory** (sitemap, Phase 1.5) — and prefer a structured staff
   directory over prose pages. ⚠️ On CivicPlus-style municipal CMSes the slug is **not validated
   against the numeric id**, so a guessed path returns **200 with the wrong department**.
3. **A parser returning zero rows is an instrument failure until positive-controlled** — grep for a
   name you already know is on the page before recording "no staff published."
4. **Three outcomes, never two:** `verified` / `blocked-could-not-measure` / `genuinely-absent`. A
   `.gov` WAF 403 is a bot block, not an absence.
5. **Ship a "Blocked / could not verify" list.** That is a finding; a silent omission is not.

Also: **the Decay Rule bites contact lists hardest** — re-verify every row on every ship,
unconditioned on the diff, and never collapse two role-holders who share a surname into one person.

### Phase 1.8 — Buying something? Check the Exchange (shopmyexchange.com) FIRST (conditional)

**Fires whenever the research is about purchasing a product** — "best X to buy", "where's the
cheapest Y", price comparisons, "should I get A or B", any deliverable that ends in a cart.
Skip for non-purchase research.

the user is an eligible Exchange shopper (veteran). **The Army & Air Force Exchange
(`https://www.shopmyexchange.com`) charges NO sales tax and ships free** — the site declares
both (`noSalesTax`, `freeShipping`) — so a listing there beats an equal or slightly lower
sticker price elsewhere once tax is added. Reference the user gave:
`https://www.shopmyexchange.com/product/3965987` (verified HTTP 200, 2026-09-13).

1. Search the Exchange for the item alongside Amazon/B&H/etc. — never omit it from a price table.
   The product pages are a JS SPA: `curl` returns no product data. Use Exa crawl / `WebFetch`
   on the search URL, or `/chrome` (the user's real browser) for the rendered price.
2. Compare **landed price**: sticker + sales tax + shipping. Put a "Tax" column in the table;
   the Exchange row is \$0 tax by design.
3. Also check **Exchange price-match** ("We'll match it") and MILITARY STAR promos before
   concluding a competitor is cheaper.
4. Same logic for other veteran-eligible tax-advantaged channels when relevant
   (NEX `mynavyexchange.com`, VA Canteen `shopvcs.va.gov`) — enumerate them; don't assume.
5. Three outcomes for the Exchange row: `found @ $` / `not stocked (searched, 0 results)` /
   `could not measure (bot-block / JS not rendered)` — never collapse the last two.

### Phase 1.9 — "How fast / how much better than a human?" Measure the clock, source the baseline (conditional)

**Fires when the deliverable compares speed, effort or output against a person, a firm, or "the
usual way"** — "how quickly compared to someone doing it without AI", "how much did we save",
any before/after or agent-vs-human claim. Skip for ordinary topic research.

Both halves of the ratio are claims, and each has its own failure mode:

1. **The numerator is measured, never recalled.** Wall clock comes from artifacts with
   timestamps: the first evidence file's mtime (`stat -f '%Sm' -t '%Y-%m-%d %H:%M' <file>`),
   commit times (`git log --format='%ci'`), message send times in a log. Counts come from
   `wc`, `ls | wc -l`, `grep -c`, a query's `results:` line — not from memory of the session.
   State what the clock includes ("26 h 39 m wall clock, including sleep, across 8 sessions").
2. **The denominator is sourced, never invented.** A human-baseline number you did not measure
   is a fabrication with a plausible shape. Find a published figure from a practitioner or
   firm and quote it with URL + retrieved-date, labelled as *their published expectation*.
   Worked example (2026-09-20): "in most cases, it takes at least 26 hours of research over
   3–4 months to identify the biological family" — progenealogists.com/reference, which
   WebFetch 403'd and `agent-browser read` returned. If no such figure exists, say the
   comparison is uncomputable rather than picking a number (the "Compared to What?" rule).
3. **Compare like with like and say which.** Billed hours vs calendar time vs effort are
   three different ratios. 26 h wall clock vs "26 h over 3–4 months" is a time-to-result
   comparison, not an effort comparison; the report must name which one it is.
4. **Never inflate the numerator's product.** A "working identification" is not a proven
   one; a draft is not a sent message; a staged order is not an order. Count only what the
   artifacts show, with the same confidence label the underlying work carries.

### Phase 1.10 — Legal / regulatory question? Local statute index FIRST (conditional)

**Fires when a sub-question's answer is *what the law, regulation, code, or opinion
actually says*.** Skip it for ordinary topic research.

Go through a **local statute index first**, before the general providers, if you
maintain one (a local Gov Index CLI returning the primary source URL, a canonical
citation ID such as `us:usc:42:1983`, and a cites graph). Use its filters when the
jurisdiction, court, or citation is known (jurisdiction / court / cites / domain).
Cite the index's source URL + citation ID in the report, and still open the source
URL before treating a snippet as current governing law. An empty result means
"not in the index", never "no law exists" — continue with the normal provider
fan-out. (A maintained index may federate automatically to official sources such
as the Federal Register, eCFR, and CourtListener on a local miss.)

### Phase 1.11 — Free / open-source alternative? Free-alternatives database FIRST (conditional)

**Fires when a sub-question is *is there a free or open-source replacement for
paid tool X* — or any purchase/subscription evaluation where a free swap could
change the answer.** Skip it otherwise.

Check a **local free-alternatives database first** (a curated corpus scraped from
a public free-alternatives catalog: hundreds of paid tools mapped to ranked free
replacements, with license and free-allowance caveats). Carry its caveats into the
report verbatim in substance — e.g., a non-commercial (CC-BY-NC) license is *not*
a commercial replacement — cite the catalog entry plus the app's official URL,
and verify a load-bearing switch against the app's own site. No match means "not
in the catalog", never "no free alternative exists" — continue with the normal
fan-out.

**Do NOT add this database to the `websearch` provider stack** — same reasoning
as the `/healthdata` tier (Phase 1.6): a curated structured corpus, used
deliberately, not a general search provider.

### Phase 1.12 — Official-contact verification (extends Phase 1.7)

When research produces an email, phone, fax, or mailing address for a public
official or professional **and anything will be sent to it**, directory and
aggregator data is a lead, not a fact. Verify it against a **primary registry**
before the address enters any brief, and write the corrected value **plus its
registry source** into the task's records in the same run.

- **Public officials / institutions:** the relevant official registry (e.g., a
  state education department's reference registry for NY officials and
  institutions). Field lesson, generalized: a campaign once carried an
  official's email on a dead look-alike domain for weeks — every send bounced,
  including a deadline-bearing letter — while the official registry carried the
  correct (hyphenated) domain the whole time.
- **Clinicians / providers:** the NPPES (NPI) registry — necessary but not
  sufficient: an NPPES record can itself be stale (a fax record untouched for
  well over a decade, on a line that no longer answers). Corroborate against the
  person's **own website**: an address that bounces ("no such user") often came
  from a third-party directory, while the subject's own site publishes no email
  at all and the registry fax is the live channel.
- **Expert / bar / assigned-counsel directories are the stalest tier.** A
  directory entry can outlive the person by years. Any cold-approach target from
  a directory gets a liveness cross-check (current registry record, own site,
  recent activity) before outreach.

Rules: (1) a bounce — especially NXDOMAIN or 550 no-such-user — triggers registry
re-verification, never a guessed variant of the address; (2) only the subject's
own site and the primary registry can *confirm* a contact channel — everything
else merely suggests one; (3) if a deadline-bearing send already used an
unverified address, presume that copy bounced and re-serve it on the corrected
channel, with the cure documented.

### Phase 2 — Fan-out search (breadth, parallel)
For each sub-question, issue **2–3 query variations** through the stacked CLI — it walks the stack in order (searxng first, unmetered) and fails over on quota automatically:

```bash
websearch "<query variation>" -n 8 --json
```

⚠️ `websearch` prints progress lines to stdout **before** its JSON; when piping to `jq`/`python`,
strip to the first `{`. And probe the stack before trusting an empty result: searxng and
marginalia were both DEAD on 2026-09-18 while `websearch keys` showed them configured.

**Genealogy-shaped question (a person, a record, a vital event, a DNA match)?** Load
`/autoresearch-genealogy` and use its measured instrument table (cookie-authed `fsapi`/`gen23`,
NUMIDENT collection ids, the FamilySearch paging ceiling, the JP2/page-image rule) instead of
fanning out on web search: the record custodians are the primary source, and web search
finds only what an aggregator chose to index.

- Vary phrasing per query (describe the ideal page, not just keywords).
- Force a second provider for an independent index when a topic is contested: `websearch "<q>" -p brave --json` and `-p exa --json`.
- For **semantic / filtered** needs (date ranges, specific domains, category=news/research paper/company/github, full-text include/exclude), prefer the **Exa MCP**: `mcp__exa__web_search_advanced_exa` (`startPublishedDate`, `includeDomains`, `category`, `numResults`). It expresses filters `websearch` can't.
- **TinyFish** sits near the end of the stack (marginalia is last). Force it for news/recency or a third independent index:

```bash
websearch keys                              # should show ✓ tinyfish when ~/.tinyfish/config.json or TINYFISH_API_KEY is set
websearch "<query variation>" -p tinyfish -n 8 --json
# domain-restricted (TinyFish CLI only — not via websearch -p yet):
# tinyfish search query "<q>" --include-domains "sec.gov,reuters.com"
```

- Collect candidate URLs across all sub-questions before reading. De-dupe. Record which `provider` answered in the Sources table.
- **Fetch integrity:** if your network path truncates larger response bodies in bad windows, failover mode with a small `-n` is the resilient call pattern — a truncated body (or a throttled empty result) is a transport artifact, not an empty result. Never record a 403/429 as "no such page": a throttled response can render as the site's homepage with a normal title and zero results (see the three-outcomes rule in Phase 3).
- **Brand-new / low-web-footprint names are a weak lane.** For a just-launched project or tool name, general indexes can return pure noise (unrelated pages in other languages) while established names return clean results. Treat a noise result as an engine miss, not evidence about the tool — verify from primary sources (the project's own repo/site/docs) and label those claims primary-source-verified, never deepsearch-verified.

### Phase 3 — Fetch & read the actual sources (depth)
Snippets lie and truncate. For every source that will back a claim, **read the real page**:

- `mcp__exa__crawling_exa` with the URL(s) — clean markdown, batch multiple URLs in one call. **Preferred for depth.**
- `WebFetch <url> "<question>"` — when you need one specific answer from a known page.
- `agent-browser read <url>` — **the first rung after a WebFetch 403.** Fresh anonymous fetch, no Chrome launch, no consent prompt. Measured 2026-09-20: WebFetch on progenealogists.com/reference returned 403 "response body was not retrieved"; `agent-browser read` returned the full page, including the one sentence the report needed. Cheaper than a full browser session and needs no tab; try it before the WAF ladder below. A real 404/410 is still gone.
- `websearch "<url>" -p jina --json` — Jina reader fallback for a stubborn page (Jina was DOWN 2026-08-27; check first).
- `tinyfish fetch content get <url> [url…]` — optional TinyFish content extract when Jina/Exa crawl are thin (still prefer Exa crawl as primary depth).
- **⚠️ WebFetch `403 Forbidden` / "response body not retrieved" / auth-required is usually a WAF bot-block, NOT a dead page (verified 2026-07-07 on health.ny.gov).** The page renders fine in a real browser — datacenter/fetcher IPs get blocked, so `.gov`/`.state`/enterprise sites 403 the tool while a human sees it load. **Do NOT treat this as "couldn't get it" and stall.** If the block is **Cloudflare** (body contains "Just a moment" / "security verification"), try **a cookie-warmed fetch helper** FIRST — browserless, at the network floor, parallelisable, and it works on sites that re-challenge every new URL where `/chrome` cannot at any speed (see the fetch-helper rung below). Otherwise **fall through to `/chrome`** (the user's real logged-in browser, which bypasses the WAF): open the URL there, then run an extraction script in the page. The real browser also runs the page's JS, so it reads interactive/JS-rendered tools a raw fetch can't (e.g. selecting a county in a state health department's "Find A Health Home By County" map to pull the result). Try `websearch -p jina`/Exa crawl first (cheaper), but a 403/bot-block is a legitimate reason to jump straight to `/chrome`. Distinguish it from a real `404`/`410` (page genuinely gone — don't browser-retry that).
- **⚡ A 403 on a Cloudflare-protected site — try a cookie-warmed fetch helper BEFORE escalating to `/chrome`.** Once a human has cleared the interstitial *once* in a real browser, the browser holds a `cf_clearance` cookie. That cookie + the **exact** User-Agent that earned it + the same egress IP is all Cloudflare needs — so you can go back to plain HTTP and skip the browser entirely. A cookie-warmed fetch helper does the whole thing:
  ```bash
  <fetch-helper> --refresh <domain>          # once, after the user clears the challenge in the browser
  <fetch-helper> "<url>" -o out.html --expect-title "<substring the real page must have>"
  ```
  Exit codes: **0** ok · **3** blocked/rate-limited · **4** no `cf_clearance` (ask the user to clear it once) · **5** empty. Why this rung exists: **the win is CAPABILITY, not raw speed** — measured 2026-09-02, the fetch helper took 0.19s vs a browser open+extract at 0.19s, identical command latency, because the browser driver returns before the page loads. What differs is that the browser then needs an 8-14s settle wait, and on a site that **re-challenges every new URL** (congress.gov does) a multi-query enumeration is impossible at any speed. the helper's 0.19s is one HTTPS round-trip — i.e. at the floor, no headroom left.

  **⚠️ THREE OUTCOMES, NEVER TWO — a throttle can render as a normal page.** congress.gov answers HTTP **429** with its **homepage**, 343 KB, a normal `<title>`, and zero results. That is byte-for-byte indistinguishable from "your search found nothing" unless you check. This is the Negative-Result Rule applied to a WAF: `ok` / `blocked-or-throttled` / `genuinely-empty`. Always pass `--expect-title` so the helper can catch the silent-throttle case and back off instead of handing you a false zero. Verified 2026-09-02: a phrase search that returned 16 results returned "0" eight seconds later, purely from rate-limiting.

  Two things that silently break it: a **guessed User-Agent** (`cf_clearance` is bound to the exact UA — the helper refuses to guess rather than 403 mysteriously), and **firing queries back-to-back** (space them ~8-10s; the helper retries with exponential backoff).

- Escalation ladder (global rule): `WebSearch`/`WebFetch` → `websearch`/Exa crawl (`mcp__exa__web_search_advanced_exa` + `mcp__exa__crawling_exa`) → (**on a 403/bot-block or JS-rendered page →** `/chrome` via the user's real browser, per the note above) → captured-API replay via a local capture/replay helper → (**walled/structured data none of those return →** `monid discover`, Phase 3.4 — paid, gap-filler only) → **STOP and ask** before driving a live browser for anything auth-walled or interactive-with-side-effects. Don't jump to a browser for an ordinary readable page. The unbrowse MCP is UNINSTALLED — do not route through it.

### Phase 3.4 — Walled / structured data? `monid discover` BEFORE declaring it inaccessible (conditional)

**Fires when a sub-question needs data the search+crawl ladder can't return as text** — social
posts/profiles (X/Twitter, LinkedIn, Instagram, TikTok, Reddit at volume), Google Maps
listings/reviews, marketplace prices, company/people enrichment, ad libraries, app-store
data, anything a JS wall or login hides from `websearch`/Exa crawl. Skip it for ordinary
readable pages — the free ladder above already handles those.

**Monid** (`/monid` skill, `monid` CLI — installed 2026-09-17, v0.1.7) is a catalog of
hundreds of hosted scrapers/APIs (Apify actors and others) behind one `discover → inspect →
run → poll` interface. Runs are **paid per result from the user's Monid balance**, so it is a
*gap-filler*, never the default — Monid's own precedence rule, which we keep:

1. **the user's own tools first, at \$0** — `/chrome` (the user's real logged-in
   browser reads X/LinkedIn/Instagram directly), a logged-in browser CLI / `/chromeapi` (captured-API
   replay), dedicated MCPs (`capitoltrades`, `robinhood`, `healthdata`, Exa), the ten
   `websearch` providers. If one of these can do it, do NOT spend Monid balance.
2. **Then Monid**, and only for what those genuinely can't reach or can't reach at the needed
   volume — say so in the report ("via Monid/<provider>/<endpoint>, $cost").

```bash
NO_COLOR=1 monid discover -q "linkedin posts" -l 5          # noun phrases; -s <score> to filter
monid inspect -p <provider> -e <endpoint>                   # NEVER guess params — body→-i, queryParams→--query, pathParams→--path
monid run -p <provider> -e <endpoint> -i '{"...":"...","maxItems":5}'   # ONE query per call, small limit first
monid runs get -r <runId> -o out.json                       # poll 5-10s; COMPLETED is UPPERCASE
monid balance                                               # report cost.value from the run when it matters
```

Traps (from the upstream skill, re-verified 2026-09-17): **limits are per query, not per
call** — 3 search terms × `maxItems:10` = 30 billable results, so pass one term; **`discover`
itself needs an active key** (`monid keys add -k <key> -l main`; keys come from
`https://app.monid.ai/access/api-keys` — the user creates the account, never the agent);
a `BLOCKED` run is terminal (workspace budget/run cap — tell the user, don't retry); use the
`Health` column only to break ties (`unknown` is common, not a warning); read the **Hints**
block before your next command; the CLI version and this skill's frontmatter `version` must
match — `npm install -g @monid-ai/cli@latest` + re-save `https://monid.ai/SKILL.md` to
every installed copy of the monid skill when they drift.

**Do NOT add Monid to the `websearch` provider stack** — same reasoning as the `/healthdata`
tier: it is a structured-endpoint marketplace, not general web search, and every call costs
money. It is a deliberate *source tier*, reached by name.

Three outcomes for a Monid attempt, never two: `retrieved (provider/endpoint, n results,
$cost)` / `no endpoint in catalog (discover returned nothing relevant)` / `could not run
(no key / BLOCKED / FAILED — state which)`.

### Phase 4 — Adversarial verification (the trust step)
For **each load-bearing claim** (any number, date, capability, price, quote, "X is the best/first/only"):
1. Find a **second independent source** (different domain, not a mirror/aggregator of the first).
2. Actively try to **refute** it — search the contrary (`"<claim>" criticism`, `"<claim>" wrong`, `<competitor> vs <claim>`).
3. Classify: **confirmed** (≥2 independent), **single-sourced** (flag it), **contradicted** (report both sides), **unverifiable** (say so). For finer work use the six-way scale: **verified / corroborated / allegation / inference / contradicted / unknown**.
4. Go to the **primary source** for stakes-bearing facts (the vendor's own pricing page, the statute, the filing) — not press/aggregators. Cite the primary.

Never promote a single-sourced or contradicted claim to a stated fact. Calibrated uncertainty beats confident wrongness.

### Phase 5 — Synthesize
Write the answer organized by the Phase-1 sub-questions. **Every claim carries an inline citation** — `[source](url)` + retrieved-date. Lead with the answer, then evidence, then open questions / what couldn't be verified. Distinguish *confirmed* from *reported* from *contested*. No fabricated stats, quotes, or sources (Exa Verify rule + global Ground-Truth standard).

### Phase 6 — Deliver
**Default to a single self-contained HTML report** (global HTML-Default rule): save to a reports folder as `deepsearch-<slug>-YYYY-MM-DD.html` and `open` it. Use the `/html-report` template (status grids, source tables, confidence badges render far better than Markdown). End with a **Sources** table: every URL used, provider that found it, retrieved-date, and confidence. For a quick conversational answer the user asked for inline, a Markdown reply with a Sources list is fine — but a *report/brief/audit/analysis* → HTML.

## Operational-evidence briefs (conditional)

**Fires when the research brief comes from an operational investigation** —
service delivery, billing, staffing, grants, or suspected operational failure
(the `gov` skill's operational-evidence handoff is the usual source). Load
`references/operational-evidence-research.md`: it fixes the brief's field names,
the service-to-payment tracing procedure, the negative-result controls, and a
seven-field return contract (findings, source_coverage, joins, authority_routes,
competing_explanations, next_test, blocked_dependencies). Accept only claims
with precise provenance; a directory match is not proof of payment, and a nearby
prosecuted business is not evidence against the target.

## Interrupted research & handoff

Before a long research run, or a handoff to another session/client, read
`references/muse-resumable-research.md`. Keep the existing issue, owner, and
actual runtime handles; save bounded batches and verified source artifacts with
an atomic workspace checkpoint. A dispatch acknowledgment is not a research
result, and a dropped observation is not proof the task stopped. On reconnect,
inspect the same handle and checkpoint, then continue only unfinished work —
never duplicate the assignment or claim completion from a report filename or an
unrelated chat reply.

## Optional: large-topic fan-out (Exa Research API is gone)
Exa's retired Research/agentic tools returned **410 Gone** (2026-08). Do **not** call them. For a very large topic, fan Phase 2–3 across **parallel subagents** and keep using live Exa **search-or-crawl**: `mcp__exa__web_search_advanced_exa` (filters) + `mcp__exa__crawling_exa` (read pages), or `websearch -p exa`. Synthesize yourself — don't ship any one provider's output unverified.

## Parallelization
For a broad topic, fan Phase 2–3 across **parallel subagents** (Agent tool / Explore), one per sub-question, each returning a cited mini-brief; then you dedupe, verify (Phase 4), and synthesize. Keeps each context lean and covers more ground. For multi-agent orchestration the user explicitly opts into, a `Workflow` (find → adversarially-verify → synthesize) is the heavier option.

## Hard rules
- **Cite or don't claim.** Every stakes-bearing assertion = a live URL + retrieved-date. Re-fetch primary sources now; memory/snippets are hypotheses.
- **Verify load-bearing claims against ≥2 independent sources** before stating them as fact; flag single-sourced ones.
- **Never fabricate** a statistic, quote, citation, URL, date, or source. Omit over invent.
- **curl/HTTP-verify every URL you put in the report resolves** (no 404s) — the report's links must work.
- **No exhaustive or negative claim about a site from search results alone.** "They don't mention X", "they only offer A and B", "there is no page about Y" are claims about the *complete set*. Search results are a sample; back these with the sitemap (Phase 1.5) or an equivalent full enumeration, or state them as "not found in what I searched" — which is a different, weaker, honest claim.
- **Respect the escalation ladder** — don't open a live browser without asking; `websearch` + Exa crawl handle the vast majority.
- **A speed or savings claim carries a measured numerator and a sourced denominator** (Phase 1.9). No human-baseline number that you did not find on a cited page; no elapsed time that you did not read off a timestamp.
- **Primary custodians beat search for records.** A vital record, a court index, a census sheet, a DNA share percentage: read it from the custodian's own API or page image, not from an aggregator's index of it. Route through `/autoresearch-genealogy` for person/record questions.
- **Provider failover is automatic** across the whole stack. Exit **3** = every provider failed → fall back to the built-in `WebSearch` tool rather than stalling. Exit **4** (no keys) is now effectively unreachable, since marginalia is keyless — so a bare exit 3 with searxng in the attempts list usually means *the native searxng service is down*, not that the web is unreachable. Kick it: `launchctl kickstart -k gui/$(id -u)/<your-searxng-service-label>`.
- **Never hardcode TinyFish (or any) API keys** in the skill, reports, or commits. Use `tinyfish auth` / `TINYFISH_API_KEY` / env only. Do **not** default to `tinyfish agent` browser automation for ordinary research — stay on the search/fetch ladder.

## Quick reference
```bash
# SITE-SCOPED research? sitemap first (Phase 1.5) — the site's own list of what exists,
# vs a search engine's list of what it indexed. Skip for open-web topic research.
curl -sL https://<host>/robots.txt | grep -i sitemap
curl -sL https://<host>/sitemap.xml | grep -o '<loc>[^<]*' | sed 's|<loc>||' | head -50

websearch keys                              # which providers are configured (NOT which work)
add-key.sh <provider>                       # paste a key (hidden), stores + LIVE-VERIFIES it (ships with the websearch CLI)
launchctl kickstart -k gui/$(id -u)/<your-searxng-service-label>   # kick native searxng (fixed :8888)
websearch "<query>" -n 8 --json             # stacked search w/ failover (primary)
websearch "<query>" -p tinyfish --json      # force TinyFish
websearch "<query>" -p exa --json           # force one provider
websearch "<query>" --order brave,exa,tavily,tinyfish --json
tinyfish auth status                        # TinyFish key present? (auto-read by websearch)
tinyfish fetch content get "<url>"          # optional page extract (not via websearch)
# Walled/structured data (social, maps, enrichment) the free ladder can't reach — PAID, Phase 3.4:
NO_COLOR=1 monid discover -q "<noun phrase>" -l 5   # then: monid inspect -p X -e Y · monid run … -i '{…,"maxItems":5}' · monid runs get -r <id> -o out.json
# Exa MCP (richer): web_search_advanced_exa (filters) · crawling_exa (read pages) ·
#   get_code_context_exa (code). The retired Research/agentic pair is 410 — do not call it.
```
Exit codes (`websearch`): `0` ok · `3` all providers failed · `4` no usable provider (rare — marginalia is keyless). Keys: env or `~/.config/websearch/keys.json` — `SEARXNG_URL`, `LINKUP_API_KEY`, `PARALLEL_API_KEY`, `YDC_API_KEY` (You.com), `TAVILY_API_KEY`, `BRAVE_API_KEY`, `JINA_API_KEY`, `EXA_API_KEY`, `TINYFISH_API_KEY`. Exa auto-reads from `~/.claude.json`; TinyFish from `~/.tinyfish/config.json`. Marginalia needs none.
