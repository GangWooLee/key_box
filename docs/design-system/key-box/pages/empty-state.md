# Empty State Page Overrides

> **PROJECT:** KeyBox
> **Page Type:** Empty State (No Secrets / Onboarding)
> **Version:** V6 (2026-02-28) — 3-Column Layout

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Design Principle

> **Empty State Onboarding** (design-knowledge-base §7.4): 첫 사용 경험이 제품의 첫인상을 결정한다. 빈 상태는 "아무것도 없다"가 아니라 "시작하세요"를 전달해야 한다.

---

## Layout Override — 3-Column Empty State

```
┌─────────┬────────────────────────────────────┬─────────────┐
│Sidebar  │ Table View                         │ Detail      │
│200px    │ fluid                              │ 340px       │
│         │                                    │             │
│Search   │                                    │             │
│         │                                    │             │
│All Keys │       (empty table area)           │  Select a   │
│API Keys │                                    │  secret to  │
│Tokens   │    🔑                              │  view       │
│Passwords│                                    │  details    │
│Certific.│    No secrets yet                  │             │
│         │                                    │             │
│─────────│    Store your first API key,       │             │
│SERVICES │    token, or credential.           │             │
│ (empty) │                                    │             │
│         │    [+ Add Your First Secret]       │             │
│         │                                    │             │
│         │    Tip: ⌘K to quick search         │             │
│         │                                    │             │
└─────────┴────────────────────────────────────┴─────────────┘
```

### Trigger Conditions

| Condition | Display |
|-----------|---------|
| 0 secrets total | Full empty state (Table View area) + Detail empty |
| 0 secrets in selected category/service | Category-specific empty state in Table View |
| 0 search results | Command Palette empty state (별도: `command-palette.md`) |
| No secret selected | Detail Panel empty state |

---

## Table View Empty State

### Global Empty (0 secrets total)

| Element | Spec |
|---------|------|
| Icon | Lucide `key-round`, 48x48px, `text-brand-500`, `opacity-60` |
| Title | "No secrets yet" — 20px Semibold, `text-primary` |
| Description | "Store your first API key, token, or credential." — 14px, `text-secondary`, max-width 280px, center-aligned |
| CTA Button | Primary button (brand-600), "Add Your First Secret", 32px height |
| Tip | "Tip: Use ⌘K to quickly search and copy secrets." — 12px, `text-muted` |
| Layout | Flex column, center-aligned (vertical + horizontal), `gap-4` |
| CTA Action | Opens Sheet Modal (Create) |

### Category/Service Empty (0 secrets in selected filter)

| Element | Spec |
|---------|------|
| Icon | Lucide `folder-open`, 40x40px, `text-slate-500`, `opacity-50` |
| Title | "No secrets in [category/service name]" — 16px Semibold, `text-secondary` |
| Description | "Add a secret or select another category." — 14px, `text-muted` |
| CTA Button | Secondary button (outline), "Add Secret" |
| Layout | Same as global, slightly smaller scale |

---

## Detail Panel Empty State

키가 선택되지 않았을 때 Detail Panel에 표시:

| Element | Spec |
|---------|------|
| Message | "Select a secret to view details" — 14px, `text-muted`, center-aligned |
| Position | 패널 중앙 (vertical + horizontal center) |

---

## Sidebar Empty State (Services)

시크릿이 0개일 때 Services 섹션:

| Element | Spec |
|---------|------|
| Display | "SERVICES" 헤더는 유지, 아래 "No services yet" 12px `text-muted` |

---

## Animation

| Element | Transition | Duration |
|---------|-----------|----------|
| Icon | Subtle `opacity: 0→0.6` fade-in | 300ms |
| Text + CTA | `opacity: 0→1` + `translateY(8px→0)` | 400ms, 100ms delay |
| Tip | `opacity: 0→1` | 500ms, 200ms delay |

**`prefers-reduced-motion`:** 모든 애니메이션 비활성화, 즉시 표시.

---

## Accessibility

- CTA 버튼: `aria-label="Add your first secret"`
- 아이콘: decorative (`aria-hidden="true"`)
- 전체 영역: `role="status"` (스크린 리더에게 상태 전달)

---

## Anti-Patterns

| Do NOT | Do Instead |
|--------|-----------|
| 빈 상태를 그냥 비워두기 | 항상 CTA + 도움말 제공 |
| 복잡한 일러스트/애니메이션 | 단일 아이콘 + 텍스트 (미니멀) |
| "데이터가 없습니다" 기술적 메시지 | 사용자 행동 유도 메시지 |
| 여러 CTA 동시 표시 | 하나의 주요 CTA (Hick's Law) |
| 3-Column 모두 빈 상태 | Table View에 CTA 집중, 나머지는 간결한 안내 |
