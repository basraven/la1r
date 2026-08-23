"""Enforce a max output-token cap on the litellm /v1/responses path.

Why: codex (OpenAI Codex CLI in the claudecodeui pod) requests
max_output_tokens=384000 (a hardcoded default; codex 0.149.0 has no config knob
and no model-catalog field to lower it). On a long session (input > 664k) that
overflows DeepSeek-V4-Flash-0731's 1,048,576-token window, DeepInfra rejects the
request mid-stream, and litellm closes the SSE stream without a final
`response.completed` — codex shows "stream disconnected before completion:
stream closed before response.completed".

litellm's model_info.max_output_tokens cap only affects what /v1/models
advertises; it is never clamped onto the outgoing request (the built-in
get_modified_max_tokens clamp only runs when litellm.modify_params is True, and
even then depends on get_max_tokens resolving the model). This pre-call
deployment hook enforces the cap directly on the request kwargs right before the
provider call. Registered via `litellm_settings.callbacks` in config.yaml;
module is mounted at /app/clamp_output.py.
"""

from litellm.integrations.custom_logger import CustomLogger

# DeepSeek window (1,048,576) - codex auto_compact_token_limit (950,000) leaves
# a ~33k margin at worst-case pre-compaction input. Matches model_info
# max_output_tokens in config.yaml.
MAX_OUTPUT_TOKENS = 65536


class ClampOutput(CustomLogger):
    async def async_pre_call_deployment_hook(self, kwargs, call_type):
        for key in ("max_tokens", "max_output_tokens"):
            value = kwargs.get(key)
            if isinstance(value, int) and value > MAX_OUTPUT_TOKENS:
                kwargs[key] = MAX_OUTPUT_TOKENS
        return kwargs


# litellm's get_instance_fn returns the module attribute as-is and drops it into
# litellm.callbacks, then calls hooks on it — so it must be an INSTANCE, not the
# class (an unbound class makes hook calls fail with "missing self"). Reference
# this in config.yaml as `clamp_output.clamp_output`.
clamp_output = ClampOutput()
