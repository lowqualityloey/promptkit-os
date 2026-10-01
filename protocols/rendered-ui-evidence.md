# Rendered UI Evidence Protocol

## Purpose

Define the browser evidence required to verify browser-rendered UI. Load this
protocol for UI implementation, responsive changes, visual audits, or UI fixes.
Use it with the applicable design workflow and `protocols/code-quality-gate.md`.
This is an evidence contract, not a required browser vendor or test framework.

## Proportionate browser coverage

Drive the running application through its real browser surface. Match coverage
to the change:

- A copy or isolated style change may need one focused route, viewport, and
  state.
- A component change covers its affected routes and relevant states.
- A shared shell, navigation, typography, token, or responsive change covers
  each route and viewport it can affect.
- A new page or flow covers each new route and its main user outcomes.

For responsive work, inspect narrow, intermediate, and wide viewports. Use 375, 768, and 1280 CSS pixels as starting points unless project breakpoints or
content need different widths. Record actual viewport dimensions. A browser
viewport is not evidence of native mobile behavior; native apps need checks on
their native surface and device sizes.

## What to observe

For each affected route and scenario, observe and record:

1. **Reachability:** primary navigation works at each checked size. Detail
   pages have a usable return path where relevant.
2. **Visibility and reflow:** required text and controls remain visible or
   reachable. Inspect screenshots and element bounds, including descendants of
   `overflow-hidden` and scroll containers. Check both document overflow and
   nested clipping; `scrollWidth` equal to the viewport does not rule out
   clipped content.
3. **Relevant states:** exercise entry, validation, submission, pending,
   success, failure, and recovery where applicable. State which checks do not
   apply. For money and measurement fields, verify the displayed unit matches
   the value users enter. For settings, verify persistence or clearly visible
   non-persistent status.
4. **Keyboard and accessibility:** operate changed controls with a keyboard
   and observe visible focus. Measure rendered contrast against the actual
   background: at least 4.5:1 for normal text, 3:1 for large text, and 3:1 for
   meaningful non-text controls and indicators where WCAG applies. A token or
   source checklist alone is not rendered evidence.

## Record and safety

Keep a concise evidence record with:

- routes and user-visible scenarios checked;
- actual viewport dimensions and relevant state for each capture;
- observed result and screenshot, browser output, or equivalent artifact link;
- any failure, unverified check, and specific reason.

Redact secrets and personal data from evidence. Use safe fixtures or
intercepted requests for workflows that could send messages, sign documents,
charge money, or cause other external effects. Do not trigger those effects
only to complete UI verification.

## Unavailable browser evidence

If a real browser, running app, or safe test data is unavailable, record **Not verified**, explain the limitation, and identify any human follow-up. Do not claim that the rendered UI gate passed or that UI work is fully verified.
Passing typechecks, builds, static checks, or source review does not imply
rendered UI verification. Continue independent work that can be completed
safely; this limitation applies to the UI verification claim, not unrelated
engineering checks.

## Regression review scenarios

Use these cases when reviewing changes to this protocol. They are manual
contract checks because the protocol governs browser observations and agent
reporting, which this repository's static test harness cannot execute.

| Case | Review setup | Required outcome |
| --- | --- | --- |
| Missing browser evidence | A UI change has passing static checks but no browser run or rendered evidence record. | Report the UI as **Not verified**; do not imply the UI gate passed. |
| Browser tooling unavailable | The app, browser, or safe fixture cannot be used. | Record the precise limitation and follow-up; keep unrelated checks separate from the UI claim. |
| Clipped control | The document width matches the viewport, but a required control may be clipped inside a nested container. | Inspect descendant bounds and rendered evidence; do not treat matching `scrollWidth` as proof that the control is visible. |
| Scope proportionate to change | Compare an isolated copy/style edit with a shared responsive shell change. | Use a focused route/state for the isolated edit; cover affected routes and narrow/intermediate/wide viewports for the shared change, recording actual dimensions. |
