# DESIGN.md FAQ: Using Your Own Design File

Common questions about how DESIGN.md works in PromptKit OS and what happens if you already have one.

---

## ✅ **Short Answer: Your DESIGN.md is Safe and Will Be Used**

If you already have a `DESIGN.md` file in your project root:
- ✅ **It will NOT be overwritten** by init scripts
- ✅ **It WILL be detected and used** by all workflows
- ✅ **It becomes the "single source of truth"** for UI/design workflows
- ✅ **You can customize it however you want**

---

## 📋 **How DESIGN.md Works**

### 1. **Detection (Automatic)**

When you run `init.sh` or `init.ps1`:

```powershell
$DesignProfile = Join-Path $ProjectRoot "DESIGN.md"
if (Test-Path $DesignProfile) {
    Write-Host "  [✓] DESIGN.md detected (brand identity & anti-slop rules)"
}
# Does NOT create or overwrite if it exists
```

**What this means**:
- Init script **checks if DESIGN.md exists**
- If yes: Reports "detected" and **does nothing**
- If no: Does **not** create one (DESIGN.md is **optional**)

---

### 2. **Usage (Context Sync Protocol)**

From `protocols/context-sync.md`:

```markdown
### 2. Brand & Visual Identity Inspection (DESIGN.md)
Check if ./DESIGN.md exists in the repository root:
- If present, parse:
  - Brand Palette & Tokens
  - Anti-Slop Guardrails
  - Typography Rules
  - Surfaces & Radii
  - Mobile Constraints
- **Single Source of Truth**: Treat DESIGN.md as the supreme 
  visual authority for all UI generation, styling, and 
  design reviews (pk:design, pk:review).
```

**What this means**:
- AI assistant **reads your DESIGN.md** at session start
- Uses it to inform all UI-related decisions
- Enforces your rules automatically

---

### 3. **Where DESIGN.md is Used**

| Workflow | How It Uses DESIGN.md |
|:---------|:----------------------|
| **pk:design** | Translates your DESIGN.md rules into component tokens and themes |
| **pk:review** | Audits code changes against your visual standards |
| **pk:plan** | Ensures proposed UI fits your design boundaries |
| **pk:onboard** | Extracts existing design tokens if DESIGN.md is present |

**Key Point**: If you have DESIGN.md, it's **automatically** enforced.

---

## 🎯 **What Happens in Different Scenarios**

### Scenario A: You Have No DESIGN.md (Default)

```bash
# You run init script
./promptkit/init.sh

# Output:
#   [✓] PROMPTKIT.md created
#   [✓] docs/STATE.md created
#   (No mention of DESIGN.md - it's optional)

# Your project:
my-project/
├── PROMPTKIT.md          ← Created
├── docs/STATE.md         ← Created
└── (no DESIGN.md)        ← Optional, not created
```

**What happens**:
- PromptKit works fine without it
- Design workflows use generic best practices
- You can create DESIGN.md later if needed

---

### Scenario B: You Already Have DESIGN.md

```bash
# Your project BEFORE init:
my-project/
├── DESIGN.md             ← YOUR existing file
└── (other files)

# You run init script
./promptkit/init.sh

# Output:
#   [✓] DESIGN.md detected (brand identity & anti-slop rules)
#   [+] PROMPTKIT.md created
#   [+] docs/STATE.md created

# Your project AFTER init:
my-project/
├── DESIGN.md             ← UNCHANGED (your original)
├── PROMPTKIT.md          ← Created
└── docs/STATE.md         ← Created
```

**What happens**:
- ✅ Your DESIGN.md is **not touched**
- ✅ Init script just **detects and reports** it
- ✅ All workflows will **use your rules**

---

### Scenario C: You Want to Create DESIGN.md Later

```bash
# After init, you decide you want design rules
cp .promptkit/templates/design-profile-template.md ./DESIGN.md

# Edit it with your brand
vim DESIGN.md

# Next AI session automatically uses it
```

**What happens**:
- Template gives you structure
- You customize with your brand
- AI assistant picks it up automatically (no re-init needed)

---

## 🛡️ **Safety Guarantees**

### Init Script Behavior (from init.ps1 and init.sh)

```powershell
# Check if DESIGN.md exists
$DesignProfile = Join-Path $ProjectRoot "DESIGN.md"
if (Test-Path $DesignProfile) {
    Write-Host "  [✓] DESIGN.md detected"
    # STOPS HERE - does not overwrite
}
# Does NOT have an 'else' clause to create it
```

**Key points**:
1. ❌ **Never overwrites** existing DESIGN.md
2. ❌ **Never creates** DESIGN.md automatically
3. ✅ **Only detects** and reports if present
4. ✅ **Optional file** - not required

---

## 🎨 **What Should Be in DESIGN.md?**

### Minimum (If You Create One)

```markdown
# Brand & Design Identity

## Colors
- Primary: #1a56db (Blue)
- Accent: #f59e0b (Amber)
- Neutral: Gray scale

## Typography
- Headings: Inter
- Body: System fonts

## Borders
- Radius: 8px (rounded-lg)

## Anti-Slop Rules
- No purple-to-cyan gradients
- No glowing backgrounds
- Matte surfaces preferred
```

