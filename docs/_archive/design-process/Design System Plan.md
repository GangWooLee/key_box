# KeyBox 디자인 시스템 — 네이티브 앱 중심 통합 계획

## Context

KeyBox는 개발자를 위한 시크릿 관리 앱이다. API 키 관리는 주로 **데스크탑/노트북에서** 이루어지므로 **macOS 우선, iOS는 보조**로 네이티브 앱을 설계한다. 두 개의 디자인 제안을 비교·통합하여 최종 디자인 시스템을 수립한다.

- **Claude 제안**: Web Hybrid (Tailwind 토큰 시스템, 상세 컴포넌트 스펙, 접근성, 반응형)
- **Gemini 제안**: macOS 네이티브 (Apple HIG, 3-column Split View, Vibrancy 사이드바, 메뉴바, 글로벌 단축키)

**통합 원칙**: Gemini의 네이티브 UX 비전 + Claude의 구현 가능한 디자인 토큰 시스템

### 확정 사항
- **실행 순서**: Phase A(웹뷰 디자인 시스템) → Phase B(macOS Tauri, 우선) → Phase C(iOS, 보조)
- **플랫폼 우선순위**: macOS (데스크탑/노트북) > iOS (모바일은 보조)
- **인증**: macOS Touch ID (MacBook) + 비밀번호. Face ID는 iOS Phase에서만 (낮은 우선순위)
- **서비스 아이콘**: 이니셜 + 해시 컬러 방식 (서비스명 → 해시 → 8가지 프리셋 컬러)
- **Pencil 연동**: 프로젝트 루트의 `key_box_pensil.pen` 파일을 설계 원천(Source of Truth)으로 사용하며, Pencil의 **Lunaris 디자인 시스템** 컴포넌트를 코드로 이식한다.

---

## 비교 결과 요약

| 항목 | 채택 | 근거 |
|------|------|------|
| **레이아웃** | 3-Column Sidebar+Table+Detail (V6 전환) | 정보량 비례 원칙. 분류 항시 가시성. macOS 네이티브 패턴 |
| **UI 폰트** | `-apple-system` → SF Pro / Inter 폴백 | Apple 기기에서 네이티브, 비Apple은 Inter |
| **코드 폰트** | SF Mono → JetBrains Mono 폴백 | Apple 기기 우선, 크로스플랫폼은 JetBrains Mono |
| **아이콘** | Lucide Icons (또는 Phosphor) | Apple 스타일의 기하학적 형태에 가장 잘 부합. (Heroicons 둥근 느낌은 SF Pro와 이질감 발생) |
| **컬러 토큰** | Claude 상세 시스템 채택 | Gemini는 "System Indigo"만 언급, 구현 불가 |
| **다크모드** | `prefers-color-scheme` (양쪽 합의) | 네이티브 셸에서 시스템 설정 자동 전파 |
| **사이드바** | Vibrancy 효과 (Gemini 비전 + CSS 구현) | `backdrop-blur` CSS + Tauri 네이티브 vibrancy |
| **글로벌 단축키** | Tauri 시스템 단축키 (Gemini) | 웹 불가, 핵심 UX 기능 |
| **메뉴바** | Tauri system tray (Gemini) | 항상 접근 가능, 1Password 방식 |
| **컴포넌트 스펙** | Claude 상세 스펙 채택 | Gemini는 목업만, 구현 가능한 스펙 없음 |
| **접근성** | Claude WCAG AA 채택 | Gemini는 접근성 미언급 |
| **반응형** | Claude 4 브레이크포인트 | 웹뷰 기반이므로 반응형 필수 |

---

## 기술 스택 결정

### Rails 백엔드 (기존 유지) + 네이티브 셸 래핑

```
Rails Backend (Phase 0 완료)
  ├── HTML 뷰 (Tailwind + Stimulus) → 웹뷰로 렌더링
  └── JSON API (Phase 3 예정) → 순수 네이티브 클라이언트용

Native Shell Layer:
  ├── macOS: Tauri v2 (★ 우선)
  │   ├── 메뉴바 아이콘 (system tray)
  │   ├── 글로벌 단축키 (⌘+Shift+K)
  │   ├── 윈도우 Vibrancy (NSVisualEffectView)
  │   ├── Touch ID (MacBook) → MEK를 macOS Keychain에 저장
  │   ├── 웹뷰 (기존 ERB 템플릿)
  │   └── 바이너리 ~5MB (Electron 대비 1/40)
  │
  └── iOS: Hotwire Native (보조, 후순위)
      ├── 네이티브 탭바, 내비게이션
      ├── Face ID (모바일 전용, 낮은 우선순위)
      └── 웹뷰 (기존 ERB 템플릿)
```

---

## 디자인 시스템

### 1. 컬러

**브랜드**: Indigo 유지 (Claude `#4F46E5` ≈ Apple System Indigo `#5856D6`, 차이 무시 가능)

