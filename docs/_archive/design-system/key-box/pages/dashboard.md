# Dashboard Page Overrides — 3-Column Layout

> **PROJECT:** KeyBox
> **Page Type:** Main Dashboard (3-Column: Sidebar + Table + Detail)
> **Version:** V6 (2026-02-28) — 2-Column -> 3-Column Native Layout

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Layout Override — 3-Column (Sidebar + Table + Detail)

```
┌─────────┬────────────────────────────────────┬─────────────┐
│Sidebar  │ Table View                         │ Detail      │
│200px    │ fluid (900px @1440)                │ 340px       │
│         │                                    │             │
│Search   │ ┌──────────────────────────────┐   │ Name  [Env] │
│         │ │  Name    Service  Env  Last  │   │ Service     │
│All Keys │ ├──────────────────────────────┤   │             │
│API Keys │ │ ● Live..  Stripe  Prod  2h   │←★│ ┌─────────┐ │
│Tokens   │ │   Test..  Stripe  Dev   4h   │   │ │ ••••••  │ │
│Passwords│ │   Webho.. Stripe  Prod  1d   │   │ │ 👁 Copy │ │
│Certific.│ │   github  GitHub  Prod  5d   │   │ └─────────┘ │
│         │ │   aws_ac  AWS     Stag  5d   │   │             │
│─────────│ │   ...                         │   │ ▶ Details   │
│SERVICES │ └──────────────────────────────┘   │ ▶ Related   │
│● Stripe │ │         + Add Secret          │   │             │
│● GitHub │ │                                │   │ [Edit][Del] │
│● AWS (5)│ │                                │   │             │
│● GCP    │                                    │             │
│● Vercel │                                    │             │
└─────────┴────────────────────────────────────┴─────────────┘
```

### 정보량 ↔ 영역 크기 비례 원칙

| 영역 | 너비 | 정보량 | 근거 |
|------|------|--------|------|
| Sidebar | 200px (고정) | 카테고리 5-7개 + 서비스 5-10개 | 텍스트 + 아이콘 + 카운트 = 200px 충분 |
| Table | fluid (~900px @1440) | 키 20-50개 × 4컬럼 | 가장 많은 정보, 가장 큰 영역 |
| Detail | 340px (고정) | 메타 5-6필드 + 값 1개 | 실제 정보량에 비례 |

---

## Column 1: Sidebar (200px)

- **Background:** `rgba(15, 23, 42, 0.6)` + `backdrop-blur-xl backdrop-saturate-[180%]` (Vibrancy)
- **Right border:** `1px rgba(255,255,255,0.1)`
- **Layout:** Vertical flex

### Search Bar (36px, sticky top)

| Element | Spec |
|---------|------|
| Container | 36px height, `rounded-md`, `bg-white/5`, `border-white/10` |
| Shortcut Badge | "⌘K", 11px Medium, `text-slate-500` |
| Placeholder | "Search secrets...", 13px Regular, `text-slate-600` |
| Padding | 4px vertical, 12px horizontal |

### Category List

| Element | Spec |
|---------|------|
| Item Height | 32px |
| Icon | 14px (emoji or Lucide) |
| Label | 13px Regular, `text-secondary` |
| Count | 11px Medium, `text-muted`, right-aligned |
| Selected State | `bg-brand-600/10` + left accent 2px `brand-600`, label `text-primary` |
| Hover | `bg-white/5` |

**Categories:** All Keys, API Keys, Tokens, Passwords, Certificates

### Services Section

| Element | Spec |
|---------|------|
| Section Header | "SERVICES", 10px Semibold, `text-slate-600`, `letter-spacing: 1px` |
| Divider | 1px `rgba(255,255,255,0.06)` above header |
| Item Height | 30px |
| Color Dot | 8px circle, deterministic hash color from service name |
| Service Name | 13px Regular, `text-slate-300` |
| Count | 11px Regular, `text-muted`, right-aligned |
| Hover | `bg-white/5` |

**Hash Color Presets:** Indigo(`#6366F1`), Orange(`#F97316`), Amber(`#F59E0B`), Emerald(`#10B981`), Pink(`#EC4899`), Sky(`#0EA5E9`), Violet(`#8B5CF6`), Rose(`#F43F5E`)

---

## Column 2: Table View (fluid)

- **Background:** `#0f172a` (slate-900)
- **Layout:** Vertical flex

### Table Header (36px, sticky top)

| Element | Spec |
|---------|------|
| Background | `rgba(255,255,255,0.03)` |
| Bottom border | `1px rgba(255,255,255,0.06)` |
| Columns | Name (fluid), Service (120px), Environment (120px), Last Used (100px) |
| Font | 12px Medium, `text-muted` |
| Padding | 0 16px |
| Sort | 컬럼 헤더 클릭 시 정렬 (▲/▼ 인디케이터) |

### Data Rows (44px, single-line)

