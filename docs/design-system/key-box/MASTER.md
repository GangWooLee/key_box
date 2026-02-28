# KeyBox Design System — MASTER

> **LOGIC:** When building a specific page, first check `pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** KeyBox — Developer Credential Manager
**Generated:** 2026-02-28 (BM25 + V3 Design Review + Manual Enhancement)
**Category:** Developer Tool / Security / Credential Manager
**Platform:** Desktop-first (1440px), Tablet 768px, Mobile 375px

---

## V3 vs BM25 Gap Analysis

| 항목 | V3 디자인 결정 | BM25 추천 | 최종 결정 | 근거 |
|------|--------------|----------|----------|------|
| **스타일** | Swiss Clean + Minimal Professional | Vibrant & Block-based | **Minimalism & Swiss Style** | BM25의 Vibrant는 부적합. Swiss Style이 Developer Tool에 최적 (WCAG AAA) |
| **Primary** | Indigo #4F46E5 | Slate #1E293B | **Indigo #4F46E5** (Primary), Slate (Surface) | 브랜드 컬러 유지. BM25 Slate는 Surface 계열로 활용 |
| **CTA** | Indigo #4F46E5 | Green #22C55E | **Indigo #4F46E5** | 단일 브랜드 강조. Green은 Success 상태용 |
| **Background** | #0F172A (Dark) | #0F172A | **#0F172A** | 완벽 일치 |
| **Font (UI)** | -apple-system / Inter | Inter | **-apple-system, Inter 폴백** | macOS 네이티브 우선 |
| **Font (Code)** | SF Mono / JetBrains Mono | Fira Code / Fira Sans | **SF Mono, JetBrains Mono** | macOS 네이티브 우선 |
| **레이아웃** | ~~2-Column~~ → **3-Column** | - | **3-Column (Sidebar 200px + Table fluid + Detail 340px)** | 정보량 비례 원칙. 분류 구조 항시 가시성 |
| **아이콘** | Lucide Icons | Heroicons/Lucide | **Lucide Icons** | SF Pro와 기하학적 형태 일치 |
| **밀도** | High (28-32px inputs) | Standard (12px padding) | **High Density** | Developer tool은 정보 밀도 우선 |
| **Border Radius** | 6-8px (md/lg) | 8-16px | **6px (md), 8px (lg)** | Native macOS 느낌 유지 |

---

## Global Rules

### 1. Layout — 3-Column (Sidebar + Table + Detail)

> **V6 전환 (2026-02-28):** 2-Column → 3-Column. 정보량 ↔ 영역 크기 비례 원칙 적용. 분류 구조의 항시 가시성 확보.

```
Desktop (1440px+):
┌─────────┬────────────────────────────────────┬─────────────┐
│Sidebar  │ Table View                         │ Detail      │
│200px    │ fluid (900px @1440)                │ 340px       │
│Vibrancy │ slate-900                          │ slate-950   │
│         │                                    │             │
│Search   │  Name    Service   Env    Last     │ Name  [Env] │
│         │ ─────────────────────────────────  │ Value Box   │
│Category │  Live..  Stripe   Prod   2h  ←★   │ ▶ Details   │
│ list    │  Test..  Stripe   Dev    4h        │ ▶ Related   │
│         │  ...                                │ [Edit][Del] │
│Services │                                    │             │
│ tree    │          + Add Secret               │             │
└─────────┴────────────────────────────────────┴─────────────┘

Tablet (768px-1023px):
  2-Column (sidebar 숨김 → 햄버거, table + detail)

Mobile (<768px):
  단일 컬럼 (table만, detail = push navigation)
