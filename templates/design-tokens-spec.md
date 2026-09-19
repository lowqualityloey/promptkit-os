# Modern Design System & Token Specification

- **System Name**: [e.g., Core UI / Nova Design System]
- **Target CSS Framework**: [Tailwind CSS v4 / CSS Variables / CVA]
- **Upstream Design Tool**: [Figma Variables / Tokens Studio / Sketch / Penpot / None]
- **Accessibility Target**: WCAG 2.2 Level AA Compliance
- **Mobile Target**: Fluid responsive reflow with $\ge 44 \times 44\text{px}$ touch targets

---

## 1. Color System & Semantic Tokens

> 🚫 **Anti-Slop Guardrail**: Ground the palette in your product's distinct identity (`DESIGN.md`). Avoid generic AI blue-to-purple gradients, cyan glows, or rainbow borders. Limit the active palette to 2–3 core colors + 1 intentional accent.
>
> 💡 **Design Tool Token Ingestion**: When pulling tokens from Figma Variables or Tokens Studio, export them as semantic aliases into `:root` rather than baking raw hex codes into individual components.

### Primitive Color Scale
```css
:root {
  /* Slate Neutral */
  --color-slate-50:  #f8fafc;
  --color-slate-100: #f1f5f9;
  --color-slate-200: #e2e8f0;
  --color-slate-300: #cbd5e1;
  --color-slate-400: #94a3b8;
  --color-slate-500: #64748b;
  --color-slate-600: #475569;
  --color-slate-700: #334155;
  --color-slate-800: #1e293b;
  --color-slate-900: #0f172a;
  --color-slate-950: #020617;

  /* Brand Primary (Example: Indigo) */
  --color-brand-500: #6366f1;
  --color-brand-600: #4f46e5;
  --color-brand-700: #4338ca;

  /* Semantic Feedback */
  --color-success-500: #10b981;
  --color-success-600: #059669;
  --color-danger-500:  #f43f5e;
  --color-danger-600:  #e11d48;
}
```

### Semantic Token Aliases (Light & Dark Theme)
```css
/* Light Theme (Default) - Contrast Verified ≥ 4.5:1 */
:root {
  --background: var(--color-slate-50);
  --foreground: var(--color-slate-900);
  
  --surface-card: #ffffff;
  --surface-card-foreground: var(--color-slate-900);
  --surface-popover: #ffffff;
  
  --primary: var(--color-brand-600);
  --primary-foreground: #ffffff;
  
  --secondary: var(--color-slate-100);
  --secondary-foreground: var(--color-slate-900);
  
  --muted: var(--color-slate-100);
  --muted-foreground: var(--color-slate-500);
  
  --border: var(--color-slate-200);
  --input: var(--color-slate-200);
  --ring: var(--color-brand-600);
  
  --destructive: var(--color-danger-600);
  --destructive-foreground: #ffffff;
}

/* Dark Theme - Contrast Verified ≥ 4.5:1 */
.dark {
  --background: var(--color-slate-950);
  --foreground: var(--color-slate-100);
  
  --surface-card: var(--color-slate-900);
  --surface-card-foreground: var(--color-slate-100);
  --surface-popover: var(--color-slate-900);
  
  --primary: var(--color-brand-500);
  --primary-foreground: #ffffff;
  
  --secondary: var(--color-slate-800);
  --secondary-foreground: var(--color-slate-100);
  
  --muted: var(--color-slate-800);
  --muted-foreground: var(--color-slate-400);
  
  --border: var(--color-slate-800);
  --input: var(--color-slate-800);
  --ring: var(--color-brand-500);
  
  --destructive: var(--color-danger-500);
  --destructive-foreground: #ffffff;
}
```

### Tactile Dual-Mode Presets (Chromatically Tinted Neutrals)

