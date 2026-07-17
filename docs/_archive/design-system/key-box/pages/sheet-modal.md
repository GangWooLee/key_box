# Sheet Modal Page Overrides

> **PROJECT:** KeyBox
> **Page Type:** Create/Edit Secret (macOS Sheet Style)

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Layout Override — macOS Sheet

```
Window Title Bar
────────────────────────────────────
│          Sheet Modal (460px)      │  ← Slides down from title bar
│                                   │
│  Title ─────────────────────────  │
│  [                              ] │
│                                   │
│  Description ───────────────────  │
│  [                              ] │
│                                   │
│  Value ─────────────────────────  │
│  [                              ] │
│  [                              ] │
│  [                              ] │
│                                   │
│  ▶ Advanced Options               │  ← Progressive Disclosure
│                                   │
│         [Cancel]  [Save Secret]   │
────────────────────────────────────
```

### Sheet Specs

| Property | Value |
|----------|-------|
| Width | 460px |
| Max Height | 70vh |
| Background | `--surface-secondary` (#0f172a) |
| Border | `1px rgba(255,255,255,0.1)` |
| Border Radius | `0 0 12px 12px` (bottom only) |
| Shadow | `0 20px 40px rgba(0,0,0,0.6)` |
| Entry Animation | `translateY(-100%) → translateY(0)`, 250ms, cubic-bezier(0.2,0.8,0.2,1) |
| Exit Animation | `translateY(0) → translateY(-100%)`, 200ms, ease-in |

### Progressive Disclosure

**Default visible (3 fields):**
1. Title — text input (required, autofocus)
2. Description — text input
3. Value — textarea, 3 lines (required, monospace font)

**Advanced Options (collapsed by default):**

> **Internal Grouping** — Cognitive Load Theory: 5개 필드를 2 chunks로 그룹화하여 인지 부하 감소.

**Group 1: Classification (분류)**
- Type (dropdown): API Key, Token, Password, Certificate, Other
- Environment (dropdown): Production, Staging, Development, Test
- Folder (dropdown): from user's folder list

**Group 2: Organization (정리)**
- Service (text input): service name
- Tags (tag input): comma-separated

Groups are visually separated by `16px` gap. Each group has a subtle label header (12px, `text-muted`).

### Action Footer

| Element | Spec |
|---------|------|
| Cancel | Ghost button, left-aligned |
| Save Secret | Primary button (brand-600), right-aligned |
| Spacing | `justify-between`, `p-4` |
| Border | top `1px --border-subtle` |

### Overlay

- Background: `rgba(0,0,0,0.3)` + `backdrop-blur-sm`
- Click outside = close (with confirmation if dirty)
