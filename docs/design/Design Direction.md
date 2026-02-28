# KeyBox — 디자인 방향성 가이드

> Pencil 와이어프레임 → Antigravity 비주얼 디자인 → 코드 구현 워크플로우 참조 문서

---

## 디자인 워크플로우

```
Pencil (.pen)          Antigravity + Gemini Pro 3.1       Rails + Tailwind
───────────────       ──────────────────────────       ──────────────────
구조 / 레이아웃   →    색상, 그라데이션, 아이콘     →    프로덕션 코드
컴포넌트 배치          비주얼 디테일, 일러스트          ERB + Tailwind CSS
인터랙션 플로우        마이크로 애니메이션               Stimulus 컨트롤러
```

### 워크플로우 단계

1. **Pencil**: 레이아웃 구조, 컴포넌트 배치, 정보 계층 확정
2. **Antigravity**: Pencil 와이어프레임 기반으로 고해상도 비주얼 생성
3. **코드 구현**: Antigravity 결과물을 Tailwind CSS + ERB로 구현

### Pencil 산출물 (현재 완성)

| 화면 | Pencil ID | 내용 |
|------|-----------|------|
| 디자인 시스템 | TRLbz | 색상, 타이포그래피, 버튼, 폼, 뱃지 |
| 대시보드 | fbuxf | 사이드바 + 시크릿 카드 목록 |
| 시크릿 생성 폼 | zGAjO | 8개 필드 + 저장/취소 |
| 시크릿 상세 | ZcVEz | 마스킹 값 + 복사 + 메타데이터 |
| 검색 오버레이 | HD5oc | Cmd+K 모달 + 실시간 결과 |
| 빈 상태 | cRQuL | 온보딩 CTA |
| 감사 로그 | RKtFe | 테이블 + 색상 코딩 액션 |

---

## 비주얼 디자인 언어

### 전체 방향

- **스타일**: Swiss Clean + Minimal Professional
- **톤**: 신뢰감, 보안, 깔끔함
- **밀도**: 중간 (정보 밀도와 여백의 균형)
- **그래픽 스타일**: 플랫 아이콘, 서브틀한 그림자, 라운드 코너

### Simplicity-First 원칙

> **V5 추가 (2026-02-28):** 모든 화면 설계의 최상위 원칙.

사용자가 심플하게 본인이 저장한 key들을 보고, 저장하고, 관리할 수 있어야 한다. 디테일한 정보를 한 번에 너무 많이 보여줬을 때 오히려 혼잡하다.

**적용 규칙:**

1. **80/20 Rule**: 사용자 행동의 80%(키 확인→값 복사)를 화면의 20% 영역에서 즉시 완료
2. **Progressive Disclosure**: 기본→고급→특수 상황별 3단계 정보 노출
   - Layer 1: Core (항상 보임) — 핵심 태스크에 필요한 최소 정보
   - Layer 2: Details (접이식) — 보조 메타데이터
   - Layer 3: Related (접이식) — 연관 항목
3. **Miller's Law (4±1)**: 한 레이어에 최대 4개 정보 그룹만 표시
4. **Hick's Law**: 선택지 ≤ 5개. 초과 시 검색/필터 제공
5. **Empty State First**: 빈 상태는 "없다"가 아니라 "시작하세요"를 전달
6. **Inline over Modal**: 파괴적 액션 확인은 인라인 (컨텍스트 유지)

### 키워드 (Antigravity 프롬프트용)

```
professional, secure, clean, minimal, developer-tool,
indigo accent, light background, subtle shadows,
rounded corners, monospace code values, Swiss typography
```

---

## 색상 시스템

### Primary Palette

| 용도 | 색상 | HEX | Tailwind |
|------|------|-----|---------|
| Primary | Indigo 600 | `#4F46E5` | `bg-indigo-600` |
| Primary Hover | Indigo 700 | `#4338CA` | `hover:bg-indigo-700` |
| Primary Light | Indigo 50 | `#EEF2FF` | `bg-indigo-50` |
| Primary Ring | Indigo 500 | `#6366F1` | `ring-indigo-500` |

