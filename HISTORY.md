# pi-patches history

Chronological record of every patch this repo has ever owned, including patches
that have been removed or migrated elsewhere. The intent is to make patch
churn auditable when reading old commits or chasing upstream behaviour changes.

## Currently active patches

These live in [`patches.json`](./patches.json) today.

| ID | File | Added | Commit |
|---|---|---|---|
| 007 | `markdown.js` codespan URLs | 2026-04-07 | [`76441ee`](https://github.com/sshkeda/pi-patches/commit/76441ee) |
| 008 | `markdown.js` codeblock highlighted-line URLs | 2026-04-07 (re-added same day) | [`a69d390`](https://github.com/sshkeda/pi-patches/commit/a69d390) |
| 009 | `markdown.js` codeblock plain-line URLs | 2026-04-07 (re-added same day) | [`a69d390`](https://github.com/sshkeda/pi-patches/commit/a69d390) |
| 020 | `tools/bash.js` timeout-in-seconds prompt snippet | 2026-04-28 | [`312e1f1`](https://github.com/sshkeda/pi-patches/commit/312e1f1) |
| 021 | `tools/bash.js` linkify helper | 2026-05-01 | [`0fbb2a8`](https://github.com/sshkeda/pi-patches/commit/0fbb2a8) |
| 022 | `tools/bash.js` linkify call site | 2026-05-01 | [`0fbb2a8`](https://github.com/sshkeda/pi-patches/commit/0fbb2a8) |
| 030 | `agent-session.js` `/reload` reopens current session file | 2026-05-05 | [`22affb8`](https://github.com/sshkeda/pi-patches/commit/22affb8) |
| 031 | `markdown.js` LaTeX-to-Unicode helper | 2026-05-10 | [`285a19d`](https://github.com/sshkeda/pi-patches/commit/285a19d) |
| 032 | `markdown.js` LaTeX-to-Unicode render preprocessor | 2026-05-10 | [`285a19d`](https://github.com/sshkeda/pi-patches/commit/285a19d) |
| 033 | `markdown.js` LaTeX-to-Unicode call site | 2026-05-10 | [`285a19d`](https://github.com/sshkeda/pi-patches/commit/285a19d) |
| 051 | `agent-session.js` parent tool-results to matching tool-call before persist | 2026-05-17 | [`b70591a`](https://github.com/sshkeda/pi-patches/commit/b70591a) |

## Retired patches

### Absorbed by upstream `earendil-works/pi-mono`

| IDs | What | Removed | Upstream version | Removal commit |
|---|---|---|---|---|
| 001–005 | OSC 8 markdown link rendering + hyperlink wrap tracking in Pi TUI | 2026-04-16 | `0.67.6` (now `@earendil-works/pi-tui`) | [`5d433ba`](https://github.com/sshkeda/pi-patches/commit/5d433ba) |
| 006 | OSC 8 update banner in interactive notification | 2026-05-17 | `0.74.1` | [`b70591a`](https://github.com/sshkeda/pi-patches/commit/b70591a) |

These patches were added in the [initial commit `76441ee`](https://github.com/sshkeda/pi-patches/commit/76441ee) and lived in `patches.json` until upstream Pi shipped equivalent behaviour. When that happens, the patch is deleted from `patches.json` rather than carried as dead code.

### Migrated to sibling repos

| IDs | What | Removed | Migrated to | Removal commit |
|---|---|---|---|---|
| 010–019 | extension runtime / tool lookup hooks (provider-bridge support) | 2026-05-03 | [`pi-claude-code/patches/pi-patches.json`](https://github.com/sshkeda/pi-claude-code/blob/main/patches/pi-patches.json) | [`6ec028b`](https://github.com/sshkeda/pi-patches/commit/6ec028b) |

The 010–019 series was originally added in commits [`f60cc09`](https://github.com/sshkeda/pi-patches/commit/f60cc09) (010–015), [`32e04ee`](https://github.com/sshkeda/pi-patches/commit/32e04ee) (016–018), and [`a41f6d9`](https://github.com/sshkeda/pi-patches/commit/a41f6d9) (019). They were scoped specifically to the pi-claude-code provider bridge, so ownership moved to the [`pi-claude-code`](https://github.com/sshkeda/pi-claude-code) repo where the provider lives. pi-patches still loads them at apply time via `sources.json`.

### Briefly removed and restored

| IDs | What happened |
|---|---|
| 008–009 | Removed 2026-04-07 in [`1f31e69`](https://github.com/sshkeda/pi-patches/commit/1f31e69) ("Remove code block URL patches, add re-apply note"), then immediately reverted in [`a69d390`](https://github.com/sshkeda/pi-patches/commit/a69d390) the same day. Still active today. |

## Patches owned by sibling repos

These were never in pi-patches' own `patches.json`; pi-patches loads them via [`sources.json`](./sources.json). Listed here for completeness so the full live patch set is in one place.

| Sibling repo | Patches | First commit |
|---|---|---|
| [`pi-read`](https://github.com/sshkeda/pi-read) | OpenRouter native `input_audio` / `video_url` / `file` routing for multimodal Gemini reads | "own OpenRouter multimodal patch manifest…" |
| [`pi-script`](https://github.com/sshkeda/pi-script) | AgentSession-backed full tool-definition lookup for single-tool SDK mode | "Build Pi Script prototype" |
| [`pi-lane`](https://github.com/sshkeda/pi-lane) | Agent state refresh after input hooks for lane/session branching | "Build pi-lane session coordination" |
| [`pi-autocompact`](https://github.com/sshkeda/pi-autocompact) | Slide native compaction cut point so summarizer fits the model context window | "Add budgeted autocompaction patch" |
| [`pi-sessions`](https://github.com/sshkeda/pi-sessions) | Short base64url session IDs and bare `--session <id>` resolution | "Initial commit: Pi session ID ergonomics patches" |
| [`pi-sync`](https://github.com/sshkeda/pi-sync) | `replayAgentEvent` for synced terminals replaying native UI events | "Initial commit: cross-terminal Pi session mirroring" |

## How to read this file

- **Active** patches should match what `bash check.sh` validates today.
- **Retired** patches are recoverable from git history if upstream regresses; check the listed commit and revert the deletion as a starting point.
- **References** inside each patch entry in `patches.json` (`upstream-package`, `consumer-repo`, `memory-note`) explain why the patch exists; they are kept up to date even after migrations.
