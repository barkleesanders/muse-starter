---
name: ai-credit-watch
description: "Find and claim free AI credits, free tokens, and free-plan offers from Anthropic/Claude, xAI/Grok, OpenAI, and Meta/Muse. Sweeps each provider's official X/Threads accounts, news pages, changelogs, and the freetokens aggregator; dedupes against a seen list; claims only offers that are fully free, need no payment method, and do not opt you into training-data sharing; verifies every claim on the provider's balance page before calling it claimed. Use when asked to find free AI credits, check for new credit offers or promos, or set up a recurring credit watch."
---

# /ai-credit-watch — Free AI Credit Watch

Track free-credit / free-plan offers from four AI providers — Anthropic (Claude),
xAI (Grok), OpenAI, and Meta (Muse) — and claim the ones that are genuinely free
and safe to claim. Everything else gets reported, never silently claimed.

## The prompt

This is the whole workflow as a single copy-paste prompt. Paste it into Muse
(or any capable agent) as-is; it is also the text this skill executes.

```text
Find me free AI credits.

Sweep these sources for free-credit, free-token, free-plan, and promo offers:

Anthropic / Claude:
- X: @ClaudeDevs, @claudeai, @AnthropicAI — posts mentioning credits, free credits, promo, claim
- anthropic.com/news and claude.com/blog — credit/promo announcements
- Claude Code changelog (github.com/anthropics/claude-code/blob/main/CHANGELOG.md) — "claim-credit" or credit mentions

xAI / Grok:
- X: @xai, @grok — posts mentioning credits, free credits, promo, claim
- x.ai/news and docs.x.ai release notes — credit mentions
- console.x.ai billing/credits page (read-only, only if already logged in)

OpenAI:
- X: @OpenAI, @OpenAIDevs — posts mentioning credits, free credits, promo
- openai.com/news and help.openai.com promotions articles
- platform.openai.com billing (read-only, only if already logged in)

Meta / Muse:
- Threads: @meta.ai — posts mentioning credits, free tokens, referral, promo
- Meta newsroom announcements
- Muse Settings — referral and token offers

General:
- github.com/luongnv89/freetokens — README + recent issues, all providers
- One general search per provider: "<provider> free credits claim"

Keep a seen list (a JSON file you create, e.g. ~/workspace/ai-credit-watch/seen.json).
Every offer is handled exactly once: compare each candidate against the seen list
(match on claim link, or title + provider) and skip anything already seen.

For each new offer, record: title, amount, provider, who is eligible, claim
deadline, claim link, source URL, and whether it requires a data-sharing opt-in.

CLAIM an offer only when ALL of these are true:
- It is free: no deposit, top-up, payment method, card, or paid trial required.
- It does NOT opt me into sharing my data for training. (xAI and OpenAI
  data-sharing credits are never allowed — xAI's cannot be reversed.)
- It is a claim/redeem button on the provider's own official domain: claude.ai,
  console.x.ai, grok.com, platform.openai.com, chatgpt.com, muse.ai — or a Muse
  token offer inside my own Settings.
- I am already logged in there. Never type a password, one-time code, or card
  number. Never create an account.
- After claiming, re-read the balance/credits page. Count it as claimed ONLY if
  the new credit actually shows. If it does not show, log "claim attempted
  <date>, not verified on balance page" and tell me — do not mark it claimed.

REPORT everything else to me in one short message, one line per offer plus the
official link: anything that needs payment, data sharing, an application form,
a referral code from a stranger, or a login you don't have. Do not claim those.

Hard rules:
- Never type a password, one-time code, or card number. Never create an account.
- Never claim anything that opts into training-data sharing.
- Never fabricate a claim link. Only use a URL you actually saw published.
- If nothing is new, say so in one line and stop.
```

## Running it on a schedule

The prompt works one-shot, but it pays off as a recurring check: run it every
6 hours and keep the same seen list between runs, so each offer is claimed or
reported exactly once and quiet runs produce no noise. In Muse, ask:
"Run the ai-credit-watch prompt every 6 hours and only message me when
something is new."

## Notes

- Verification rule for claims: a claim is not done when the button is clicked —
  it is done when the credit shows on the provider's balance page.
- Offers that recur (monthly plan credits, referral token grants) belong in the
  seen list too, marked claimed once, so they are never double-claimed.
- Third-party gateway promos surfaced by aggregators (new-account credits on
  someone else's API gateway) are report-only, never claim: they are not the
  provider's own domain.
