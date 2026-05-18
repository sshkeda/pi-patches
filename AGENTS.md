Follow these repo rules in order. If rules conflict, the earlier rule wins.

1. Treat `patches.json`, `sources.json`, and sibling manifests as the patch source of truth; do not hand-edit installed Pi package files except through this repo's scripts.
2. Keep patch entries precise: `find`, `replace`, `verify`, and `occurrences` must match the current upstream file shape, and `references` must explain why the patch still exists.
3. Prefer deleting patches absorbed by upstream over carrying stale patch debt; update `test.sh` and README patch tables whenever patches or external sources change.
4. Run `bash check.sh` after editing manifests, source-data JSON, shell scripts, JavaScript helpers, update docs, or this policy file.
5. Use `bash check.sh --with-tests` only when validating against the currently installed Pi package; use `bash apply.sh` or `bash upgrade.sh` only when intentionally mutating an active Pi install.
6. Use `./pi-update` for upstream review sessions; its prompt lives in `PI_UPDATE_PROMPT.md` and its expected-extension baseline lives in `pi-update-extensions.json`.
