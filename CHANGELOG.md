# Changelog

Notable changes to Headroom, newest first. Loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]
- Added: a per-provider Refresh button (Claude, Codex) next to each provider's heading in the combined popover, so refreshing one no longer re-polls the other.
- Changed: tightened card padding, bar height and font sizes in the combined popover so Claude + Codex together take noticeably less vertical space.
- Fixed: the popover no longer leaves blank space reserved above its content — the window was sticking to whatever height Settings (its tallest view) had last needed instead of shrinking back down.
- Changed: README links point at jengguru/headroom; new tagline.

## [0.3.0] - 2026-09-23
- Added: Codex (ChatGPT plan) usage as a second provider, with a combined or per-service menu bar icon and provider-named notifications.
- Added: tag-triggered Release workflow publishing signed `Headroom.zip` builds (+ SHA-256) to GitHub Releases.
- Changed: hardened CI — SHA-pinned GitHub Actions, read-only token, no-third-party-dependency check, hardened runtime, launch smoke test.

## [0.2.0] - 2026-09-23
- Added: first release — menu bar app tracking Claude Code's session/weekly usage limits via the same endpoint its own `/usage` command uses.