```

**Breakpoints:**

| 이름 | 최소 너비 | 레이아웃 |
|------|----------|---------|
| Mobile | 0px | 단일 컬럼, 테이블만 |
| Tablet | 768px (md) | 2-Column (table + detail), sidebar 햄버거 |
| Desktop | 1024px (lg) | 3-Column (180 + fluid + 300) |
| Wide | 1440px (xl) | 3-Column (200 + fluid + 340) |

### 2. Color Palette

**Brand:**
```css
@theme {
  --color-brand-50:  #eef2ff;
  --color-brand-100: #e0e7ff;
  --color-brand-500: #6366f1;
  --color-brand-600: #4f46e5;   /* Primary CTA */
  --color-brand-700: #4338ca;   /* Hover */
}
```

**Semantic Surfaces (Dark Mode):**

| Token | Dark Value | Usage |
|-------|-----------|-------|
| `--surface-primary` | `#020617` (slate-950) | Detail panel background |
| `--surface-secondary` | `#0f172a` (slate-900) | Table view background |
| `--surface-sidebar` | `rgba(15, 23, 42, 0.6)` + blur | Sidebar vibrancy |
| `--text-primary` | `#f1f5f9` (slate-100) | Headings, secret names |
| `--text-secondary` | `#94a3b8` (slate-400) | Metadata, timestamps |
| `--text-muted` | `#64748b` (slate-500) | Placeholders, hints |
| `--border-primary` | `rgba(255,255,255,0.1)` | Panel borders |
| `--border-subtle` | `rgba(255,255,255,0.06)` | Section dividers |

**State Colors:**

| State | Color | Hex | Usage |
|-------|-------|-----|-------|
| Success | Emerald | `#10B981` | 저장 성공, 복사 확인 |
| Warning | Amber | `#F59E0B` | 만료 임박, 주의 |
| Danger | Red | `#EF4444` | 삭제, 에러 |
| Info | Sky | `#0EA5E9` | 정보, 도움말 |

**Environment Badges:**

| 환경 | Background | Text | Border |
|------|-----------|------|--------|
| Production | `rgba(239,68,68,0.15)` | `#FCA5A5` | `rgba(239,68,68,0.3)` |
| Staging | `rgba(245,158,11,0.15)` | `#FCD34D` | `rgba(245,158,11,0.3)` |
| Development | `rgba(16,185,129,0.15)` | `#6EE7B7` | `rgba(16,185,129,0.3)` |
| Test | `rgba(148,163,184,0.15)` | `#CBD5E1` | `rgba(148,163,184,0.3)` |

### 3. Typography

**Font Stacks:**
```css
--font-sans: -apple-system, BlinkMacSystemFont, "Inter", system-ui, sans-serif;
--font-mono: "SF Mono", "JetBrains Mono", "Fira Code", ui-monospace, monospace;
```

**Type Scale:**

| Level | Size | Weight | Usage |
|-------|------|--------|-------|
| H1 | 24px | Bold 700 | Page titles |
| H2 | 20px | Semibold 600 | Section headings |
| H3 | 16px | Semibold 600 | Secret names in detail |
| Body | 16px | Regular 400 | Body text |
| Small | 14px | Regular 400 | List item names, labels |
| Caption | 12px | Medium 500 | Badges, timestamps |
| Code | 14px | Regular 400 | Secret values (font-mono) |

### 4. Spacing

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | 4px | Badge padding, tight gaps |
| `--space-sm` | 8px | Icon gaps, inline spacing |
| `--space-md` | 16px | Standard padding |
| `--space-lg` | 24px | Section padding |
| `--space-xl` | 32px | Panel padding |

### 5. Shadows (Dark Mode)

| Level | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 2px rgba(0,0,0,0.3)` | Subtle lift |
| `--shadow-md` | `0 4px 12px rgba(0,0,0,0.5)` | Popups, dropdowns |
| `--shadow-lg` | `0 10px 24px rgba(0,0,0,0.6)` | Modals |
| `--shadow-xl` | `0 20px 40px rgba(0,0,0,0.7)` | Command palette |

---

## Component Specs (Desktop Native Density)

### Buttons (5 variants)

| Variant | Height | Background | Text | Border |
|---------|--------|-----------|------|--------|
| Primary | 28-32px | `--brand-600` | white | none |
| Secondary | 28-32px | `rgba(255,255,255,0.05)` | `--text-primary` | `--border-primary` |
| Outline | 28-32px | transparent | `--text-secondary` | `--border-primary` |
| Danger | 28-32px | `#DC2626` | white | none |
| Ghost | 28-32px | transparent | `--text-secondary` | none |

**Common:** `rounded-md` (6px), `cursor-pointer`, `transition-colors duration-150`

