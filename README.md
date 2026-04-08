# pi-patches

OSC 8 hyperlink patches for [pi](https://github.com/badlogic/pi-mono). Makes URLs clickable in the terminal — links, code spans, and the update banner all get proper [OSC 8](https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda) sequences that survive line wrapping.

## Usage

```bash
# Apply after installing or upgrading pi
bash apply.sh

# Verify patches work
bash test.sh
```

> **Note:** Patches need to be re-applied after every pi update since `npm install -g` replaces node_modules.

## What it patches

| Patch | File | What |
|-------|------|------|
| 001 | `markdown.js` | Wrap markdown links in OSC 8 |
| 002–005 | `utils.js` | Track OSC 8 state in `AnsiCodeTracker` so hyperlinks survive line wraps |
| 006 | `interactive-mode.js` | Make the update banner changelog URL clickable |
| 007 | `markdown.js` | Wrap URLs in inline code spans (`` `https://...` ``) |

## How it works

`patches.json` defines each patch as a find/replace pair with a verify string. `apply.sh` reads the JSON, locates pi's install directory, applies all patches atomically (no files written if any patch fails), and `test.sh` validates the output.
