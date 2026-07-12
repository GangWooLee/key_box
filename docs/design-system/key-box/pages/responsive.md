# Responsive Design Specifications

> **PROJECT:** KeyBox
> **Page Type:** Responsive Breakpoints (Tablet + Mobile)
> **Version:** V7 (2026-03-01) — Full Redesign

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Design Principle

> **Mobile-first progressive enhancement.** Core functionality (search, copy, create) must work flawlessly at every breakpoint. Reduce, don't remove.

---

## Breakpoint Map

| Name | Range | Columns | Sidebar | Detail |
|------|-------|---------|---------|--------|
| Mobile | 0-767px | 1 | Hidden (hamburger) | Full-screen push |
| Tablet | 768-1023px | 2 | Hidden (hamburger) | Slide-over panel |
| Desktop | 1024-1439px | 3 | 180px | 300px |
| Wide | 1440px+ | 3 | 200px | 340px |

---

## Desktop (1024px+) — Reference

3-Column layout as specified in `dashboard.md`. This is the primary design target.

---

## Tablet (768-1023px)

### Layout Change

```
┌────────────────────────────────────┐
│ [☰] KeyBox          [⌘K] [+ Add] │  Top bar (48px)
├────────────────────────────────────┤
│ Name ▼   Service    Env    Last   │  Table header
├────────────────────────────────────┤
│ Live..   Stripe    [Prod]   2h    │  Table rows (full width)
│ Test..   Stripe    [Dev]    4h    │
│ gh_tok   GitHub    [Prod]   5d    │
│ aws_ac   AWS       [Stag]   5d    │
│ ...                               │
├────────────────────────────────────┤
│              24 secrets            │  Footer
└────────────────────────────────────┘
         ┌──────────────────┐
         │   Detail Panel   │  ← Slide-over (340px, right)
         │   (overlay)      │
         └──────────────────┘
```

### Top Bar

| Element | Spec |
|---------|------|
| Height | 48px |
| Background | `bg-slate-900`, `border-b border-white/10` |
| Hamburger | Lucide `menu`, 20px, `text-secondary`, left |
| Logo | "KeyBox", 16px Semibold, center |
| Actions | Search icon (⌘K) + Add button, right |

### Sidebar (Hamburger Menu)

| Property | Value |
|----------|-------|
| Trigger | Hamburger icon tap |
| Width | 280px |
| Position | Slide-in from left |
| Overlay | `bg-black/30`, `backdrop-blur-sm` |
| Animation | `translateX(-100%→0)`, 250ms ease |
| Close | Tap overlay or swipe left or Lucide `x` button |
| Content | Same as desktop sidebar |

### Table View

| Property | Value |
|----------|-------|
| Width | Full viewport |
| Columns | Name (fluid), Service (120px), Env (badge), Last Used (80px) |
| Row Height | 48px (slightly larger for touch) |

### Detail Panel (Slide-Over)

| Property | Value |
|----------|-------|
| Trigger | Row tap in table |
| Width | 340px |
| Position | Fixed right, full height |
| Overlay | `bg-black/30`, `backdrop-blur-sm` |
| Animation | `translateX(100%→0)`, 250ms ease |
| Close | Swipe right, tap overlay, or close button |
| Content | Same as desktop detail panel |

---

## Mobile (<768px)

### Layout Change

```
┌────────────────────────────┐
│ [☰] KeyBox       [⌘K] [+]│  Top bar (48px)
├────────────────────────────┤
│ Live API Key       [Prod] │  Simplified row
│ Stripe · 2h ago           │  2-line layout
├────────────────────────────┤
│ Test API Key        [Dev] │
│ Stripe · 4h ago           │
├────────────────────────────┤
│ GitHub Token       [Prod] │
│ GitHub · 5d ago           │
├────────────────────────────┤
│ ...                       │
├────────────────────────────┤
│         24 secrets        │
└────────────────────────────┘
```

### Top Bar

| Element | Spec |
|---------|------|
| Height | 48px |
| Hamburger | Left, 44x44 touch target |
| Logo | "KeyBox", 16px Semibold, center |
| Actions | Search (44x44), Add (44x44), right |
| Padding | `px-4` |

### Table Rows (Mobile)

