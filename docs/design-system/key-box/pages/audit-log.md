# Audit Log Page

> **PROJECT:** KeyBox
> **Page Type:** Audit Log (Activity History)
> **Version:** V7 (2026-03-01) — Full Redesign

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Design Principle

> Scannable timeline of all secret interactions. Filter-first design for quick forensics. Expandable rows for detail-on-demand.

---

## Layout — Full-Width Content Area

Audit Log replaces the 3-column dashboard with a single full-width content area, accessed via sidebar navigation or a dedicated route.

```
┌──────────────────────────────────────────────────────────────┐
│ ← Back to Dashboard          Audit Log                       │
│                                                              │
│ Action [All ▼]  Period [Last 7d ▼]  Search [____________]   │  Filter bar
│                                                              │
│ ● Create  "Stripe API Key"    john@ex.com    2h ago         │  Expandable row
│ ● Copy    "GitHub Token"      john@ex.com    4h ago         │
│ ● Update  "AWS Access Key"    john@ex.com    1d ago         │
│ ● Delete  "Old Test Key"      john@ex.com    3d ago         │
│                                                              │
│ ◀ 1 2 3 ▶                                     50 per page  │
└──────────────────────────────────────────────────────────────┘
```

---

## Page Specs

### Header Bar

| Element | Spec |
|---------|------|
| Back Link | Lucide `arrow-left` 16px + "Back to Dashboard", 14px, `text-secondary`, `hover:text-primary` |
| Title | "Audit Log" — 24px Semibold, `text-primary` |
| Layout | Flex row, `items-center`, `justify-between`, `mb-6` |

### Filter Bar

| Element | Spec |
|---------|------|
| Container | `bg-white/[0.03]`, `rounded-lg`, `p-3`, `mb-4` |
| Layout | Flex row, `gap-3`, `items-center` |

#### Action Filter (Dropdown)

| Property | Value |
|----------|-------|
| Label | "Action" — 12px, `text-muted` |
| Options | All, Create, Copy, Update, Delete, Reveal |
| Width | 140px |
| Style | Select component from design system |

#### Period Filter (Dropdown)

| Property | Value |
|----------|-------|
| Label | "Period" — 12px, `text-muted` |
| Options | Last 24h, Last 7d, Last 30d, Last 90d, All time |
| Default | Last 7d |
| Width | 140px |

#### Search

| Property | Value |
|----------|-------|
| Placeholder | "Search by secret name or user..." |
| Width | `flex-1` (fill remaining) |
| Debounce | 300ms |
| Style | Input with Lucide `search` 16px leading icon |

---

## Log Entry Row

### Collapsed State (Default)

| Element | Spec |
|---------|------|
| Height | 48px |
| Layout | Grid: `action-dot 8px` | `action-label 80px` | `secret-name flex-1` | `user 160px` | `timestamp 100px` | `expand 32px` |
| Hover | `bg-white/[0.03]` |
| Border | Bottom `1px rgba(255,255,255,0.04)` |
| Padding | `px-4` |

#### Action Dot Colors

| Action | Dot Color | Label |
|--------|-----------|-------|
| Create | `bg-emerald-500` | "Create" |
| Copy | `bg-sky-500` | "Copy" |
| Update | `bg-amber-500` | "Update" |
| Delete | `bg-red-500` | "Delete" |
| Reveal | `bg-violet-500` | "Reveal" |

#### Row Content

| Element | Spec |
|---------|------|
| Action Dot | 8px circle, color per action type |
| Action Label | 12px Medium, `text-secondary` |
| Secret Name | 14px Medium, `text-primary`, truncate with ellipsis |
| User | 14px Regular, `text-secondary`, truncate |
| Timestamp | 12px Regular, `text-muted`, relative time |
| Expand Icon | Lucide `chevron-down` 16px, `text-muted`, rotate on expand |

### Expanded State (Click to expand)

```
│ ● Create  "Stripe API Key"    john@ex.com    2h ago    ▼    │
│   ┌──────────────────────────────────────────────────────┐   │
│   │ IP Address    127.0.0.1                              │   │
│   │ User Agent    Chrome 120 / macOS 15.2                │   │
│   │ Changes       name: "old name" → "new name"          │   │
│   │               tags: added "production"                │   │
│   └──────────────────────────────────────────────────────┘   │
```

| Element | Spec |
|---------|------|
| Container | `bg-white/[0.02]`, `rounded-md`, `p-4`, `mx-4 mb-2` |
| Layout | 2-column grid, label + value |
| Label | 12px Medium, `text-muted`, 120px width |
| Value | 14px Regular, `text-secondary` |
| Changes | Diff-style: old value `text-red-400` + `line-through`, new value `text-emerald-400` |
| Animation | `max-height` + `opacity` transition, 200ms ease-out |

#### Detail Fields

| Field | Content |
|-------|---------|
| IP Address | Request IP |
| User Agent | Browser + OS |
| Changes | Field-level diff (for Update action) |
| Previous Value | Masked `••••••••` (for security) |

---

## Pagination

| Element | Spec |
|---------|------|
| Position | Bottom of log, `mt-4` |
| Layout | Flex row, `justify-between`, `items-center` |
| Page Info | "Showing 1-50 of 234" — 12px, `text-muted` |
| Per Page | "50 per page" — 12px, `text-muted`, right |
| Buttons | Previous / Next, Ghost buttons with Lucide `chevron-left`/`chevron-right` |
| Page Numbers | Current: `bg-brand-600`, `text-white`. Others: Ghost button style |
| Disabled | `opacity-50`, `cursor-not-allowed` |

---

## Empty State

| Element | Spec |
|---------|------|
| Icon | Lucide `scroll-text`, 48px, `text-slate-500`, `opacity-60` |
| Title | "No activity yet" — 20px Semibold, `text-primary` |
| Description | "Activity will appear here as you use KeyBox" — 14px, `text-secondary` |
| Layout | Center-aligned, `py-16` |

---

## Animation

| Element | Transition | Duration |
|---------|-----------|----------|
| Row expand | `max-height` + `opacity`, 200ms ease-out |
| Row collapse | `max-height` + `opacity`, 150ms ease-in |
| Filter change | Table content fade, 150ms |
| Chevron rotate | `rotate(0→180deg)`, 200ms |

---

## Accessibility

- Table: `role="table"` with proper `role="row"`, `role="cell"`
- Expand/collapse: `aria-expanded="true/false"`, `aria-controls="detail-N"`
- Filter changes: `aria-live="polite"` on results count
- Pagination: `aria-label="Pagination"`, `aria-current="page"` on active
- Action dots: `aria-label="[Action] action"` (not just color)
- Keyboard: Tab to rows, Enter/Space to expand, arrow keys optional

---

## Anti-Patterns

| Do NOT | Do Instead |
|--------|-----------|
| Show full secret values in log | Always mask values `••••••••` |
| Auto-refresh without indicator | Manual refresh or polling indicator |
| Infinite scroll | Pagination (predictable, bookmarkable) |
| Complex nested filters | Flat filter bar, max 3 filters |
| Color-only action indicators | Dot + text label (color blind safe) |
