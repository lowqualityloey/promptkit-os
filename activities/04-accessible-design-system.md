# Activity 04: Engineering an Accessible, Tokenized Design System

## Overview
Design and implement a production-grade, accessible UI component primitive library featuring dark/light tokenized themes, headless accessibility (Radix UI / React Aria), Class Variance Authority (CVA), responsive container queries, and full WCAG 2.2 Level AA compliance.

---

## Challenge Scope

Build a core set of compound, polymorphic UI components:
1. **Modal Dialog / Sheet (`<Dialog />`)**:
   - Focus trap management.
   - Screen reader announcement on open/close (`aria-modal`, `aria-labelledby`, `aria-describedby`).
   - Backdrop blur, animated entrance/exit with `prefers-reduced-motion` support.
   - Restores focus to original trigger element on `Escape` key or backdrop click.
2. **Accessible Combobox / Autocomplete (`<Combobox />`)**:
   - Keyboard arrow navigation through filtered options.
   - `aria-activedescendant` state tracking.
   - Asynchronous debounced search with loading skeleton and empty state.
3. **Data Table with Column Sorting & Pagination (`<DataTable />`)**:
   - Keyboard accessible sort headers with `aria-sort="ascending|descending"`.
   - Responsive container query card layout on small container widths.

---

## Simulation Steps

### Step 1: Define Design Tokens (`pk:design`)
1. Activate `pk:design`.
2. Define primitive and semantic CSS variables for Slate Neutral, Brand Accent, Surface Card, and Destructive states.
3. Verify color contrast ratios meet WCAG 2.2 Level AA ($4.5:1$ text, $3.0:1$ UI controls).

### Step 2: Implement Component Variants with CVA
1. Build reusable variant definitions for Buttons, Badges, and Dialog sizes.
2. Ensure strict TypeScript prop type safety.

### Step 3: Integrate Headless Primitives
1. Wrap Radix UI or React Aria primitives into composable, clean components.
2. Ensure polymorphic rendering (`asChild` pattern) is supported so components can render as Next.js `<Link>` or native `<button>`.

### Step 4: Audit Accessibility & Keyboard Controls (`pk:review`)
1. Execute keyboard-only walkthrough: Tab, Shift+Tab, Arrows, Space, Enter, Escape.
2. Run automated a11y tests using `@axe-core/react` or Playwright `axe-playwright`.

### Step 5: Document Component Guidelines
1. Record component usage examples and token references in the host-owned `./docs/design/design-tokens-spec.md`, scaffolded from the read-only kit source `<kit>/templates/design-tokens-spec.md`.

---

## Success Criteria
- [ ] Zero automated axe-core accessibility violations.
- [ ] 100% keyboard navigable with visible, high-contrast focus rings.
- [ ] Fully responsive with container queries and fluid typography.
- [ ] Dark and Light theme tokens switch seamlessly with zero layout shift.
