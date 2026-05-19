/**
 * Additional pi-mock regressions for pi-autocompact.
 */
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createMock, script, text } from "../pi-mock/dist/index.js";

const TIMEOUT = 60_000;

function writeHugeUserOnlySession({ messageCount = 40, charsPerMessage = 20_000 } = {}) {
  const dir = mkdtempSync(join(tmpdir(), "pi-autocompact-edge-"));
  const sessionFile = join(dir, "session.jsonl");
  const now = new Date().toISOString();
  let parentId = null;
  const entries = [{ type: "session", version: 3, id: "autocompact-edge", timestamp: now, cwd: dir }];

  for (let i = 0; i < messageCount; i++) {
    const id = `user-${String(i).padStart(3, "0")}`;
    entries.push({
      type: "message",
      id,
      parentId,
      timestamp: now,
      message: {
        role: "user",
        content: [{
          type: "text",
          text: `AUTOCOMPACT_EDGE_USER_${i}_START\n${"x".repeat(charsPerMessage)}\nAUTOCOMPACT_EDGE_USER_${i}_END`,
        }],
        timestamp: Date.now() + i,
      },
    });
    parentId = id;
  }

  writeFileSync(sessionFile, `${entries.map((entry) => JSON.stringify(entry)).join("\n")}\n`);
  return { dir, sessionFile };
}

test("compaction fails before provider call when even the first message cannot fit", async () => {
  const { dir, sessionFile } = writeHugeUserOnlySession({ messageCount: 40, charsPerMessage: 600_000 });
  const mock = await createMock({
    brain: script(text("this provider should not be called")),
    sessionFile,
    startupTimeoutMs: 15_000,
    runTimeoutMs: TIMEOUT,
  });

  try {
    const compactResponse = await mock.sendRpc({ type: "compact" });
    assert.equal(compactResponse.success, false, "unrecoverably huge compaction should fail cleanly");
    assert.match(
      compactResponse.error ?? "",
      /too large to fit even the first message|too large to fit/i,
      "error should explain that the compaction prompt cannot fit",
    );
    assert.equal(mock.requests.length, 0, "Pi should not send a known-over-budget summarizer request to the provider");
  } finally {
    await mock.close();
    rmSync(dir, { recursive: true, force: true });
  }
});
