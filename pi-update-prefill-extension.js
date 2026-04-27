// Prefills the interactive Pi editor for the pi-update launcher.
// Loaded explicitly by ./pi-update; harmless if PI_UPDATE_PREFILL_PROMPT is unset.

export default function piUpdatePrefill(pi) {
  pi.on("session_start", async (_event, ctx) => {
    const prompt = process.env.PI_UPDATE_PREFILL_PROMPT;
    if (!prompt || !ctx.ui?.setEditorText) return;

    const current = ctx.ui.getEditorText?.() ?? "";
    if (current.trim()) return;

    ctx.ui.setEditorText(prompt);
    ctx.ui.setTitle?.("pi-update patch review");
  });
}