### Table Rows (High Density)

- Height: 44px (single-line, 고밀도)
- **No card shadows, no thick borders**
- Hover: `bg-slate-800/50` fade-in (150ms)
- Selected: `bg-brand-600/10` + left accent border (2px brand-600)
- Columns: Name (fluid, 14px Medium) | Service (120px) | Environment (badge) | Last Used (100px, 12px)
- Separator: 1px `rgba(255,255,255,0.04)` between rows

### Input Fields

- Height: 28-32px
- Border: 1px `--border-primary`, `rounded-md`
- Focus: `ring-2 ring-brand-500 ring-offset-2 ring-offset-slate-900`
- Font: 14px Regular

### Badges

- `rounded-full`, `px-2 py-0.5`, `text-xs font-medium`
- Environment colors per table above

### Service Icons (Deterministic Hash Color)

- 서비스명 첫 글자를 컬러 원형 배경에 표시
- 서비스명 → hash → 8가지 프리셋 컬러 중 결정적 선택
- Size: 24x24px (list), 32x32px (detail)

---

## Animation

| Element | Transition | Duration | Easing |
|---------|-----------|----------|--------|
| List item hover | bg-color fade | 150ms | ease-in-out |
| Button hover | bg-color | 150ms | ease-in-out |
| Modal (Cmd+K) | scale(0.95→1) + opacity | 200ms | cubic-bezier(0.2,0,0,1) |
| Sheet modal | translateY(-100%→0) | 250ms | cubic-bezier(0.2,0.8,0.2,1) |
| Toast | translateX(100%→0) | 300ms | cubic-bezier(0.2,0,0,1) |
| Secret reveal | opacity crossfade | 150ms | ease |
| Copy feedback | icon dissolve (check) | 1500ms | ease-in-out |

**`prefers-reduced-motion`:** 모든 애니메이션 비활성화.

---

## Accessibility (WCAG AA)

- Color contrast: normal text 4.5:1, large text 3:1
- Touch targets: 44x44px minimum (mobile viewport only; desktop uses 28-32px native density)
- Focus ring: `focus-visible:ring-2 ring-brand-500 ring-offset-2`
- Keyboard: All interactive elements Tab-accessible. List items support arrow key navigation
- `aria-label`: Required for icon-only buttons
- Skip links: Provided for keyboard navigation

---

## CSS Token Mapping (Pencil → Code)

| Pencil Value | Tailwind Class | CSS Variable |
|-------------|---------------|-------------|
| `#020617` | `bg-slate-950` | `--surface-primary` |
| `#0f172a` | `bg-slate-900` | `--surface-secondary` |
| `#4f46e5` | `bg-indigo-600` | `--color-brand-600` |
| `#f1f5f9` | `text-slate-100` | `--text-primary` |
| `#94a3b8` | `text-slate-400` | `--text-secondary` |
| `rgba(255,255,255,0.1)` | `border-white/10` | `--border-primary` |
| `rgba(255,255,255,0.06)` | `border-white/[0.06]` | `--border-subtle` |

---

## Progressive Disclosure Principle

> **Core Design Philosophy**: 사용자의 80%+ 태스크(키 이름 확인 → 값 복사)를 최소 인지 부하로 완료할 수 있도록 정보를 단계적으로 노출한다.

### 3-Layer Rule

모든 정보가 밀집된 화면은 반드시 3-Layer Progressive Disclosure를 적용:

| Layer | 노출 방식 | 포함 정보 | 이론적 근거 |
|-------|----------|----------|------------|
| **Layer 1: Core** | 항상 보임 | 핵심 태스크 완료에 필요한 최소 정보 (3-4 chunks) | Miller's Law (4±1) |
| **Layer 2: Details** | 접이식 (기본 닫힘) | 보조 메타데이터, 분류 정보 | Cognitive Load Theory |
| **Layer 3: Related** | 접이식 (기본 닫힘) | 연관 항목, 부가 컨텍스트 | Hick's Law (선택지 축소) |

### 적용 지점

