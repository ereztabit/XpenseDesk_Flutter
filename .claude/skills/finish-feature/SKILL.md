---
name: finish-feature
description: Use when a feature/bug on develop is done and ready to bank on the trunk - but NOT to release. Triggers - "finish the feature", "finish this", "wrap it up", "done with this", "commit to develop". Runs review + checks, then commits and pushes develop. Does NOT merge to main and does NOT deploy.
---

# Finish Feature (bank on develop - no release)

Finalizes the current work on the `develop` trunk per
[docs/branching-and-release.md](../../../docs/branching-and-release.md). This is
**not** a release: it commits and pushes `develop` only. It never merges to `main`
and never deploys. Releasing is a separate, explicit step (`ship-feature`).

Invoking this skill is the user's consent for the commit + push to `develop` it
performs.

> **HARD RULE: stop immediately on ANY failing step.** Do not work around a failure -
> report it with the failing output and wait for the user.

## Steps (in order)

1. **Be on develop.** `git checkout develop`. All work commits here - never `main`.
2. **Feature log.** Confirm the feature has a row in the root `README.md` feature
   log; if missing, add it (`Date | Feature | Description <= 200`).
3. **Code review + security review.** Run the `code-review` skill and the
   `security-review` skill on the diff (`git diff origin/main` - covers
   committed-on-develop + working-tree changes). Report findings. A real blocking
   issue (correctness bug / security vuln) -> **STOP** and surface it.
4. **Checks green.** Run `flutter analyze` (must be clean) and
   `flutter build web --release --dart-define=ENV=prod` (must compile). If a `test/`
   suite exists, run `flutter test` too. **Any failure -> STOP.**
5. **Commit + push develop.** Stage the changes, commit with a clear message,
   `git push origin develop`.
6. **Done - report and STOP.** State clearly: committed + pushed on `develop`, **not
   released**. The work is banked on the trunk; deploy later with `ship-feature`.

## Notes
- This skill deliberately stops at `develop`. It does NOT merge to `main` and does
  NOT trigger CI - so nothing deploys.
- Several finished features can accumulate on `develop` and be released together in
  one `ship-feature` run.
