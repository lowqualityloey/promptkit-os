# Design System Workflow (Modern UI/UX & Component Architecture)

## Fast Shorthand
Trigger anytime with: `pk:design` (or `/pk-design`)

## Mission
Guide the developer in designing, engineering, and auditing production-grade, human-crafted UI/UX architectures. Standardize **Design Tokens**, accessible interaction contracts, anti-slop aesthetic discipline, responsive mobile reflow, compositor-friendly motion, and WCAG 2.2 Level AA compliance.

---

## Requirement Over Implementation

`pk:design` MUST specify the required UX, accessibility, visual, responsive, and behavioral outcome. It MUST NOT prescribe an implementation stack. Resolve the project's stack first (see `./PROMPTKIT.md`): React, Radix UI, React Aria, CVA, and Tailwind appear in this workflow as labeled **implementation examples** for React + Tailwind projects — never as mandatory dependencies. Port every example to the project's own stack (e.g., semantic HTML plus the project's CSS in an Astro project) while preserving the stated contract.

---

## The 5-Layer UI Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│               MODERN UI COMPONENT ARCHITECTURE              │
├─────────────────────────────────────────────────────────────┤
│ 1. Design Tokens & Aesthetic Foundation Layer               │
│    (Brand palette, semantic aliases, type clamp, radii)     │
├─────────────────────────────────────────────────────────────┤
│ 2. Accessible Interaction Layer (stack-agnostic)            │
│    (Semantic HTML + headless primitives — e.g. Radix UI /   │
│     React Aria — for focus-visible, ARIA, focus traps)      │
├─────────────────────────────────────────────────────────────┤
│ 3. Style & Variant Layer (project styling system)           │
│    (e.g. Tailwind CSS v4 + CVA; compositor-only motion)     │
├─────────────────────────────────────────────────────────────┤
│ 4. Composable Component Layer (project framework idioms)    │
│    (e.g. Radix Slot asChild, ternaries, derived state)      │
├─────────────────────────────────────────────────────────────┤
│ 5. Mobile Ergonomics & Responsive Reflow Layer              │
│    (~44px tap targets, min-w-0 flex, dvh, safe-area insets) │
└─────────────────────────────────────────────────────────────┘
```

---

## Preconditions
- Developer is building or refactoring UI components, a design system, or user interaction flows.
- Access to `.promptkit/templates/design-tokens-spec.md`.
- Review project profile in `./PROMPTKIT.md` (if present) for brand identity and styling stack — resolve the project's implementation stack here before any component work (see **Requirement Over Implementation**).

---

## Visual Mockup & Figma Ingestion Pipeline

When translating visual assets from design tools (Figma, Sketch, Penpot, or screenshot mockups), treat the mockup as an aesthetic specification, not as executable code. Never let an AI agent naively dump pixel-fixed JSX with hardcoded hex codes.

### 1. Supported Input Modalities
- **Visual Mockup / Screenshot**: Pasting UI screenshots directly into the prompt.
- **Figma Dev Mode / Layout Inspection**: Auto-layout properties (direction, padding, item gaps, alignment constraints).
- **Design Tokens / Variables**: Exported Figma Variables, Tokens Studio JSON, or CSS custom properties.
- **Direct MCP Integration**: Querying nodes and style properties via a Figma MCP server.

### 2. The 4-Stage Ingestion Sequence
```text
┌─────────────────────────────────────────────────────────────┐
│                 FIGMA-TO-CODE INGESTION PIPELINE            │
├─────────────────────────────────────────────────────────────┤
│ 1. Token Extraction     ──> Update DESIGN.md & CSS variables│
│    (Zero hardcoded hex codes; map to semantic token aliases)│
├─────────────────────────────────────────────────────────────┤
│ 2. Layout Translation   ──> Auto-Layout to semantic Flex/Grid│
│    (Direction, gaps, alignments -> responsive Tailwind/CSS) │
├─────────────────────────────────────────────────────────────┤
│ 3. Architecture Mapping ──> 5-Layer UI Component Tree       │
│    (Headless Radix/Aria + CVA variants + Slot composability)│
├─────────────────────────────────────────────────────────────┤
│ 4. Blindspot Remediation──> Reflow, Skeletons & Tap Targets │
│    (Audit mobile stacking, ≥44px targets, loading/empty)    │
└─────────────────────────────────────────────────────────────┘
```

### 3. Mockup Blindspot Remediation Checklist
Figma frames are static desktop or mobile snapshots that frequently omit critical engineering realities. Always remediate these 5 blindspots before writing component code:
1. **Responsive Reflow over Fixed Widths**:
   - Replace static pixel widths (e.g., `w-[384px]`, `w-[1200px]`) with fluid containers (`w-full max-w-md mx-auto`) and collapsible flex/grid layouts.
   - Collapse horizontal navigation or multi-column grids into single-column flows on small viewports.
2. **Touch Targets (~44×44px target; 24×24px AA floor)**:
   - Designers frequently draw compact $16\text{px}$–$24\text{px}$ icons or links. Give primary interactive controls a practical hit area of ~$44 \times 44\text{px}$ using padding or invisible touch expanders (`min-h-[44px] min-w-[44px]`); WCAG 2.2 AA's floor (SC 2.5.8) is $24 \times 24\text{px}$ with spacing/equivalent/inline exceptions — inline text links are not required to become 44px boxes.
3. **Async Content Resilience**:
   - Figma mockups only show the happy data state. Author content-shaped loading skeletons, empty states with clear calls to action, and error recovery banners.
4. **Accessible Interaction States**:
   - Add keyboard `:focus-visible:ring-2` focus rings, Escape key dismissal, and explicit `aria-label` attributes on icon-only buttons.
5. **Text Truncation & Overflow Safeguards**:
   - Add `min-w-0` to flex/grid containers and use `truncate` or `line-clamp-*` to prevent long dynamic content from blowing out the layout.

### 4. Design Study Protocol (`pk:design study <url | screenshot>`)

When inspired by an existing product or visual reference, extract its design DNA rather than copying pixels:
1. **Inspect Macrostructure & Rhythm**: Identify hero archetype, navigation model, and section surface banding. Refuse repeating identical layout cards.
2. **Extract Typography Roles**: Identify distinct display, body, and tabular numeral roles. Refuse using a single generic sans-serif for all roles.
3. **Derive Color Bands & Signal Accent**: Map surface paper/background, border hairlines, and isolate the single $\le 5\%$ accent hue.
4. **Export Portable `DESIGN.md`**: Emit a project-root `DESIGN.md` declaring tokens, typography pairing, and chosen Iconify family so any agent builds against it.

---

## Design Ceremony Tiers (D0–D3)

Before any design work, resolve the design ceremony tier. This is `pk:design`'s analogue of routing levels: minimum sufficient procedure, escalated only when risk requires it — D-level is not determined solely by change size.

- **D0 — Micro**: spacing, color, typography tweak, small visual correction. Apply the relevant rule directly (tokens, states, contrast); no study, no tokens artifact beyond a note in the target file.
- **D1 — Component**: a button, card, nav item, form field, interactive element. Steps for the touched surfaces (states, touch targets, a11y); no full-surface reflow audit.
- **D2 — Surface**: a page, responsive layout, form flow, navigation system, major section. Full relevant steps plus mobile reflow, content states, and the UI Delivery Gate Checklist.
- **D3 — System**: design system, theme architecture, major UX restructuring, accessibility overhaul, cross-surface redesign. Full workflow: study protocol, tokens artifact in `./docs/design/`, and the gate checklist.

Escalate D0→D1→D2→D3 when risk requires it (a11y impact, cross-surface reach, new interactive patterns); never downgrade a D3 need to ceremony savings.

---

## Workflow Steps

### Step 1: Tactile Aesthetic Foundations & Anti-Slop Discipline

1. **Tactile Canvas & The "Paper" Rule (`antislop-ui`)**:
   - **No Pure Extremes**: Never default to raw `#000000` pitch black or sterile `#ffffff` blinding white.
   - **Engineered Paper Grounds**: Light mode sits on calm, tinted paper (`oklch(96–98.5% 0.005–0.015 <anchor hue>)`). Dark mode sits on deep tinted obsidian or graphite (`oklch(13–16% 0.008–0.015 <anchor hue>)`).
   - **Tint the Neutrals**: Neutrals must carry a subtle chroma trace of the anchor hue in both themes. If the anchor is warm terracotta, neutrals lean warm espresso; if cobalt, they lean cool graphite.
   - **Hairlines Over Blur**: Depth comes from 1px ruler-drawn borders (`--color-rule`), not heavy drop shadows (`shadow-2xl`) or washed-out glassmorphism blur (`backdrop-blur`). Everything sits matte.
   - **Elevation in Dark Mode**: Elevated cards and dialogs sit `+3% to +5%` lighter than the base canvas (`oklch(17%)` over `oklch(13%)`) with a 1px hairline border. Surfaces never sit darker than the canvas.

2. **The 5% Signal Rule**:
   - Limit saturated accent color to **less than 5% of any viewport**.
   - Accents are optical **signals** (active tab tick, focus ring, primary action button, status badge), never decorative background washes or rainbow gradients.

3. **Macrostructure & Layout Rhythm Variety**:
   - **Break the Generic Rut**: Refuse the automatic AI template (`Hero + Badge ──> 3 Bento Cards ──> Fake Logos ──> Pill CTA ──> 4-col Footer`).
   - **Refuse Uniform Bento Grids**: Do not generate pages with uniform repeating card grids (e.g. 6 identical floating boxes). Introduce layout rhythm: alternating full-bleed surface bands, asymmetric feature spotlights, and varied card column spans.
   - **Curated Non-Slop Iconify Families**: Recommend human-crafted sets via Iconify (`ph:*` Phosphor for modern fintech/SaaS, `radix-icons:*` for 15px micro-density, `tabler:*` for sharp enterprise). Never accept the framework's default icon set without a deliberate single-family choice — including Lucide, which is acceptable only as a curated project-wide pick, never as an unconsidered default that reproduces the recognizable AI template aesthetic.
   - Diversify section rhythms based on the product's genre:
     - *Asymmetric Split*: Left-aligned punchy headline + right-aligned interactive artifact (working terminal or API demo).
     - *Editorial Magazine*: Asymmetric columns, rich pull-quotes, and generous whitespace.
     - *Dense Workbench*: Sticky side-rail navigation, tabular data strips, and monospace telemetry.

4. **Honest Copy — Zero Fabricated Social Proof**:
   - **Never Invent Metrics**: AI claims like *"+47% conversion"*, *"trusted by 50,000+ teams"*, or fake logo bars are slop the moment they are invented.
   - If the user did not provide real metrics, use authentic qualitative descriptions, placeholders (`"—"`, `[metric to confirm]`), or select a layout that does not rely on metric counters.

5. **Banned Subtle AI Tells**:
   - **No Italic Titles**: Headings and display titles must stay roman/upright (`font-style: normal`). Italicized buzzwords (`Built to <em>think</em>`) are an unmistakable AI tell. Express emphasis through font weight or color.
   - **No Hand-Drawn Fake Chrome**: Never draw fake browser address bars (URL pills with red/yellow/green traffic-light dots) or fake phone frames. Real screenshots sit matte in a clean `<figure>` with a 1px hairline border.
   - **No Uniform Pill Syndrome**: Use intentional geometric radii (`rounded-md` or `rounded-lg`). Reserve `rounded-full` strictly for avatar circles and status dots.

6. **Dual-Mode Theme Presets**:
   - **Preset A: Cobalt Dev-Tool (Cool Technical Register)**:
     - *Light*: Canvas `oklch(98.5% 0.004 250)`, Ink `oklch(22% 0.016 258)`, Hairline `oklch(88% 0.008 250)`, Signal Cobalt `oklch(56% 0.22 256)`.
     - *Dark*: Canvas `oklch(14% 0.010 255)`, Card `oklch(18% 0.012 255)`, Ink `oklch(93% 0.006 255)`, Signal Cobalt `oklch(65% 0.21 256)`.
   - **Preset B: Hum Warm Editorial (Artisanal Humanist Register)**:
     - *Light*: Canvas `oklch(97% 0.012 80)`, Ink `oklch(20% 0.015 65)`, Hairline `oklch(86% 0.010 80)`, Signal Terracotta `oklch(58% 0.18 45)`.
     - *Dark*: Canvas `oklch(15% 0.012 60)`, Card `oklch(19% 0.014 60)`, Ink `oklch(92% 0.008 75)`, Signal Terracotta `oklch(68% 0.17 50)`.

7. **Zero-Byte Native System Font Stacks**:
   - **No Mandatory Font Bundles**: External web font downloads are never required. Rely on zero-latency native system font stacks:
     - `--font-sans`: `system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`
     - `--font-mono`: `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', monospace`
     - `--font-serif`: `ui-serif, Georgia, Cambria, 'Times New Roman', serif`
   - **Mandatory Typographic Craft**:
     - `font-variant-numeric: tabular-nums` on all metrics, counters, and tables to prevent horizontal jitter.
     - `text-wrap: balance` or `text-pretty` on all headings to eliminate single-word widows.
     - `leading-relaxed` (minimum 1.5 line-height) on body copy.
     - Real typographic punctuation (`…`, curly quotes `“”`, non-breaking spaces `&nbsp;`).

8. **Universal Icon Directory & Standards via Iconify**:
   - **Authoritative Catalog**: Designate [Iconify](https://icon-sets.iconify.design/) as the universal directory to verify exact icon names and clean SVG paths without forcing `@iconify/react` as an npm dependency.
   - **Single-Family Consistency**: Pick exactly one primary icon family per project (e.g. Lucide for modern minimal, Radix for dense tools, Phosphor for warm editorial). Never mix mismatched line weights in the same view.
   - **Brand & Tech Marks**: Use Iconify's `simple-icons` collection for third-party brand marks (GitHub, Stripe, Docker, Figma, PostgreSQL) rather than hand-drawing distorted paths.
   - **Sizing & Inheritance**: Standardize sizes (`14px`, `16px`, `20px`), use `currentColor` for automatic theme/hover inheritance, and give icon hit areas ~$44 \times 44\text{px}$ where practical (AA floor $24 \times 24\text{px}$, SC 2.5.8).

---

### Step 2: Accessibility & Interaction Parity

1. **Headless Primitives (stack-resolved)**:
   - Build composite widgets (modals, dropdowns, comboboxes, tabs, tooltips) on battle-tested headless primitives — Radix UI, React Aria, or Ark UI in React projects; the equivalent accessible library or pattern in other stacks — to inherit correct focus trapping, screen reader announcements, and portal rendering. Where a stack offers no equivalent, implement the interaction contract (focus trap, ARIA attributes, Escape handling) directly on semantic HTML.

2. **Focus State Discipline**:
   - **Never use `outline-none` without an immediate replacement**: Always pair with `:focus-visible:ring-2` (e.g., `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-primary`).
   - Use `:focus-visible` over `:focus` to ensure focus rings only appear during keyboard navigation, not on mouse clicks.
   - Group compound controls using `:focus-within`.

3. **Keyboard Navigation & Hit Parity**:
   - `Tab` / `Shift+Tab`: Natural logical navigation order.
   - `Enter` / `Space`: Activation of buttons, toggles, and checkboxes.
   - `Arrow Keys`: Navigation within composite widgets (menus, dropdowns, tabs, segmented controls).
   - `Escape`: Closes open dialogs, tooltips, and popovers, returning focus to the triggering element.
   - **Hover-to-Tap Parity**: Mobile screens have no hover. Every hover reveal or tooltip must have a tap equivalent and visible `:active` feedback.

4. **ARIA & Semantic HTML Standards**:
   - Use semantic HTML tags first (`<button>`, `<main>`, `<dialog>`, `<table>`, `<nav>`) before reaching for ARIA.
   - Strict element semantics: `<button>` for actions/mutations; `<a>` or `<Link>` for navigation. **Never `<div onClick>`**.
   - **Icon-Only Buttons**: Any button containing only an icon (`<button><TrashIcon /></button>`) **must** include an explicit `aria-label="Delete item"`.
   - **Decorative Icons**: Icons paired with visible text must include `aria-hidden="true"`.
   - **Live Regions**: Dynamic async notifications (toasts, inline form validation) must declare `aria-live="polite"`.

5. **Applicability-Based Interactive State Contract**:
   - Every interactive component must explicitly implement and style all states **applicable to its role** — not a blanket list. Generally applicable: `default`, `:focus-visible`. Pointer-interactive elements add `hover`, `:active`. Disableable controls add `disabled`. Async/stateful controls (submit buttons, save actions, validated form fields) add `loading`, `error`, `success`. A textual navigation link, for example, owes only `default` and `:focus-visible`. The catalog below defines each state:
     1. **`default`**: Rested baseline presentation on the matte paper or card surface.
     2. **`hover`**: Perceptible contrast adjustment (`hover:bg-primary/90` or subtle border shift).
     3. **`:focus-visible`**: Crisp keyboard navigation ring (`focus-visible:ring-2 focus-visible:ring-offset-2`).
     4. **`:active`**: Physical press compression (`active:scale-[0.98]`).
     5. **`disabled`**: Reduced opacity and event isolation (`disabled:opacity-50 disabled:pointer-events-none`).
     6. **`loading`**: Content-shaped skeleton or spinner with text announcement (`aria-busy="true"` and `"Saving…"`).
     7. **`error`**: Destructive border ring (`border-danger`) with actionable error remediation text.
     8. **`success`**: Brief affirmative state transition (e.g., checkmark confirmation).

---

### Step 3: Form Ergonomics & Input Hygiene

1. **Never Block Paste**: Never intercept `onPaste` with `preventDefault()`. Users rely on password managers and verification code pasting.
2. **Input Types & Autocomplete**:
   - Specify accurate `type` (`email`, `tel`, `url`, `number`) and `inputmode` (`numeric`, `decimal`).
   - Include standard `autocomplete` attributes (`email`, `username`, `current-password`, `new-password`, `tel`).
   - Set `spellCheck={false}` on emails, codes, and usernames.
3. **Continuous Hit Targets**:
   - Checkboxes and radio buttons must share a single, unbroken hit target with their labels (no dead zones between box and text).
4. **Error Recovery**:
   - Display errors inline beside the offending field with clear remediation instructions.
   - Focus the first invalid field upon form submission failure.

---

### Step 4: Component Variant Architecture & Runtime Performance (React example)

1. **Type-Safe Variants — React + CVA implementation example**: the following is one idiomatic implementation for a React + Tailwind project; port the variant, focus-visible, disabled, and press contract to the project's own styling system:
   ```typescript
   import * as React from 'react';
   import { cva, type VariantProps } from 'class-variance-authority';
   import { Slot } from '@radix-ui/react-slot';

   export const buttonVariants = cva(
     'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 min-h-[44px] px-4 py-2 select-none active:scale-[0.98]',
     {
       variants: {
         variant: {
           primary: 'bg-primary text-primary-foreground hover:bg-primary/90',
           secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
           outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
           ghost: 'hover:bg-accent hover:text-accent-foreground',
           destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
         },
         size: {
           sm: 'min-h-[44px] h-11 px-3 text-xs',
           md: 'min-h-[44px] h-11 px-4 text-sm',
           lg: 'min-h-[48px] h-12 px-6 text-base',
           icon: 'min-h-[44px] min-w-[44px] h-11 w-11 p-0',
         },
       },
       defaultVariants: {
         variant: 'primary',
         size: 'md',
       },
     }
   );

   export interface ButtonProps
     extends React.ButtonHTMLAttributes<HTMLButtonElement>,
       VariantProps<typeof buttonVariants> {
     asChild?: boolean;
   }

   export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
     ({ className, variant, size, asChild = false, ...props }, ref) => {
       const Comp = asChild ? Slot : 'button';
       return (
         <Comp
           className={buttonVariants({ variant, size, className })}
           ref={ref}
           {...props}
         />
       );
     }
   );
   Button.displayName = 'Button';
   ```

2. **Rendering Discipline — React example (`vercel-react-best-practices`)**: applies when the project's stack is React:
   - **Ternary Conditionals**: Always use `condition ? <Component /> : null` instead of `condition && <Component />` to prevent accidental `0` DOM renders.
   - **Derived State During Render**: Calculate filtered lists, selected items, and derived state directly in the render body. Do not duplicate state inside `useEffect`.
   - **No Inline Component Declarations**: Never define helper components inside the render scope of another component (causes unmount/remount loops and lost focus).
   - **Non-Urgent Transitions**: Use `useTransition` / `startTransition` for tab switches and filter changes so text input and button clicks remain immediately responsive.

---

### Step 5: Mobile Ergonomics & Responsive Reflow (`antislop-layoutmobile`)

1. **Reflow over Shrinking**:
   - **Core Principle**: *"Mobile layout is a different layout, not desktop squeezed into a phone."*
   - Multi-column grids must collapse and stack into single-column reflowing flows at narrow viewports rather than squeezing content into unreadable slivers.
   - Breakpoints must be placed where content breaks, not based on arbitrary device model dimensions.

2. **Touch Targets (~44×44px target; 24×24px AA floor)**:
   - Every primary interactive target (buttons, icons, toggles, controls) should provide ~**$44 \times 44\text{px}$** of usable hit area where practical — even if the visual icon inside is smaller; WCAG 2.2 AA (SC 2.5.8) floors at $24 \times 24\text{px}$ with spacing/equivalent/inline exceptions, so inline text links are exempt.
   - Maintain at least $8\text{px}$ spacing between adjacent touch targets so thumbs never mis-tap.

3. **Prevent Horizontal Scroll Leaks**:
   - Flex and Grid children must include `min-w-0` to allow text truncation (`truncate`, `line-clamp-*`) without forcing parent container blowout.
   - All images, canvas, and video elements must include `max-w-full h-auto`.
   - Tables on mobile must either scroll within an isolated container (`overflow-x-auto`) or reflow into card lists.

4. **Dynamic Viewport Height & Safe Areas**:
   - Use `dvh` (e.g. `min-h-dvh`, `h-dvh`) instead of `100vh` to prevent jumping when mobile browser URL bars appear or hide.
   - Fixed bottom navigation bars and sticky headers must reserve space for content and respect safe-area insets:
     ```css
     padding-bottom: max(1rem, env(safe-area-inset-bottom));
     ```

---

### Step 6: Motion & Compositor-Friendly Transitions

1. **Compositor-First Motion**:
   - Prefer animating `transform` and `opacity` — they avoid browser layout recalculation and jank.
   - `color`, `background-color`, and `border-color` transitions are permitted for interaction feedback (e.g., `transition-colors duration-150 ease-out`).
   - **Never animate layout-affecting properties** (`width`, `height`, `margin`, `padding`, `top`, `left`).
   - **Never use `transition: all`**: explicitly declare transitioned properties (e.g., `transition-colors duration-150 ease-out`, `transition-transform duration-200`).

2. **Respect `prefers-reduced-motion`**:
   - Always provide a reduced-motion fallback:
     ```css
     @media (prefers-reduced-motion: reduce) {
       *, *::before, *::after {
         animation-duration: 0.01ms !important;
         animation-iteration-count: 1 !important;
         transition-duration: 0.01ms !important;
       }
     }
     ```
   - Avoid endless, un-prompted pulsing or floating loops. Motion must guide user focus, not act as distracting wallpaper.

---

### Step 7: Content Resilience & Empty States

Ensure all async components support the 4 fundamental UI states with meaningful messaging:
1. **Loading State**: Content-shaped skeleton loaders matching the exact dimensions of final content (not generic spinners).
2. **Empty State**: Explain *why* the view is empty and provide the single primary action button to populate it (e.g., `"No books in your library yet. Browse the catalog to add your first book."`).
3. **Error State**: Actionable recovery message with a `"Retry"` trigger.
4. **Success / Data State**: Fluid rendering with optimistic UI updates where appropriate.

### Step 8: Emit Design Tokens Artifact
Persist the decisions from Steps 1–7 using `templates/design-tokens-spec.md`, saved to `./docs/design/YYYY-MM-DD-design-<surface>.md`. A run that produces no artifact file has produced no durable output — chat-only guidance does not count as delivery.

---

## Completion Criteria
- Design tokens artifact generated in `./docs/design/` from `templates/design-tokens-spec.md`.
- Every interactive element meets the applicability-based state contract and practical touch-target guidance (~44×44px primary targets; 24×24px AA floor).
- Exactly one icon family selected deliberately and applied consistently.
- UI Delivery Gate Checklist below passes without exceptions.

---

## No-DESIGN.md Visual Floor

When no `DESIGN.md` exists, UI work still ships finished — restraint plus a defined minimum (propose accept-or-change, never impose):

- **Curated Aesthetic Archetypes**: Propose one of four human-crafted archetypes rather than defaulting to an unstyled monochrome void:
  1. *Warm Paper / Editorial*: Parchment surface `oklch(97% 0.012 95)` (`#faf6ee`), `Plus Jakarta Sans` + `JetBrains Mono`, mint/pear/terracotta signal chips.
  2. *High-Density Fintech*: Rich slate `oklch(15% 0.015 250)` (`#0f1115`), `Inter` / `Geist` + tabular numerals, `Radix 15px` (`radix-icons:*`) or `Phosphor Light` (`ph:*-light`), emerald status indicators.
  3. *Clean Modern SaaS*: Crisp neutral white/zinc, bold geometric headings, single saturated $\le 5\%$ accent.
  4. *Dark Terminal*: Monochrome dark graphite, high-contrast 1px hairlines, pure monospace / technical grotesque, zero decorative noise.
- **One icon family**: the Iconify single-family rule applies as a requirement, not guidance — every view gets its icon pass (no mixed weights). Prefer curated human sets (`ph:*`, `radix-icons:*`, `tabler:*`) over generic Lucide. Icons must have a functional or navigational purpose; never add icons merely to fill visual space — text-only controls and navigation links are complete without icons.
- **Tabular figures**: `tabular-nums` on all metrics, counters, and tables.
- **Favicon**: every shipped page declares a favicon derived from a stated rule (e.g. first letterform of the wordmark on the primary token, or the primary action glyph); no blank-tab default ships (never leave framework default favicons like Next.js triangle).
- **One type pairing, proposed**: a single accept-or-change pairing (display + body, with 2026-era rationale); the system stack remains the default unless explicitly accepted.
- **21st.dev catalog (React + Tailwind only, advisory)**: the agent may propose specific components with links as a taste source; each proposal needs human approval and must inherit project tokens and pass the a11y, single-family, and license gates. Free components only unless the human buys. Excluded: CLI/MCP install paths, templates-as-starters, offline reliance, blanket trust. Offline or out-of-scope stacks fall back to system defaults.

---

## 📋 UI Delivery Gate Checklist

Before marking any UI task complete, verify all criteria pass:

- [ ] **Visual Floor Enforced**: Replaced default framework tab favicon (no blank-tab or Next.js triangle default); applied a single Iconify family across all interactive controls.
- [ ] **Aesthetic Craft**: Palette is derived from brand identity; no generic blue/purple AI gradients, no decorative emoji, and glass/glow is limited to 1–2 elements.
- [ ] **Contrast Compliance**: Normal text passes $\ge 4.5:1$ and large text/UI controls pass $\ge 3.0:1$ in both light and dark themes.
- [ ] **Focus Replacement**: No `outline-none` without an immediate `:focus-visible:ring-2` replacement.
- [ ] **Accessible Icon Buttons**: Every icon-only button includes an `aria-label`; decorative icons have `aria-hidden="true"`.
- [ ] **Semantic Elements**: Buttons use `<button>`, links use `<a>`/`<Link>`; zero `<div onClick>`.
- [ ] **Form Hygiene**: Paste is never blocked; fields have `autocomplete`, shared hit targets, and inline error recovery.
- [ ] **Touch Targets**: Primary interactive targets provide ~$44 \times 44\text{px}$ hit area where practical (AA floor $24 \times 24\text{px}$, SC 2.5.8; inline text links exempt) with adequate finger spacing.
- [ ] **Mobile Reflow**: Zero horizontal scroll leaks (`min-w-0` on flex/grid children), viewport uses `dvh`, and bottom nav respects safe-area insets.
- [ ] **Compositor-First Motion**: Never animate layout-affecting properties; `transform`/`opacity` preferred, `color`/`background-color`/`border-color` permitted for feedback; no `transition: all`; `prefers-reduced-motion` honored.
- [ ] **React Performance**: Conditionals use ternary (`? : null`); derived state is computed during render; no nested inline components.
- [ ] **Figma Blindspots Remediated**: Static pixel widths replaced with fluid reflow, ~44×44px touch targets verified, and loading skeletons / empty states implemented.
- [ ] **Applicability-Based State Contract**: Interactive components explicitly implement all states applicable to their role (default + focus-visible universally; hover/active for pointer-interactive; disabled when disableable; loading/error/success for async/stateful controls).
- [ ] **Honest Copy**: Copy contains zero fabricated metrics, fake customer counts, or invented social proof.
- [ ] **5% Signal Accent**: Saturated accent is confined to $<5\%$ of viewport area; no decorative gradient floods.
- [ ] **Typography & AI Tells**: Headings are upright (no italic titles); `tabular-nums` enabled on data/counters; no hand-drawn browser chrome.
- [ ] **Single Icon Family**: All UI icons derive from a single cohesive set via Iconify (`simple-icons` for tech marks).
- [ ] **Favicon Declared**: Every shipped page has a favicon per the stated rule; no blank-tab default.
- [ ] **Type Pairing Resolved**: One pairing proposed-and-accepted, or explicitly waived with the system stack.
- [ ] **Third-Party Components Vetted**: Each catalog component inherits tokens and passes a11y, single-family, and license gates with human approval evidenced.
