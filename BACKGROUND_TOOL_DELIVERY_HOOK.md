# Background tool delivery hook proposal

## Goal

Give Pi extensions a first-class way to wait until a custom/background result has been delivered into a model-visible turn before clearing UI-only pending state.

This is for generic long-running awaited tools (for example `pi-background-tool`), not for adding model-controlled `background` parameters to tools.

## Verified Pi 0.75.0 runtime path

Inspected installed Pi source under:

- `/Users/sshkeda/.nvm/versions/node/v24.13.0/lib/node_modules/@earendil-works/pi-coding-agent/dist/core/agent-session.js`
- `/Users/sshkeda/.nvm/versions/node/v24.13.0/lib/node_modules/@earendil-works/pi-coding-agent/dist/core/sdk.js`
- `/Users/sshkeda/.nvm/versions/node/v24.13.0/lib/node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core/dist/agent-loop.js`
- `/Users/sshkeda/.nvm/versions/node/v24.13.0/lib/node_modules/@earendil-works/pi-coding-agent/dist/core/messages.js`

Observed path:

1. Extension `pi.sendMessage(message, { deliverAs: "steer" | "followUp", triggerTurn: true })` is bound by `AgentSession._bindExtensionCore()` to `this.sendCustomMessage(message, options)`.
2. `AgentSession.sendCustomMessage()` converts extension input to an `AgentMessage` with `role: "custom"`.
3. If Pi is streaming, `deliverAs: "steer"` calls `this.agent.steer(appMessage)` and `deliverAs: "followUp"` calls `this.agent.followUp(appMessage)`.
4. If Pi is idle and `triggerTurn` is true, `sendCustomMessage()` calls `this.agent.prompt(appMessage)`.
5. `pi-agent-core/dist/agent-loop.js` drains steering messages before the next assistant response and follow-up messages after the agent would otherwise stop.
6. Immediately before each model call, `agent-loop.js` applies `transformContext`, then `convertToLlm(messages)`, then calls `streamFn(model, llmContext, options)`.
7. Pi's `convertToLlm()` maps `role: "custom"` messages to LLM `role: "user"` messages. Therefore a custom background result is model-visible when it reaches this provider-request boundary.
8. `dist/core/sdk.js` wires `streamFn` options:
   - `onPayload` emits `before_provider_request` and can replace the provider payload.
   - `onResponse` emits `after_provider_response` after response headers are received and before the stream is consumed.

Implication: today's public extension events can prove two different things:

- `before_provider_request` proves the background result text is in the provider payload Pi is about to send.
- `after_provider_response` after a matching `before_provider_request` is stronger: it proves Pi received provider response headers for a request whose payload included the background result text.

## Gap

There is no single first-class runtime API like `waitForMessageDeliveredToModel(messageId)` or event like `message_delivered_to_model`.

A package can approximate delivery by correlating:

1. `before_provider_request` payload contains the custom result content, then
2. the next `after_provider_response` fires.

That approximation is based on real Pi events, but it is still an extension-side heuristic because:

- `after_provider_response` does not include a provider request id, payload hash, or message ids.
- `before_provider_request` exposes provider-shaped payloads, so content matching is brittle and may include escaped/transformed text.
- There is no runtime-owned acknowledgement tied to a specific `AgentMessage` or session entry.

## Proposed upstream/runtime hook

Add a delivery-oriented extension event or promise API at the provider boundary, after `convertToLlm()` and before/after provider dispatch.

Preferred event shape:

```ts
interface ProviderRequestPreparedEvent {
  type: "provider_request_prepared";
  requestId: string;
  sessionId?: string;
  messages: Message[];
  payload: unknown;
}

interface ProviderRequestDeliveredEvent {
  type: "provider_request_delivered";
  requestId: string;
  sessionId?: string;
  status: number;
  headers: Record<string, string>;
}
```

Minimum viable alternative:

- Add a stable `requestId` to both existing `before_provider_request` and `after_provider_response` events.
- Optionally include the converted `messages` or a runtime-computed `messageIds` list if AgentMessages can retain ids at that boundary.

## Required tests

Use `pi-mock` as an end-to-end UX harness, not only provider payload matching.

Regression shape:

1. Temporary extension registers a slow tool using a generic background runner.
2. Tool starts work immediately.
3. It completes after the auto-background threshold.
4. Pending UI starts only after promotion.
5. Final custom message is sent with `deliverAs` + `triggerTurn`.
6. A provider request containing the custom background context occurs.
7. Pending UI finishes only after the provider delivery signal, not merely after `sendMessage()` returns.
8. The model responds to the background context.

Current local proof in `/Users/sshkeda/gh/pi-background-tool`:

```text
npm test
✔ unit lifecycle tests
✔ pi-mock integration: pending finishes after background result is present in the next LLM request
```

## Current local adapter decision

Until Pi exposes a first-class request/delivery id, `pi-background-tool` should keep a small `waitForInjection` seam. The default watcher should use the strongest available real events:

- register the target before calling `pi.sendMessage()` to avoid missing immediate turns;
- observe matching content in `before_provider_request`;
- resolve only after the following `after_provider_response` by default;
- allow a test-only/legacy option to resolve at `before_provider_request`.

This keeps `pi-pending` as UI only and avoids treating model output as protocol.