#### Preset A: Cobalt Dev-Tool (Developer Tools, Technical SaaS, Precision Dashboards)
```css
/* Light Mode - Precision Technical Paper */
[data-theme="cobalt"] {
  --background: oklch(98% 0.005 240);
  --surface-card: oklch(100% 0 0);
  --surface-subtle: oklch(96% 0.008 240);
  --foreground: oklch(18% 0.02 240);
  --foreground-muted: oklch(46% 0.02 240);
  --border: oklch(91% 0.01 240);
  --border-subtle: oklch(94% 0.008 240);
  --primary: oklch(52% 0.22 250);       /* Electric cobalt signal (max 5% viewport area) */
  --primary-foreground: oklch(99% 0 0);
  --ring: oklch(52% 0.22 250 / 0.35);
}

/* Dark Mode - Graphite Monolith (Not Naive Inversion) */
[data-theme="cobalt"].dark,
.dark [data-theme="cobalt"] {
  --background: oklch(14% 0.015 245);   /* Deep slate base */
  --surface-card: oklch(18% 0.018 245); /* +4% lightness for physical elevation */
  --surface-subtle: oklch(16% 0.016 245);
  --foreground: oklch(94% 0.008 240);   /* Crisp technical white */
  --foreground-muted: oklch(62% 0.015 240);
  --border: oklch(24% 0.018 245);       /* 1px crisp separation hairline */
  --border-subtle: oklch(20% 0.015 245);
  --primary: oklch(64% 0.21 248);       /* Vibrant cobalt interactive cue */
  --primary-foreground: oklch(14% 0.015 245);
  --ring: oklch(64% 0.21 248 / 0.4);
}
```

#### Preset B: Hum Warm Editorial (Boutique SaaS, Knowledge Bases, Long-Form Documentation)
```css
/* Light Mode - Warm Linen Paper */
[data-theme="hum"] {
  --background: oklch(97% 0.012 75);    /* Warm linen ground */
  --surface-card: oklch(99% 0.006 75);  /* Subtle warm lift */
  --surface-subtle: oklch(94.5% 0.015 75);
  --foreground: oklch(20% 0.02 55);     /* Deep espresso ink */
  --foreground-muted: oklch(48% 0.02 55);
  --border: oklch(90% 0.018 75);        /* Crisp warm hairline */
  --border-subtle: oklch(93% 0.012 75);
  --primary: oklch(50% 0.16 42);        /* Terracotta / burnt amber signal (5% rule) */
  --primary-foreground: oklch(99% 0.005 75);
  --ring: oklch(50% 0.16 42 / 0.35);
}

/* Dark Mode - Obsidian Ink & Smoked Ochre */
[data-theme="hum"].dark,
.dark [data-theme="hum"] {
  --background: oklch(15% 0.018 60);    /* Smoked espresso/obsidian ground */
  --surface-card: oklch(19% 0.02 60);   /* Elevated card layer */
  --surface-subtle: oklch(17% 0.018 60);
  --foreground: oklch(93% 0.01 70);     /* Warm parchment text */
  --foreground-muted: oklch(65% 0.015 65);
  --border: oklch(25% 0.022 60);        /* 1px subtle warm hairline */
  --border-subtle: oklch(21% 0.018 60);
  --primary: oklch(68% 0.15 45);        /* Warm amber signal */
  --primary-foreground: oklch(15% 0.018 60);
  --ring: oklch(68% 0.15 45 / 0.4);
}
```

---

## 2. Typography Hierarchy & Fluid Scales

> ⚡ **Zero-Byte Native Font Philosophy**: Avoid forced external web font downloads (`fonts.googleapis.com`). Standard system font stacks achieve instant load with zero layout shift (CLS 0). Pair with `font-feature-settings: "tnum" 1` for numeric tables and metrics, and `text-wrap: balance` for headings.

