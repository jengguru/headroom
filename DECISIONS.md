# Decisions

Why Headroom is built the way it is — one append-only entry per non-trivial
decision, newest first. `CHANGELOG.md` says *what* shipped; this says *why*,
including the paths that were tried and abandoned, so nobody (human or
Claude) re-litigates or re-tries them from scratch.

## 2026-09-27 — Distribute via a separate Homebrew tap, not the main repo

**Context:** Wanted `brew install --cask headroom` instead of manually
downloading `Headroom.zip` and dragging it into Applications.

**Decision:** Headroom isn't notable enough to be accepted into the
official `homebrew-cask` repo, so distribution goes through a personal tap:
[jengguru/homebrew-headroom](https://github.com/jengguru/homebrew-headroom),
holding only `Casks/headroom.rb` (points `url`/`sha256` at this repo's
GitHub Releases) and a README. No app code lives there and it isn't a
place to develop features — see this repo's own `CLAUDE.md` for the
release steps that keep it in sync.

**Hit along the way:**
- Pushing the release tag itself (not just branches) got a 403 from this
  session's git credentials; tags needed pushing from a machine with real
  rights to the repo.
- The tap repo's branch ruleset required a "macos" status check that no
  workflow in that repo produces, permanently blocking every push until
  the requirement was removed — a tap this small doesn't need CI.
- **`brew install --cask headroom` (bare, no tap prefix) installs the wrong
  app.** The official Homebrew Cask repository already has an unrelated
  cask named `headroom` (for [extraheadroom.com](https://extraheadroom.com),
  a "Headroom Labs" video-call app) — confirmed on a real Mac: it has its
  own sign-in flow and a completely different icon, nothing to do with this
  project. The trusted official cask wins over a personal tap's identically
  named one, silently. The only fix is always using the fully-qualified
  name: `brew install --cask jengguru/headroom/headroom` (and the same
  for `brew upgrade`) — README.md and CLAUDE.md's Releasing section both
  say this now. Renaming this project's own cask token was considered and
  rejected: it wouldn't remove the ambiguity (the collision would just move
  to whatever new name is picked, and `headroom` is also the name of at
  least two other unrelated Claude/Codex usage-tracking side projects found
  when investigating this), so full qualification is the actual fix, not a
  workaround.

## 2026-09-27 — Settings is a real window, not swapped into the popover

**Context:** Settings used to swap in place of the main usage view inside
the same `MenuBarExtra(.window)` popover (toggled by the gear button).
After the compact-popover change (below) made the main view noticeably
shorter than Settings, reopening the main view left blank space — and its
window shadow — reserved above the content where the taller Settings view
used to reach.

**Tried and confirmed not to work, in order:**
1. `.fixedSize(horizontal: false, vertical: true)` on the root view.
2. `.id(showingSettings)` on the swapped subtree, to force SwiftUI to tear
   down and rebuild it (not just diff it) on every toggle.
3. `NSViewRepresentable` (`WindowHeightSync`) reaching the real `NSWindow`
   directly and forcing `setFrame` to the hosting view's `fittingSize`.

All three still left the gap after actually testing on a real Mac
(confirmed via screenshots: the window's drop shadow extended over the
blank space too, meaning the live `NSWindow` frame genuinely wasn't
shrinking — not just a SwiftUI layout report being stale). `MenuBarExtra`'s
`.window` style just doesn't reliably shrink its backing window back down
once it's grown for a taller view, and no amount of telling SwiftUI the
"correct" ideal size fixed that from inside the same window.

**Decision:** Stopped patching around it. Settings now opens as a genuine
second window via a SwiftUI `Settings { }` scene (the standard macOS
Preferences pattern), triggered from an `LSUIElement` app with
`NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)`
since there's no visible app-menu item to click. The popover now only ever
shows one shape of content, so the resize bug has no case left to trigger.

**If a menu-bar Settings *panel* (not a window) is wanted again:** the
underlying `MenuBarExtra` sizing bug is still there; don't retry 1–3 above
without a different mechanism (e.g. an `NSPopover`-based custom
implementation instead of `MenuBarExtra`, which has its own resizing API).

**Follow-up (confirmed on a real Mac):** the new Settings window opened,
but behind other apps and not on the current macOS Space — an accessory
(`LSUIElement`) app doesn't get "bring to front" / "follow me to this
Space" for its windows for free the way a regular app does.
`SettingsWindowSetup` (an `NSViewRepresentable` in `SettingsPanel`) sets
`window.collectionBehavior.insert(.moveToActiveSpace)` once, when the
window is first created, and stashes a weak reference to it
(`SettingsWindowReference`) so the gear button can call
`window.makeKeyAndOrderFront(nil)` on every click after `NSApp.activate` —
not just the first time the window is created.

**Second follow-up (still confirmed behind other apps' windows):**
`activate` + `makeKeyAndOrderFront` weren't enough either — macOS
deliberately restricts an accessory-policy (`.accessory`) app from forcing
its windows above other apps'; that's the point of that policy, not a bug
to route around locally. The gear button now flips
`NSApp.setActivationPolicy(.regular)` before showing Settings (which lifts
that restriction, at the cost of a Dock icon appearing while the window is
open — same trade-off other menu-bar-only apps make for their own
Settings/About windows), and `SettingsWindowSetup` flips it back to
`.accessory` via `NSWindow.willCloseNotification` once the window closes.

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
