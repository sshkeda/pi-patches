#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Test that OSC 8 patches are working correctly.
# Run after apply.sh to verify patches produce correct output.
# ---------------------------------------------------------------------------
set -euo pipefail

PI_PKG="$(dirname "$(which pi 2>/dev/null || echo '')")/../lib/node_modules/@mariozechner/pi-coding-agent"
if [ ! -d "$PI_PKG" ]; then
  PI_PKG="$HOME/.nvm/versions/node/$(node -v)/lib/node_modules/@mariozechner/pi-coding-agent"
fi

PI_TUI="$PI_PKG/node_modules/@mariozechner/pi-tui"
ERRORS=0

echo "→ Running OSC 8 patch tests..."

node --input-type=module << SCRIPT
import { wrapTextWithAnsi } from "$PI_TUI/dist/utils.js";
import { Markdown } from "$PI_TUI/dist/components/markdown.js";

let passed = 0;
let failed = 0;

function assert(name, condition, detail) {
  if (condition) {
    console.log("  ✓ " + name);
    passed++;
  } else {
    console.error("  ✗ " + name);
    if (detail) console.error("    " + detail);
    failed++;
  }
}

// ── Test 1: AnsiCodeTracker preserves OSC 8 across line wraps ──
{
  const url = "https://example.com/very/long/path/that/will/definitely/wrap/across/multiple/lines";
  const osc8Open = "\x1b]8;;" + url + "\x07";
  const osc8Close = "\x1b]8;;\x07";
  const text = osc8Open + url + osc8Close;
  const lines = wrapTextWithAnsi(text, 40);

  assert(
    "OSC 8 wraps to multiple lines",
    lines.length >= 2,
    "Expected >=2 lines, got " + lines.length
  );

  assert(
    "Line 0 starts with OSC 8 open",
    lines[0].includes("\x1b]8;;" + url + "\x07"),
    "Missing OSC 8 open on line 0"
  );

  assert(
    "Continuation line re-opens OSC 8",
    lines[1].includes("\x1b]8;;" + url + "\x07"),
    "Line 1: " + JSON.stringify(lines[1])
  );

  assert(
    "Last line closes OSC 8",
    lines[lines.length - 1].includes("\x1b]8;;\x07"),
    "Missing OSC 8 close on last line"
  );
}

// ── Test 2: OSC 8 + SGR styles both preserved on continuation ──
{
  const url = "https://example.com/styled/link/that/wraps/across/lines/for/testing";
  const text = "\x1b]8;;" + url + "\x07\x1b[38;5;110m\x1b[4m" + url + "\x1b[24m\x1b[39m\x1b]8;;\x07";
  const lines = wrapTextWithAnsi(text, 40);

  assert(
    "Continuation has both OSC 8 and SGR color",
    lines.length >= 2 &&
    lines[1].includes("\x1b]8;;" + url + "\x07") &&
    /\x1b\[[\d;]*m/.test(lines[1]),
    "Line 1: " + JSON.stringify(lines[1])
  );
}

// ── Test 3: OSC 8 close resets tracker state ──
{
  const url = "https://example.com/link";
  const text = "\x1b]8;;" + url + "\x07linktext\x1b]8;;\x07 normal text that should not have osc8 and is long enough to wrap";
  const lines = wrapTextWithAnsi(text, 40);

  const lastLine = lines[lines.length - 1];
  // Count OSC 8 opens (non-empty URL) on last line — should be 0
  const osc8Opens = (lastLine.match(/\x1b\]8;;[^\x07]+\x07/g) || []);
  assert(
    "Text after OSC 8 close has no hyperlink",
    osc8Opens.length === 0,
    "Last line has unexpected OSC 8: " + JSON.stringify(lastLine)
  );
}

// ── Test 4: Markdown bare URL gets OSC 8 ──
{
  const theme = {
    heading: s=>s, bold: s=>s, italic: s=>s, code: s=>s,
    codeBlock: s=>s, codeBlockBorder: s=>s, codeBlockLanguage: s=>s,
    quote: s=>s, quoteBorder: s=>s, hr: s=>s, listBullet: s=>s,
    link: s=>s, linkUrl: s=>s, underline: s=>s, strikethrough: s=>s,
    highlightCode: (c,l)=>c, tableBorder: s=>s,
  };

  const url = "https://example.com/bare/url/test";
  const md = new Markdown(url, 0, 0, theme);
  const lines = md.render(80);
  const output = lines.join("");

  assert(
    "Bare URL wrapped in OSC 8",
    output.includes("\x1b]8;;" + url + "\x07") && output.includes("\x1b]8;;\x07"),
    "Output: " + JSON.stringify(output)
  );
}

