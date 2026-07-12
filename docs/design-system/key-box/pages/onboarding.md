# Onboarding Pages — 3-Step Welcome Flow

> **PROJECT:** KeyBox
> **Page Type:** Post-Signup Onboarding (3 Steps)
> **Version:** V7 (2026-03-01) — Full Redesign

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Design Principle

> **Progressive Disclosure**: One concept per step. Minimize friction for first secret storage. Make the user feel productive within 30 seconds.

---

## Flow Overview

```
[Step 1: Welcome] → [Step 2: First Secret] → [Step 3: Shortcuts] → [Dashboard]
```

- 3 steps total, sequential (no skip to arbitrary step)
- Step 2 has [Skip] option
- Step indicator: 3 dots (filled = current, hollow = pending/done)

---

## Layout — Centered Card (Same as Auth)

```
┌─────────────────────────────────────┐
│          (vertical center)          │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │  Card: 420px max, slate-900
│  │    (Step content)           │    │
│  │                             │    │
│  │    ● ○ ○                    │    │  Step indicator
│  │    [Primary Action]         │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

### Container (shared across steps)

| Property | Value |
|----------|-------|
| Background | `#020617` (slate-950) — full viewport |
| Card Width | 420px (max), `w-full` |
| Card Style | `bg-slate-900`, `border-white/10`, `rounded-lg`, `p-8` |
| Shadow | `--shadow-lg` |

---

## Step 1: Welcome

```
┌─────────────────────────────────┐
│                                 │
│         Key icon (48px)         │  Lucide `key-round`, brand-500
│                                 │
│   "Welcome to KeyBox"           │  20px Semibold, text-primary
│   "Your secure vault for       │  14px, text-secondary
│    API keys and credentials"    │  max-width 280px, center
│                                 │
│        ● ○ ○                    │  Step dots
│                                 │
│     [Continue →]                │  Primary button, 200px
│                                 │
└─────────────────────────────────┘
```

| Element | Spec |
|---------|------|
| Icon | Lucide `key-round`, 48px, `text-brand-500` |
| Title | "Welcome to KeyBox" — 20px Semibold, `text-primary` |
| Description | "Your secure vault for API keys and credentials" — 14px, `text-secondary`, center, max-width 280px |
| CTA | Primary button, "Continue", Lucide `arrow-right` 16px trailing |
| Layout | Flex column, `items-center`, `gap-4` |

---

## Step 2: First Secret

```
┌─────────────────────────────────┐
│                                 │
│   "Add your first secret"      │  20px Semibold
│   "You can always add more     │  14px, text-secondary
│    later"                       │
│                                 │
│   Name                          │
│   [________________________]    │  autofocus
│                                 │
│   Value                         │
│   [________________________]    │  monospace
│                                 │
│        ○ ● ○                    │
│                                 │
│   [Add Secret]    [Skip →]     │
│                                 │
└─────────────────────────────────┘
```

| Element | Spec |
|---------|------|
| Title | "Add your first secret" — 20px Semibold, `text-primary` |
| Description | "You can always add more later" — 14px, `text-secondary` |
| Name Input | Text input, label "Name", autofocus, placeholder "e.g., Stripe API Key" |
| Value Input | Text input, label "Value", monospace font, placeholder "e.g., sk_live_..." |
| Primary CTA | Primary button, "Add Secret", left-aligned in footer |
| Skip | Ghost button, "Skip", Lucide `arrow-right` trailing, right-aligned |
| Layout | `gap-4` between fields, `gap-6` before buttons |
| Validation | Both fields required if "Add Secret" clicked; Skip bypasses validation |

---

## Step 3: Shortcuts

```
┌─────────────────────────────────┐
│                                 │
│   "Quick Shortcuts"             │  20px Semibold
│   "Master these to work faster" │  14px, text-secondary
│                                 │
│   ┌─────────────────────────┐   │
│   │ ⌘K  Search secrets      │   │  Shortcut row
│   ├─────────────────────────┤   │
│   │ ⌘N  New secret          │   │
│   ├─────────────────────────┤   │
│   │ ⌘C  Copy value          │   │
│   └─────────────────────────┘   │
│                                 │
│        ○ ○ ●                    │
│                                 │
│   [Go to Dashboard →]          │
│                                 │
└─────────────────────────────────┘
```

| Element | Spec |
|---------|------|
| Title | "Quick Shortcuts" — 20px Semibold, `text-primary` |
| Description | "Master these to work faster" — 14px, `text-secondary` |
| Shortcut Row | 44px height, `bg-white/5`, `rounded-md`, `px-4` |
| Key Badge | `bg-white/10`, `rounded`, `px-2 py-0.5`, 12px Mono Bold |
| Key Label | 14px Regular, `text-secondary`, `ml-3` |
| Row Spacing | `space-y-2` |
| CTA | Primary button, "Go to Dashboard", Lucide `arrow-right` trailing |

---

## Step Indicator

| Element | Spec |
|---------|------|
| Dot Size | 8px circle |
| Active | `bg-brand-500` |
| Inactive | `bg-white/20` |
| Spacing | `gap-2` between dots |
| Position | Centered, between content and CTA button |

---

## Transitions

| Transition | Animation |
|-----------|-----------|
| Step → Next | Content slide-left + fade, 250ms ease |
| Step → Previous | Content slide-right + fade, 250ms ease |
| Dot activation | Scale 1→1.2→1, 200ms |
| Final → Dashboard | Full page fade, 300ms |

---

## Accessibility

- Step indicator: `aria-label="Step N of 3"`, `role="progressbar"`
- Skip button: `aria-label="Skip this step"`
- Shortcut keys: Decorative display only (not functional during onboarding)
- Focus: Auto-focus on primary CTA (Step 1, 3) or first input (Step 2)

---

## Anti-Patterns

| Do NOT | Do Instead |
|--------|-----------|
| More than 3 steps | Keep it to 3 (welcome, action, education) |
| Force secret creation | Allow skip on Step 2 |
| Complex form on Step 2 | Name + Value only (minimal friction) |
| Fancy illustrations | Single icon per step |
| Auto-advance timer | User-controlled progression |
