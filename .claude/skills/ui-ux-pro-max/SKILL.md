---
description: 데이터 기반 UI/UX 디자인 인텔리전스. 67개 스타일, 97개 팔레트, 57개 폰트 페어링, 100개 UX 가이드라인, 25개 차트 타입을 BM25 검색으로 추천합니다. 디자인 시스템 생성, 산업별 추론 규칙 100개, 13개 기술 스택 지원.
trigger_keywords:
  - frontend design
  - design component
  - beautiful UI
  - create landing page
  - make it pretty
  - improve design
  - design system
  - visual design
  - 예쁘게
  - 디자인 개선
globs:
  - "app/views/**/*.html.erb"
  - "app/assets/stylesheets/**/*.css"
  - "app/javascript/**/*.js"
alwaysApply: false
---

# UI/UX Pro Max - Design Intelligence

> BM25 검색 엔진 기반 디자인 추천 시스템
> 출처: [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)

## When to Apply

Reference these guidelines when:
- Designing new UI components or pages
- Choosing color palettes and typography
- Reviewing code for UX issues
- Building landing pages or dashboards
- Implementing accessibility requirements

## Rule Categories by Priority

| Priority | Category | Impact | Domain |
|----------|----------|--------|--------|
| 1 | Accessibility | CRITICAL | `ux` |
| 2 | Touch & Interaction | CRITICAL | `ux` |
| 3 | Performance | HIGH | `ux` |
| 4 | Layout & Responsive | HIGH | `ux` |
| 5 | Typography & Color | MEDIUM | `typography`, `color` |
| 6 | Animation | MEDIUM | `ux` |
| 7 | Style Selection | MEDIUM | `style`, `product` |
| 8 | Charts & Data | LOW | `chart` |

---

## Prerequisites

```bash
python3 --version || python --version
```

Python 미설치 시 (macOS):
```bash
brew install python3
```

---

## How to Use This Skill

UI/UX 작업 요청 시 (design, build, create, implement, review, fix, improve) 아래 워크플로우를 따릅니다.

### Step 1: Analyze User Requirements

사용자 요청에서 핵심 정보 추출:
- **Product type**: SaaS, e-commerce, portfolio, dashboard, landing page 등
- **Style keywords**: minimal, playful, professional, elegant, dark mode 등
- **Industry**: healthcare, fintech, gaming, education 등
- **Stack**: 기본값 `html-tailwind` (Rails + Tailwind 프로젝트)

### Step 2: Generate Design System (REQUIRED)

**항상 `--design-system`으로 시작** — 종합 추천을 받습니다:

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system [-p "Project Name"]
```

이 명령은:
1. 5개 도메인을 병렬 검색 (product, style, color, landing, typography)
2. `ui-reasoning.csv`의 추론 규칙으로 최적 매치 선택
3. 완전한 디자인 시스템 반환: 패턴, 스타일, 색상, 타이포, 효과
4. 피해야 할 안티패턴 포함

**예시 (key_box):**
```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "education SaaS korean learning" --design-system -p "key_box"
```

### Step 2b: Persist Design System (Master + Overrides Pattern)

디자인 시스템을 세션 간 유지하려면 `--persist` 추가:

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "Project Name"
```

생성 파일:
- `design-system/MASTER.md` — 글로벌 디자인 규칙
- `design-system/pages/` — 페이지별 오버라이드 폴더

**페이지별 오버라이드:**
```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "key_box" --page "dashboard"
```

**계층적 검색 로직:**
1. 특정 페이지 빌드 시 `design-system/pages/[page].md` 먼저 확인
2. 파일 존재 시 → Master 오버라이드
3. 미존재 시 → `design-system/MASTER.md` 사용

### Step 3: Supplement with Detailed Searches (as needed)

디자인 시스템 생성 후 도메인별 상세 검색:

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<keyword>" --domain <domain> [-n <max_results>]
```

| 필요 | Domain | 예시 |
|------|--------|------|
| 스타일 옵션 | `style` | `--domain style "glassmorphism dark"` |
| 차트 추천 | `chart` | `--domain chart "real-time dashboard"` |
| UX 모범 사례 | `ux` | `--domain ux "animation accessibility"` |
| 폰트 대안 | `typography` | `--domain typography "elegant luxury"` |
| 랜딩 구조 | `landing` | `--domain landing "hero social-proof"` |

### Step 4: Stack Guidelines (Default: html-tailwind)

스택별 구현 가이드라인 조회. 미지정 시 `html-tailwind` 기본:

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<keyword>" --stack html-tailwind
```

Available stacks: `html-tailwind`, `react`, `nextjs`, `vue`, `svelte`, `swiftui`, `react-native`, `flutter`, `shadcn`, `jetpack-compose`

---

## Search Reference

### Available Domains

| Domain | Use For | Example Keywords |
|--------|---------|------------------|
| `product` | 제품 유형 추천 | SaaS, e-commerce, portfolio, healthcare |
| `style` | UI 스타일, 색상, 효과 | glassmorphism, minimalism, dark mode |
| `typography` | 폰트 페어링, Google Fonts | elegant, playful, professional |
| `color` | 산업별 컬러 팔레트 | saas, ecommerce, healthcare, fintech |
| `landing` | 페이지 구조, CTA 전략 | hero, testimonial, pricing, social-proof |
| `chart` | 차트 유형, 라이브러리 추천 | trend, comparison, timeline, funnel |
| `ux` | 모범 사례, 안티패턴 | animation, accessibility, z-index, loading |
| `web` | 웹 인터페이스 가이드 | aria, focus, keyboard, semantic |

---

## Output Formats

