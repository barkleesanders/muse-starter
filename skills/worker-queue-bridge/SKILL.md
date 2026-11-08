

# Worker-Queue Bridge

## When to use

- You need to run commands (or deliver work) on a machine you cannot reach
  inbound: no open ports, no SSH, NAT/firewall in the way.
- Both sides can only make **outbound HTTPS** — the queue in the middle does
  the rendezvous.
- You are replacing a fragile transport (cron + SSH polling, a relay tunnel,
  a laptop-side poller) with something that survives reboots on both ends.
- You want to fan the same pattern out to more targets later (one queue
  namespace per bridge).

## Architecture — three components, one contract

**1. Queue (Cloudflare Worker + KV).** Five routes, all authenticated:

- `POST /cmd/submit` `{id, cmd_b64}` → `200 {ok:true}` | `409` on
  id/payload conflict, `{duplicate:true}` on identical re-submit.
- `GET /cmd/pending` → `[{id, cmd_b64}]` — what the executor should run.
- `POST /cmd/result` `{id, exit, output_b64, truncated}` — **atomically
  consumes** the command so it can't be picked up twice.
- `GET /cmd/results` → `{id: result}` — what the adapter should drain.
- `POST /cmd/ack` `{ids}` — deletes **results only**.

Separate KV keyspaces for commands vs results so the two sides can never
delete each other's records. Unclaimed commands expire after 24h into a
synthetic timeout result plus a dead-letter entry.

**2. Submitter adapter (runs near the requester).** Watches a spool dir:

- `req/*.cmd` → submit → delete the local `.cmd` on 200.
- Poll `/cmd/results` → write `res/<id>.out` **atomically, only-if-missing**,
  format `<output>\n---exit:N---` → ack drained ids.
- Exponential backoff 60s→300s with jitter on failures. Never prints the key.

**3. Remote executor (runs on the target).** Long-polls `/cmd/pending`:

- Runs each command in its own process group; SIGKILL on timeout
  (default 300s, hard max 1800s → exit 124 + note).
- Caps merged stdout+stderr at 256KB with an explicit truncation trailer.
- Denylist of command prefixes (`sudo`, `su`, `doas` → exit 126, refused).
- Posts the result, then acks. **Fail-open:** on bridge errors it logs and
  exits 0 — a dead bridge never pages anyone.

**Filesystem contract (keep byte-stable — callers and humans depend on it):**
drop shell text into `req/<id>.cmd`; read `res/<id>.out` when it appears.

## Semantics — say these exactly

- **At-least-once execution, at-most-once result delivery.** A crash between
  the side effect and the result post re-executes the command. Never promise
  exactly-once for arbitrary shell.
- Idempotent command ids (see 409/duplicate rules above).
- KV reads lag writes 10–60s across edge PoPs; a 60s poll cadence absorbs it.
  Don't mistake lag for a stuck queue.

## Building a new bridge from this pattern

1. **Namespace.** New KV key prefix per bridge (`cmdq2:…`), or a new Worker.
2. **Queue.** Copy the route handlers; add unit tests covering the Telegram /
   existing routes as a regression gate; deploy with `npx wrangler deploy`
   (never `npm run deploy` if the repo guards it). **Freshness (2026-10-14):**
   in any of the user's repos this deploy goes through `/ship`, whose Phase -1.9
   preflight aborts unless the checkout is committed, pushed, at the origin
   tip, and clean — GitHub is the source of truth, never the local tree.
3. **Adapter.** Submit / drain / ack / backoff. Reuse the auth pattern below.
4. **Executor.** Timeout+kill, output cap, denylist, fail-open. On macOS use a
   launchd agent with `StartInterval 60` + `RunAtLoad` — **not** `KeepAlive`
   (the script does one poll cycle per invocation; KeepAlive would hot-loop).
5. **Cutover.** **Retire the old transport first.** A racing old poller
   double-consumes commands and shadows results with its own outputs. Verify
   with `launchctl list`, `tmux ls`, and `pgrep` on every machine that ever
   ran the old worker before declaring the new bridge the owner. Also sweep
   the spool dir: stale `res/*.out` files shadow new results under the
   write-if-missing rule — archive them out of the live spool.
6. **Prove it.** A real command end-to-end with actual output in the report;
   kill both pollers mid-flight, restart, and confirm exactly one `.out`,
   nothing lost, no duplicate execution of the side effect you can avoid.
7. **Harden.** Heartbeat cron (full-loop echo every 30m, silent on success,
   alerts on failure) + stuck-command alert (result not drained after
   10 min → executor may be down).

## Auth pattern

- Reuse the host service's existing credential for the queue routes. Never
  mint a new secret for the bridge, never print or log it.
- From sandboxed VMs, reach the Worker through the connector's authd
  surrogate — and send a **browser User-Agent**: Cloudflare returns 403
  (error 1010) to bare urllib/python clients.
- Executors read the bearer from a local `0600` env file, never from the queue.

## Gotchas (earned the hard way)

1. The Workers runtime has no Node `Buffer` without `nodejs_compat` — use
   `atob`/`btoa`. It passes local tests and 400s in production otherwise.
2. Never hand-maintain a KV index under concurrent writers; use `kv.list()`
   prefix scans or entries get orphaned.
3. Retire old pollers **before** cutover, not after — a racing consumer
   corrupts results silently.
4. KV read-after-write lag is real (10–60s). Wait before calling it stuck.
5. Keep the `req/` → `res/` contract byte-stable; it is the API.

## Reference implementation (live, proven 2026-09-16)

- Worker: a small Node service on the remote machine — `src/cmdq.js`, routes
  in `src/index.js`, with a full test suite for the queue logic.
- Client adapter: a small script on the submitting side
  (+ a heartbeat check); a 60s cron keeps it running.
- Remote executor: a small script on the target machine,
  A launchd/systemd unit keeps the executor running.

## Available connectors

Use `muse.connector_search` to find the current connector docs before following
recovered instructions.
