

# x — X/Twitter API v2 CLI

Go CLI (`~/.local/bin/x`) built with the CLI Printing Press from the X API v2 OpenAPI spec, with a hand-written OAuth 2.0 multi-account auth layer.
from the X API v2 OpenAPI spec, with a hand-written OAuth 2.0 multi-account
auth layer that mirrors `~/tools/x-api/x_api_oauth.py` exactly.

All writes go direct via this CLI.

## Invocation

The CLI lives on the machine that holds the account tokens. From another host, invoke it over SSH:

```bash
ssh <host> '~/.local/bin/x <command>'
```

## Accounts

| Handle | User ID | Token scopes (2026-10-11) |
|---|---|---|




Account arg accepts handle (case-insensitive, `@` optional) or numeric user ID.

## Commands

```bash
x me <account>                        # authenticated profile
x user <account> <username>           # look up user by @handle
x timeline <account> [max]            # account's recent tweets (5-100, def 10)
x mentions <account> [max]            # mentions/replies to account (5-100, def 40)
x search <account> <query> [max]      # recent search (10-100, def 10)
x handles                             # handle → user ID map

x post <account> <text>               # post tweet
x post <account> <text> --reply-to <id>  # (or use reply)
x reply <account> <tweet-id> <text>   # reply to tweet
x delete <account> <tweet-id>         # delete own tweet

x like|unlike <account> <tweet-id>
x follow|unfollow <account> <user-id>
x block|unblock <account> <user-id>
x mute|unmute <account> <user-id>

x dm-events <account> [max]           # recent DM events
x dm-send <account> <user-id> <text>  # 1:1 DM
x dm-reply <account> <conv-id> <text> # reply in DM conversation
```

## Agent-native flags

`--json` `--compact` `--csv` `--plain` `--quiet` `--select` `--dry-run`
`--yes` `--no-input` `--agent` (sets all agent defaults). Auto-JSON when piped.
Exit codes: 0 ok, 2 usage, 3 not-found, 4 auth, 5 API, 7 rate-limited.

## Auth details

- Tokens: `~/.cookies/x.com/multi/oauth-tokens/<user_id>.json` (0600)
- Client creds: `~/.cookies/x.com/xurl-creds.env`
- Auto-refresh when within 5 min of expiry (POST `api.x.com/2/oauth2/token`,
  Basic auth, atomic save). Never printed or logged.
- Adaptive rate limiter: starts 2 req/s, halves on 429, typed `RateLimitError`.
- Env overrides: `X_OAUTH_TOKENS_DIR`, `XURL_CREDS_FILE`.

## Write approval

**Writes (post, reply, delete, like, follow, block, mute, DM sends) need
the user's per-action approval on the exact text.** No exceptions. Reads
(me, timeline, mentions, search, handles, user) are free.

## X platform limits (not bypassable)

- API replies are hard-blocked unless the original tweet @mentioned or quoted
  the account first (X policy since Feb 2026). Offer a standalone @mention
  post instead when a reply is blocked.
- Only `@TISFPOWEROUTAGE` can currently write. Re-minting the other two
  tokens needs the user's browser OAuth authorization.

## Fallback

`~/tools/x-api/x_api_oauth.py` (Python) remains as fallback — same commands,
same token layout. Do not modify it.

## Source

- Generated project: `~/printing-press/work/x-cli/` (printing press + hand-written `internal/xauth`, `internal/xapi`, `internal/cli/xcmd.go`)
- Spec: `/tmp/x-trimmed-spec.json` (18-endpoint subset of X API v2)
- Scorecard 2026-10-11: **90/100 Grade A** · dogfood: PASS
## Available connectors

Use `muse.connector_search` to find the current connector docs before following
recovered instructions.
