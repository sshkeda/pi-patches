# pi-patches

Small install-time patches for [pi](https://github.com/badlogic/pi-mono).

Today this repo owns local patches for:
- **extra OSC 8 hyperlink coverage** for gaps not yet upstreamed (update banner, inline code spans, and URL-only code-block lines)
- **bash timeout prompt clarity** so models see that the bash tool's `timeout` argument is in seconds, not milliseconds
- **bash output URL linkification** so bare URLs in rendered bash tool output remain clickable/copyable across terminal wraps
- **`/reload` current-session refresh** so reload reopens the session file it was invoked from before rebuilding chat
- **conflict-pruned patch manifests** that stay compatible with upstream `0.67.6+`, where base markdown OSC 8 links and wrap tracking are now built in

It also acts as a patch orchestrator for sibling repos. Right now it loads:
- **`../pi-read/patches/pi-patches.json`** — adds native `input_audio`, `video_url`, and `file` routing on Pi's OpenAI-compatible OpenRouter path
- **`../pi-claude-code/patches/pi-patches.json`** — exposes extension-runtime tool lookup hooks, supports extension tool-call short-circuit results, and lets provider bridges resolve pre-computed tool results directly

## Usage

### Review and update

`pi-update` launches an interactive review/update session. It starts by reviewing manifests, external sources, patch applicability, and tests; when those checks show the update path is safe, the session should proceed to the real Pi upgrade flow. It should stop instead only for a real conflict, failed check, unavailable referenced source, destructive ambiguity, or another serious verified uncertainty. In other words: launching `pi-update` is enough authorization to update once verification succeeds; it is not supposed to stop for another confirmation unless there is a good verified reason.

The prefilled prompt is short and points Pi at `UPDATE_INSTRUCTIONS.md`, which contains the full workflow. Press Enter/Return to send it when ready, or edit it first.

```bash
# Launch the dedicated Pi patch-review session
bash pi-update

# Existing aliases that point at update.sh still work; update.sh delegates here
bash update.sh
```

Defaults:

- model: `openai-codex/gpt-5.5`
- reasoning/thinking: `medium`
- changelog: <https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/CHANGELOG.md>

Configure defaults globally with an optional profile file:

```bash
mkdir -p ~/.pi/agent
cat > ~/.pi/agent/pi-update.env <<'EOF'
PI_UPDATE_MODEL=openai-codex/gpt-5.5
PI_UPDATE_THINKING=medium
EOF
```

Override from zsh or any shell when needed; explicit environment variables win over the profile file:

```bash
PI_UPDATE_MODEL='openai-codex/gpt-5.5' PI_UPDATE_THINKING=medium pi-update
```

Recommended alias in `~/.zshrc`:

```bash
alias pi-update='bash /Users/sshkeda/Documents/GitHub/pi-patches/pi-update'
```

The old alias still remains safe if you already have it:

```bash
alias pi-update='bash /Users/sshkeda/Documents/GitHub/pi-patches/update.sh'
```

### Explicit mutating upgrade command

`upgrade.sh` is the explicit mutating flow that the review/update session uses after checks pass. You can also run it manually:

```bash
bash upgrade.sh
```

That command asks for confirmation, then runs:

1. `npm install -g @mariozechner/pi-coding-agent@latest`
2. `bash apply.sh`
3. `bash test.sh`

Manual equivalent:

```bash
npm install -g @mariozechner/pi-coding-agent@latest
bash apply.sh
bash test.sh
```

> **Note:** Patches need to be re-applied after every real Pi update since `npm install -g` replaces node_modules.

## What it patches

| Patch | File | What |
|-------|------|------|
| 006 | `interactive-mode.js` | Make the update banner changelog URL clickable |
| 007 | `markdown.js` | Wrap URLs in inline code spans (`` `https://...` ``) |
| 008–009 | `markdown.js` | Wrap URL-only lines in code blocks (highlighted + plain) |
| 020 | `tools/bash.js` | Make the bash prompt snippet explicit that `timeout` is seconds (`timeout=120` for two minutes), not milliseconds |
| 021–022 | `tools/bash.js` | Wrap bare URLs in rendered bash tool output with OSC 8 hyperlinks |
| 030 | `agent-session.js` | Reopen the current session file during `/reload` before rebuilding chat |
| external (`pi-read` 016–018) | `openai-completions.js` via `../pi-read/patches/pi-patches.json` | Route OpenRouter audio/video/PDF through native `input_audio` / `video_url` / `file` chat-completions content blocks |
| external (`pi-claude-code` 010–019) | extension runtime/types and `pi-agent-core` via `../pi-claude-code/patches/pi-patches.json` | Expose extension tool lookup/runtime helpers, allow concrete cached tool-call results, and resolve provider-bridge pre-computed tool results |

> Upstream `0.67.6` absorbed former patches **001–005** by adding native markdown OSC 8 link rendering and hyperlink wrap tracking in `@mariozechner/pi-tui`.

## How it works

`pi-update` is the shell-friendly entrypoint for patch maintenance. It:

1. checks that `pi` is available on `PATH`
2. `cd`s into this repo
3. launches `pi --model "$PI_UPDATE_MODEL" --thinking "$PI_UPDATE_THINKING" --extension ./pi-update-prefill-extension.js`
4. the extension prefills the editor with a short prompt pointing at `UPDATE_INSTRUCTIONS.md`; it does not auto-submit
5. after you submit the prompt, the agent reviews the repo and upstream changes, then runs the real upgrade when verification is safe

`update.sh` is kept only for backwards compatibility with older aliases and delegates to `pi-update`.

`upgrade.sh` is the explicit mutating updater used by the review session when the path is safe. It confirms first, then reinstalls Pi globally, runs `apply.sh`, and runs `test.sh`. In an agent-run session after safe verification, the confirmation can be supplied explicitly (for example, `printf 'y\n' | bash upgrade.sh`).

`patches.json` defines local patches that live in this repo. `sources.json` points at additional patch manifests owned by sibling repos (currently `../pi-read/patches/pi-patches.json` and `../pi-claude-code/patches/pi-patches.json`). `apply.sh` loads all of them, locates pi's install directory, applies everything atomically (no files written if any patch fails), and `test.sh` validates the upstream OSC 8 baseline, the remaining local hyperlink/runtime/reload patches, extension-runtime/tool-call behavior, and OpenRouter multimodal routing behavior.

Patch entries may include a `references` array. Keep it updated when adding, changing, or deleting a patch:

- `upstream-package` points at the original Pi package/source area to inspect when Pi updates.
- `consumer-repo` points at local repos that rely on the patched behavior and may need cleanup when the patch is upstreamed or removed.
- `memory-note` points at durable notes that explain why the patch exists.
