#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Verify the installed pi build still has the expected upstream + local patch
# behavior after apply.sh runs.
# ---------------------------------------------------------------------------
set -euo pipefail

PI_BIN="$(command -v pi || true)"
if ! PI_PKG="$(node - "$PI_BIN" <<'NODE'
const fs = require("fs");
const path = require("path");
const bin = process.argv[2];
const candidates = [];
if (bin) {
  try {
    const realBin = fs.realpathSync(bin);
    candidates.push(path.resolve(path.dirname(realBin), ".."));
  } catch {}
  const binDir = path.dirname(bin);
  candidates.push(path.resolve(binDir, "../lib/node_modules/@earendil-works/pi-coding-agent"));
  candidates.push(path.resolve(binDir, "../lib/node_modules/@mariozechner/pi-coding-agent"));
}
candidates.push(path.join(process.env.HOME, ".nvm/versions/node", process.version, "lib/node_modules/@earendil-works/pi-coding-agent"));
candidates.push(path.join(process.env.HOME, ".nvm/versions/node", process.version, "lib/node_modules/@mariozechner/pi-coding-agent"));
for (const candidate of candidates) {
  if (fs.existsSync(path.join(candidate, "package.json"))) {
    console.log(candidate);
    process.exit(0);
  }
}
process.exit(1);
NODE
)"; then
  echo "ERROR: pi-coding-agent not found. Is pi installed?" >&2
  exit 1
fi

if [ -d "$PI_PKG/node_modules/@earendil-works/pi-tui" ]; then
  PI_TUI="$PI_PKG/node_modules/@earendil-works/pi-tui"
  PI_AI="$PI_PKG/node_modules/@earendil-works/pi-ai"
  PI_AGENT_CORE="$PI_PKG/node_modules/@earendil-works/pi-agent-core"
else
  PI_TUI="$PI_PKG/node_modules/@mariozechner/pi-tui"
  PI_AI="$PI_PKG/node_modules/@mariozechner/pi-ai"
  PI_AGENT_CORE="$PI_PKG/node_modules/@mariozechner/pi-agent-core"
fi

echo "→ Running pi-patches verification tests..."

PI_PKG="$PI_PKG" PI_TUI="$PI_TUI" PI_AI="$PI_AI" PI_AGENT_CORE="$PI_AGENT_CORE" node --input-type=module <<'SCRIPT'
import { readFileSync } from "node:fs";

const PI_PKG = process.env.PI_PKG;
const PI_TUI = process.env.PI_TUI;
const PI_AI = process.env.PI_AI;
const PI_AGENT_CORE = process.env.PI_AGENT_CORE;

const { wrapTextWithAnsi } = await import(`${PI_TUI}/dist/utils.js`);
const { setCapabilities } = await import(`${PI_TUI}/dist/terminal-image.js`);
const { Markdown } = await import(`${PI_TUI}/dist/components/markdown.js`);
const { initTheme } = await import(`${PI_PKG}/dist/modes/interactive/theme/theme.js`);
const { createBashToolDefinition } = await import(`${PI_PKG}/dist/core/tools/bash.js`);

setCapabilities({ images: null, trueColor: true, hyperlinks: true });
initTheme("dark");

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

function escapeRegex(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function osc8OpenRe(url) {
  return new RegExp(`\\x1b\\]8;;${escapeRegex(url)}(?:\\x07|\\x1b\\\\)`);
}

function osc8CloseRe() {
  return /\x1b\]8;;(?:\x07|\x1b\\)/;
}

function hasOsc8Open(text, url) {
  return osc8OpenRe(url).test(text);
}

function hasOsc8Close(text) {
  return osc8CloseRe().test(text);
}

function countOsc8Opens(text) {
  return text.match(/\x1b\]8;;[^\x07\x1b]+(?:\x07|\x1b\\)/g)?.length ?? 0;
}

