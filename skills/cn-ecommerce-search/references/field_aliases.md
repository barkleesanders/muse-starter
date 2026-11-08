# Field-alias pitfalls

The Sorftime APIs use non-standard field names. Check this list before
assuming an endpoint does not return something. Source of truth:
`~/workspace/ecommerce-search/vendor/sorftime-data-cli/resources/_field_aliases.md`.

| You want | Temu field | 1688 field |
|---|---|---|
| price | `Price` | `Price` (also `WholesalePriceRange` for tiers) |
| monthly sales | `MonthlySaleCount` | `SalesOf30d` |
| total sales | `CumulativeSaleCount` | n/a |
| rating | `Star` | `Score` |
| review count | `ReviewCount` | `ReviewCount` |
| product URL | n/a (use `ProductId`) | `Url` |
| store | `StoreName` | `StoreName` |
| minimum order qty | n/a | `MinOrderQuantity` |

## Parameter naming traps (Sorftime)

- Temu/1688 keyword search takes `{"Name": "..."}` with capital N, not lowercase `name`.
- 1688 image search takes `{"ImageUrl": "..."}`.
- Category queries take `{"NodeId": "..."}`; paginate from page 1.
- API status field is `Code` on success, `code` on error: use `jq -r '.Code // .code'`.
- Endpoint names are PascalCase without separators: `ProductSearchFromName`, not `product-search`.

## Taobao TOP notes

- `taobao.item.search` was retired from the TOP public catalog (verified
  2026-09-14 against open.taobao.com; no doc page exists anymore). For
  keyword discovery use the 1688 path or the site-search capture workflow.
- Signing (verified against official doc "API调用方法详解", 2026-04-24):
  sort params by name ASCII order, exclude `sign`/byte[]/empty params,
  concatenate `secret + k1+v1 + k2+v2 + ... + secret`, MD5, uppercase hex.
  Gateway: https://gw.api.taobao.com/router/rest.
  `taobao_top.py --dry-run` prints the signed request for offline checking.
