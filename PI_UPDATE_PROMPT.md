# Pi Update Migration Prompt

Safely migrate Stephen's launchable Pi installs to latest upstream `@earendil-works/pi-coding-agent`; keep patches, extensions, config, docs, and tests coherent. No shallow bumps.

1. Read upstream changelog first: <https://github.com/earendil-works/pi-mono/blob/main/packages/coding-agent/CHANGELOG.md>. Inspect upstream code/docs when changes overlap patches, extension APIs/loading, config, providers/models/thinking, sessions, tools, compaction, or TUI.
2. Inventory every launchable `pi`: `which -a`, symlinks/realpaths, package roots/versions, PATH/hash risks.
3. Inspect active state: settings/models/extension configs, `pi list`, this repo's scripts/manifests/docs, every `sources.json` manifest, and expected extensions from `pi-update-extensions.json`.
4. Audit extension repos discovered from active config, `pi list`, `sources.json`, and `pi-update-extensions.json`; report expected extensions that are missing locally or not installed.
5. For every locally available expected extension, run its declared check/test script when present, and run at least one real Pi load smoke against the active install. Package/direct extension smoke must include non-interactive print mode with `-e <extension-or-package-root> -p` to catch startup, shutdown, stale-ctx, and delayed timer failures. For UI/TUI extensions, also run or add a pi-mock interactive smoke that exercises the user-visible behavior.
6. Compare patches to upstream: delete absorbed patches; precisely update remaining manifest fields, references, and tests.
7. Before real mutation run `bash check.sh`; also run isolated latest-Pi apply/test when practical, and `bash check.sh --with-tests` when validating against the active install.
8. If safe, update/patch every relevant install. Stop only for real conflicts, failed checks, unavailable sources, destructive ambiguity, or serious verified uncertainty.
9. Verify versions, roots, patch markers, `pi list`, `test.sh`, and extension smoke results. Run all extension test suites (`npm test` or `test.sh`) again against the patched new Pi version to verify no regressions. If regressions are found, actively debug and repair the broken tests or extension logic before declaring the update complete. Ensure no stale exact Pi pins remain unless documented.

Final: upstream version, install roots/status, extension/config/package changes and missing extensions, patch changes, checks, per-extension smoke status, manifest status, observed risks, and whether the real update ran; if not, give the exact command.