// ── Test 5: Markdown named link [text](url) gets OSC 8 ──
{
  const theme = {
    heading: s=>s, bold: s=>s, italic: s=>s, code: s=>s,
    codeBlock: s=>s, codeBlockBorder: s=>s, codeBlockLanguage: s=>s,
    quote: s=>s, quoteBorder: s=>s, hr: s=>s, listBullet: s=>s,
    link: s=>s, linkUrl: s=>s, underline: s=>s, strikethrough: s=>s,
    highlightCode: (c,l)=>c, tableBorder: s=>s,
  };

  const url = "https://example.com/named";
  const md = new Markdown("[Click here](" + url + ")", 0, 0, theme);
  const lines = md.render(80);
  const output = lines.join("");

  assert(
    "Named link wrapped in OSC 8",
    output.includes("\x1b]8;;" + url + "\x07"),
    "Output: " + JSON.stringify(output)
  );

  assert(
    "Named link text visible",
    output.includes("Click here"),
    "Output: " + JSON.stringify(output)
  );

  assert(
    "Named link URL in parens also inside OSC 8",
    // The OSC 8 close should come AFTER the (url) part
    output.indexOf("(" + url + ")") < output.lastIndexOf("\x1b]8;;\x07"),
    "OSC 8 closes before URL parens"
  );
}

// ── Test 6: Multiple links don't leak OSC 8 between them ──
{
  const theme = {
    heading: s=>s, bold: s=>s, italic: s=>s, code: s=>s,
    codeBlock: s=>s, codeBlockBorder: s=>s, codeBlockLanguage: s=>s,
    quote: s=>s, quoteBorder: s=>s, hr: s=>s, listBullet: s=>s,
    link: s=>s, linkUrl: s=>s, underline: s=>s, strikethrough: s=>s,
    highlightCode: (c,l)=>c, tableBorder: s=>s,
  };

  const md = new Markdown("[A](https://a.com) then [B](https://b.com)", 0, 0, theme);
  const lines = md.render(80);
  const output = lines.join("");

  assert(
    "First link has correct OSC 8 URL",
    output.includes("\x1b]8;;https://a.com\x07"),
    "Output: " + JSON.stringify(output)
  );

  assert(
    "Second link has correct OSC 8 URL",
    output.includes("\x1b]8;;https://b.com\x07"),
    "Output: " + JSON.stringify(output)
  );
}

// ── Test 7: URL in backtick code span gets OSC 8 ──
{
  const theme = {
    heading: s=>s, bold: s=>s, italic: s=>s, code: s=>s,
    codeBlock: s=>s, codeBlockBorder: s=>s, codeBlockLanguage: s=>s,
    quote: s=>s, quoteBorder: s=>s, hr: s=>s, listBullet: s=>s,
    link: s=>s, linkUrl: s=>s, underline: s=>s, strikethrough: s=>s,
    highlightCode: (c,l)=>c, tableBorder: s=>s,
  };

  const url = "https://agentvibe.pages.dev/join?c=j57bpc9ggjknj4yxc1mz3mr71184b81a&s=6baf0e16358be3b89b9e8c2160d879d61198695d6fac8f1ae317a4d70059b350";
  const bt = "\x60";
  const md = new Markdown(bt + url + bt, 0, 0, theme);
  const lines = md.render(80);
  const output = lines.join("");

  assert(
    "URL in backtick code span gets OSC 8",
    output.includes("\x1b]8;;" + url + "\x07") && output.includes("\x1b]8;;\x07"),
    "Output: " + JSON.stringify(output)
  );
}

// ── Test 8: Non-URL code span does NOT get OSC 8 ──
{
  const theme = {
    heading: s=>s, bold: s=>s, italic: s=>s, code: s=>s,
    codeBlock: s=>s, codeBlockBorder: s=>s, codeBlockLanguage: s=>s,
    quote: s=>s, quoteBorder: s=>s, hr: s=>s, listBullet: s=>s,
    link: s=>s, linkUrl: s=>s, underline: s=>s, strikethrough: s=>s,
    highlightCode: (c,l)=>c, tableBorder: s=>s,
  };

  const bt = "\x60";
  const md = new Markdown(bt + "const x = 5" + bt, 0, 0, theme);
  const output = md.render(80).join("");

  assert(
    "Non-URL code span has no OSC 8",
    !output.includes("\x1b]8;;"),
    "Output: " + JSON.stringify(output)
  );
}

// ── Test 9: URL in code span wraps correctly with OSC 8 ──
{
  const url = "https://example.com/very/long/url/that/will/definitely/wrap/across/multiple/terminal/lines/when/rendered";
  const bt = "\x60";
  const md_input = bt + url + bt;

  const theme = {
    heading: s=>s, bold: s=>s, italic: s=>s, code: s=>s,
    codeBlock: s=>s, codeBlockBorder: s=>s, codeBlockLanguage: s=>s,
    quote: s=>s, quoteBorder: s=>s, hr: s=>s, listBullet: s=>s,
    link: s=>s, linkUrl: s=>s, underline: s=>s, strikethrough: s=>s,
    highlightCode: (c,l)=>c, tableBorder: s=>s,
  };

  const md = new Markdown(md_input, 0, 0, theme);
  const lines = md.render(40);

  assert(
    "URL code span wraps to multiple lines",
    lines.length >= 2,
    "Expected >=2 lines, got " + lines.length
  );

  if (lines.length >= 2) {
    assert(
      "Wrapped URL code span continuation has OSC 8",
      lines[1].includes("\x1b]8;;" + url + "\x07"),
      "Line 1: " + JSON.stringify(lines[1])
    );
  }
}

// ── Summary ──
console.log("");
console.log("→ " + passed + " passed, " + failed + " failed");
if (failed > 0) process.exit(1);
SCRIPT
