# Pi Update Migration Prompt

Safely migrate Stephen's launchable Pi installs to latest upstream `@earendil-works/pi-coding-agent`; keep patches, extensions, config, docs, and tests coherent. No shallow bumps.

1. Read upstream changelog first: <https://github.com/earendil-works/pi-mono/blob/main/packages/coding-agent/CHANGELOG.md>. Inspect upstream code/docs when changes overlap patches, extension APIs/loading, config, providers/models/thinking, sessions, tools, compaction, or TUI.
2. Inventory every launchable `pi`: `which -a`, symlinks/realpaths, package roots/versions, PATH/hash risks.
3. Inspect active state: settings/models/extension configs, `pi list`, this repo's scripts/manifests/docs, every `sources.json` manifest, and expected extensions from `pi-update-extensions.json`.
4. Audit extension repos discovered from active config, `pi list`, `sources.json`, and `pi-update-extensions.json`; report expected extensions that are missing locally or not installed.
5. Compare patches to upstream: delete absorbed patches; precisely update remaining manifest fields, references, and tests.
6. Before real mutation run `bash check.sh`; also run isolated latest-Pi apply/test when practical, and `bash check.sh --with-tests` when validating against the active install.
7. If safe, update/patch every relevant install. Stop only for real conflicts, failed checks, unavailable sources, destructive ambiguity, or serious verified uncertainty.
8. Verify versions, roots, patch markers, `pi list`, `test.sh`, and no stale exact Pi pins unless documented.

Final: upstream version, install roots/status, extension/config/package changes and missing extensions, patch changes, checks, manifest status, observed risks, and whether the real update ran; if not, give the exact command.