| Property | Value |
|----------|-------|
| Height | 64px (2-line layout) |
| Layout | Vertical within each row |
| Line 1 | Secret name (14px Medium, `text-primary`) + Env badge (right) |
| Line 2 | Service name + " · " + relative time (12px, `text-muted`) |
| Separator | `1px rgba(255,255,255,0.04)` |
| Padding | `px-4 py-3` |
| Touch Target | Full row, 64px minimum |

### Detail View (Full-Screen Push)

| Property | Value |
|----------|-------|
| Trigger | Row tap |
| Transition | Push navigation (slide left), 250ms |
| Header | "← Back" + Secret name, 48px |
| Content | Full-screen, same fields as desktop detail |
| Scroll | Vertical scroll if content overflows |
| Close | "← Back" button or swipe right (iOS gesture) |

### Sidebar (Hamburger — same as Tablet)

Same as tablet hamburger menu but full-height.

---

## Component Responsive Overrides

### Sheet Modal

| Viewport | Behavior |
|----------|---------|
| Desktop | 460px centered, slide-down from top |
| Tablet | 460px centered, slide-down |
| Mobile | Full-width bottom sheet, rounded top corners (12px), slide-up |

#### Mobile Bottom Sheet

| Property | Value |
|----------|-------|
| Width | `100vw` |
| Max Height | `85vh` |
| Border Radius | `12px 12px 0 0` (top only) |
| Handle | 40x4px pill, `bg-white/20`, center top, `mt-2` |
| Animation | `translateY(100%→0)`, 300ms ease |
| Dismiss | Swipe down or tap overlay |

### Command Palette

| Viewport | Behavior |
|----------|---------|
| Desktop | 560px centered, fixed position |
| Tablet | 480px centered |
| Mobile | Full-width, top-fixed, `px-4` margin, max-height 70vh |

### Toast

| Viewport | Position |
|----------|---------|
| Desktop/Tablet | Top-right, 320px width |
| Mobile | Top-center, `calc(100vw - 32px)` width |

### Delete Confirmation

| Viewport | Behavior |
|----------|---------|
| All | Inline within detail panel (no change needed) |
| Mobile | Inline within full-screen detail view |

---

## Touch Targets

All interactive elements on mobile/tablet viewports:

| Element | Minimum Size |
|---------|-------------|
| Buttons | 44x44px |
| Table rows | 48px height (tablet), 64px (mobile) |
| Icon buttons | 44x44px |
| Checkbox/Radio | 44x44px touch area |
| Links | 44px line-height |
| Close buttons | 44x44px |

---

## Typography Scale (Mobile)

| Level | Desktop | Mobile |
|-------|---------|--------|
| H1 | 24px | 20px |
| H2 | 20px | 18px |
| Body | 16px | 16px (no change) |
| Small | 14px | 14px |
| Caption | 12px | 12px |

**Minimum body text**: 16px on mobile (prevents iOS zoom on focus).

---

## Gesture Support (Mobile)

| Gesture | Action |
|---------|--------|
| Swipe right on detail | Close detail, return to list |
| Swipe down on bottom sheet | Dismiss modal |
| Swipe right on toast | Dismiss toast |
| Pull down on list | Refresh (if applicable) |
| Long press on row | Context menu (Copy, Edit, Delete) |

---

## Animation (Mobile)

| Transition | Duration | Note |
|-----------|----------|------|
| Push navigation | 250ms | iOS-style slide |
| Bottom sheet | 300ms | Spring-like ease |
| Hamburger menu | 250ms | Slide + overlay fade |
| All transitions | 0ms | If `prefers-reduced-motion` |

---

## Accessibility (Mobile-Specific)

- Minimum font size: 16px body (prevents iOS zoom)
- Touch targets: 44x44px minimum
- Swipe gestures: Always have button alternatives
- Bottom sheet handle: `aria-label="Drag to dismiss"`
- Hamburger: `aria-label="Open navigation menu"`, `aria-expanded`
- Focus trap: Active when modal/sheet/sidebar is open

---

## Anti-Patterns

| Do NOT | Do Instead |
|--------|-----------|
| Hide core features on mobile | Reduce UI, keep all functionality |
| Tiny tap targets (<44px) | 44px minimum on all touch viewports |
| Horizontal scroll on mobile | Stack vertically, hide non-essential columns |
| Desktop modals on mobile | Bottom sheets (native feel) |
| Gesture-only interactions | Always provide button alternative |
| `h-screen` | `h-dvh` (accounts for mobile browser chrome) |
| Fixed position elements blocking content | Safe area padding (`env(safe-area-inset-bottom)`) |
