// Prefills the interactive Pi editor for the pi-update launcher.
// Loaded explicitly by ./pi-update; harmless if PI_UPDATE_PREFILL_PROMPT is unset.

const REQUIRED_PROVIDER = "pi-codex";
const REQUIRED_MODEL = "gpt-5.5-fast";
const REQUIRED_MODEL_REF = `${REQUIRED_PROVIDER}/${REQUIRED_MODEL}`;

function modelRef(model) {
  if (!model) return "<none>";
  return `${model.provider}/${model.id}`;
}

function isRequiredModel(model) {
  return model?.provider === REQUIRED_PROVIDER && model?.id === REQUIRED_MODEL;
}

function failFast(ctx, phase, model = ctx.model) {
  const active = modelRef(model);
  const message = `ERROR: pi-update requires active model ${REQUIRED_MODEL_REF}; got ${active} during ${phase}. Aborting before any review work can run on the wrong provider.`;
  ctx.ui?.notify?.(message, "error");
  ctx.ui?.setTitle?.("pi-update model guard failed");
  ctx.ui?.setEditorText?.(message);
  console.error(message);
  process.exitCode = 1;
  ctx.shutdown?.();
  setTimeout(() => process.exit(1), 25);
  return true;
}

function enforceRequiredModel(ctx, phase, model = ctx.model) {
  return !isRequiredModel(model) && failFast(ctx, phase, model);
}

export default function piUpdatePrefill(pi) {
  pi.on("session_start", async (_event, ctx) => {
    const prompt = process.env.PI_UPDATE_PREFILL_PROMPT;
    if (!prompt || !ctx.ui?.setEditorText) return;
    if (enforceRequiredModel(ctx, "session_start")) return;

    const current = ctx.ui.getEditorText?.() ?? "";
    if (current.trim()) return;

    ctx.ui.setEditorText(prompt);
    ctx.ui.setTitle?.("pi-update patch review");
  });

  pi.on("model_select", async (event, ctx) => {
    const prompt = process.env.PI_UPDATE_PREFILL_PROMPT;
    if (!prompt) return;
    enforceRequiredModel(ctx, "model_select", event.model);
  });

  pi.on("before_agent_start", async (_event, ctx) => {
    const prompt = process.env.PI_UPDATE_PREFILL_PROMPT;
    if (!prompt) return;
    enforceRequiredModel(ctx, "before_agent_start");
  });
}
