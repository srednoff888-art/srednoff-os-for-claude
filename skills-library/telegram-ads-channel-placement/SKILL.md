---
name: telegram-ads-channel-placement
description: "Plan, structure, and audit campaigns on the official Telegram Ads platform (ads.telegram.org) - channel/bot targeting, sponsored-message copy within the 160-character limit, TON payment, and Telegram's ad guidelines. Use when the task involves Telegram Ads, ads.telegram.org, sponsored messages in Telegram channels, or promoting a Telegram channel/bot via Telegram's own ad platform - not Telegram bot development and not third-party Telegram traffic (that's a different skill and a different product)."
---

# Telegram Ads (ads.telegram.org) — Channel Placement

SREDNOFF-authored. No third-party Claude Code skill for the Telegram Ads platform was
found during github-research (verified 27.07.2026) - Yandex Direct, Google Ads, and Meta
Ads all have real community skills (see `yandex-direct-ppc`, `google-ads-full-audit`,
`meta-ads-full-audit`); Telegram Ads specifically does not yet. This skill is written
directly from Telegram's own public ad platform and guidelines, not adapted from a
third-party source - treat it as a starting structure, not a scored/benchmarked audit
tool the way the other three are.

## What Telegram Ads actually is

- Official platform at ads.telegram.org - sponsored text messages placed at the bottom
  of a channel's post feed, not personalized/behavioral targeting.
- Targeting is by **channel or topic category**, not by user profile - advertisers pick
  the channels (or let Telegram's category targeting pick relevant ones) where the ad
  should appear.
- Ad format: up to 160 characters of text, optionally one button linking to a channel,
  bot, or external URL. No images in the standard unit.
- Minimum spend and self-serve thresholds vary by market; large campaigns are typically
  billed in TON (Telegram's own cryptocurrency) or by invoice for verified advertisers.
- Full current rules: https://ads.telegram.org/guidelines - always check this before
  finalizing copy, since Telegram's content policy is stricter than most ad platforms
  (no clickbait, no crypto/gambling in most markets, no impersonation).

## Workflow

1. Clarify the actual goal: channel growth, bot installs, or external-site traffic. The
   button destination changes based on this - don't default to "external URL" without
   asking.
2. Identify target channels: either explicit channel list (if the advertiser knows their
   audience's channels) or category-based targeting (broader reach, less precise).
3. Draft copy within the 160-character hard limit. Telegram's own guidance favors direct,
   non-clickbait phrasing - flag anything that reads like clickbait for revision before
   presenting it as a finished draft.
4. Cross-check the draft and target categories against the current guidelines
   (https://ads.telegram.org/guidelines) - policy changes over time, don't rely on
   cached knowledge of what was allowed previously.
5. If this campaign sits alongside other paid-media work, note the channel/CPM basis
   (Telegram Ads is priced and reported differently from CPC/CPA search or social
   platforms) so it isn't compared apples-to-apples in a blended report without a caveat.

## Guardrails

- Do not submit or pay for a live campaign - this skill produces a plan/draft for human
  review, not an executed spend action (Telegram Ads has no public API for autonomous
  campaign management as of this writing; everything goes through the ads.telegram.org
  web UI).
- Do not claim behavioral/interest targeting exists on this platform - it does not;
  overstating targeting precision to a client would be a real factual error, not just
  a style issue.
- If the advertiser's market has additional restrictions (financial services, alcohol,
  regulated categories), say so explicitly and point to the guidelines page rather than
  guessing at what's allowed.
