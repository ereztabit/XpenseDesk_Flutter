---
name: start-feature
description: Use when starting a new feature or bug fix on this Flutter repo. Triggers - "new feature", "start a feature", "new bug", "begin work on X", "let's work on Y". Prepares the develop trunk (syncs main into it) and logs the work item in the root README. Does NOT commit.
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
4. **Log the work item** in the root `README.md` feature table: insert a new row
   directly under the header divider (newest first):
   `| <today YYYY-MM-DD> | <feature/bug name> | <description <= 200 chars> |`
   Ask the user for the name/description if they did not give one.
5. **Do NOT commit.** Leave the README edit (and the synced branch) in place - the
   feature is committed later by `ship-feature` (commits need explicit consent).
   Report: on `develop`, synced with `main`, README row added; ready to work.

## Notes
- All work happens on `develop`. The main->develop sync in step 3 is the only git
  write here and only runs because the user invoked this skill.
- Releasing is a separate, explicit step - the `ship-feature` skill.
