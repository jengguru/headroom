# Changelog

Notable changes to Headroom, newest first. Loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]
- Fixed: the gear button's Settings window failed to open at all on macOS 26 — it relied on a private, undocumented `showSettingsWindow:` selector that stopped working on that OS version. Settings is now a plain `NSWindow` this app creates and owns directly, instead of one triggered through SwiftUI's `Settings { }` scene.

## [0.4.0] - 2026-09-27
- Added: a per-provider Refresh button (Claude, Codex) next to each provider's heading in the combined popover, so refreshing one no longer re-polls the other.
- Changed: tightened card padding, bar height and font sizes in the combined popover so Claude + Codex together take noticeably less vertical space.
- Changed: Settings is now a real window (opened from the gear button) instead of swapping in place inside the popover — the popover's window wasn't reliably shrinking back down after showing the taller Settings view, leaving blank space (and its shadow) above the content.
- Fixed: the Settings window now actually comes to the front instead of staying behind other apps' windows, and follows you to whichever macOS Space you're on. Its Dock icon appears only while it's open (macOS restricts window ordering for menu-bar-only apps otherwise).
- Changed: opening Settings now closes the popover instead of leaving it open behind the Settings window.
- Changed: README links point at jengguru/headroom; new tagline.

## [0.3.0] - 2026-09-23
- Added: Codex (ChatGPT plan) usage as a second provider, with a combined or per-service menu bar icon and provider-named notifications.
- Added: tag-triggered Release workflow publishing signed `Headroom.zip` builds (+ SHA-256) to GitHub Releases.
- Changed: hardened CI — SHA-pinned GitHub Actions, read-only token, no-third-party-dependency check, hardened runtime, launch smoke test.

## [0.2.0] - 2026-09-23
- Added: first release — menu bar app tracking Claude Code's session/weekly usage limits via the same endpoint its own `/usage` command uses.
