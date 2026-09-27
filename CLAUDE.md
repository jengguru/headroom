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
1. Bump `Resources/Info.plist`'s `CFBundleShortVersionString` (and
   `CFBundleVersion`) and move `CHANGELOG.md`'s `[Unreleased]` entries under
   the new version, in a normal branch → PR → merge.
2. Push a tag `vX.Y.Z` on `main` matching that version. `release.yml` builds
   the universal app and publishes it as a GitHub Release (`Headroom.zip` +
   its SHA-256).
   - Tag pushes need a real push from a machine with rights to it — a
     session whose git access is scoped to branch pushes only will get a
     403 pushing the tag itself; push it from a local checkout instead.
3. Update the Homebrew tap so `brew upgrade --cask headroom` picks up the
   new version: in [jengguru/homebrew-headroom](https://github.com/jengguru/homebrew-headroom),
   bump `Casks/headroom.rb`'s `version` to the new tag and `sha256` to the
   new release's `Headroom.zip` digest (from the release page or its
   `Headroom.zip.sha256` asset). That tap is a separate repo — it holds
   only that one cask file pointing at this repo's releases, nothing else
   to develop there.