### Semantic Colors

| 용도 | HEX | Tailwind | 사용처 |
|------|-----|---------|--------|
| Success | `#166534` bg `#DCFCE7` | `text-green-800 bg-green-100` | 생성, 저장 성공 |
| Warning | `#92400E` bg `#FEF3C7` | `text-yellow-800 bg-yellow-100` | 수정, 주의 |
| Danger | `#DC2626` bg `#FEE2E2` | `text-red-600 bg-red-100` | 삭제, 에러 |
| Info | `#1E40AF` bg `#DBEAFE` | `text-blue-800 bg-blue-100` | 복사, 정보 |

### Neutral Palette

| 용도 | HEX | Tailwind |
|------|-----|---------|
| 배경 | `#F9FAFB` | `bg-gray-50` |
| 카드 배경 | `#FFFFFF` | `bg-white` |
| 사이드바 배경 | `#F3F4F6` | `bg-gray-100` |
| 테두리 | `#E5E7EB` | `border-gray-200` |
| 보조 텍스트 | `#6B7280` | `text-gray-500` |
| 본문 텍스트 | `#374151` | `text-gray-700` |
| 헤딩 텍스트 | `#111827` | `text-gray-900` |

### 감사 로그 액션 도트

| 액션 | 색상 | HEX |
|------|------|-----|
| Create | Green | `#22C55E` |
| Copy | Blue | `#3B82F6` |
| Update | Yellow | `#EAB308` |
| Delete | Red | `#EF4444` |

---

## 타이포그래피

### 폰트 패밀리

| 용도 | 폰트 | 대체 |
|------|------|------|
| UI (본문, 헤딩, 버튼) | **Inter** | system-ui, sans-serif |
| 시크릿 값, 코드 | **SF Mono** | Menlo, Consolas, monospace |

### 타이프 스케일

| 레벨 | 크기 | Weight | 용도 |
|------|------|--------|------|
| Display | 32px | Bold (700) | 페이지 타이틀 |
| Heading 1 | 24px | Semibold (600) | 섹션 헤딩 |
| Heading 2 | 20px | Semibold (600) | 서브 헤딩 |
| Body | 16px | Regular (400) | 본문 텍스트 |
| Small | 14px | Regular (400) | 보조 텍스트, 라벨 |
| Caption | 12px | Medium (500) | 뱃지, 메타데이터 |

---

## 컴포넌트 디자인 가이드

### 버튼

| 종류 | 배경 | 텍스트 | 테두리 | 사용처 |
|------|------|--------|--------|--------|
| Primary | Indigo 600 | White | 없음 | 주요 CTA (저장, 생성) |
| Secondary | Gray 100 | Gray 700 | 없음 | 보조 액션 (취소) |
| Outline | White | Gray 700 | Gray 300 | 중립 액션 |
| Danger | Red 600 | White | 없음 | 삭제, 위험 액션 |
| Ghost | 투명 | Gray 500 | 없음 | 아이콘 버튼, 최소 강조 |

**공통 규격**: 최소 높이 44px, 라운드 8px, 포커스 링 2px Indigo

### 카드

- 배경: `white`, 라운드: `12px`, 그림자: `shadow-sm`
- 테두리: `1px solid gray-100`
- 패딩: `24px`
- 호버: `shadow-md` 트랜지션 (150ms)

### 입력 필드

- 높이: `44px`, 패딩: `0 16px`
- 테두리: `1px solid gray-300`, 라운드: `8px`
- 포커스: `ring-2 ring-indigo-500 border-indigo-500`
- 라벨: 14px Medium, 위 간격 8px

### 뱃지

| 타입 | 배경 | 텍스트 | 사용처 |
|------|------|--------|--------|
| Production | Green 100 | Green 800 | 환경 뱃지 |
| Staging | Yellow 100 | Yellow 800 | 환경 뱃지 |
| Development | Blue 100 | Blue 800 | 환경 뱃지 |
| API Key | Violet 100 | Violet 800 | 타입 뱃지 |
| Token | Orange 100 | Orange 800 | 타입 뱃지 |