**This is enough** for PromptKit to enforce your brand.

---

### Full Example (PromptKit Template)

See `.promptkit/templates/design-profile-template.md` for:
- Complete color system
- Typography tokens
- Component patterns
- Accessibility rules (WCAG 2.2 AA)
- Mobile touch targets
- Anti-slop guardrails

**You can use this as a starting point** or write your own from scratch.

---

## 🔧 **Customization Options**

### Option 1: Use Your Existing DESIGN.md As-Is

```bash
# If you already have brand guidelines:
my-project/
├── DESIGN.md             ← Your existing brand doc
└── ...

# Just install PromptKit - it will use it
git submodule add ... .promptkit
./.promptkit/init.sh
```

**PromptKit adapts to your format**.

---

### Option 2: Enhance Your Existing DESIGN.md

```bash
# Add PromptKit-specific sections to your file:
# (at the bottom of your existing DESIGN.md)

## AI Assistant Rules (PromptKit OS)
- Use these tokens in all generated UI code
- Enforce WCAG 2.2 AA contrast ratios
- No client-side business logic in components
```

**Merge your brand + PromptKit conventions**.

---

### Option 3: Keep Separate Files

```bash
my-project/
├── BRAND-GUIDELINES.md   ← Your team's brand doc
├── DESIGN.md             ← Lighter AI-specific rules
└── ...
```

**DESIGN.md can reference your main guidelines**:
```markdown
# Design Identity (AI Assistant)

See BRAND-GUIDELINES.md for full brand details.

## Key Tokens for Code Generation
- Primary: (see BRAND-GUIDELINES.md)
- Use semantic color-primary not hardcoded hex
```

---

## ❓ **Common Questions**

### Q: Is DESIGN.md required?
**A**: No, it's **optional**. PromptKit works without it.

### Q: Will init overwrite my DESIGN.md?
**A**: **Never**. Init script only detects, never creates or overwrites.

### Q: Can I use my own format?
**A**: **Yes**. PromptKit reads whatever you have.

### Q: What if I don't have UI code?
**A**: No problem. DESIGN.md is for frontend projects. Backend-only projects don't need it.

### Q: Can I have multiple design systems?
**A**: Yes, if you're in a monorepo:
```bash
monorepo/
├── DESIGN.md              ← Global design system
├── apps/
│   ├── web/
│   │   └── DESIGN.md      ← App-specific overrides
│   └── mobile/
│       └── DESIGN.md      ← Mobile-specific rules
```

PromptKit will use the closest DESIGN.md to the active workspace.

### Q: How do I tell AI to ignore parts of my DESIGN.md?
**A**: Add a comment:
```markdown
<!-- AI: Skip this section - internal team notes only -->
## Internal Design Process
(Team meeting notes that AI doesn't need to see)
<!-- AI: End skip -->
```

---

## 🚀 **Best Practices**

### 1. **Keep It Focused**
- Only include rules AI needs to generate code
- Skip team process/meeting notes
- Focus on tokens, patterns, constraints

### 2. **Be Specific**
```markdown
❌ "Use our brand colors"
✅ "Primary: #1a56db, Accent: #f59e0b, use as CSS variables"

❌ "Make it accessible"
✅ "Minimum contrast 4.5:1, touch targets ≥24×24px AA floor (~44×44px on primary controls)"
```

### 3. **Update When Brand Changes**
- DESIGN.md is git-tracked
- Changes automatically picked up in next AI session
- No re-init needed

### 4. **Reference from Code**
```typescript
// In your tailwind.config.ts
// See DESIGN.md for color token definitions
export default {
  theme: {
    colors: {
      primary: '#1a56db', // From DESIGN.md
    }
  }
}
```

---

## 📚 **Related Documentation**

- **Template**: `.promptkit/templates/design-profile-template.md`
- **Protocol**: `.promptkit/protocols/context-sync.md` (how it's read)
- **Workflows**: `.promptkit/workflows/design-system.md` (how it's used)
- **Example**: `examples/saas-dashboard/` (no DESIGN.md shown, but would work)

---

## ✅ **Summary**

| Your Situation | What Happens |
|:---------------|:-------------|
| **No DESIGN.md** | PromptKit works fine, uses generic best practices |
| **Have DESIGN.md** | PromptKit detects it, uses it as single source of truth, never overwrites |
| **Create later** | Just add the file, AI picks it up automatically (no re-init) |
| **Custom format** | PromptKit adapts to your format |
| **Want template** | Copy from `.promptkit/templates/design-profile-template.md` |

**Your DESIGN.md is completely safe and will be respected by all workflows.** 🎉

---

**Still have questions?** See:
- `QUICKSTART.md` - Section 4 on Visual Brand Identity
- `docs/ADOPTION-GUIDE.md` - How to integrate with existing projects
- `examples/` - Real-world project examples