| 화면 | Layer 1 | Layer 2 | Layer 3 |
|------|---------|---------|---------|
| Detail Pane | 이름 + 환경 + 값 + 복사 | Description, Type, Folder, Tags, Dates | Related Secrets |
| Sheet Modal | Title + Description + Value | Classification (Type, Env, Folder) + Organization (Service, Tags) | — |
| Command Palette | 검색 + 결과 목록 | — | — |

### Disclosure Toggle Specs

| Property | Value |
|----------|-------|
| Height | 36px |
| Label | "▶ [Section Name]" (collapsed) / "▼ [Section Name]" (expanded) |
| Font | 14px Semibold, `text-secondary` |
| Hover | `bg-white/5`, `rounded-md` |
| Animation | `max-height` transition, 200ms ease-out |
| Persistence | 상태를 `localStorage`에 저장 (사용자 선호 유지) |

---

## Anti-Patterns (KeyBox Specific)

| Do NOT | Do Instead | Severity |
|--------|-----------|----------|
| 모든 메타데이터를 한 번에 노출 | Core만 노출, Details/Related 접이식 | **CRITICAL** |
| 빈 상태 없이 구현 | Empty State 필수 설계 (CTA + 도움말) | **CRITICAL** |
| 파괴적 액션에 별도 모달 | 인라인 확인 (컨텍스트 유지) | HIGH |
| Heavy rounded corners (16px+) | `rounded-md` (6px), `rounded-lg` (8px) | HIGH |
| Glassmorphism everywhere | Vibrancy only on list panel + modal overlays | HIGH |
| Fluffy pastel shadows | Sharp dark shadows (`rgba(0,0,0,0.5)`) | MEDIUM |
| Colorful gradients | Single accent (Indigo) + monochrome hierarchy | MEDIUM |
| Low information density | High density (28-32px inputs, 56px list items) | HIGH |
| Card-based list items | Edge-to-edge list with 1px borders | HIGH |
| Emojis as icons | Lucide Icons SVG | HIGH |
| Roboto, Arial fonts | -apple-system, Inter | HIGH |
| `h-screen` | `h-dvh` | MEDIUM |
| `h-6 w-6` | `size-6` | LOW |
| Hardcoded color values | `@theme` CSS variables | HIGH |
| 2-Column layout (List + Detail) | 3-Column (Sidebar + Table + Detail) | CRITICAL |
| Dropdown folder selector | Sidebar category/service tree (항시 가시) | CRITICAL |
| Detail pane > 400px width | Detail 340px (정보량에 비례) | HIGH |
| Table without sortable headers | 컬럼 헤더 클릭으로 정렬 | MEDIUM |

---

## Pre-Delivery Checklist

- [ ] No emojis used as icons (Lucide Icons SVG only)
- [ ] `cursor-pointer` on all clickable elements
- [ ] Hover states with smooth transitions (150ms)
- [ ] Text contrast 4.5:1 minimum (dark mode)
- [ ] Focus states visible (`focus-visible:ring-2`)
- [ ] `prefers-reduced-motion` respected
- [ ] Responsive: 375px, 768px, 1024px, 1440px tested
- [ ] 3-Column layout (Sidebar 200px + Table fluid + Detail 340px)
- [ ] Sidebar category/service tree functional
- [ ] Table sortable headers functional
- [ ] `@theme` CSS variables used (no hardcoded colors)
- [ ] `aria-label` on icon-only buttons
- [ ] Edge-to-edge list items (no card shadows)
- [ ] Desktop native density (28-32px inputs)
- [ ] **Progressive Disclosure: Detail pane uses 3-Layer structure**
- [ ] **Empty States: All empty conditions have CTA + help text**
- [ ] **Delete: Inline confirmation (no separate modal)**

---

**BM25 Source Queries:**
- Main: `"developer tool security credential manager minimal dark professional keyboard shortcuts"`
- Style: `"dark minimalism flat clean high density monospace"` → Minimalism & Swiss Style
- Color: `"security productivity dark indigo trust"` → Micro SaaS (#6366F1)
- UX: `"keyboard shortcuts accessibility 3-column sidebar table detail dashboard"`
- Typography: `"developer technical code monospace professional"` → Developer Mono
- Stack: `"dark minimal security dashboard"` → html-tailwind
