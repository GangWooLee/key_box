# Auth Pages — Login & Signup

> **PROJECT:** KeyBox
> **Page Type:** Authentication (Login + Signup)
> **Version:** V7 (2026-03-01) — Full Redesign

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Design Principle

> Minimal, centered, trust-inducing. One task per screen. No distractions.

---

## Layout — Centered Card on Dark Background

```
┌─────────────────────────────────────┐
│          (vertical center)          │
│                                     │
│       Key icon (Indigo-500)         │  Lucide `key-round`, 32px
│       "KeyBox"                      │  20px Semibold, text-primary
│                                     │
│     "Log in to KeyBox"              │  24px Semibold, text-primary
│  "Don't have an account? Sign up"   │  14px, Indigo-500 link
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Email                       │    │  label 14px
│  │ [________________________]  │    │  input 32px, rounded-md
│  │                             │    │
│  │ Password                    │    │
│  │ [____________________] [eye]│    │  + reveal toggle
│  │                             │    │
│  │ [ ] Remember me             │    │  14px checkbox
│  │                             │    │
│  │ [      Log in           ]   │    │  Primary button, full-width
│  └─────────────────────────────┘    │
│          (vertical center)          │
└─────────────────────────────────────┘
```

---

## Page Specs

### Container

| Property | Value |
|----------|-------|
| Background | `#020617` (slate-950) — full viewport |
| Layout | Flex column, `items-center justify-center`, `min-h-dvh` |
| Padding | `px-4` (mobile safe) |

### Logo Section

| Element | Spec |
|---------|------|
| Icon | Lucide `key-round`, 32px, `text-brand-500` |
| App Name | "KeyBox", 20px Semibold, `text-primary`, `mt-2` |
| Spacing | `mb-8` below logo section |

### Card

| Property | Value |
|----------|-------|
| Width | 380px (max), `w-full` |
| Background | `#0f172a` (slate-900) |
| Border | `1px rgba(255,255,255,0.1)` |
| Border Radius | `rounded-lg` (8px) |
| Padding | `p-8` (32px) |
| Shadow | `--shadow-lg` |

### Heading

| Element | Spec |
|---------|------|
| Title | "Log in to KeyBox" / "Create your account" — 24px Semibold, `text-primary` |
| Subtitle | "Don't have an account? Sign up" / "Already have an account? Log in" — 14px, `text-secondary` |
| Link Color | `text-brand-500`, `hover:text-brand-400` |
| Spacing | Title `mb-1`, Subtitle `mb-6` |

### Form Fields

| Element | Spec |
|---------|------|
| Label | 14px Medium, `text-secondary`, `mb-1.5` |
| Input | 32px height, `bg-white/5`, `border-white/10`, `rounded-md`, 14px |
| Input Focus | `ring-2 ring-brand-500 ring-offset-2 ring-offset-slate-900` |
| Password Reveal | Lucide `eye` / `eye-off`, 16px, Ghost button inside input |
| Field Spacing | `space-y-4` between fields |
| Email Autofocus | Login: email autofocus. Signup: name autofocus |

### Remember Me (Login only)

| Element | Spec |
|---------|------|
| Checkbox | 16x16px, `rounded`, `border-white/10` |
| Label | "Remember me", 14px, `text-secondary` |
| Spacing | `mt-4 mb-6` |

### Submit Button

| Element | Spec |
|---------|------|
| Style | Primary button (brand-600), full-width |
| Height | 36px |
| Text | "Log in" / "Create account" — 14px Semibold, white |
| Hover | `bg-brand-700` |
| Loading | Spinner icon replaces text, button disabled |

### Signup Additional Fields

| Field | Spec |
|-------|------|
| Name | Text input, before email |
| Password Confirmation | Below password, same style |

---

## Error States

| Type | Display |
|------|---------|
| Field Error | Below input, `text-red-400`, 12px, Lucide `alert-circle` 14px inline |
| General Error | Above form, Alert component (red bg), dismissible |
| Network Error | Toast notification (error variant) |

### Error Messages

| Scenario | Message |
|----------|---------|
| Invalid email | "Please enter a valid email address" |
| Wrong password | "Invalid email or password" (no field-specific hint) |
| Email taken (Signup) | "An account with this email already exists" |
| Weak password | "Password must be at least 8 characters" |

---

## Transitions

| Action | Animation |
|--------|-----------|
| Login → Signup | Card content crossfade, 200ms ease |
| Submit loading | Button spinner, 150ms ease-in |
| Error appear | `opacity: 0→1` + `translateY(-4px→0)`, 200ms |
| Success → Dashboard | Full page fade-out, 300ms |

---

## Accessibility

- All inputs have visible `<label>` with `for`/`id` pairing
- Password reveal: `aria-label="Show password"` / `aria-label="Hide password"`
- Submit button: `aria-busy="true"` during loading
- Error messages: `aria-live="polite"`, linked via `aria-describedby`
- Tab order: Logo → Email → Password → Remember me → Submit → Switch link
- Enter key submits form

---

## Anti-Patterns

| Do NOT | Do Instead |
|--------|-----------|
| Social login buttons (Google, GitHub) | Email/password only (Phase 1) |
| "Forgot password" link | Phase 2 addition |
| Complex password requirements shown upfront | Validate on submit |
| Separate pages for Login/Signup in Pencil | Single frame, two sections side-by-side |
