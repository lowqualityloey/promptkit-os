# Brand & Design Identity Specification (`DESIGN.md`)

> **Instructions for AI**: Read this file during every session. This document is the single source of truth for the project's visual identity, styling tokens, typography, surfaces, and anti-slop design guardrails. All UI code must conform to these rules.

---

## 1. Brand Essence & Visual Character
- **Product Name**: [e.g., Shelf / Acme Analytics]
- **Theme Preset**: [Custom | Cobalt Dev-Tool (Cool Technical) | Hum Warm Editorial (Artisanal Humanist)]
- **Brand Personality**: [e.g., Clean, industrial, high-signal, utilitarian, editorial]
- **Theme Default**: [Light theme default | Dark theme default | System auto with toggle]
- **Aesthetic Tone**: [Grounded matte surfaces, 1px ruler-drawn hairlines, generous whitespace, high contrast, zero unnecessary decoration]

---

## 2. Color Palette & Anti-Slop Guardrails
> 🚫 **Anti-Slop Rule**: Never use generic AI blue-to-purple / cyan gradients, rainbow glow backdrops, or neon pastel palettes. All colors must derive strictly from the tokens below.
>
> 💡 **The 5% Signal Rule**: Saturated accent color must occupy less than 5% of any viewport area. It is used strictly for optical signals (active tabs, focus rings, primary action buttons, status badges), never as a decorative background wash.
>
> 💡 **Figma / Design Tool Ingestion**: When extracting colors from Figma Variables, Tokens Studio, or Dev Mode, normalize them into the semantic tokens below. Never permit an AI assistant to paste raw arbitrary hex codes directly into JSX or CSS classes.

### Core Dual-Mode Color Tokens (Chromatic Tinting)
- **Paper & Ink (No Pure `#000` or `#fff`)**:
  - Background (Light Canvas): `oklch(96–98.5% 0.005–0.015 <anchor hue>)` [e.g., `#f8fafc` or `#fbfaf7`]
  - Background (Dark Canvas): `oklch(13–16% 0.008–0.015 <anchor hue>)` [e.g., `#0f172a` or `#181412`]
  - Surface Card (Light): Matte ground with 1px border
  - Surface Card (Dark): `+3% to +5%` lighter than dark canvas (`oklch(17–19%)`), never darker
  - Foreground / Ink (Light): `oklch(18–22% 0.015 <anchor hue>)` (Deep charcoal, not `#000`)
  - Foreground / Ink (Dark): `oklch(92–95% 0.006 <anchor hue>)` (Soft parchment, not harsh `#fff`)
  - Border Hairline: 1px mechanical rule (`oklch(86–90%)` light / `oklch(22–26%)` dark)
- **Brand Primary**: [e.g., Deep Forest Green `#1b4332`, Cobalt `#0055ff`, or Indigo `#4f46e5`]
- **Brand Secondary**: [e.g., Sage `#74c69d`, Slate `#64748b`, or Muted Graphite]
- **Deliberate Signal Accent**: [e.g., Electric Cobalt, Ochre Gold, or Terracotta]. **Used at key focal moments only (<5% of viewport).**
- **Semantic Feedback**:
  - Success: `#10b981` (Emerald)
  - Destructive / Error: `#e11d48` (Rose)
  - Warning: `#f59e0b` (Amber)

---

## 3. Typography Hierarchy & Zero-Cost Rules

### Zero-Byte Native System Font Stacks (Default)
External font downloads are not required. Modern system fonts provide zero-latency, zero-layout-shift rendering:
- **Heading / Display Font**: `system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`
  - Optional Web Pairing: Space Grotesk, Cabinet Grotesk, or Instrument Serif.
- **Body Font**: `system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`
  - Optional Web Pairing: Inter, Geist.
- **Code & Numeric Font**: `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', monospace`
  - Optional Web Pairing: JetBrains Mono, Fira Code.

