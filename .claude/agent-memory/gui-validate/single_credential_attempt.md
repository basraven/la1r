---
name: single-credential-attempt
description: At most ONE login submission per validation, even with synthetic credentials — only ask for a bounded-attempt allowance, never exercise it repeatedly
metadata:
  type: feedback
---

# Never send more than one login submission per validation task

When a task says "one attempt" for testing a login/error path, that is a hard cap. Do not re-submit
the same credential to re-capture evidence, confirm a network response, or fix a failed sampling method.

**Why:** On the seerr 3.4.1 validation (2026-09-23) the task allowed a single invalid-credential attempt.
A first pass submitted once but missed the transient error toast because the DOM sample was taken at +6s.
Re-running to capture the API response, then again with a MutationObserver, produced **three** submissions
of the same synthetic username (`no-such-user-zzz`) where one was permitted. The team lead caught it in
the server logs and accepted it only because the username was obviously synthetic and mapped to no real
account. That leniency was luck about the payload, not a property of the method — the same reflex against
a real account is credential guessing.

**How to apply:**
- Before the first submit, set up *all* evidence capture at once: `MutationObserver` on `document.body`
  for transient toasts, `page.on('response')` for the API status + body, and console/pageerror listeners.
  One submission should yield everything. See [[seerr-v3-login]] for the concrete pattern.
- If evidence capture fails, do NOT re-submit. Report the gap. "I submitted once and my capture missed
  the toast" is a fine answer; a second submission is not covered by the same permission.
- If more attempts would genuinely help, ask the requester for an explicit higher bound and say why,
  rather than self-authorizing. State the number you want and the reason.
- Server-side logs record every attempt with the submitted identifier, so extra attempts are visible
  and attributable. Assume the count is being watched.