```css
:root {
  /* Native Zero-Byte System Stacks */
  --font-sans: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-mono: ui-monospace, "SF Mono", "Cascadia Code", "Segoe UI Mono", Menlo, Consolas, monospace;
  --font-serif: ui-serif, Charter, "Bitstream Charter", "Sitka Text", Cambria, Georgia, serif;

  /* Font Sizes */
  --text-xs:   0.75rem;   /* 12px */
  --text-sm:   0.875rem;  /* 14px */
  --text-base: 1rem;      /* 16px */
  --text-lg:   1.125rem;  /* 18px */
  --text-xl:   1.25rem;   /* 20px */
  --text-2xl:  1.5rem;    /* 24px */

  /* Fluid Scales for Headings (Mobile → Desktop clamp) */
  --text-fluid-h1: clamp(2rem, 5vw, 3.25rem);
  --text-fluid-h2: clamp(1.5rem, 3.5vw, 2.25rem);
  --text-fluid-h3: clamp(1.25rem, 2.5vw, 1.75rem);
}

/* Numeric & Heading Enhancements */
.font-tabular {
  font-feature-settings: "tnum" 1;
  font-variant-numeric: tabular-nums;
}

h1, h2, h3 {
  text-wrap: balance;
}
```

---

## 3. Spacing, Touch Targets, Mobile Ergonomics & Icons

> 🎯 **Icon Standards (Iconify)**:
> - Use [Iconify](https://icon-sets.iconify.design/) as the unified catalog reference.
> - Standardize on **ONE** family across the entire project (e.g., Lucide, Tabler, Phoshor, or Heroicons).
> - Use `simple-icons` strictly for brand/tech logos (GitHub, Figma, Docker).
> - Never mix conflicting families or stroke weights in adjacent views.
> - Inline raw SVGs or use project-level icon wrappers; do not mandate `@iconify/react` runtime package.

```css
:root {
  /* Spacing Scale */
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */
  --space-12: 3rem;    /* 48px */

  /* Touch Targets (Minimum 44px for thumb accessibility) */
  --touch-target-min: 44px;

  /* Icon Sizing Tokens */
  --icon-xs: 0.875rem; /* 14px - badges, compact metadata */
  --icon-sm: 1rem;     /* 16px - inline with body text, buttons */
  --icon-md: 1.25rem;  /* 20px - primary action buttons, nav items */
  --icon-lg: 1.5rem;   /* 24px - modal headers, empty state spotlights */

  /* Safe Area Insets (for mobile notches & home indicator bars) */
  --safe-area-top: env(safe-area-inset-top, 0px);
  --safe-area-bottom: env(safe-area-inset-bottom, 0px);

  /* Border Radii (Intentional, tactile rounding - never pill shapes) */
  --radius-sm: 0.25rem; /* 4px */
  --radius-md: 0.375rem; /* 6px */
  --radius-lg: 0.5rem; /* 8px */
  --radius-full: 9999px; /* Reserved strictly for avatars and circular status dots */

  /* Elevation Shadows (Matte & grounded, not floating) */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.06);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.05);
}
```

---

## 4. Transitions & Motion Tokens

> ⚠️ **Compositor Rule**: Animate `transform` and `opacity` only. Never use `transition: all`.

```css
:root {
  --transition-fast: 150ms cubic-bezier(0.16, 1, 0.3, 1);
  --transition-normal: 200ms cubic-bezier(0.16, 1, 0.3, 1);
  --transition-slow: 300ms cubic-bezier(0.16, 1, 0.3, 1);
}

@media (prefers-reduced-motion: reduce) {
  :root {
    --transition-fast: 0.01ms;
    --transition-normal: 0.01ms;
    --transition-slow: 0.01ms;
  }
}
```

---

## 5. Accessible Component Reference Pattern (Tailwind + Radix + CVA)

```tsx
import * as React from 'react';
import * as DialogPrimitive from '@radix-ui/react-dialog';
import { cva, type VariantProps } from 'class-variance-authority';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export const DialogOverlay = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Overlay>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Overlay>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Overlay
    ref={ref}
    className={cn(
      'fixed inset-0 z-50 bg-black/60 backdrop-blur-sm transition-opacity duration-200',
      'data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0',
      className
    )}
    {...props}
  />
));
DialogOverlay.displayName = DialogPrimitive.Overlay.displayName;
```
