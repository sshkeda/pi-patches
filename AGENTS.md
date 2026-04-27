# pi-patches Agent Instructions

This repo maintains local install-time patches for the globally installed `@mariozechner/pi-coding-agent` package and orchestrates additional patch manifests from sibling repos.

## Project overview

Key files:

- `patches.json` — local patch manifest owned by this repo.
- `sources.json` — external patch manifests loaded from sibling repos.
- `apply.sh` — applies local and external manifests atomically to the active Pi install.
- `test.sh` — verifies the patched Pi install behavior.
- `pi-update` — launches an interactive review/update session for Pi maintenance.
- `UPDATE_INSTRUCTIONS.md` — detailed workflow for `pi-update` review/update sessions only.
- `upgrade.sh` — explicit mutating updater: reinstall Pi globally, apply patches, run tests.
- `update.sh` — backwards-compatible wrapper that delegates to `pi-update`.

## General maintenance rules

- Keep `README.md`, scripts, manifests, and this file semantically coherent whenever behavior changes.
- Keep patch entries precise: `find`, `replace`, `verify`, and `occurrences` should match the current target file shape.
- Keep patch `references` metadata current for upstream packages, consumer repos, and memory notes.
- Prefer deleting redundant patches over carrying stale patch debt.
- When editing manifests, validate JSON before finishing.
- When editing shell scripts, run `bash -n` on changed scripts before finishing.
- When editing JavaScript helper files, run `node --check` before finishing.
- Do not run mutating global-install commands casually; use the Pi update workflow below when the task is actually to update Pi.

## Pi update workflow

Use this workflow when the user asks to run/review `pi-update`, update Pi, review upstream Pi changes, or prepare this repo for a Pi upgrade.

1. Read `UPDATE_INSTRUCTIONS.md` and follow it for the detailed review/update process.
2. Review the upstream Pi changelog at `https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/CHANGELOG.md`.
3. Inspect at least `patches.json`, `sources.json`, `apply.sh`, `test.sh`, `README.md`, and every external manifest referenced by `sources.json`.
4. Verify JSON/shell syntax and external manifest availability before drawing conclusions.
5. Test patch applicability against the current/latest upstream Pi package shape when practical, preferably in an isolated global-prefix install before touching the active install.
6. If verification shows the update path is safe, proceed with the real Pi upgrade flow. Do **not** stop just because the user did not separately re-confirm after launching `pi-update`.
7. Stop and ask/report instead only for a real conflict, failed check, unavailable referenced source, destructive ambiguity, or another serious verified uncertainty.

## Command semantics

- `pi-update` is a review/update session launcher. It should lead to the real upgrade when checks are safe.
- `upgrade.sh` is the mutating updater. It reinstalls Pi globally, runs `apply.sh`, and then runs `test.sh`.
- `update.sh` is only a backwards-compatible wrapper that delegates to `pi-update`.

If running `upgrade.sh` non-interactively from an agent after safe verification, it is acceptable to provide the script confirmation explicitly, for example:

```bash
printf 'y\n' | bash upgrade.sh
```

## Final response checklist for Pi update sessions

When completing a Pi update/review session, summarize:

- upstream version/changelog considered
- patches kept, removed, or changed
- tests/checks run
- external manifest status
- remaining observed risks
- whether the real Pi update was performed, and if not, the exact command to run
