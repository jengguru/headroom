# Decisions

Why Headroom is built the way it is — one append-only entry per non-trivial
decision, newest first. `CHANGELOG.md` says *what* shipped; this says *why*,
including the paths that were tried and abandoned, so nobody (human or
Claude) re-litigates or re-tries them from scratch.

## 2026-09-27 — Made the combined popover more compact by tightening spacing, not restructuring it

**Context:** With Claude + Codex both on, the combined popover's stacked
per-provider cards felt tall and "clunky".

**Options considered:** (1) shrink existing card padding/font sizes, (2)
collapse each primary window to a single-line row (title + % + bar, no
reset countdown) instead of a card, (3) hide `extraWindows` behind a
"Show more" disclosure.

**Decision:** Went with (1) only — smallest, lowest-risk change, and kept
all the same information visible. `Card` padding 14→10, `UsageBar` height
6→5, `ProviderSection`/`content` inter-item spacing tightened, and the
compact `UsageCard`'s percentage font 20→17.

**If still too tall:** (2) and (3) are still on the table — (2) trades
away the reset countdown for the biggest height win; (3) keeps everything
but requires an extra tap to see Opus/Sonnet-specific windows.

## 2026-09-27 — Did not add multi-Claude-account tracking

**Context:** Wanted to track a personal and a work (Enterprise/SSO) Claude
account side by side, without logging out and back in to check either one.

**Explored:** Claude Code shards its Keychain item by `CLAUDE_CONFIG_DIR`
(`Claude Code-credentials-<sha256-prefix-of-path>`, reverse-engineered
against a real install — see git history on the now-reverted
`298c9ac..38d0372` range for the working implementation). It worked: a
second account signed in under its own `CLAUDE_CONFIG_DIR` showed up in
Headroom with live, auto-refreshing usage data.

**Decision:** Reverted anyway. The one-time manual sign-in step per extra
account (`CLAUDE_CONFIG_DIR=<dir> claude` → `/login`) wasn't worth the
added Settings UI and code complexity for the value it gave.

**Also explored and explicitly rejected:** showing the dollar-based spend
allowance (`/api/organizations/{org}/usage`, the number behind claude.ai's
Settings → Usage page). It authenticates with the full `sessionKey` web
session cookie, not Claude Code's scoped OAuth token — a much more
sensitive credential, and the same "browser cookie, expires, looks like
scraping" trade-off the README already ruled out for the original CLI
usage number. Not doing this either, for the same reason.

**If revisited:** the reverted commits (before `82fd76d`, the revert
commit) are a complete, working reference for the Keychain-sharding
approach if the calculus changes (e.g. Claude Code adds a documented way
to enumerate signed-in accounts).
