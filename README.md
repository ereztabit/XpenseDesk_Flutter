# xpensedesk_flutter

XpenseDesk - an AI-powered expense approval tool for small businesses (Flutter web).

## Branching & release

Work flows `develop` (trunk) -> `main` (release/deploy). Pushing `main` deploys to
Azure Static Web Apps via CI. See [docs/branching-and-release.md](docs/branching-and-release.md).

## Feature log

Newest first. One row per feature. The row is inserted at `start-feature` (Version
`TBD`); the version is filled in at `finish-feature` when the build is bumped.

| Date | Version | Feature | Description |
|------|---------|---------|-------------|
| 2026-06-21 | v1.6 | Branching & release method | Adopt develop/main trunk-and-release flow with start-feature / finish-feature / ship-feature skills; block search-engine indexing for the private app. |
