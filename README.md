# pi-patches

Small install-time patches for [pi](https://github.com/badlogic/pi-mono).

Today this repo patches three things directly:
- **extra OSC 8 hyperlink coverage** for gaps not yet upstreamed (update banner, inline code spans, and URL-only code-block lines)
- **extension-runtime tool lookup hooks** (`getToolDefinition`, `getAllRegisteredTools`) for native custom-tool integration
- **conflict-pruned patch manifests** that stay compatible with upstream `0.67.6+`, where base markdown OSC 8 links and wrap tracking are now built in

It also acts as a patch orchestrator for sibling repos. Right now it loads the OpenRouter multimodal transport patch from:
- **`../pi-read/patches/pi-patches.json`** — adds native `input_audio`, `video_url`, and `file` routing on Pi's OpenAI-compatible OpenRouter path

## Usage

```bash
# One-shot update: reinstall pi globally, re-apply patches, then verify them
bash update.sh

# Or do the steps manually
npm install -g @mariozechner/pi-coding-agent
bash apply.sh
bash test.sh
```

If you add this alias to `~/.zshrc`:

```bash
alias pi-update='bash /Users/sshkeda/Documents/GitHub/pi-patches/update.sh'
```

then `pi-update` runs the same one-shot flow from any directory.

> **Note:** Patches need to be re-applied after every pi update since `npm install -g` replaces node_modules.

## What it patches

| Patch | File | What |
|-------|------|------|
| 006 | `interactive-mode.js` | Make the update banner changelog URL clickable |
| 007 | `markdown.js` | Wrap URLs in inline code spans (`` `https://...` ``) |
| 008–009 | `markdown.js` | Wrap URL-only lines in code blocks (highlighted + plain) |
| 010–015 | `loader.js`, `runner.js`, `types.d.ts` | Expose extension tool lookup/runtime helpers so extensions can resolve registered tools natively by name |
| 016–018 | `openai-completions.js` via `../pi-read/patches/pi-patches.json` | Route OpenRouter audio/video/PDF through native `input_audio` / `video_url` / `file` chat-completions content blocks |

> Upstream `0.67.6` absorbed former patches **001–005** by adding native markdown OSC 8 link rendering and hyperlink wrap tracking in `@mariozechner/pi-tui`.

## How it works

`update.sh` is the entrypoint for the shell alias. It:

1. runs `npm install -g @mariozechner/pi-coding-agent`
2. runs `apply.sh` to re-apply the local patches from `patches.json`
3. runs `test.sh` to verify the patched install still behaves correctly

`patches.json` defines local patches that live in this repo. `sources.json` points at additional patch manifests owned by sibling repos (for example `../pi-read/patches/pi-patches.json`). `apply.sh` loads all of them, locates pi's install directory, applies everything atomically (no files written if any patch fails), and `test.sh` validates the upstream OSC 8 baseline, the remaining local hyperlink/runtime patches, and the OpenRouter multimodal routing behavior.

