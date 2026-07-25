# in-progress/

Specs for what we are **actively working on right now** — nothing else.

**This folder is empty whenever no work is in flight.** That is the normal, healthy
state, not a mistake.

A spec arrives here from `../backlog/` when work starts (`start-feature`) and leaves
when the work resolves:

| Outcome | Where the spec goes |
|---------|--------------------|
| Shipped to production | `../completed/` (`ship-feature`) |
| Paused, dropped, or only partly built | back to `../backlog/` |

Never park a spec here for work nobody is doing, and never author a new spec
directly into `../completed/`. If you find a file here while
`docs/current-work.md` has no `## Currently Working On` section, one of the two is
wrong — reconcile them.

Bug reports do not use this folder; they live in `../bugs/` and move to
`../bugs/completed/` when closed.
