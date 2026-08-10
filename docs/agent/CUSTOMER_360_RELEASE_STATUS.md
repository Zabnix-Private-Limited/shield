# Customer 360 release status

## Current state

The implemented Agent Customer 360 slice is ready for targeted internal QA. It reuses current schema-backed tables and therefore requires no SQL or migration.

Focused evidence recorded on 2026-08-10:

- Nest authorization/scope regression suites: 11 passed.
- Customer 360 responsive widget matrix: 8 passed at 768, 1024, 1280, 1366, 1440, 1600, 1920, and 960 logical pixels.
- Flutter root smoke compilation has passed for the routed portal shell.

## Open acceptance evidence

- Authenticated browser checks for allowed and denied principals.
- Responsive visual checks at the documented desktop widths.
- Full-suite execution where the Windows runner is stable.

These are release-evidence gates, not permission to bypass the existing agent scope.
