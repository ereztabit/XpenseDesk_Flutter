---
name: ship-feature
description: Use when finished work on develop is ready to release to production on this Flutter repo. Triggers - "ship it", "release this", "ready for deployment", "push to prod", "deploy". Merges develop -> main and pushes (CI deploys), then files the shipped docs. Assumes the work is already committed on develop (run finish-feature first). STOPS immediately on any conflict or failing step.
---

# Ship Feature (release to production)

Releases the work already banked on `develop` to production per
[docs/branching-and-release.md](../../../docs/branching-and-release.md). **Pushing
`main` is what deploys** - GitHub Actions auto-deploys the Flutter web build to
Azure Static Web Apps on `main` push; there is no manual deploy.

This skill assumes the feature is **already committed and pushed on `develop`**
(via `finish-feature`). It does not write new feature commits - it merges, releases,
and then files the shipped paperwork. Invoking this skill is the user's consent for
the merge, push, resulting deploy, and the docs-filing commit it performs.

> **HARD RULE: stop immediately on ANY merge conflict or ANY failing step.** Do not
> work around a failure - report it with the failing output and wait for the user.

## Steps (in order)

1. **Pre-flight - develop must be clean and pushed.** `git checkout develop`;
   `git status --short`. If there are uncommitted changes, **STOP** - tell the user
   to run `finish-feature` first (this skill releases, it does not commit feature
   work). Then `git push origin develop` to be sure the trunk is up to date (should
   be a no-op if finish-feature already pushed).
2. **Work out what is actually shipping, and tell the user.** Run
   `git log --oneline --no-merges origin/main..develop`. Several finished features
   can accumulate on the trunk, so this release may carry more than the one the user
   is thinking of. List it, and keep this list - step 6 needs it.
3. **Confirm feature log.** Confirm each shipping item has its row in the root
   `README.md` feature log with a real version (not `TBD`); a `TBD` or missing row
   points to a skipped `finish-feature` - prefer re-running that over patching by hand.
4. **Merge develop -> main.** `git checkout main`;
   `git pull --ff-only origin main`; `git merge --no-ff develop`.
   **Any conflict -> STOP immediately**, report the files, leave it for the user.
5. **Build main.** Run `flutter build web --release --dart-define=ENV=prod` on the
   merged `main` to confirm it compiles. Build breaks -> **STOP**.
6. **Push main (= deploy).** `git push origin main` -> triggers the CI deploy
   ([.github/workflows/azure-static-web-apps.yml](../../../.github/workflows/azure-static-web-apps.yml)).
   Report the commit and that the Action is running (the user can watch it). Do
   **not** run any manual `flutter build web` + SWA upload.
7. **File the shipped paperwork** - now that the code IS in production, on
   `develop` (`git checkout develop`), for each item from step 2:
   - **`docs/current-work.md`:** delete the item's line from `## Currently Working
     On` (the `banked on develop as vX.Y, awaiting ship-feature` marker
     `finish-feature` left). Delete the whole `## Currently Working On` section once
     nothing is left in it. Shipped work leaves **no** trace in this file - no `[x]`,
     no "done" section; the README row and `docs/completed/` are the record.
   - **Move the spec out of `docs/in-progress/`:**
     - Everything in the doc is now live -> `git mv docs/in-progress/<spec>.md
       docs/completed/<spec>.md` (same for its `-CR.md`, and for a whole feature
       folder). Use `git mv` so history follows the file.
     - **The doc also specs follow-ups that are NOT built -> `git mv` it to
       `docs/backlog/`**, not `completed/`, and update its status header to say
       which parts shipped and what is still open. Add the remaining piece as a
       backlog line in `current-work.md`. It does **not** stay in `in-progress/` -
       nothing we are not actively working on lives there.
     - Either way `docs/in-progress/` must end up empty (bar its `README.md`) once
       nothing is in flight.
   - **Repoint every inbound link to the moved paths.** Grep the whole repo for
     `in-progress/<name>` - references hide in `docs/README.md`, `CLAUDE.md`,
     `docs/v2/README.md`, `docs/pre-deployment-issues.md`, other specs, closed bug
     docs, and Dart doc comments in `lib/`. Also fix the moved file's own outbound
     relative links: a `../foo.md` inside a folder that moved from `in-progress/` to
     `completed/` now needs `../../in-progress/foo.md`.
   - **Bugs:** any shipped bug fix whose doc is still in `docs/bugs/` should be
     closed through the `bug` skill (Status `done` + Resolution, `git mv` to
     `docs/bugs/completed/`, line deleted from `current-work.md`).
   - **Verify:** grep for `in-progress/<moved-name>` and expect zero hits. Then
     check the invariants: `docs/in-progress/` holds nothing but its `README.md`
     (unless something else really is being worked on), `## Currently Working On`
     is gone from `current-work.md`, and every file in `docs/backlog/` maps to a
     live line in `current-work.md` (or, for post-MVP work, in `docs/v2/README.md`,
     which links out to specs rather than holding them). A spec no tracker mentions
     is either shipped (move it) or forgotten (raise it with the user).
8. **Commit + push the paperwork on develop.** Commit the doc moves and
   `current-work.md` cleanup (a docs-only commit - no version bump), then
   `git push origin develop`. `main` picks these docs up at the next release; docs
   are never deployed, so that lag is harmless.
9. **Return to develop and report.** Confirm: released commit on `main`, CI running,
   docs filed, `current-work.md` clean. Further work continues on the trunk.

## Notes
- Review + analyze/build/test checks live in `finish-feature`. This skill trusts that
  develop is already green; it only adds a compile check on the merged `main`.
- If the merge conflicts or the `main` build breaks, the release does not proceed -
  fix on `develop`, re-run `finish-feature`, then re-run this skill. Step 7 has not
  run at that point, so nothing is mislabelled as shipped.
- Never bypass a conflict or a red step to "get it out" - stopping is correct.
- Step 7 is what keeps the folders honest. Skipping it is how shipped specs end up
  stranded in `in-progress/` and how stale "awaiting ship-feature" lines accumulate
  in `current-work.md`. `docs/current-work.md` plus `docs/in-progress/` are meant to
  read as our current state of mind: if we are not working on it, it is a backlog
  feature or a bug, and it lives in `docs/backlog/` or `docs/bugs/`.
- Editing the docs: use the Edit/Write tools. Do **not** bulk-rewrite them with
  PowerShell `Set-Content`/`Out-File` - PowerShell 5.1 mangles their UTF-8 content
  (em dashes, box drawing, Hebrew) and adds a BOM.