```css
@theme {
  --color-brand-50:  #eef2ff;
  --color-brand-500: #6366f1;
  --color-brand-600: #4f46e5;   /* 주요 액션 */
  --color-brand-700: #4338ca;   /* 호버 */
}
```

**시맨틱 서피스** (모드별 CSS 변수):

| 토큰 | Light | Dark |
|------|-------|------|
| `--surface-primary` | white | `oklch(16% .014 265)` |
| `--surface-secondary` | slate-50 | `oklch(19% .014 265)` |
| `--surface-sidebar` | `rgba(243,244,246, 0.75)` + blur | `rgba(30,30,30, 0.65)` + blur |
| `--text-primary` | slate-900 | slate-100 |
| `--text-secondary` | slate-500 | slate-400 |
| `--border-primary` | slate-200 | slate-700 |

**상태 컬러**: emerald(성공), amber(경고), red(위험), sky(정보)

**환경 뱃지**: Production(red), Staging(amber), Development(emerald), Test(slate)

### 2. 타이포그래피

**폰트 스택** (플랫폼 자동 해상도):
```css
--font-sans: -apple-system, BlinkMacSystemFont, "Inter", system-ui, sans-serif;
--font-mono: "SF Mono", "JetBrains Mono", "Fira Code", ui-monospace, monospace;
```

**타입 스케일**:

| 레벨 | 크기 | 무게 | 용도 |
|------|------|------|------|
| H1 | 24px | Bold 700 | 페이지 제목 |
| H2 | 20px | Semibold 600 | 섹션 제목 |
| H3 | 16px | Semibold 600 | 카드/시크릿 이름 |
| Body | 16px | Regular 400 | 본문 |
| Small | 14px | Regular 400 | 라벨, 메타데이터 |
| Caption | 12px | Medium 500 | 뱃지, 타임스탬프 |
| Code | 14px | Regular 400 | 시크릿 값 (font-mono) |

### 3. 레이아웃: 3-Column (Sidebar + Table + Detail)

> **V6 전환 (2026-02-28):** 2-Column → 3-Column. 정보량 ↔ 영역 크기 비례 원칙 적용. 분류 구조의 항시 가시성 확보. macOS 네이티브 Credential Manager 레퍼런스 참조. 상세: `docs/design-system/key-box/MASTER.md`

```
Desktop (lg+):
┌─────────┬────────────────────────────────────┬─────────────┐
│Sidebar  │ Table View                         │ Detail      │
│200px    │ fluid (900px @1440)                │ 340px       │
│Vibrancy │ slate-900                          │ slate-950   │
│         │                                    │             │
│Search   │  Name    Service   Env    Last     │ Name [Env]  │
│         │  ─────────────────────────────     │ Value Box   │
│Category │  Live..  Stripe   Prod   2h  ←★   │ ▶ Details   │
│ list    │  Test..  Stripe   Dev    4h        │ ▶ Related   │
│         │  ...                                │ [Edit][Del] │
│Services │                                    │             │
│ tree    │          + Add Secret               │             │
└─────────┴────────────────────────────────────┴─────────────┘

Tablet (md):  2-Column (sidebar 숨김, table + detail)
Mobile (<md): 단일 컬럼 (table만, detail push)
```

**Sidebar Vibrancy** (CSS 근사):
```
Dark:  bg-slate-900/60 backdrop-blur-xl backdrop-saturate-[180%]
```

**Sidebar 구성**:
- 검색 바 (⌘K 단축키)
- 카테고리 목록: All Keys, API Keys, Tokens, Passwords, Certificates
- 서비스 트리: 서비스명 + hash color dot + 아이템 카운트 뱃지

**서비스 아이콘** (이니셜 + 해시 컬러):
- 서비스명 첫 글자를 컬러 원형 배경에 표시
- 서비스명 → 해시 → 8가지 프리셋 컬러 중 결정적(deterministic) 선택
- 같은 서비스명은 항상 같은 색상

### 4. 다크모드

`prefers-color-scheme` + 수동 토글 (localStorage)

### 5. Progressive Disclosure & Simplicity

> **V5 추가 (2026-02-28):** 전체 디자인에 Progressive Disclosure 원칙 적용. Miller's Law, Hick's Law, Cognitive Load Theory 기반.

**핵심 원칙**: 사용자의 80%+ 태스크(키 확인 → 값 복사)를 Layer 1에서 즉시 완료. 보조 정보는 접이식으로 숨김.

