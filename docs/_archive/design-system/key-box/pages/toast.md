# Toast System

> **PROJECT:** KeyBox
> **Page Type:** Toast Notifications (4 Variants)
> **Version:** V7 (2026-03-01) — Full Redesign

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Design Principle

> Non-blocking feedback. Appears, informs, disappears. Never interrupts workflow.

---

## Position & Stacking

| Property | Value |
|----------|-------|
| Position | Fixed, top-right corner |
| Offset | `top: 16px`, `right: 16px` |
| Stack Direction | Vertical, newest on top |
| Max Visible | 3 toasts (oldest auto-dismissed when 4th arrives) |
| Stack Gap | `8px` between toasts |
| Z-Index | `z-50` |

### Responsive Position

| Viewport | Position |
|----------|---------|
| Desktop (1024px+) | Top-right, 320px width |
| Tablet (768-1023px) | Top-right, 320px width |
| Mobile (<768px) | Top-center, `calc(100vw - 32px)` width |

---

## Toast Anatomy

```
┌──────────────────────────────────┐
│ [icon]  Message text       [×]   │  Single line preferred
│         Secondary text           │  Optional, 12px
└──────────────────────────────────┘
```

### Shared Specs

| Property | Value |
|----------|-------|
| Width | 320px (desktop), full-width minus padding (mobile) |
| Min Height | 44px |
| Padding | `px-4 py-3` |
| Background | `#1e293b` (slate-800) |
| Border | `1px rgba(255,255,255,0.1)` |
| Border Radius | `rounded-lg` (8px) |
| Shadow | `--shadow-md` |
| Font (Message) | 14px Medium, `text-primary` |
| Font (Secondary) | 12px Regular, `text-muted` |
| Icon Size | 16px |
| Close Button | Lucide `x`, 14px, `text-muted`, Ghost button 28x28 |

---

## 4 Toast Variants

### 1. Success

| Property | Value |
|----------|-------|
| Icon | Lucide `check-circle`, `text-emerald-400` |
| Left Accent | 3px `bg-emerald-500` (left border) |
| Example | "Secret saved successfully" |
| Auto-Dismiss | 3 seconds |

### 2. Error

| Property | Value |
|----------|-------|
| Icon | Lucide `alert-circle`, `text-red-400` |
| Left Accent | 3px `bg-red-500` |
| Example | "Failed to save secret" |
| Auto-Dismiss | 5 seconds (longer for errors) |
| Action | Optional "Retry" text button |

### 3. Info (Copy Feedback)

| Property | Value |
|----------|-------|
| Icon | Lucide `clipboard-check`, `text-sky-400` |
| Left Accent | 3px `bg-sky-500` |
| Message | "Copied to clipboard" |
| Secondary | "Clears in 30s" |
| Auto-Dismiss | 3 seconds |

### 4. Undo (Delete Feedback)

| Property | Value |
|----------|-------|
| Icon | Lucide `trash-2`, `text-slate-400` |
| Left Accent | 3px `bg-slate-500` |
| Message | "Deleted \"[Secret Name]\"" |
| Action Button | "Undo" — `text-brand-400`, 14px Medium |
| Auto-Dismiss | 5 seconds |
| Undo Window | Action available for full 5 seconds |

---

## Animation

| Action | Animation | Duration | Easing |
|--------|-----------|----------|--------|
| Enter | `translateX(100%) → translateX(0)` + `opacity: 0→1` | 300ms | cubic-bezier(0.2,0,0,1) |
| Exit (dismiss) | `opacity: 1→0` + `translateX(0→20px)` | 200ms | ease-in |
| Exit (auto) | `opacity: 1→0` | 200ms | ease-in |
| Stack reflow | `translateY` shift, 200ms | 200ms | ease-out |
| Progress bar | Width 100%→0%, linear | equals auto-dismiss duration |

### Progress Indicator

| Property | Value |
|----------|-------|
| Height | 2px |
| Position | Bottom edge of toast |
| Color | Matches left accent color, `opacity-50` |
| Animation | Width shrinks from 100% to 0% over dismiss duration |
| Pause | Hover pauses countdown and progress |

---

## Interaction

| Action | Behavior |
|--------|----------|
| Hover | Pause auto-dismiss timer, show close button |
| Click close (x) | Immediate dismiss with exit animation |
| Click "Undo" | Reverse action, dismiss toast, show success toast |
| Swipe right (mobile) | Dismiss toast |
| `prefers-reduced-motion` | No slide/fade, instant show/hide |

---

## Accessibility

- `role="status"`, `aria-live="polite"` (success/info)
- `role="alert"`, `aria-live="assertive"` (error)
- Close button: `aria-label="Dismiss notification"`
- Undo button: `aria-label="Undo delete"`
- Auto-dismiss pause on focus (keyboard navigation)
- Toast region: `aria-label="Notifications"`

---

## Anti-Patterns

| Do NOT | Do Instead |
|--------|-----------|
| Stack more than 3 toasts | Dismiss oldest, queue new |
| Block user interaction | Non-modal, overlays nothing interactive |
| Use for critical errors | Use inline error states for critical failures |
| Animate on reduced-motion | Instant show/hide |
| Toast for form validation | Inline field errors |
