---
name: finish-feature
description: Use when a feature/bug is done and ready to bank on the develop trunk - but NOT to release. Triggers - "finish the feature", "finish this", "wrap it up", "done with this", "commit to develop". Runs review + checks, then commits and pushes develop. Works from develop directly, or from a feature/<slug> branch (full-stack mission), in which case it merges develop into the feature branch first, hard-stops on any conflict, and only then merges back to develop. Does NOT merge to main and does NOT deploy.
---

# Finish Feature (bank on develop - no release)

Finalizes the current work on the `develop` trunk per
[docs/branching-and-release.md](../../../docs/branching-and-release.md). This is
**not** a release: it commits and pushes `develop` only. It never merges to `main`
and never deploys. Releasing is a separate, explicit step (`ship-feature`).

Works from two starting points:

| You are on | What happens |
|---|---|
| `develop` | Checks, then commit + push `develop` |
| `feature/<slug>` (full-stack mission) | Checks, commit + push the feature branch, then merge `develop` **into** it, re-run the checks on the result, and merge back to `develop` |

Invoking this skill is the user's consent for the commit + push to `develop` it
performs, and for the feature-branch merge-back in step 9.

> **HARD RULE: stop immediately on ANY failing step.** Do not work around a failure -
> report it with the failing output and wait for the user.

## Steps (in order)

1. **Identify the branch you are finishing on.** Run `git branch --show-current`.
   There are exactly two cases:
   - **On `develop`** (the normal single-repo flow) - proceed. All work commits
     here, never `main`.
   - **On `feature/<slug>`** (a full-stack mission - see the root
     `CLAUDE.md`) - proceed the same way through steps 2-8, committing on the
     feature branch, then run **step 9** to integrate and merge back to
     `develop`. Do **not** `git checkout develop` here; that would strand the
     uncommitted work.
   - On `main` or anything else - **STOP** and ask.
2. **Feature log.** Confirm the feature has a row in the root `README.md` feature
   log (added at `start-feature`); if missing, add it
   (`Date | Version | Feature | Description <= 200`) with Version `TBD`.
3. **Code review + security review.** Run the `code-review` skill and the
   `security-review` skill on the diff (`git diff origin/main` - covers
   committed-on-develop + working-tree changes). Report findings. A real blocking
   issue (correctness bug / security vuln) -> **STOP** and surface it.
4. **Checks green.** Run `flutter analyze` (must be clean) and
   `flutter build web --release --dart-define=ENV=prod` (must compile). If a `test/`
   suite exists, run `flutter test` too. **Any failure -> STOP.**
   - Pre-existing findings tracked as their own backlog bug (e.g. the known
     info-level lints) are not a failure of this change - say so explicitly with
     the count, and confirm the change added none.
5. **Bump the app version.** Run `sh .githooks/bump-version.sh` - bumps the minor
   version in `pubspec.yaml` and stages it. It prints `old -> new` (e.g.
   `1.6.0+1 -> 1.7.0+1`). **This is the ONLY place the version bumps** (mid-feature
   commits must not bump). Skip only if this finish carries no shippable app change
   (pure repo/docs chore) and the user agrees.
6. **Stamp the version into the feature log.** Take the displayed form of the new
   version - `v{MAJOR}.{MINOR}` (e.g. `1.7.0+1` -> `v1.7`) - and replace the `TBD`
   in this feature's `README.md` row with it. If the bump was skipped (chore), leave
   the row's Version as the current `v{MAJOR}.{MINOR}` or mark it `-`.
7. **Update the work-tracking docs.** The work is developed but NOT in production,
   so it is not yet "done":
   - In `docs/current-work.md`, keep the item under `## Currently Working On` and
     rewrite its line to exactly one banked marker:
     `<name> - banked on develop as v{MAJOR}.{MINOR} (<today YYYY-MM-DD>), awaiting ship-feature.`
     plus any genuinely outstanding verification. **`ship-feature` deletes this
     line when it releases** - it is a short-lived marker, never a permanent entry.
   - Leave the spec in `docs/in-progress/` — the work is still in flight until it
     is released. It moves to `docs/completed/` at `ship-feature`, because
     "completed" means shipped to production, not merged.
   - **A bug fix that the user has verified is done now**: close it through the
     `bug` skill (Status `done` + Resolution, `git mv` the doc to
     `docs/bugs/completed/`, delete its line from `current-work.md`) rather than
     leaving a banked marker.
8. **Commit + push the branch you are on.** Stage the changes, commit with a
   clear message, and push:
   - On `develop`: `git push origin develop`. **You are done - go to step 10.**
   - On `feature/<slug>`: `git push origin feature/<slug>`, then continue to
     step 9.
9. **Feature branch only - integrate, then merge back to `develop`.**
   **Merge `develop` into your feature branch FIRST, never the other way round.**
   Any conflict then surfaces on your own branch, where it is yours to resolve,
   instead of landing half-merged on the shared trunk that everyone builds on.
   1. `git fetch origin`
   2. `git checkout develop && git pull --ff-only origin develop` - get the real
      current trunk. If this is not a fast-forward, **STOP**: `develop` has
      diverged locally and that must be sorted out first.
   3. `git checkout feature/<slug> && git merge develop`
   4. **Conflict here -> HARD STOP.** Do not resolve it as part of finishing the
      feature, do not `--abort` and try another route, do not merge into
      `develop` anyway. Report the conflicting files and wait for the user.
   5. **If the merge brought anything in, re-run step 4's checks** on the merged
      feature branch. This is the only point where your work and the trunk are
      compiled together - a clean build before the merge proves nothing about
      the combination. Any failure -> **STOP**.
   6. `git checkout develop && git merge --no-ff feature/<slug>` - now guaranteed
      trivial, because the feature branch already contains everything on
      `develop`. If git still reports a conflict here, something is wrong -
      **STOP**.
   7. `git push origin develop`.
   8. Leave the feature branch in place; deleting it is the user's call.
10. **Done - report and STOP.** State clearly: committed + pushed on `develop`, **not
    released**. The work is banked on the trunk; deploy later with `ship-feature`.
    On a full-stack mission, say plainly that this repo is banked and name the
    other repo's state - both halves need finishing before either can ship.

## Notes
- This skill deliberately stops at `develop`. It does NOT merge to `main` and does
  NOT trigger CI - so nothing deploys. That is true on both paths: finishing a
  feature branch merges it to `develop` and stops there.
- **Why `develop` -> feature before feature -> `develop`:** the second merge is
  then trivial by construction, so the shared trunk never receives a conflicted
  or half-resolved merge. A conflict is a signal to stop and think, not an
  obstacle to work around mid-skill.
- Several finished features can accumulate on `develop` and be released together in
  one `ship-feature` run; each keeps its own banked marker until then.
- Editing the docs: use the Edit/Write tools. Do **not** rewrite these files with
  PowerShell `Set-Content`/`Out-File` - PowerShell 5.1 mangles their UTF-8 content
  (em dashes, box drawing, Hebrew) and adds a BOM.
