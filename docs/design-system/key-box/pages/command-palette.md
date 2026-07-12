# Command Palette Page Overrides

> **PROJECT:** KeyBox
> **Page Type:** Global Search Overlay (Cmd+K / Spotlight Style)

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Layout Override — Floating Overlay

```
┌─────────────────────────────────────┐
│         Blurred Background          │
│                                     │
│   ┌─────────────────────────────┐   │
│   │ 🔍  Search secrets...      │   │  ← 560px wide, centered
│   ├─────────────────────────────┤   │
│   │ ▶ stripe prod key    Prod  │   │  ← Active (brand tint)
│   │   AWS access key     Stag  │   │
│   │   GitHub token       Dev   │   │
│   ├─────────────────────────────┤   │
│   │ ↵ Copy  ↑↓ Navigate  Esc  │   │  ← Footer hints
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### Modal Specs

| Property | Value |
|----------|-------|
| Width | 560px |
| Position | Center (vertical + horizontal) |
| Background | `rgba(15, 23, 42, 0.95)` |
| Border | `1px rgba(255,255,255,0.15)` + top edge glow |
| Border Radius | `12px` |
| Shadow | `0 24px 48px rgba(0,0,0,0.7)`, `blur-3xl` |
| Entry Animation | scale(0.95→1) + opacity(0→1), 200ms |
| Exit Animation | scale(1→0.95) + opacity(1→0), 150ms |

### Search Input

| Property | Value |
|----------|-------|
| Height | 48px |
| Font Size | 18px |
| Border | none (borderless) |
| Background | transparent |
| Placeholder | "Search secrets..." (`text-slate-500`) |
| Icon | Lucide `search`, 20px, `text-slate-400` |
| Focus | Immediate (autofocus on open) |

### Result List

| Property | Value |
|----------|-------|
| Max visible | 6 items |
| Item height | 44px |
| Active item | `bg-brand-600/10` background + left accent |
| Inactive item | transparent |
| Left | Service icon (hash color) + Secret name (14px) |
| Right | Environment badge |

### Default State (검색어 없을 때)

> **Recency Effect** (Serial Position Effect): 최근 사용한 항목을 기본 표시하여 재접근 시간 최소화.

| Property | Value |
|----------|-------|
| Section label | "Recent" (12px, `text-muted`), 상단 좌측 |
| Items | 최근 복사/접근한 시크릿 3개 |
| Fallback | 최근 항목이 없으면 전체 목록에서 최신 3개 |

### Empty State (검색 결과 없음)

> **Information Scent** (Pirolli & Card 1999): 도움말 텍스트로 다음 행동 유도.

```
┌─────────────────────────────────┐
│                                 │
│   No secrets found              │
│                                 │
│   Try searching by:             │
│   · Service name (e.g. stripe)  │
│   · Environment (e.g. prod)     │
│   · Tag (e.g. payment)          │
│                                 │
└─────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Title | "No secrets found" (14px, `text-secondary`) |
| Help text | "Try searching by:" + 3 examples (12px, `text-muted`) |
| Alignment | Center-aligned within result area |

### Footer (Keyboard Hints)

| Property | Value |
|----------|-------|
| Height | 36px |
| Background | `rgba(255,255,255,0.03)` |
| Border | top `1px --border-subtle` |
| Content | `↵ to Copy` · `↑↓ to Navigate` · `Esc to Close` |
| Font | 12px, `text-slate-500` |

### Overlay Background

- `rgba(0,0,0,0.5)` + `backdrop-filter: blur(8px)`
- Click outside = close
- Trigger: `Cmd+K` (macOS) / `Ctrl+K` (other)

### Keyboard Navigation

| Key | Action |
|-----|--------|
| ↑/↓ | Navigate results |
| Enter | Copy selected secret value to clipboard + close |
| Esc | Close palette |
| Tab | Cycle through result sections (if any) |
| Type | Filter results in real-time |
