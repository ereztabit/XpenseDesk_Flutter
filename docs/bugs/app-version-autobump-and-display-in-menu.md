# Bug: Auto-Bump Minor Version in pubspec.yaml at Commit Time + Show Version in Main Menu

> **Status: new**

## Problem

There is no way to confirm a deployment actually reached production. Two pieces
are missing:

1. The minor version in `pubspec.yaml` should auto-increment as part of every
   commit, transparently — bumped and staged so it lands in the same commit
   without the developer having to think about it. Today `pubspec.yaml` is pinned
   at `1.0.0+1` and never changes.
2. The current app version should be visible at the very bottom of the main
   navigation menu, below everything else. This is an internal aid for us to
   verify a deployment has reached production — not a user-facing feature.

## Reproduce Steps

1. Make a commit.
   -- Expected: `pubspec.yaml`'s minor version is incremented and included in that
      same commit automatically.
   -- Actual: version stays `1.0.0+1` forever; no way to tell which build is live.
2. Open the navigation menu and scroll to the bottom.
   -- Expected: a small version label (e.g. `v1.1`) at the very bottom.
   -- Actual: no version is shown anywhere.

## Decisions

- **`pubspec.yaml` is the single source of truth for the version.** The bump
  materializes there, in the commit — NOT injected at build time in CI.
- **Bump happens at commit time, automatically and silently**, and is staged into
  the same commit being made.
- **Only the minor number increments** each commit: `1.0` -> `1.1` -> `1.2` ...
  Major stays fixed until bumped manually. (The `pubspec` `+build` suffix can ride
  along or be left as-is — TBD, see Open Questions.)
- **Display format: `major.minor` only, e.g. `v1.1`.** No patch, no build
  metadata, no SHA shown on screen.

## Suggested Fix

### Part 1 — auto-bump the minor version in pubspec.yaml at commit time

The mechanism must run on every commit, bump `version:` in `pubspec.yaml`
(minor +1), and `git add` the file so it is part of the commit. Preferred
mechanism — a **git `pre-commit` hook** so it is independent of who/what makes
the commit:

- `.git/hooks/pre-commit` (or, version-controlled, a script under the repo wired
  in via the project's hook setup) that:
  1. Reads `version: MAJOR.MINOR+BUILD` from `pubspec.yaml`.
  2. Increments MINOR.
  3. Writes it back and runs `git add pubspec.yaml` so it is included in the
     in-progress commit.
- Must be idempotent within a single commit (don't double-bump on hook retries)
  and must not bump on commits that change nothing relevant. Edge cases to settle:
  merge commits, rebases, amends, and commits made by tooling.

NOTE: this repo's CLAUDE.md says Claude must never commit unless explicitly asked
that turn. A git hook is the robust place for this so the bump happens for ANY
commit (Claude's or the user's) — it does not depend on Claude remembering.

### Part 2 — display version in the menu

- Read the version from the bundled `pubspec` at runtime via the
  `package_info_plus` package (`PackageInfo.fromPlatform()` -> `info.version`),
  then format as `v$major.$minor` (strip patch/build for display).
- Render a muted version caption at the bottom of:
  - `lib/widgets/header/desktop_menu.dart` (after the last menu item)
  - `lib/widgets/header/mobile_menu_sheet.dart` (after the action items)
- No new ARB string needed — it is just `vX.Y` (a number, not translatable copy).

## Open Questions (confirm with user before implementing)

- Hook delivery: a tracked script the repo installs, or a documented manual
  `.git/hooks/pre-commit` setup? (Tracked + an install step is more reproducible.)
- What happens to the `pubspec` `+build` metadata — leave at `+1`, or also bump?
- Behavior on merge/rebase/amend commits — bump or skip?
