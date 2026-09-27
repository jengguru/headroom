# Working in this repo

## Changelog is the source of truth
Whenever a PR lands on `main` (a feature, fix, or user-visible change), add
one bullet to the `[Unreleased]` section of `CHANGELOG.md` in that same PR —
don't wait until release time to reconstruct it from commit messages.

When cutting a release: rename `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD`
matching the new git tag and `Resources/Info.plist`'s `CFBundleShortVersionString`,
then add a fresh empty `[Unreleased]` above it.

## Record non-trivial decisions, especially abandoned ones
For anything more than a small fix — a new feature, a design considered and
rejected, an approach tried and reverted — add an entry to `DECISIONS.md`
in the same PR: context, what was decided (or undone), and why. This is
what stops the same dead end (e.g. an approach that turned out to need a
credential too sensitive to store) from being re-explored from scratch in
a future session.

## Build & test
- `swift build` / `swift test` — this package has no third-party dependencies
  (`scripts/check-no-dependencies.sh` enforces that in CI).
- `scripts/build-app.sh` (`UNIVERSAL=1` for both architectures) builds the
  ad-hoc-signed `Headroom.app`; `scripts/smoke-test.sh` launches it.

## Releasing
Push a tag `vX.Y.Z` on `main` matching `Info.plist`'s version — `release.yml`
builds the universal app and publishes it as a GitHub Release.
