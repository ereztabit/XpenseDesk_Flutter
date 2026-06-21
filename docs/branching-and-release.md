# Branching & Release Method

How work flows from an idea to production on this repo. This is the authoritative
description; `CLAUDE.md` points here. It mirrors the backend repo's method
(`XpenseDeskServer/docs/branching-and-release.md`), adapted for Flutter web on
Azure Static Web Apps.

## Branches

| Branch | Role |
|--------|------|
| `develop` | **The trunk.** All work and commits happen here. |
| `main` | **The release/deploy branch.** Code reaches it only by merging `develop`. |

## Golden rules

- **Never commit, push, or merge without the user's explicit, in-turn consent.**
  Invoking the `start-feature` / `ship-feature` skills counts as consent for the
  steps those skills perform.
- **All work happens on `develop`.** Never commit straight to `main`.
- **Pushing `main` is the deploy.** GitHub Actions
  ([.github/workflows/azure-static-web-apps.yml](../.github/workflows/azure-static-web-apps.yml))
  auto-deploys the Flutter web build to Azure Static Web Apps on every push to
  `main`. Pushing `develop` never deploys.
- **No manual deploys.** CI owns deployment. Do not run `flutter build web` + a
  manual SWA upload by hand to push to production.

## Feature audit log

Every shipped feature gets one row in the root [README.md](../README.md) table:
`Date | Feature | Description` (description <= 200 chars), newest first. It must
stay committed/pushed so it is readable on GitHub.

## The flow

Three explicit phases. **Finishing is not releasing** - work is banked on `develop`,
then released to `main` on a separate, explicit say-so (you can batch several
finished features into one release).

1. **Start** a feature/bug -> `start-feature` skill: move to `develop`, sync it with
   `main`, add the README row.
2. **Build** the feature on `develop`.
3. **Finish** when done -> `finish-feature` skill: review + checks, commit/push
   `develop`. **Stops there - no merge, no deploy.**
4. **Ship** when you decide to release -> `ship-feature` skill: merge `develop` ->
   `main`, build, push `main` (CI deploys).

## Skills

- **`start-feature`** ([.claude/skills/start-feature/SKILL.md](../.claude/skills/start-feature/SKILL.md))
  - Working tree must be clean (else stop).
  - Checkout `develop`, pull latest.
  - Ensure `main` is fully merged into `develop` (merge it in; **stop on conflict**).
  - Add the README feature-log row. Does **not** commit.
- **`finish-feature`** ([.claude/skills/finish-feature/SKILL.md](../.claude/skills/finish-feature/SKILL.md))
  1. Code review + security review of the diff. Blocking finding -> stop.
  2. `flutter analyze` clean + `flutter build web --release` green (+ `flutter test`
     if tests exist) -> else stop.
  3. Commit + push `develop`. **Stops here - does NOT merge to `main`, does NOT deploy.**
- **`ship-feature`** ([.claude/skills/ship-feature/SKILL.md](../.claude/skills/ship-feature/SKILL.md))
  - Assumes the work is already committed/pushed on `develop` (via `finish-feature`).
  1. Pre-flight: `develop` clean + pushed (else stop, run `finish-feature` first).
  2. Merge `develop` -> `main`. **Conflict -> stop immediately.**
  3. Build `main` (must compile -> else stop).
  4. Push `main` -> CI deploys.
  - **Stop immediately on any conflict or any failing step** - never work around it.