### 사이드바 (Sidebar — 200px)

> **V6 전환 (2026-02-28):** 드롭다운 폴더 필터 → 사이드바 복원. 분류 구조의 항시 가시성 확보.

- 위치: 좌측 200px 고정
- 배경: `rgba(15, 23, 42, 0.6)` + `backdrop-blur-xl` (Vibrancy)
- 구성: 검색 바 (⌘K, 36px) + 카테고리 목록 (32px items) + 서비스 트리 (hash color dot)
- 선택 상태: `bg-brand-600/10` + left accent 2px
- 디자인 시스템: `docs/design-system/key-box/pages/dashboard.md` 참조

### 토스트 (알림)

- 위치: 화면 우측 상단
- 지속 시간: 3초 (자동 사라짐)
- 성공: Green 아이콘 + "복사되었습니다" / "저장되었습니다"
- 에러: Red 아이콘 + 에러 메시지
- 라운드: `8px`, 그림자: `shadow-lg`

---

## 화면별 디자인 노트

### 대시보드

> **V6 전환 (2026-02-28):** 2-Column → 3-Column. 정보량 ↔ 영역 크기 비례 원칙 적용.

- **레이아웃**: 3-Column (사이드바 200px + 테이블 뷰 fluid + 디테일 340px). 분류 구조의 항시 가시성 확보
- **사이드바**: Vibrancy 배경, 검색 바 (⌘K), 카테고리 목록 + 서비스 트리 (hash color dot + 카운트)
- **테이블 뷰**: 4컬럼 테이블 (Name/Service/Env/Last Used), 44px 행, 정렬 가능, 하단 "+ Add Secret"
- **디테일 패널**: 340px 컴팩트. 이름+환경, Value Box (마스킹+복사), 접이식 Details/Related, Edit/Delete
- **Antigravity 포인트**: 테이블 행 호버, 복사 아이콘 마이크로 애니메이션, 시크릿 값 reveal crossfade
- **모바일**: 테이블만 (디테일 push navigation)
- **디자인 시스템**: `docs/design-system/key-box/pages/dashboard.md` 참조

### 시크릿 생성 폼

- **필드 순서**: 폴더 → 타입 → 이름* → 값* → 서비스명 → 환경 → 태그 → 메모
- **Antigravity 포인트**: 필드 포커스 트랜지션, 유효성 검사 인라인 에러
- **모바일**: 단일 컬럼, 키보드 대응 스크롤

### 시크릿 상세

- **헤더**: 시크릿명 + 타입/환경 뱃지 + 수정/삭제 버튼
- **값 섹션**: 마스킹 `••••••` + 눈 아이콘(표시/숨기) + 복사 아이콘
- **메타데이터**: 생성일, 최근 접근일, 태그
- **Antigravity 포인트**: 마스킹 ↔ 표시 전환 애니메이션

### 검색 오버레이

- **트리거**: `Cmd+K` (macOS) / `Ctrl+K` (Windows)
- **레이아웃**: 중앙 모달, 배경 블러 오버레이
- **결과**: 선택된 항목 Indigo 배경, 키보드 네비게이션 힌트 (↑↓ Enter ESC)
- **Antigravity 포인트**: 모달 등장 애니메이션 (scale + fade), 결과 하이라이트 트랜지션

### 빈 상태 (온보딩)

- **중앙 요소**: 잠금 아이콘 (48px) + 환영 텍스트 + CTA 버튼
- **톤**: 친근하고 안내하는 느낌
- **Antigravity 포인트**: 잠금 아이콘에 서브틀한 그라데이션 또는 일러스트

### 감사 로그

- **테이블 구조**: 시간, 액션, 대상, 사용자, IP
- **액션 구분**: 색상 코딩된 도트 (Create=Green, Copy=Blue, Update=Yellow, Delete=Red)
- **Antigravity 포인트**: 테이블 행 호버 효과, 액션 도트 미세 펄스 애니메이션

---

## Antigravity 프롬프트 참고

### 기본 프롬프트 템플릿