function basicTheme(highlightCode = (code) => code, extra = {}) {
  return {
    heading: (s) => s,
    bold: (s) => s,
    italic: (s) => s,
    code: (s) => s,
    codeBlock: (s) => s,
    codeBlockBorder: (s) => s,
    codeBlockLanguage: (s) => s,
    quote: (s) => s,
    quoteBorder: (s) => s,
    hr: (s) => s,
    listBullet: (s) => s,
    link: (s) => s,
    linkUrl: (s) => s,
    underline: (s) => s,
    strikethrough: (s) => s,
    highlightCode,
    tableBorder: (s) => s,
    ...extra,
  };
}

// ── Upstream OSC 8 baseline (001–005 are now upstream) ─────────────────────
{
  const url = "https://example.com/very/long/path/that/will/definitely/wrap/across/multiple/lines";
  const text = `\x1b]8;;${url}\x1b\\${url}\x1b]8;;\x1b\\`;
  const lines = wrapTextWithAnsi(text, 40);

  assert("OSC 8 wraps to multiple lines", lines.length >= 2, "Expected >=2 lines, got " + lines.length);
  assert("Line 0 starts with OSC 8 open", hasOsc8Open(lines[0], url), "Line 0: " + JSON.stringify(lines[0]));
  assert("Continuation line re-opens OSC 8", lines.length >= 2 && hasOsc8Open(lines[1], url), "Line 1: " + JSON.stringify(lines[1]));
  assert("Last line closes OSC 8", hasOsc8Close(lines[lines.length - 1]), "Last line: " + JSON.stringify(lines[lines.length - 1]));
}

