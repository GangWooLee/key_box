# Error Pages — 404 / 500 / 422

> **PROJECT:** KeyBox
> **Page Type:** Error Pages (HTTP Error States)
> **Version:** V7 (2026-03-01) — Full Redesign

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Design Principle

> Friendly, not scary. Acknowledge the problem, offer a way out. Same visual language as auth pages (centered card, dark background).

---

## Layout — Centered Minimal

```
┌─────────────────────────────────┐
│                                 │
│        Key icon (32px)          │  Lucide `key-round`, brand-500
│        "KeyBox"                 │  20px, text-primary
│                                 │
│     (Error icon, 48px)          │  Varies per error type
│                                 │
│   "Page not found"              │  24px Semibold
│   "The page you're looking     │  14px, text-secondary
│    for doesn't exist"           │
│                                 │
│   [Go to Dashboard]            │  Primary button
│                                 │
└─────────────────────────────────┘
```

### Shared Container

| Property | Value |
|----------|-------|
| Background | `#020617` (slate-950) — full viewport |
| Layout | Flex column, `items-center justify-center`, `min-h-dvh` |
| Content Width | 380px max |
| Content Alignment | Center text |

### Logo (Shared)

| Element | Spec |
|---------|------|
| Icon | Lucide `key-round`, 32px, `text-brand-500` |
| Text | "KeyBox", 20px Semibold, `text-primary` |
| Spacing | `mb-12` below logo |

---

## 404 — Not Found

| Element | Spec |
|---------|------|
| Icon | Lucide `search`, 48px, `text-slate-400` |
| Error Code | "404" — 14px Mono, `text-muted`, `mb-2` |
| Title | "Page not found" — 24px Semibold, `text-primary` |
| Description | "The page you're looking for doesn't exist or has been moved." — 14px, `text-secondary`, center, max-width 300px |
| CTA | Primary button, "Go to Dashboard" |
| Secondary | Ghost link, "Go back" — 14px, `text-secondary`, `mt-3` |

---

## 500 — Server Error

| Element | Spec |
|---------|------|
| Icon | Lucide `alert-triangle`, 48px, `text-amber-400` |
| Error Code | "500" — 14px Mono, `text-muted`, `mb-2` |
| Title | "Something went wrong" — 24px Semibold, `text-primary` |
| Description | "We're working on fixing this. Please try again in a moment." — 14px, `text-secondary`, center, max-width 300px |
| CTA | Primary button, "Try Again" (reloads page) |
| Secondary | Ghost link, "Go to Dashboard" — 14px, `text-secondary`, `mt-3` |

---

## 422 — Unprocessable Entity

| Element | Spec |
|---------|------|
| Icon | Lucide `file-warning`, 48px, `text-red-400` |
| Error Code | "422" — 14px Mono, `text-muted`, `mb-2` |
| Title | "Request could not be processed" — 24px Semibold, `text-primary` |
| Description | "The request was well-formed but could not be processed. Please try again." — 14px, `text-secondary`, center, max-width 300px |
| CTA | Primary button, "Go to Dashboard" |
| Secondary | Ghost link, "Go back" — 14px, `text-secondary`, `mt-3` |

---

## Spacing

| Section | Spacing |
|---------|---------|
| Logo → Error icon | `mb-12` |
| Error icon → Error code | `mb-4` |
| Error code → Title | `mb-2` |
| Title → Description | `mb-2` |
| Description → CTA | `mb-6` |
| CTA → Secondary link | `mt-3` |

---

## Animation

| Element | Animation | Duration |
|---------|-----------|----------|
| Icon | `opacity: 0→1` + subtle `scale(0.9→1)` | 300ms, ease-out |
| Text | `opacity: 0→1` + `translateY(8px→0)` | 400ms, 100ms delay |
| CTA | `opacity: 0→1` | 500ms, 200ms delay |

---

## Accessibility

- Error code: `aria-hidden="true"` (decorative)
- Main message: `role="alert"`
- CTA button: Clear, descriptive label
- "Go back": Uses `history.back()`, `aria-label="Go to previous page"`
- Page `<title>`: "404 - Page Not Found | KeyBox"

---

## Anti-Patterns

| Do NOT | Do Instead |
|--------|-----------|
| Technical jargon ("HTTP 404") | Friendly language ("Page not found") |
| Dead-end page (no navigation) | Always provide CTA + back link |
| Blame the user | Neutral, helpful tone |
| Complex illustrations | Single Lucide icon |
| Stack trace or debug info | Clean, minimal display |
