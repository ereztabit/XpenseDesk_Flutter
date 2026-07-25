---
name: start-feature
description: Use when starting a new feature or bug fix on this Flutter repo. Triggers - "new feature", "start a feature", "new bug", "begin work on X", "let's work on Y". Prepares the develop trunk (syncs main into it), promotes the item in docs/current-work.md, and logs it in the root README. Does NOT commit.
---

# Start Feature / Bug

Prepares a clean `develop` trunk to begin new work, per
[docs/branching-and-release.md](../../../docs/branching-and-release.md). Run the
steps yourself. **STOP and report if any step fails or hits a conflict** - never
improvise around it.

## Steps

1. **Working tree must be clean.** `git status --short`. If there are uncommitted
   changes, **STOP** and tell the user - they decide whether to ship/stash first
   (do not risk losing work).
2. **Switch to develop.** `git fetch origin`; `git checkout develop` (if absent
   locally: `git checkout -b develop origin/develop`); `git pull --ff-only origin develop`.
3. **Make develop fresh - main must be fully merged in.**
   - `git rev-list --count develop..origin/main`
   - If > 0, main has commits develop lacks -> `git merge --no-edit origin/main`.
   - **Any merge conflict -> STOP immediately** and report the conflicting files.
   - If 0, develop already has all of main - nothing to merge.
4. **Promote the item in `docs/current-work.md`.** That file is a pure backlog of
   open work with no history (see CLAUDE.md "Work Tracking").
   - Create a `## Currently Working On` section directly under the intro if it is
     not already there - it exists only while something is actually in progress.
   - **Move** the item's line out of its backlog section (`## TODO (Backlog)`,
     `## report bugs (pending)`, `## general environment`, ...) into that section,
     dropping the `[ ]` checkbox. Move it - do not copy it, or the item will be
     listed twice.
   - If the work is not yet in the backlog at all (a brand-new request), add it
     straight to `## Currently Working On`.
   - For a bug, ALSO set the bug doc's `Status` to `in progress` (the `bug` skill
     owns that doc's lifecycle).
5. **Move the spec doc into `docs/in-progress/`.** That folder means "being worked
   on right now" and is empty the rest of the time.
   - Spec already in `docs/backlog/` (the usual case):
     `git mv docs/backlog/<spec>.md docs/in-progress/<spec>.md` (also its `-CR.md`,
     or the whole feature folder). Use `git mv` so history follows the file.
   - Brand-new spec: author it directly in `docs/in-progress/`. Never author into
     `docs/completed/` — that folder means shipped.
   - **Repoint inbound links** to the moved path. Grep the repo for
     `backlog/<name>`; references hide in `docs/README.md`, `docs/current-work.md`,
     `docs/v2/README.md`, other specs, closed bug docs, and Dart doc comments in
     `lib/`. Fix the moved file's own `../` outbound links too if it is a folder.
   - No spec at all (small fix, or a bug with just a bug doc) — nothing to move.
6. **Log the work item** in the root `README.md` feature table: insert a new row
   directly under the header divider (newest first):
   `| <today YYYY-MM-DD> | TBD | <feature/bug name> | <description <= 200 chars> |`
   The Version is `TBD` here on purpose - `finish-feature` fills it in when the build
   is bumped. Ask the user for the name/description if they did not give one.
7. **Do NOT commit.** Leave the doc edits and the synced branch in place - the work
   is committed later by `finish-feature` (commits need explicit consent).
   Report: on `develop`, synced with `main`, promoted in `current-work.md`, README
   row added; ready to work.

## Notes
- All work happens on `develop`. The main->develop sync in step 3 is the only git
  write here and only runs because the user invoked this skill.
- `finish-feature` banks the work on `develop`; `ship-feature` releases it. Both
  are separate, explicit steps.
- Doc surfaces to keep in step: `docs/current-work.md` says what is open and what
  is being worked on, `docs/in-progress/` holds the spec while it is worked, the
  `README.md` row records the release.
- **If the work is later paused or dropped, reverse this skill's step 4 and 5** -
  move the item's line back to a backlog section and `git mv` the spec back to
  `docs/backlog/`. Nothing stays parked in `## Currently Working On` or
  `docs/in-progress/`.
- Editing the docs: use the Edit/Write tools. Do **not** rewrite them with
  PowerShell `Set-Content`/`Out-File` - PowerShell 5.1 mangles their UTF-8 content
  (em dashes, box drawing, Hebrew) and adds a BOM. `git mv` is safe.