{
  const url = "https://example.com/styled/link/that/wraps/across/lines/for/testing";
  const text = `\x1b]8;;${url}\x1b\\\x1b[38;5;110m\x1b[4m${url}\x1b[24m\x1b[39m\x1b]8;;\x1b\\`;
  const lines = wrapTextWithAnsi(text, 40);

  assert(
    "Continuation preserves OSC 8 + SGR styles",
    lines.length >= 2 && hasOsc8Open(lines[1], url) && /\x1b\[[\d;]*m/.test(lines[1]),
    "Line 1: " + JSON.stringify(lines[1]),
  );
}

{
  const url = "https://example.com/link";
  const text = `\x1b]8;;${url}\x1b\\linktext\x1b]8;;\x1b\\ normal text that should not have osc8 and is long enough to wrap`;
  const lines = wrapTextWithAnsi(text, 40);
  const lastLine = lines[lines.length - 1];

  assert("Text after OSC 8 close has no hyperlink", countOsc8Opens(lastLine) === 0, "Last line: " + JSON.stringify(lastLine));
}

{
  const url = "https://example.com/bare/url/test";
  const output = new Markdown(url, 0, 0, basicTheme()).render(80).join("");

  assert("Bare URL renders as OSC 8 hyperlink", hasOsc8Open(output, url) && hasOsc8Close(output), "Output: " + JSON.stringify(output));
}

{
  const url = "https://example.com/named";
  const output = new Markdown(`[Click here](${url})`, 0, 0, basicTheme()).render(80).join("");

  assert("Named link renders as OSC 8 hyperlink", hasOsc8Open(output, url) && hasOsc8Close(output), "Output: " + JSON.stringify(output));
  assert("Named link text stays visible", output.includes("Click here"), "Output: " + JSON.stringify(output));
}

{
  const output = new Markdown("[A](https://a.com) then [B](https://b.com)", 0, 0, basicTheme()).render(80).join("");

  assert("First markdown link has correct URL", hasOsc8Open(output, "https://a.com"), "Output: " + JSON.stringify(output));
  assert("Second markdown link has correct URL", hasOsc8Open(output, "https://b.com"), "Output: " + JSON.stringify(output));
}

// ── Local LaTeX math rendering patch (031–033) ─────────────────────────────
{
  const output = new Markdown(String.raw`\[\theta_i \sim \text{Beta}(\alpha, \beta)\]`, 0, 0, basicTheme()).render(80).join("\n");
  assert(
    "Block LaTeX renders to Unicode math",
    output.includes("θᵢ ∼ Beta(α, β)") && !output.includes("\\theta") && !output.includes("\\text"),
    "Output: " + JSON.stringify(output),
  );
}

{
  const output = new Markdown(String.raw`Inline $Y_i \mid \theta_i \sim \text{Binomial}(n_i, \theta_i)$ done`, 0, 0, basicTheme()).render(100).join("\n");
  assert(
    "Inline dollar LaTeX renders to Unicode math",
    output.includes("Yᵢ ∣ θᵢ ∼ Binomial(nᵢ, θᵢ)") && !output.includes("\\mid") && !output.includes("\\text"),
    "Output: " + JSON.stringify(output),
  );
}

{
  const output = new Markdown(String.raw`Code stays raw: \`$\theta_i$\``, 0, 0, basicTheme()).render(80).join("\n");
  assert("LaTeX inside code spans is protected", output.includes(String.raw`$\theta_i$`), "Output: " + JSON.stringify(output));
}

// ── Local OSC 8 coverage patches (006–009) ─────────────────────────────────
{
  const source = readFileSync(`${PI_PKG}/dist/modes/interactive/interactive-mode.js`, "utf8");
  assert("Update banner changelog URL patch is present", source.includes("const changelogRawUrl ="), "interactive-mode.js missing changelogRawUrl helper");
}

{
  const source = readFileSync(`${PI_PKG}/dist/core/agent-session.js`, "utf8");
  assert(
    "/reload reopens the current session file",
    source.includes("const currentSessionFile = this.sessionManager.getSessionFile();") &&
      source.includes("currentSessionFile && existsSync(currentSessionFile)") &&
      source.includes("this.sessionManager.setSessionFile(currentSessionFile);") &&
      source.includes("this.agent.state.messages = this.sessionManager.buildSessionContext().messages;"),
    "agent-session.js missing current-session reload reopen logic",
  );
  assert(
    "input hooks can refresh active session before prompt build",
    source.includes("// Refresh agent transcript in case input hooks changed the active session leaf."),
    "agent-session.js missing input-hook session refresh patch",
  );
}

{
  const url = "https://agentvibe.pages.dev/join?c=j57bpc9ggjknj4yxc1mz3mr71184b81a&s=6baf0e16358be3b89b9e8c2160d879d61198695d6fac8f1ae317a4d70059b350";
  const bt = "\x60";
  const output = new Markdown(bt + url + bt, 0, 0, basicTheme()).render(80).join("");

  assert("URL in backtick code span gets OSC 8", hasOsc8Open(output, url) && hasOsc8Close(output), "Output: " + JSON.stringify(output));
}

{
  const output = new Markdown("`const x = 5`", 0, 0, basicTheme()).render(80).join("");
  assert("Non-URL code span has no OSC 8", !output.includes("\x1b]8;;"), "Output: " + JSON.stringify(output));
}

{
  const url = "https://example.com/very/long/url/that/will/definitely/wrap/across/multiple/terminal/lines/when/rendered";
  const outputLines = new Markdown("`" + url + "`", 0, 0, basicTheme()).render(40);

  assert("URL code span wraps to multiple lines", outputLines.length >= 2, "Expected >=2 lines, got " + outputLines.length);
  if (outputLines.length >= 2) {
    assert("Wrapped URL code span continuation has OSC 8", hasOsc8Open(outputLines[1], url), "Line 1: " + JSON.stringify(outputLines[1]));
  }
}

{
  const url = "https://example.com/very/long/path/in/code/block";
  const block = `${"`".repeat(3)}\n${url}\n${"`".repeat(3)}`;
  const output = new Markdown(block, 0, 0, basicTheme((code) => code.split("\n"))).render(120).join("");

  assert("URL in highlighted code block gets OSC 8", hasOsc8Open(output, url), "Output: " + JSON.stringify(output));
}

{
  const url = "https://example.com/plain/code/block";
  const block = `${"`".repeat(3)}\n${url}\n${"`".repeat(3)}`;
  const output = new Markdown(block, 0, 0, basicTheme(null)).render(120).join("");

  assert("URL in plain code block gets OSC 8", hasOsc8Open(output, url), "Output: " + JSON.stringify(output));
}

{
  const block = `${"`".repeat(3)}\nconst x = 5;\n${"`".repeat(3)}`;
  const output = new Markdown(block, 0, 0, basicTheme((code) => code.split("\n"))).render(80).join("");

  assert("Non-URL code block has no OSC 8", !output.includes("\x1b]8;;"), "Output: " + JSON.stringify(output));
}

// ── Extension runtime tool lookup patches (010–015) ────────────────────────
{
  const loaderSource = readFileSync(`${PI_PKG}/dist/core/extensions/loader.js`, "utf8");
  assert("Extension runtime exposes getToolDefinition stub", loaderSource.includes("getToolDefinition: notInitialized"), "loader.js missing runtime stub");
  assert("Extension API exposes getAllRegisteredTools", loaderSource.includes("getAllRegisteredTools() {"), "loader.js missing API method");
}

{
  const runnerSource = readFileSync(`${PI_PKG}/dist/core/extensions/runner.js`, "utf8");
  assert(
    "Extension runner binds tool lookup helpers",
    (runnerSource.includes("this.runtime.getToolDefinition = (toolName) => this.getToolDefinition(toolName);") ||
      runnerSource.includes("actions.getToolDefinition ?? ((toolName) => this.getToolDefinition(toolName))")) &&
      (runnerSource.includes("this.runtime.getAllRegisteredTools = () => this.getAllRegisteredTools();") ||
        runnerSource.includes("actions.getAllRegisteredTools ?? (() => this.getAllRegisteredTools())")),
    "runner.js missing runtime bindings",
  );
  assert(
    "Extension runner exposes invokeTool context action",
    runnerSource.includes("invokeToolFn = async () => { throw new Error(\"Extension runtime not initialized\"); };") &&
      runnerSource.includes("this.invokeToolFn = contextActions.invokeTool ?? this.invokeToolFn;") &&
      runnerSource.includes("return runner.invokeToolFn(name, args, options);"),
    "runner.js missing invokeTool context action",
  );
}

{
  const agentSessionSource = readFileSync(`${PI_PKG}/dist/core/agent-session.js`, "utf8");
  assert(
    "AgentSession exposes full tool definition lookup actions",
    agentSessionSource.includes("getToolDefinition: (name) => this.getToolDefinition(name)") &&
      agentSessionSource.includes("getAllRegisteredTools: () => Array.from(this._toolDefinitions.values())"),
    "agent-session.js missing full tool lookup actions",
  );
  assert(
    "AgentSession exposes native nested invokeTool",
    agentSessionSource.includes("async invokeTool(name, args = {}, options = {})") &&
      agentSessionSource.includes("type: \"tool_execution_start\"") &&
      agentSessionSource.includes("type: \"tool_execution_end\"") &&
      agentSessionSource.includes("invokeTool: (name, args, options) => this.invokeTool(name, args, options)"),
    "agent-session.js missing nested invokeTool implementation",
  );
}

{
  const typesSource = readFileSync(`${PI_PKG}/dist/core/extensions/types.d.ts`, "utf8");
  assert("Extension types declare getToolDefinition handler", typesSource.includes("export type GetToolDefinitionHandler = (name: string) => ToolDefinition | undefined;"), "types.d.ts missing handler type");
  assert("Extension API declares getToolDefinition()", typesSource.includes("getToolDefinition(name: string): ToolDefinition | undefined;"), "types.d.ts missing API method");
  assert("Extension API declares getAllRegisteredTools()", typesSource.includes("getAllRegisteredTools(): RegisteredTool[];"), "types.d.ts missing registered-tools API method");
  assert("Extension context declares invokeTool()", typesSource.includes("export interface InvokeToolOptions") && typesSource.includes("invokeTool(name: string, args?: unknown, options?: InvokeToolOptions)"), "types.d.ts missing invokeTool context API");
}

{
  const coreTypesSource = readFileSync(`${PI_AGENT_CORE}/dist/types.d.ts`, "utf8");
  const beforeToolCallResult = coreTypesSource.match(/export interface BeforeToolCallResult \{[\s\S]*?\n\}/)?.[0] ?? "";
  assert(
    "beforeToolCall result supports concrete content/details/isError",
    beforeToolCallResult.includes("content?: (TextContent | ImageContent)[];") &&
      beforeToolCallResult.includes("details?: unknown;") &&
      beforeToolCallResult.includes("isError?: boolean;"),
    "pi-agent-core/types.d.ts BeforeToolCallResult missing short-circuit result fields; got: " + beforeToolCallResult,
  );
}

{
  const coreLoopSource = readFileSync(`${PI_AGENT_CORE}/dist/agent-loop.js`, "utf8");
  assert(
    "agent loop honors beforeToolCall concrete result payloads",
    coreLoopSource.includes("beforeResult.content || beforeResult.details !== undefined") &&
      coreLoopSource.includes("beforeResult.isError ?? !(beforeResult.content || beforeResult.details !== undefined)"),
    "pi-agent-core/agent-loop.js missing beforeToolCall short-circuit handling",
  );
}

{
  const bashToolSource = readFileSync(`${PI_PKG}/dist/core/tools/bash.js`, "utf8");
  assert(
    "bash prompt snippet warns timeout is seconds, not milliseconds",
    bashToolSource.includes("timeout=120 for 2 minutes, never milliseconds"),
    "dist/core/tools/bash.js missing explicit timeout unit prompt snippet",
  );
  assert(
    "bash output URL linkifier patch is present",
    bashToolSource.includes("function linkifyBareUrls(text)") && bashToolSource.includes('theme.fg("toolOutput", linkifyBareUrls(line))'),
    "dist/core/tools/bash.js missing bash output URL linkifier",
  );
}

{
  const url = "https://vercel.com/docs/accounts/team-members-and-roles/access-roles/team-level-roles?resource=Remote+Cache+Artifact";
  const bashDef = createBashToolDefinition(PI_PKG);
  const component = bashDef.renderResult(
    { content: [{ type: "text", text: `WARNING see ${url}` }] },
    { expanded: false, isPartial: false },
    basicTheme(),
    { state: {}, lastComponent: undefined, invalidate: () => {}, showImages: false, isError: false },
  );
  const lines = component.render(56);
  const output = lines.join("\n");
  assert("Bash result URL renders as OSC 8 hyperlink", hasOsc8Open(output, url), "Output: " + JSON.stringify(output));
  assert(
    "Wrapped bash result URL continuation has OSC 8",
    lines.length >= 3 && lines.slice(2).some((line) => hasOsc8Open(line, url)),
    "Lines: " + JSON.stringify(lines),
  );
}

{
  const extensionTypesSource = readFileSync(`${PI_PKG}/dist/core/extensions/types.d.ts`, "utf8");
  const toolCallEventResult = extensionTypesSource.match(/export interface ToolCallEventResult \{[\s\S]*?\n\}/)?.[0] ?? "";
  assert(
    "extension tool_call result supports concrete content/details/isError",
    toolCallEventResult.includes("content?: (TextContent | ImageContent)[];") &&
      toolCallEventResult.includes("details?: unknown;") &&
      toolCallEventResult.includes("isError?: boolean;"),
    "extensions/types.d.ts ToolCallEventResult missing short-circuit result fields; got: " + toolCallEventResult,
  );
}

// ── OpenRouter multimodal routing patches from pi-read (016–018) ───────────
const { convertMessages } = await import(`${PI_AI}/dist/providers/openai-completions.js`);

function openRouterModel() {
  return {
    provider: "openrouter",
    api: "openai-completions",
    id: "google/gemini-3.1-pro-preview",
    baseUrl: "https://openrouter.ai/api/v1",
    input: ["text", "image"],
  };
}

const compat = {
  requiresAssistantAfterToolResult: false,
  requiresToolResultName: false,
  requiresThinkingAsText: false,
};

{
  const messages = convertMessages(openRouterModel(), {
    messages: [{ role: "user", content: [{ type: "text", text: "transcribe this" }, { type: "image", mimeType: "audio/mp4", data: "AAAA" }] }],
  }, compat);
  const media = messages[0].content[1];
  assert("OpenRouter audio uses input_audio", media?.type === "input_audio" && media?.input_audio?.format === "m4a" && media?.input_audio?.data === "AAAA", "Media: " + JSON.stringify(media));
}

{
  const messages = convertMessages(openRouterModel(), {
    messages: [{ role: "user", content: [{ type: "text", text: "analyze this" }, { type: "image", mimeType: "video/mp4", data: "BBBB" }] }],
  }, compat);
  const media = messages[0].content[1];
  assert("OpenRouter video uses video_url", media?.type === "video_url" && media?.video_url?.url === "data:video/mp4;base64,BBBB", "Media: " + JSON.stringify(media));
}

{
  const messages = convertMessages(openRouterModel(), {
    messages: [{ role: "user", content: [{ type: "text", text: "summarize this" }, { type: "image", mimeType: "application/pdf", data: "CCCC" }] }],
  }, compat);
  const media = messages[0].content[1];
  assert("OpenRouter PDF uses file", media?.type === "file" && media?.file?.filename === "attachment.pdf" && media?.file?.file_data === "data:application/pdf;base64,CCCC", "Media: " + JSON.stringify(media));
}

{
  const messages = convertMessages(openRouterModel(), {
    messages: [
      {
        role: "assistant",
        content: [{ type: "toolCall", id: "call_1", name: "read", arguments: { path: "a.m4a" } }],
        api: "openai-completions",
        provider: "openrouter",
        model: "google/gemini-3.1-pro-preview",
        usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } },
        stopReason: "toolUse",
        timestamp: Date.now(),
      },
      {
        role: "toolResult",
        toolCallId: "call_1",
        toolName: "read",
        content: [
          { type: "text", text: "Read audio file [audio/mp4, 18.0 MB]" },
          { type: "image", mimeType: "audio/mp4", data: "DDDD" },
        ],
        isError: false,
        timestamp: Date.now(),
      },
    ],
  }, compat);
  const syntheticUser = messages[messages.length - 1];
  const media = syntheticUser?.content?.[1];
  assert(
    "OpenRouter tool-result audio uses input_audio",
    syntheticUser?.role === "user" && media?.type === "input_audio" && media?.input_audio?.format === "m4a",
    "Synthetic user: " + JSON.stringify(syntheticUser),
  );
}

{
  const model = {
    provider: "openai",
    api: "openai-completions",
    id: "gpt-4.1",
    baseUrl: "https://api.openai.com/v1",
    input: ["text", "image"],
  };
  const messages = convertMessages(model, {
    messages: [{ role: "user", content: [{ type: "text", text: "legacy path" }, { type: "image", mimeType: "audio/mp4", data: "EEEE" }] }],
  }, compat);
  const media = messages[0].content[1];
  assert("Non-OpenRouter audio still falls back to image_url", media?.type === "image_url" && media?.image_url?.url === "data:audio/mp4;base64,EEEE", "Media: " + JSON.stringify(media));
}

console.log("");
console.log(`→ ${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
SCRIPT

# ── External behavioral tests ───────────────────────────────────────────────
if [ -x "$(dirname "$0")/../pi-autocompact/test.sh" ]; then
  echo "→ Running pi-autocompact behavioral tests..."
  bash "$(dirname "$0")/../pi-autocompact/test.sh"
fi
