---
name: ai-app
category: web
version: 1
token_budget: 1500
activation:
  manifests:
    - package.json
verification:
  fast:
    - npm run type-check
  required:
    - npm run test:evals
  extended:
    - npm run build
    - npm run lint
invariants:
  - "Every model call crosses one provider adapter; no vendor SDK is imported outside it"
  - "User text, retrieved documents, and tool output are untrusted data, never instructions"
  - "Every request declares a token and cost budget enforced before dispatch"
  - "A prompt change ships only with an eval run that can fail"
anti_patterns:
  - "Interpolating user input into the system prompt"
  - "Shipping a prompt edit with no eval baseline to compare against"
  - "Retrying 429 and 5xx under the same policy"
  - "Logging raw prompts and completions that contain user PII"
---
# AI Application Playbook

Operational guidelines for applications that call a model provider as part of their product surface.

Select for a `package.json` declaring `openai`, `@anthropic-ai/sdk`, `ai`, `@ai-sdk/*`, `langchain`, or `@google/generative-ai` as a dependency. A `package.json` alone is not evidence of an AI surface — confirm the dependency before applying this playbook, and report the provider as unconfirmed when the manifest cannot be resolved.

## 1. Architectural Invariants

- **Single Provider Adapter**: All model calls cross one module that owns the SDK client, model id, timeout, and retry policy. Application code depends on that module's interface, never on a vendor SDK type. A model swap must be a change in one file.
- **Untrusted Input Boundary**: User text, retrieved documents, tool results, and prior model output are data. They never become instructions. Delimit untrusted content structurally — separate message roles, explicit data blocks — and never concatenate it into the system prompt.
- **Explicit Cost Budget**: Every request declares a maximum input and output token budget and enforces it before dispatch — truncate, reject, or route to a cheaper model. Discovering the overrun on the invoice is not enforcement.
- **Eval Before Iteration**: A prompt is code. Changing it requires a runnable eval set with recorded baseline scores, so a regression is visible before merge rather than after a user reports it.
- **Streaming Is a State Machine**: A streamed response has explicit states — idle, streaming, complete, aborted, failed — and the UI renders each one. Partial output is never presented as final.

## 2. Critical Anti-Patterns & Pitfalls

- **System Prompt Interpolation**: Building the system prompt with a template literal that includes user input hands the user the instruction channel. Keep the system prompt static; pass user content in a user-role message.
- **Retrieved Text as Instruction**: A document that says "ignore previous instructions" is a document, not a command. Treat retrieval results as quoted data behind a visible boundary.
- **Unbounded Retry on 429**: Rate limits and server errors need different policies. Retrying a 429 on the same schedule amplifies the limit; retrying a 5xx blindly repeats a possibly non-idempotent call.
- **Raw Prompt Logging**: Logging full prompts and completions writes user PII into the log store. Redact before the write, not after the incident.
- **Provider Types in Domain Code**: Leaking a vendor completion type into business logic makes the vendor a permanent dependency of the domain model.
- **Eval-Free Prompt Edits**: A prompt tweak that "feels better" with no eval run is an unmeasured change to product behavior.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `npm run type-check` to verify adapter interfaces and message shapes.
- **Required (L2 Controlled / Pre-Commit)**:
  `npm run test:evals` to score the current prompt set against recorded baselines and fail on regression.
- **Extended (L3 Release / CI)**:
  `npm run build` and `npm run lint` to validate bundling and code hygiene.