### Mandatory Typographic Craft Rules
- **No Italic Titles**: Headings and display titles must stay roman/upright (`font-style: normal`). An italicized word inside a title (`Built to <em>think</em>`) is an unmistakable AI tell.
- **Tabular Numbers**: Mandatory `font-variant-numeric: tabular-nums` for timers, financial counters, and data tables to eliminate column jitter.
- **Balanced Headings**: Use `text-wrap: balance` or `text-pretty` to prevent orphan words (widows).
- **Body Readability**: Minimum 1.5 line height (`leading-relaxed`).
- **Punctuation Standard**: Always use real ellipsis (`…`), curly quotes (`“”`), and non-breaking spaces for units (`10&nbsp;MB`, `⌘&nbsp;K`).
- **Fluid Scaling**: Translate static desktop font sizes from Figma mockups into responsive `clamp()` rules (e.g., `text-[clamp(1.5rem,3vw,2.25rem)]`) rather than fixed pixel dimensions to ensure clean mobile reflow.

---

## 4. Surfaces, Radius & Elevation
- **Hairlines Over Blur**:
  - Depth is created via 1px crisp mechanical borders (`--border-hairline`), not blurred drop shadows.
  - Cards and list rows sit flat and matte.
- **No Hand-Drawn Fake Chrome**:
  - Never draw fake browser address bars (URL pills with red/yellow/green traffic-light dots) or fake phone frames. Real screenshots sit matte in a clean `<figure>` with a 1px hairline border.
- **Border Radii (Intentional Hierarchy)**:
  - Small elements (badges, tags): `rounded-sm` (4px)
  - Standard controls (buttons, inputs): `rounded-md` (6px)
  - Containers (cards, dialogs): `rounded-lg` (8px)
  - 🚫 **Anti-Pill Rule**: Reserve `rounded-full` strictly for avatar circles and indicator dots. Do not create uniform pill-shaped cards, buttons, or inputs.
- **Glassmorphism Dose Cap**:
  - Dose cap: At most 1–2 frosted (`backdrop-blur`) surfaces across an entire view.

---

## 5. Mobile Ergonomics & Responsive Reflow
- **Touch Target Minimum**: Every button, input, toggle, and nav link must have a hit area of at least **$44 \times 44\text{px}$** with $\ge 8\text{px}$ finger spacing.
- **Reflow over Shrinking**: Multi-column grids must collapse and stack into single-column flows on mobile viewports.
- **Zero Horizontal Scroll**: All flex/grid children must declare `min-w-0` to allow clean text truncation (`truncate`, `line-clamp-*`).
- **Viewport Units**: Use `dvh` (dynamic viewport height) for full-screen dialogs and drawers; never use `100vh`.
- **Safe-Area Insets**: Fixed bottom bars and sticky navigation must include `env(safe-area-inset-bottom)`.

---

## 6. Motion & Interaction Rules
- **The Mandatory 8-State Component Contract**:
  - Every interactive element must implement: `default`, `hover`, `:focus-visible`, `:active`, `disabled`, `loading`, `error`, `success`.
- **Compositor Transitions Only**: Animate `transform` and `opacity` only. Never use `transition: all`.
- **Physical Press Feedback**: Buttons compress with `active:scale-[0.98]`.
- **Reduced Motion**: Always provide reduced-motion fallbacks (`@media (prefers-reduced-motion: reduce)`).
- **No Endless Loops**: No unprompted pulsing, floating, or bouncing animations.

---

## 7. Universal Icon System Standards ([Iconify](https://icon-sets.iconify.design/))
- **Authoritative Catalog**: Use [Iconify](https://icon-sets.iconify.design/) to verify exact icon names and SVG paths without requiring an npm package dependency.
- **Single-Family Consistency**: Pick one primary icon set per project:
  - *Lucide*: Clean, modern SaaS and web apps.
  - *Radix Icons*: High-density developer tools and compact dashboards.
  - *Phosphor*: Warm, editorial, and humanist products.
  - *Tabler*: Expressive, wide-domain application suites.
- **Brand Logos**: Always pull official third-party brand marks (GitHub, Stripe, PostgreSQL, Docker, Figma) from Iconify's `simple-icons` collection. Never draw manual brand paths.
- **Sizing & Inheritance**: Standardize sizes (`14px`, `16px`, `20px`), use `currentColor` for automatic state/theme inheritance, and enclose icons in $\ge 44 \times 44\text{px}$ hit areas.

---

## 8. Content Integrity & Honest Copy
- **Zero Fabricated Metrics**: Never invent marketing statistics (*"+47% conversion"*, *"trusted by 50,000+ teams"*) or hallucinated social proof logo bars.
- If real metrics are unavailable, use authentic qualitative descriptions, placeholders (`"—"`, `[metric to confirm]`), or select a structural layout that does not depend on stat counters.
