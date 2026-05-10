# Pi Update Review Instructions

You are running inside the local `pi-patches` repository.

Goal: review upstream Pi changes, verify this repo and its referenced patch sources, make any needed repo fixes, and then update the installed Pi instance when the checks show the update path is safe.

## Tasks

1. Read the upstream Pi coding-agent changelog:
   <https://github.com/earendil-works/pi-mono/blob/main/packages/coding-agent/CHANGELOG.md>
2. Inspect this repository, especially:
   - `patches.json`
   - `sources.json`
   - `apply.sh`
   - `test.sh`
   - `README.md`
   - any external patch manifests referenced by `sources.json`
3. Compare the current local patch set against the upstream changelog and, when needed, the installed/local upstream Pi package files.
4. Determine whether any patches are now redundant, obsolete, conflicting, incomplete, or need updates because upstream absorbed or changed the behavior.
5. Make the necessary repo changes so patch manifests, apply/test scripts, and docs are consistent and the final patched Pi build can be updated comfortably and reliably.
6. Verify all referenced inputs before drawing conclusions. At minimum:
   - run syntax/manifest checks for `patches.json`, `sources.json`, and every external manifest referenced by `sources.json`
   - confirm each referenced external manifest path exists and can be loaded
   - test patch applicability against the target/upstream Pi package shape when practical
   - run `apply.sh`/`test.sh` against the installed Pi package or an isolated install, depending on what is safest for the current state

## Operating rules

- Do not blindly run `npm install -g` or auto-update Pi before verification. First review the changelog, inspect manifests/scripts/docs, verify external manifests, and confirm patch applicability.
- If everything is verified, consistent, and the update path is safe, proceed with the explicit Pi update flow; do not stop just to ask for permission.
- Warn or ask before updating only when there is a real conflict, failed check, unavailable referenced source, destructive ambiguity, or another serious verified uncertainty.
- Prefer removing redundant patches over carrying stale patch debt.
- If a patch is still needed, make it precise and robust against the current upstream file shape.
- Do not speculate that external sources may be missing on other machines. Actually verify referenced external manifests in this working tree and report the observed result.
- If an external source manifest is unavailable or failing, report that clearly and update docs/tests only when justified.
- Keep README usage accurate: `pi-update` launches this review/update session; the actual install/update flow remains the separate explicit `upgrade.sh` command.

## Before finishing

Summarize:

- upstream version/changelog considered
- patches kept, removed, or changed
- tests run
- verified external manifest status
- remaining risks, limited to observed facts or serious verified ambiguities
- whether the real Pi update was performed; if not, the exact command to run afterward
