# pi-patches

Small install-time patches for [pi](https://github.com/earendil-works/pi-mono).

## Upstream track record

Six patches shipped from this repo on **2026-04-07** were later absorbed into upstream `pi-mono`:

- patches **001–005** (OSC 8 markdown link rendering + hyperlink wrap tracking) → absorbed in **`pi-mono 0.67.6`** on **2026-04-16**, 9 days after they shipped here.
- patch **006** (OSC 8 update-notification banner) → absorbed in **`pi-mono 0.74.1`** on **2026-05-17**, 40 days after it shipped here.

The full per-patch history — active, retired, migrated — is in the [Patch history](#patch-history) section below.

## What ships today

This repo currently owns local patches for:
- **extra OSC 8 hyperlink coverage** for gaps not yet upstreamed (inline code spans and URL-only code-block lines)
- **bash timeout prompt clarity** so models see that the bash tool's `timeout` argument is in seconds, not milliseconds
- **bash output URL linkification** so bare URLs in rendered bash tool output remain clickable/copyable across terminal wraps
- **terminal LaTeX math Unicode rendering** so `$...$`, `$$...$$`, `\\(...\\)`, and `\\[...\\]` display as readable Unicode instead of raw TeX
- **`/reload` current-session refresh** so reload reopens the session file it was invoked from before rebuilding chat
- **tool-result parenting** so tool-result messages persist below the assistant message that emitted their tool call, even when extension hooks branch the session leaf
- **native compaction reliability** so the summarizer prompt fits the model context window even when `messagesToSummarize` would overflow, with threshold continuation between tool-use calls

It also acts as a patch orchestrator for sibling repos. Right now it loads:
- **`../pi-read/patches/pi-patches.json`** — adds native `input_audio`, `video_url`, and `file` routing on Pi's OpenAI-compatible OpenRouter path
- **`../pi-script/patches/pi-patches.json`** — preserves AgentSession-backed full tool-definition lookup for Pi Script's hidden-tool SDK delegation
- **`../pi-sync/patches/pi-patches.json`** — refreshes agent state after input hooks and exposes native UI event replay hooks for synced Pi terminals

## Usage

### Review and update

`pi-update` launches an interactive review/update session. It starts by reviewing manifests, external sources, patch applicability, and tests; when those checks show the update path is safe, the session should proceed to the real Pi upgrade flow. It should stop instead only for a real conflict, failed check, unavailable referenced source, destructive ambiguity, or another serious verified uncertainty. In other words: launching `pi-update` is enough authorization to update once verification succeeds; it is not supposed to stop for another confirmation unless there is a good verified reason.

The prefilled prompt lives in `PI_UPDATE_PROMPT.md`, with expected extension baseline data in `pi-update-extensions.json`. It requires auditing all launchable Pi installs, active config, discovered/expected extensions, patches, package pins, and tests before performing the real update when safe. Press Enter/Return to send it when ready, or edit it first.

```bash
# Launch the dedicated Pi patch-review session
bash pi-update

# Existing aliases that point at update.sh still work; update.sh delegates here
bash update.sh
```

Defaults:

- model: `pi-codex/gpt-5.5-fast`
- reasoning/thinking: `medium`
- prompt file: `PI_UPDATE_PROMPT.md`
- changelog: <https://github.com/earendil-works/pi-mono/blob/main/packages/coding-agent/CHANGELOG.md>

Configure defaults globally with an optional profile file:

```bash
mkdir -p ~/.pi/agent
cat > ~/.pi/agent/pi-update.env <<'EOF'
PI_UPDATE_MODEL=pi-codex/gpt-5.5-fast
PI_UPDATE_THINKING=medium
EOF
```

Override from zsh or any shell when needed; explicit environment variables win over the profile file:

```bash
PI_UPDATE_MODEL='pi-codex/gpt-5.5-fast' PI_UPDATE_THINKING=medium pi-update
PI_UPDATE_PROMPT_FILE=/path/to/custom-prompt.md pi-update
```

Recommended alias in `~/.zshrc` (point at wherever you cloned this repo):

```bash
alias pi-update='bash "$HOME/path/to/pi-patches/pi-update"'
```

The old alias still remains safe if you already have it:

```bash
alias pi-update='bash "$HOME/path/to/pi-patches/update.sh"'
```

### Explicit mutating upgrade command

`upgrade.sh` is the explicit mutating flow that the review/update session uses after checks pass. You can also run it manually:

```bash
bash upgrade.sh
```

That command asks for confirmation, then runs:

1. `npm install -g --force @earendil-works/pi-coding-agent@latest`
2. `bash apply.sh`
3. `bash test.sh`

Manual equivalent:

```bash
npm install -g --force @earendil-works/pi-coding-agent@latest
bash apply.sh
bash test.sh
```

Non-mutating repo checks:

```bash
bash check.sh
bash check.sh --with-tests  # also runs bash test.sh against the active Pi install
```

> **Note:** Patches need to be re-applied after every real Pi update since `npm install -g` replaces node_modules.

### Pre-commit hook (lefthook)

`lefthook.yml` wires `bash check.sh` into a pre-commit hook so manifest/JSON/shell/JS syntax issues are caught before they land. Install lefthook once, then enable the hook in your local clone:

```bash
brew install lefthook
lefthook install
```

## Patch history

Chronological record of every patch this repo has ever owned — active, retired, and migrated. Each row links to the commit that added or removed the patch so churn stays auditable when reading old commits or chasing upstream behaviour changes.

### Active patches

These live in [`patches.json`](./patches.json) today and are validated by `bash check.sh`. Grouped by feature.

#### OSC 8 hyperlinks in markdown

| ID | File | What it does | Added | Commit |
|---|---|---|---|---|
| 007 | `markdown.js` | Wrap URLs inside inline code spans (`` `https://...` ``) | 2026-04-07 | [`76441ee`](https://github.com/sshkeda/pi-patches/commit/76441ee) |
| 008 | `markdown.js` | Wrap URL-only highlighted code-block lines | 2026-04-07 (re-added same day) | [`a69d390`](https://github.com/sshkeda/pi-patches/commit/a69d390) |
| 009 | `markdown.js` | Wrap URL-only plain code-block lines | 2026-04-07 (re-added same day) | [`a69d390`](https://github.com/sshkeda/pi-patches/commit/a69d390) |

#### Bash tool

| ID | File | What it does | Added | Commit |
|---|---|---|---|---|
| 020 | `tools/bash.js` | Make the bash prompt snippet explicit that `timeout` is seconds (`timeout=120` for two minutes), not milliseconds | 2026-04-28 | [`312e1f1`](https://github.com/sshkeda/pi-patches/commit/312e1f1) |
| 021 | `tools/bash.js` | `linkifyBareUrls` helper | 2026-05-01 | [`0fbb2a8`](https://github.com/sshkeda/pi-patches/commit/0fbb2a8) |
| 022 | `tools/bash.js` | Apply linkify in rendered bash tool output | 2026-05-01 | [`0fbb2a8`](https://github.com/sshkeda/pi-patches/commit/0fbb2a8) |

#### Session reload

| ID | File | What it does | Added | Commit |
|---|---|---|---|---|
| 030 | `agent-session.js` | `/reload` reopens current session file before rebuilding chat | 2026-05-05 | [`22affb8`](https://github.com/sshkeda/pi-patches/commit/22affb8) |

#### LaTeX math in markdown

| ID | File | What it does | Added | Commit |
|---|---|---|---|---|
| 031 | `markdown.js` | LaTeX-to-Unicode preprocessor helper | 2026-05-10 | [`285a19d`](https://github.com/sshkeda/pi-patches/commit/285a19d) |
| 032 | `markdown.js` | LaTeX-to-Unicode render via `unicodeit` | 2026-05-10 | [`285a19d`](https://github.com/sshkeda/pi-patches/commit/285a19d) |
| 033 | `markdown.js` | LaTeX-to-Unicode call site | 2026-05-10 | [`285a19d`](https://github.com/sshkeda/pi-patches/commit/285a19d) |

#### Tool-result parenting

| ID | File | What it does | Added | Commit |
|---|---|---|---|---|
| 051 | `agent-session.js` | Parent tool-results to matching tool-call before persist | 2026-05-17 | [`b70591a`](https://github.com/sshkeda/pi-patches/commit/b70591a) |

#### Native compaction reliability

Originally a sibling [`pi-autocompact`](https://github.com/sshkeda/pi-autocompact) repo, [merged into pi-patches](https://github.com/sshkeda/pi-patches) on 2026-05-18. Keeps Pi's native compaction prompts intact but stops the summariser request from exceeding the model context window, and lets the agent stop between tool-use calls when compaction is needed.

| IDs | File | What it does | Added | Commit |
|---|---|---|---|---|
| 100–102 | `dist/core/compaction/compaction.js` | Summary budget helpers, track per-message entry IDs, slide cut point so the summariser prompt always fits | 2026-05-11 | [`6591fa1`](https://github.com/sshkeda/pi-autocompact/commit/6591fa1) |
| 103–105 | `pi-agent-core/dist/agent.js` + `.d.ts` | Forward `shouldStopAfterTurn` agent-loop option and typings (`106` absorbed upstream in 0.75.4) | 2026-05-11 | [`df3a2cf`](https://github.com/sshkeda/pi-autocompact/commit/df3a2cf) |
| 107–115 | `agent-session.js`, `sdk.js` | Threshold-continuation wiring so the agent stops between tool-use calls before context overflow | 2026-05-11 | [`df3a2cf`](https://github.com/sshkeda/pi-autocompact/commit/df3a2cf) |

### Retired — absorbed by upstream `pi-mono`

| IDs | What | Removed | Upstream version | Removal commit |
|---|---|---|---|---|
| 001–005 | OSC 8 markdown link rendering + hyperlink wrap tracking in Pi TUI | 2026-04-16 | `0.67.6` (now `@earendil-works/pi-tui`) | [`5d433ba`](https://github.com/sshkeda/pi-patches/commit/5d433ba) |
| 006 | OSC 8 update banner in interactive notification | 2026-05-17 | `0.74.1` | [`b70591a`](https://github.com/sshkeda/pi-patches/commit/b70591a) |

These patches were added in the [initial commit `76441ee`](https://github.com/sshkeda/pi-patches/commit/76441ee) and lived in `patches.json` until upstream Pi shipped equivalent behaviour. When that happens, the patch is deleted rather than carried as dead code.

### Retired — migrated to sibling repos

| IDs | What | Removed | Migrated to | Removal commit |
|---|---|---|---|---|
### Briefly removed and restored

| IDs | What happened |
|---|---|
| 008–009 | Removed 2026-04-07 in [`1f31e69`](https://github.com/sshkeda/pi-patches/commit/1f31e69) ("Remove code block URL patches, add re-apply note"), then immediately reverted in [`a69d390`](https://github.com/sshkeda/pi-patches/commit/a69d390) the same day. Still active today. |

### Sibling-owned patches loaded at apply time

These never lived in `patches.json` directly; pi-patches loads them via [`sources.json`](./sources.json). Listed here so the full live patch set is in one place.

| Sibling repo | What | Manifest |
|---|---|---|
| [`pi-read`](https://github.com/sshkeda/pi-read) | OpenRouter native `input_audio` / `video_url` / `file` routing for multimodal Gemini reads | `../pi-read/patches/pi-patches.json` |
| [`pi-script`](https://github.com/sshkeda/pi-script) | AgentSession-backed full tool-definition lookup for single-tool SDK mode | `../pi-script/patches/pi-patches.json` |
| [`pi-lane`](https://github.com/sshkeda/pi-lane) | Agent state refresh after input hooks for lane/session branching | `../pi-lane/patches/pi-patches.json` |
| [`pi-sessions`](https://github.com/sshkeda/pi-sessions) | Short base64url session IDs and bare `--session <id>` resolution | `../pi-sessions/patches/pi-patches.json` |
| [`pi-sync`](https://github.com/sshkeda/pi-sync) | `replayAgentEvent` for synced terminals replaying native UI events | `../pi-sync/patches/pi-patches.json` |

## How it works

`pi-update` is the shell-friendly entrypoint for patch maintenance. It:

1. checks that `pi` is available on `PATH`
2. `cd`s into this repo
3. reads the full prefilled prompt from `PI_UPDATE_PROMPT.md` (or `$PI_UPDATE_PROMPT_FILE`)
4. launches `pi --model "$PI_UPDATE_MODEL" --thinking "$PI_UPDATE_THINKING" --extension ./pi-update-prefill-extension.js`
5. the extension prefills the editor with that full Markdown prompt; it does not auto-submit
6. after you submit the prompt, the agent reviews the repo and upstream changes, then runs the real upgrade when verification is safe

`update.sh` is kept only for backwards compatibility with older aliases and delegates to `pi-update`.

`upgrade.sh` is the explicit mutating updater used by the review session when the path is safe. It confirms first, then reinstalls Pi globally, runs `apply.sh`, and runs `test.sh`. In an agent-harness session after safe verification, the confirmation can be supplied explicitly (for example, `printf 'y\n' | bash upgrade.sh`).

`patches.json` defines local patches that live in this repo. `sources.json` points at additional patch manifests owned by sibling repos; `pi-update-extensions.json` is the expected-extension baseline used during update audits. `check.sh` validates local manifests/source data, external manifest availability, shell syntax, and JavaScript helper syntax without mutating the Pi install. `apply.sh` loads all patch manifests, locates pi's `@earendil-works/pi-coding-agent` install, applies everything atomically (no files written if any patch fails), and `test.sh` validates the upstream OSC 8 baseline, local hyperlink/runtime/reload/session patches, extension-runtime/tool-call behavior, OpenRouter multimodal routing behavior, and the autocompact patches' behavior via pi-mock.

Patch entries may include a `references` array. Keep it updated when adding, changing, or deleting a patch:

- `upstream-package` points at the original Pi package/source area to inspect when Pi updates.
- `consumer-repo` points at local repos that rely on the patched behavior and may need cleanup when the patch is upstreamed or removed.
- `memory-note` points at durable notes that explain why the patch exists.
