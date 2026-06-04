---
name: bug
description: Manage bug reports in this Flutter repo - file a new bug, move it through its lifecycle, or finish (close) it. Use whenever the user says things like "file a bug", "open a bug", "add a bug", "log this bug", "start work on <bug>", "move <bug> to in progress", "we're done with <bug>", "the bug is done", or asks "what bugs are pending". Maintains docs/bugs/*.md, docs/bugs/completed/, and the pending list in docs/current-work.md.
---

# Bug workflow

This repo tracks bugs as markdown files plus a single pending list. Follow this
process exactly - it is the team standard.

## Where things live

- Active bug docs: `docs/bugs/<kebab-name>.md`
- Closed bug docs (archive / history): `docs/bugs/completed/<kebab-name>.md`
- Pending list (the single index): `docs/current-work.md`, under the heading
  `## report bugs (pending)`

## Status lifecycle

`new` -> `reviewed by me` -> `in progress` -> `done`

- `new` - just filed from the user's description; the user has not reviewed it yet.
- `reviewed by me` - the user has read and (usually) expanded it, but coding has
  not started.
- `in progress` - development is underway.
- `done` - developed AND verified; the user has explicitly said we are done.

## Hard rules

- "What bugs are pending?" -> read ONLY `docs/current-work.md`. Never scan the
  bugs folder to answer this.
- `docs/current-work.md` holds ONLY pending and in-progress bugs. When a bug is
  done, DELETE its line from that file - no `[x]` leftovers, no "done" section.
  History lives in `docs/bugs/completed/`.
- The bug doc is the source of truth for status; the `current-work.md` line is the
  index. Keep them in sync.
- Plain text only in all docs - no box-drawing characters or special unicode.
- Never `git add` / commit / push unless the user explicitly says so in the same
  turn. Filing or closing a bug is a docs edit, not a commit trigger.

## Operation A - File a new bug

Trigger: "file a bug", "open a bug", "add a bug", "log this bug", etc. The user
gives a brief explanation and maybe an image.

1. If essential reproduction detail is missing, ask the user. Otherwise write the
   full report yourself - do not make the user write it.
2. Create `docs/bugs/<kebab-name>.md` from the template below, with
   `Status: new`. Pick a descriptive kebab-case filename; make sure it does not
   already exist in `docs/bugs/` or `docs/bugs/completed/`.
3. Add one line to `## report bugs (pending)` in `docs/current-work.md`:
   `- [ ] <short summary> -- see docs/bugs/<name>.md`
4. Report what you filed. Do not commit unless asked.

## Operation B - Move through the lifecycle

- The user has reviewed / expanded the bug -> set the doc `Status` to
  `reviewed by me`.
- We start coding -> set `Status` to `in progress` in BOTH the doc and the
  `current-work.md` line (mark the line, e.g. prefix the summary with
  `(in progress)`), so the pending list shows what is actively being worked.

## Operation C - Finish (close) a bug

Trigger: the user says we are done (this only happens after development AND
verification).

1. In the doc, set `Status: done` and add or complete a `## Resolution` section:
   what shipped, key file references, and the relevant commit(s).
2. Move the file with history preserved:
   `git mv docs/bugs/<name>.md docs/bugs/completed/<name>.md`
3. Remove the bug's line from `docs/current-work.md` entirely.
4. Search for and fix any stale links that referenced the old
   `docs/bugs/<name>.md` path; repoint them at
   `docs/bugs/completed/<name>.md`.
5. Report. Do not commit unless asked.

## Bug doc template

```
# Bug: <Short Title>

> **Status: new**

## Problem

<What is wrong, from the user / business perspective.>

## Reproduce Steps

1. ...
2. ...
   -- Expected: ...
   -- Actual: ...

## Suggested Solution Approach

<Optional. The business-level intent of the fix.>

## Suggested Fix

<Technical approach with file references when known. If it needs investigation,
say so plainly rather than asserting an unverified fix.>
```

## Notes

- When a bug is closed it gains a `## Resolution` section; the open template does
  not include one.
- If the user reports several issues at once, prefer one focused doc per distinct
  bug unless they are clearly facets of a single issue.
