---
name: codex-stream-disconnect-litellm
description: Codex "stream closed before response.completed" is a litellm /v1/responses mid-stream error symptom — diagnose via async_data_generator errors in litellm logs
metadata:
  type: project
---

Codex (in claudecodeui pod) reporting "stream disconnected before completion: stream closed before response.completed" is a **symptom of a litellm /v1/responses mid-stream error**, not a network blip.

**Why:** When the upstream provider errors mid-stream (e.g. deepinfra rejects with ContextWindowExceededError), litellm's `async_data_generator` (proxy_server.py:7627) raises and closes the SSE stream WITHOUT emitting a final `response.completed` event. The OpenAI Responses SDK then reports a premature stream close. The uvicorn access log still shows `200 OK` for these requests (headers are sent before the failure), so non-200 search won't find them.

**How to apply:** To diagnose, grep litellm logs for `proxy_server.py:7627 - .*Exception occured` around the reported time. On 2026-08-23 the cause was ContextWindowExceededError: DeepSeek-V4-Flash-0731 max context = 1,048,576 tokens; a codex request with 664,577 input + 384,000 requested output = 1,048,577 overflowed by 1 token. Failing requests were retried (litellm router num_retries: 2 / retry_after: 5.0 + codex retries), failing identically. Model timeout is 300s — the rejection came within ~4-30s, so NOT a timeout. Related: codex requests `max_output_tokens: 384000`, so any long conversation overflows the 1M window.

Benign log noise not to chase: "Container ownership recording skipped on streaming /v1/responses", "Dropping Responses API tool of type 'namespace'", "register_model ... not in built-in cost map", and "No api key passed in" on GET /v1/models probes (401, from claudecodeui health checks).

**Fixed 2026-08-23:** `kubernetes/development/litellm/config.yaml` now sets `model_info: max_input_tokens: 1000000, max_output_tokens: 128000` on deepseek-v4-flash so input+output never overflows the 1,048,576 window. Verified after `kubectl apply -k` + rollout restart: mounted `/app/config.yaml` shows both caps, GET /v1/models returns them (was 393216 before), and POST /v1/responses returns 200. NOTE: claudecodeui's proxy-check hits `http://litellm/v1/models` — a curl exit 7 right after a litellm rollout restart is transient (pod still settling); just retry.