```bash
# ASCII box (기본) — 터미널 표시 최적
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "fintech crypto" --design-system

# Markdown — 문서화 최적
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "fintech crypto" --design-system -f markdown
```

---

## 프로젝트 디자인 프로필 (key_box)

| 항목 | 값 |
|------|-----|
| 산업 | Education / EdTech |
| 대상 | 한국어 학습자, 모바일 우선 |
| 톤 | (검색으로 결정) |
| 플랫폼 | Mobile-first (375px 기준) |
| 아이콘 | Heroicons (SVG) |

### 톤 선택 가이드 → 검색 키워드 매핑

| 톤 | 검색 키워드 |
|-----|-----------|
| Brutally Minimal | `minimalism clean whitespace` |
| Maximalist Chaos | `maximalism bold layers` |
| Retro-Futuristic | `retro neon gradient` |
| Organic/Natural | `organic natural earth` |
| Luxury/Refined | `luxury elegant refined` |
| Playful/Toy-like | `playful cartoon animation` |
| Editorial/Magazine | `editorial magazine layout` |
| Brutalist/Raw | `brutalism raw border` |
| Art Deco/Geometric | `geometric symmetry art-deco` |

### 한국어 폰트 페어링

```css
/* 시스템 폰트 기본 (모바일 네이티브 경험) */
font-family: system-ui, -apple-system, sans-serif;

/* 커스텀 폰트 권장 */
font-family: 'Pretendard', system-ui, sans-serif; /* 본문 — 고가독성 */
font-family: 'Noto Sans KR', sans-serif;          /* 대안 — Google Fonts */
```

### ERB / Tailwind 구현 팁

```erb
<%# 프로젝트 색상 변수 (@theme) 사용 %>
<button class="bg-primary text-white hover:bg-primary-dark">...</button>

<%# 프로젝트 유틸리티 클래스 우선 %>
<button class="btn-primary">...</button>

<%# Heroicons SVG 아이콘 (이모지 대신) %>
<%= render "shared/icon", name: "check-circle", class: "w-5 h-5" %>
```

### Tailwind CSS v4 토큰 활용

- `@theme` 변수로 색상/간격/폰트 정의 → `bg-primary`, `text-accent` 사용
- `dvh` 단위 사용 (`h-screen` 대신 `h-dvh`)
- 하드코딩 색상값 → `@theme` 변수로 대체

---

## Common Rules for Professional UI

### Icons & Visual Elements

| Rule | Do | Don't |
|------|----|----- |
| **No emoji icons** | SVG 아이콘 (Heroicons, Lucide) | 이모지 (🎨 🚀 ⚙️) |
| **Stable hover** | color/opacity 전환 | scale로 레이아웃 시프트 |
| **Brand logos** | Simple Icons에서 공식 SVG | 추측하거나 잘못된 경로 |
| **Consistent sizing** | 고정 viewBox (24x24) w-6 h-6 | 랜덤 사이즈 |

### Interaction & Cursor

| Rule | Do | Don't |
|------|----|----- |
| **cursor-pointer** | 모든 클릭 가능 요소에 적용 | 기본 커서 유지 |
| **Hover feedback** | color, shadow, border 시각 피드백 | 인터랙티브 표시 없음 |
| **Smooth transitions** | `transition-colors duration-200` | 500ms 초과 |

### Light/Dark Mode Contrast

| Rule | Do | Don't |
|------|----|----- |
| **Glass card light** | `bg-white/80` 이상 | `bg-white/10` (투명) |
| **Text contrast** | `#0F172A` (slate-900) | `#94A3B8` (slate-400) |
| **Border visibility** | `border-gray-200` (light) | `border-white/10` (invisible) |

---

## Anti-Patterns (절대 하지 말 것)

| 피할 것 | 대안 |
|---------|------|
| Inter, Roboto, Arial 폰트 | Pretendard, Noto Sans KR, 시스템 폰트 |
| 자주색 그라디언트 | 프로젝트 브랜드 컬러 사용 |
| 예측 가능한 레이아웃 | 비대칭, 오버랩, stagger 효과 |
| 균등 분배 색상 | 지배적 색상 (primary) + 악센트 (accent) |
| 이모지를 아이콘으로 | Heroicons SVG |
| `h-screen` | `h-dvh` (dvh 단위) |
| 하드코딩 색상값 | `@theme` 변수 사용 |
| "쿠키커터" 디자인 | 프로젝트 컨텍스트 특화 |

---

## Pre-Delivery Checklist

| Category | Item | Check |
|----------|------|-------|
| 접근성 | 아이콘 버튼 `aria-label` | [ ] |
| 접근성 | 이미지 `alt` 텍스트 | [ ] |
| 접근성 | `focus-visible:ring-2` 가시성 | [ ] |
| 접근성 | `prefers-reduced-motion` 지원 | [ ] |
| 터치 | 최소 44x44px 터치 타겟 | [ ] |
| 터치 | 인터랙티브 요소 `cursor-pointer` | [ ] |
| 터치 | 호버 레이아웃 시프트 없음 | [ ] |
| 반응형 | 375px (iPhone SE) 정상 | [ ] |
| 반응형 | 768px (태블릿) 정상 | [ ] |
| 성능 | `loading="lazy"` 이미지 | [ ] |
| 성능 | CLS 방지 (aspect-ratio) | [ ] |
| 일관성 | `@theme` 색상 변수 사용 | [ ] |
| 일관성 | 프로젝트 유틸리티 클래스 | [ ] |
| 일관성 | Heroicons 아이콘 세트 | [ ] |
| 일관성 | 이모지 아이콘 대신 SVG | [ ] |

---

**Version**: 1.0.0
**Source**: [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)
**Last Updated**: 2026-02-23
