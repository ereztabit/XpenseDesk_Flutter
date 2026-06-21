---
name: ship-feature
description: Use when finished work on develop is ready to release to production on this Flutter repo. Triggers - "ship it", "release this", "ready for deployment", "push to prod", "deploy". Merges develop -> main and pushes (CI deploys). Assumes the work is already committed on develop (run finish-feature first). STOPS immediately on any conflict or failing step.
---

# Ship Feature (release to production)

Releases the work already banked on `develop` to production per
[docs/branching-and-release.md](../../../docs/branching-and-release.md). **Pushing
`main` is what deploys** - GitHub Actions auto-deploys the Flutter web build to
Azure Static Web Apps on `main` push; there is no manual deploy.

This skill assumes the feature is **already committed and pushed on `develop`**
(via `finish-feature`). It does not write new feature commits - it merges and
releases. Invoking this skill is the user's consent for the merge, push, and
resulting deploy it performs.

> **HARD RULE: stop immediately on ANY merge conflict or ANY failing step.** Do not
> work around a failure - report it with the failing output and wait for the user.

## Steps (in order)

1. **Pre-flight - develop must be clean and pushed.** `git checkout develop`;
   `git status --short`. If there are uncommitted changes, **STOP** - tell the user
   to run `finish-feature` first (this skill releases, it does not commit feature
   work). Then `git push origin develop` to be sure the trunk is up to date (should
   be a no-op if finish-feature already pushed).
2. **Confirm feature log.** Confirm the release has its row(s) in the root
   `README.md` feature log; if missing, that points to a skipped `finish-feature` -
   add the row, then prefer re-running `finish-feature`.
3. **Merge develop -> main.** `git checkout main`;
   `git pull --ff-only origin main`; `git merge --no-ff develop`.
   **Any conflict -> STOP immediately**, report the files, leave it for the user.
4. **Build main.** Run `flutter build web --release --dart-define=ENV=prod` on the
   merged `main` to confirm it compiles. Build breaks -> **STOP**.
5. **Push main (= deploy).** `git push origin main` -> triggers the CI deploy
   ([.github/workflows/azure-static-web-apps.yml](../../../.github/workflows/azure-static-web-apps.yml)).
   Report the commit and that the Action is running (the user can watch it). Do
   **not** run any manual `flutter build web` + SWA upload.
6. **Return to develop.** `git checkout develop` so further work continues on the trunk.

## Notes
- Review + analyze/build/test checks live in `finish-feature`. This skill trusts that
  develop is already green; it only adds a compile check on the merged `main`.
- If the merge conflicts or the `main` build breaks, the release does not proceed -
  fix on `develop`, re-run `finish-feature`, then re-run this skill.
- Never bypass a conflict or a red step to "get it out" - stopping is correct.
