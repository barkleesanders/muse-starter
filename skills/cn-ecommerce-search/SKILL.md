

# CN E-commerce Search

## Purpose

Give agents read-only, scriptable product search over Temu, 1688, and
Taobao through one wrapper, so sourcing questions get real listings with
prices and sales instead of web ads. Temu and 1688 search need no keys at
all: they drive the user's real Chrome on the user's machine, which reuses his
existing sessions. Taobao needs the user's own TOP app keys; without them
`taobao` commands exit non-zero with setup hints instead of faking results.

## Tooling

```
~/workspace/ecommerce-search/cli/cnshop <platform> <command> [args]
```

| Usage | Example |
|---|---|
| Temu keyword search (browser, free) | `cnshop temu search "wireless earbuds"` |
| Temu product detail (Sorftime) | `cnshop temu detail 123456789` |
| 1688 keyword search (browser, free) | `cnshop 1688 search "蓝牙耳机"` |
| 1688 product detail (Sorftime) | `cnshop 1688 detail 789542752062` |
| Taobao search (TOP) | `cnshop taobao search "蓝牙耳机"` |
| Taobao item detail | `cnshop taobao item 123456` |
| Print signed request, send nothing | `cnshop taobao search "耳机" --dry-run` |
| Environment self-check | `bash ~/workspace/ecommerce-search/scripts/doctor.sh` |

Output is clean JSON summaries (title, price, sales, image, url). The
skill ships `bin/cnshop` as a shim to the wrapper for convenience.

Under the hood:
- Temu/1688 search run `~/tools/cn-search/temu_search.py` /
  `1688_search.py` on the user's machine over SSH. Temu calls
  its own in-page search API with freshly minted auth tokens captured from
  the page's suggest traffic; 1688 reads the parsed offer-search response
  the page's own mtop client fetched. Promoted placements (Temu: no ad
  markers observed on sampled products; 1688: `isBid`/`isP4P` offers) are
  filtered out. Pagination beyond page 1 is not proven; treat
  `--page > 1` as unverified. Note 2026-09-15: 1688's bot detection
  escalated after repeated scripted navigations and its search endpoint now
  redirects to a Taobao login page; the 1688 browser route is parked until
  the user signs in once in Chrome or the block cools down. Temu search is
  unaffected and verified working.
- Temu/1688 `detail` go through `sorftime api <Endpoint> '<json>'`
  `--domain <N>` (Temu US = 701, 1688 = 601) via the local install at
  `~/workspace/ecommerce-search/vendor/`. Full endpoint docs live in the
  vendored repo: `vendor/sorftime-data-cli/resources/temu-api.md` and
  `1688-api.md`; its own SKILL.md covers advanced recipes.
- Taobao goes through `cli/taobao_top.py` against
  `https://eco.taobao.com/router/rest` with TOP MD5 signing.

See `references/field_aliases.md` for the field-name traps (price is
`Price` on Temu/1688, sales is `MonthlySaleCount`/`SalesOf30d`, etc.).

## Auth

Nothing needed for Temu/1688 search: the browser route reuses the user's
own Chrome sessions on the user's machine and copies no cookies or tokens off
it. Two registrations exist only for the paid/detail paths, both done by
the user himself:

1. **Sorftime (Temu/1688 `detail` only):** register at
   https://open-intl.sorftime.com (Google sign-in, free trial credits),
   copy the Account-SK from the dashboard, then run:
   ```
   sorftime add main <account-sk>
   sorftime use main
   ```
   Use the vendored binary: `~/workspace/ecommerce-search/vendor/node_modules/.bin/sorftime`.
2. **Taobao Open Platform (Taobao):** create a self-use app at
   https://open.taobao.com (developer console, 1-2 day review), then:
   ```
   export TAOBAO_APP_KEY=...
   export TAOBAO_APP_SECRET=...
   ```

Run `bash ~/workspace/ecommerce-search/scripts/doctor.sh` to see exactly
what is still missing; fix the MISS items and re-run the user's request.

## Operating Rules

1. Never invent results: with no Taobao keys, `taobao` commands exit
   non-zero with setup hints. Report that state, then walk the user
   through Auth. Temu/1688 search need no keys.
2. Batch loops must sleep 1 second between calls; the Sorftime endpoints
   burn credits (2-5 per call) while the browser route is free. Dry-run
   previews before large pulls.
3. Do not claim a platform is searchable until its check passes in
   `doctor.sh`. Report access as missing, never as "no products found".
4. Match the user's language: English in, English out; Chinese in,
   Chinese out. Never mix.
5. No official shopping MCPs exist from Temu, 1688, or Taobao; do not
   invent one or claim an MCP agent is available.
6. Never copy cookies, tokens, or secrets off the user's machine; the browser
   route runs entirely in-page.
## Available connectors

Use `muse.connector_search` to find the current connector docs before following
recovered instructions.