| Element | Spec |
|---------|------|
| Height | 44px (고밀도, single-line) |
| Hover | `bg-slate-800/50` fade-in (150ms) |
| Selected | `bg-brand-600/10` + left accent 2px `brand-600` |
| Name | 14px Medium, `text-primary` (selected) or `text-slate-300` |
| Service | 14px Regular, `text-secondary` |
| Environment | 환경 뱃지 (기존 컬러 토큰 재사용), `rounded-full`, 11px |
| Last Used | 12px Regular, `text-muted`, 상대 시간 ("2h ago") |
| Separator | 1px `rgba(255,255,255,0.04)` between rows |
| Padding | 0 16px |

### Bottom Bar (44px, sticky bottom)

| Element | Spec |
|---------|------|
| Top border | `1px rgba(255,255,255,0.06)` |
| Add Button | Primary `brand-600`, "+" + "Add Secret", `rounded-md`, 13px |
| Count | "N secrets", 12px Regular, `text-muted`, right-aligned |
| Padding | 0 16px |

### Context Menu (우클릭)

| Action | Shortcut |
|--------|----------|
| Copy Value | ⌘C |
| Edit | ⌘E |
| Delete | ⌘⌫ |

---

## Column 3: Detail Panel (340px)

- **Background:** `#020617` (slate-950)
- **Left border:** `1px rgba(255,255,255,0.1)`
- **Layout:** Vertical flex, padding 20px
- **Design Principle:** Progressive Disclosure (Miller's Law 4±1 chunks)

### Layer 1: Core (항상 보임)

핵심 태스크(이름 확인 → 값 복사)를 즉시 완료할 수 있는 최소 정보만 노출.

| Element | Spec |
|---------|------|
| Secret Name | 16px Semibold, `text-primary` |
| Environment Badge | 오른쪽 정렬, `rounded-full`, 환경별 컬러 |
| Service Indicator | 10px hash color dot + service name (14px, `text-secondary`) |
| Timestamp | "2h ago", `text-muted` (12px), right-aligned |
| Value Box | `bg-white/5`, `rounded-lg`, `p-3`, border `1px white/10` |
| Value Text | Monospace 13px (`JetBrains Mono`), masked `••••••••` |
| Reveal Button | Ghost button, "👁 Reveal", `text-secondary` |
| Copy Button | Primary `brand-600`, "📋 Copy" |

**Cognitive Load:** 3 chunks (이름+환경, 서비스+시간, 값+복사) = Miller's Law 범위 내

### Layer 2: Details (접이식, 기본 닫힘)

| Element | Spec |
|---------|------|
| Toggle Header | "▶ Details" / "▼ Details", 13px Medium, `text-secondary` |
| Content | `grid-cols-2`, `gap-y-2`, 13px labels |
| Fields | Description, Type, Folder, Tags, Created, Last used |
| Animation | `max-height` transition, 200ms ease-out |
| Divider | top `1px rgba(255,255,255,0.06)` |

### Layer 3: Related (접이식, 기본 닫힘)

| Element | Spec |
|---------|------|
| Toggle Header | "▶ Related Secrets (N)", 13px Medium, `text-secondary` |
| Content | 관련 시크릿 목록 (이름 + 환경 뱃지), 클릭 시 해당 시크릿으로 이동 |
| Empty State | 0개이면 섹션 자체 미노출 |

### Action Footer (하단 고정)

| Element | Spec |
|---------|------|
| Edit Button | Outline button, `border-white/10`, `text-secondary` |
| Delete Button | Ghost danger, `text-red-500`, right-aligned |
| Position | Detail pane 하단 고정, `border-top: 1px rgba(255,255,255,0.06)` |
| Height | 44px |

### Empty State (키 미선택)

키가 선택되지 않았을 때 Detail Panel에 표시:

| Element | Spec |
|---------|------|
| Message | "Select a secret to view details" — 14px, `text-muted`, center-aligned |
| Position | 패널 중앙 (vertical + horizontal center) |

---

## Responsive Breakpoints

| Name | Width | Layout |
|------|-------|--------|
| Desktop Wide | ≥1440px | 3-Column (200 + fluid + 340) |
| Desktop | 1024-1439px | 3-Column (180 + fluid + 300) |
| Tablet | 768-1023px | 2-Column (sidebar 숨김 → 햄버거, table + detail) |
| Mobile | <768px | 단일 컬럼 (table만, detail = push navigation) |

---

## Interaction Override

- **Sidebar → Table:** 카테고리/서비스 클릭 시 테이블 필터링 (Turbo Frame)
- **Table → Detail:** 행 클릭 시 Detail Panel 업데이트 (Turbo Frame, no page reload)
- **Copy button:** Click → icon transitions to checkmark (1.5s) → returns to copy icon
- **Secret reveal:** Eye icon toggles mask ↔ value with 150ms crossfade
- **Keyboard:** ↑↓ to navigate table rows, Enter to select, Esc to deselect
- **Table sort:** 컬럼 헤더 클릭 시 정렬 (▲/▼), 기본 정렬: Last Used (최신 순)
- **Context menu:** 테이블 행 우클릭 → Copy Value, Edit, Delete
- **Disclosure toggle:** Click header to expand/collapse, `max-height` transition 200ms
- **Delete confirmation:** Inline confirmation (see `pages/delete-confirmation.md`)