**3-Layer Rule**:
- **Layer 1: Core** — 항상 보임. 이름, 환경, 값, 복사 (3-4 chunks = Miller's Law)
- **Layer 2: Details** — 접이식(기본 닫힘). Description, Type, Folder, Tags, Dates
- **Layer 3: Related** — 접이식(기본 닫힘). Related Secrets (0개일 때 섹션 숨김)

**적용 화면**:
| 화면 | Layer 1 | Layer 2+ |
|------|---------|----------|
| Detail Pane | 이름+환경+값+복사 | Details(접이식), Related(접이식) |
| Sheet Modal | 3 기본 필드 | Advanced Options → Classification + Organization 그룹화 |
| Command Palette | 검색+결과 | 빈 상태 도움말, Recent 기본 표시 |
| Empty State | 아이콘+메시지+CTA | — |
| Delete Confirm | 인라인 확인 | — (별도 모달 없음) |

**이론적 근거**: `docs/design-knowledge-base/` — Miller's Law (§10), Hick's Law (§10), Progressive Disclosure (§08 §5.3), Loss Aversion (§10)

### 6. 컴포넌트 스펙 (Desktop Native Density)

**데스크탑 덴시티 우선**: 컴포넌트의 기본 높이를 28~32px로 컴팩트하게 구성하여 네이티브 앱의 정보 밀도를 맞춥니다. (모바일 44px 터치 타겟은 Phase C 모바일 뷰포인트에만 적용)

**버튼**: 5 변형 (Primary/Secondary/Outline/Danger/Ghost), 높이 `28px~32px`, `rounded-md`
**목록 아이템 (List Item)**: 그림자와 보더 **없음**. `edge-to-edge` 폭 또는 양끝 약간의 패딩만 존재.
- 호버/선택 시 상태 표시 층(배경색만 브랜드 50 또는 slate 100)으로 처리하여 Mail, Notes 앱과 동일한 룩 앤 필 제공
**입력 필드**: `28px~32px` 높이, `rounded-md`, focus `ring-2 ring-brand-500`
**뱃지**: 환경별 + 타입별 컬러 코딩, `rounded-full`, 매우 작고 컴팩트하게
**모달/오버레이**: 
- **Command Palette** (Cmd+K): 정중앙에 플로팅되는 Glassmorphism 오버레이 モ달
- **일반 얼럿 및 입력 팝업 (데스크탑)**: macOS 특유의 **Sheet 스타일** (윈도우 상단 타이틀바에서 미끄러지듯 내려오는 형태)을 CSS 애니메이션으로 구현하거나 Tauri Native Dialog 사용.

### 6. 애니메이션

| 요소 | 전환 | 시간 | Easing |
|------|------|------|--------|
| 목록 아이템 호버 | 배경색 crossfade | 150ms | ease-in-out |
| 버튼 호버 | 배경색 | 150ms | ease-in-out |
| 모달 진입 (Cmd+K) | scale + opacity | 200ms | cubic-bezier(0.2,0,0,1) |
| Sheet 모달 진입 | translateY(위에서 아래로) | 250ms | cubic-bezier(0.2,0.8,0.2,1) |
| 토스트 진입 | translateX | 300ms | cubic-bezier(0.2,0,0,1) |
| `prefers-reduced-motion` → 모든 애니메이션 비활성화 |

### 7. 접근성 (WCAG AA)

- 색상 대비: 일반 텍스트 4.5:1, 큰 텍스트 3:1
- 모바일 뷰포트 전환 시 터치 타겟: 최소 44x44px (CSS 변수 `--input-height` 확장)
- 포커스 링: `focus-visible:ring-2 ring-brand-500 ring-offset-2` (Mac 테마에 맞춰 부드럽게)
- 키보드 내비게이션: 모든 인터랙티브 요소 Tab 접근 가능 (리스트 아이템은 방향키 탐색 지원)
- `aria-label`: 아이콘 버튼 필수

---

## 실행 순서

### Phase A: 디자인 토큰 기반 구축 (웹뷰 레이어)

| Step | 작업 | 파일 |
|------|------|------|
| 1 | Tailwind @theme 토큰 + CSS 변수 + 다크모드 | `application.css` |
| 2 | 폰트 로딩 (Inter + JetBrains Mono) | `application.html.erb` |
| 3 | 다크모드 인프라 (인라인 스크립트 + theme_controller.js) | `theme_controller.js`, `application.html.erb` |
| 4 | 3-Column (Sidebar+Table+Detail) 레이아웃 | `secrets/index.html.erb` |
| 5 | 컬러 마이그레이션 (gray→slate, dark: 변형) | 15개 ERB 파일 |
| 6 | 컴포넌트 파셜 + 헬퍼 | `shared/`, `application_helper.rb` |
| 7 | Glassmorphism 오버레이 (Command Palette) | `shared/_command_palette.html.erb` |

### Phase B: macOS 데스크탑 셸 (Tauri v2) — 별도 프로젝트
### Phase C: iOS 모바일 셸 (Hotwire Native) — 별도 프로젝트

---

## Status

- [ ] Phase A Step 1: Design Tokens
- [ ] Phase A Step 2: Font Loading
- [ ] Phase A Step 3: Dark Mode Infrastructure
- [ ] Phase A Step 4: 3-Column Layout (Sidebar + Table + Detail)
- [ ] Phase A Step 5: Color Migration
- [ ] Phase A Step 6: Component Partials + Helpers
- [ ] Phase A Step 7: Command Palette
- [ ] Phase B: macOS Tauri v2 (별도 프로젝트)
- [ ] Phase C: iOS Hotwire Native (별도 프로젝트)