```
Design a [화면명] screen for KeyBox, a secure credential management web app.

Style: Swiss Clean, minimal, professional
Colors: Indigo-600 primary (#4F46E5), gray neutrals, white cards
Font: Inter for UI, SF Mono for secret values
Border radius: 8-12px
Shadows: subtle (shadow-sm), elevated on hover (shadow-md)

The design should convey trust, security, and developer-friendliness.
Target: solo indie developers managing API keys and secrets.

Layout: [레이아웃 설명]
Components: [컴포넌트 목록]
```

### 화면별 프롬프트 변형

**대시보드**:
```
Two-panel layout: 240px dark sidebar with folder navigation,
main content with secret cards grid.
Each card shows: name, service, type badge, env badge, masked value, copy icon.
Empty state shows lock icon + welcome CTA for first-time users.
```

**검색 오버레이**:
```
Cmd+K style search overlay with blurred background.
Search input at top with magnifying glass icon.
Results list below with keyboard navigation indicators.
Selected result highlighted in indigo-50.
Footer shows keyboard shortcuts (↑↓ Navigate, Enter Select, ESC Close).
```

---

## 반응형 브레이크포인트

| 이름 | 최소 너비 | 레이아웃 변화 |
|------|----------|-------------|
| Mobile | 0px | 단일 컬럼 (테이블만, 디테일 push navigation) |
| Tablet | 768px (md) | 2-Column (sidebar 숨김, table + detail) |
| Desktop | 1024px (lg) | 3-Column (180 + fluid + 300) |
| Wide | 1440px (xl) | 3-Column (200 + fluid + 340) |

---

## 애니메이션 / 트랜지션 가이드

| 요소 | 트랜지션 | 지속 시간 | 이징 |
|------|---------|----------|------|
| 버튼 호버 | 배경색 변경 | 150ms | ease-in-out |
| 카드 호버 | 그림자 증가 | 200ms | ease-out |
| 모달 등장 | scale(0.95→1) + opacity(0→1) | 200ms | ease-out |
| 모달 퇴장 | scale(1→0.95) + opacity(1→0) | 150ms | ease-in |
| 토스트 등장 | translateX(100%→0) | 300ms | ease-out |
| 토스트 퇴장 | opacity(1→0) | 200ms | ease-in |
| 시크릿 표시/숨기 | opacity crossfade | 150ms | ease |
| 검색 결과 전환 | 배경색 변경 | 100ms | ease |

---

## 아이콘 체계

- **스타일**: Lucide Icons (Outline 24px) — SF Pro와 기하학적 형태 일치
- **일관성**: 같은 아이콘셋에서만 선택
- **크기**: 기본 20px (인라인), 24px (버튼), 48px (빈 상태)

| 용도 | 아이콘 | Heroicons 이름 |
|------|--------|---------------|
| 검색 | 🔍 | `magnifying-glass` |
| 복사 | 📋 | `clipboard-document` |
| 자물쇠 | 🔒 | `lock-closed` |
| 눈 (보기) | 👁 | `eye` |
| 눈 (숨기기) | 🙈 | `eye-slash` |
| 추가 | ➕ | `plus` |
| 폴더 | 📁 | `folder` |
| 수정 | ✏️ | `pencil-square` |
| 삭제 | 🗑 | `trash` |
| 설정 | ⚙️ | `cog-6-tooth` |

---

## 접근성 요구사항

- **색상 대비**: 일반 텍스트 4.5:1, 큰 텍스트 3:1 (WCAG AA)
- **터치 타겟**: 최소 44x44px
- **포커스 표시**: `focus-visible:ring-2 ring-indigo-500 ring-offset-2`
- **키보드 네비게이션**: 모든 인터랙티브 요소 Tab으로 접근 가능
- **스크린 리더**: `aria-label` (아이콘 버튼), `role="dialog"` (모달)
- **모션 감소**: `prefers-reduced-motion` 미디어 쿼리 존중

---

## 관련 문서

- [[Product Design]] — 제품 개요, 사용자 플로우, 화면 목록
- [[Technical Architecture]] — 기술 아키텍처, Tailwind 토큰
- [[Phase Plan]] — 구현 로드맵, 수용 기준
