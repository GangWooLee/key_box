---
paths:
  - "app/views/**"
  - "app/javascript/**"
  - "app/assets/**"
---

# 프론트엔드 — Stimulus · 접근성 · 디자인 · Tailwind

## Stimulus 컨트롤러 내부 구조 (순서 규칙)

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 1. 선언부
  static targets = ["content", "icon"]
  static values = {
    open: { type: Boolean, default: false },
    url: String,
    debounce: { type: Number, default: 300 }
  }
  static classes = ["hidden", "active"]

  // 2. 상수
  static DEBOUNCE_MS = 300

  // 3. 라이프사이클
  connect() {}
  disconnect() {}  // 필수: 리스너/타이머/RAF 정리

  // 4. Public Actions (data-action에서 호출)
  toggle() {}

  // 5. Value Change Callbacks
  openValueChanged() {}

  // 6. Private Methods (# prefix)
  #render() {}

  // 7. Getters/Setters
  get #isValid() {}
}
```

## Stimulus 핵심 원칙

- **1 컨트롤러 = 1 관심사** (작고 집중된 컨트롤러 선호)
- **disconnect()에서 반드시 정리**: 타이머, 이벤트 리스너, RAF
- **Generic 컨트롤러**: `toggle`, `clipboard` 등 — 3곳 이상 사용 시 추출
- **전역 변수 금지**: `window.*` 대신 Stimulus values 사용

## 컨트롤러 조합 패턴

| 패턴 | 용도 |
|------|------|
| 부모-자식 | 중첩된 DOM 구조 |
| 이벤트 디스패치 | 느슨한 결합 통신 |
| Outlet | 형제 컨트롤러 참조 |
| 공유 Value | 서버에서 공통 데이터 주입 |

### 이벤트 통신

```javascript
// 자식 → 부모: dispatch
this.dispatch("completed", { detail: { stepId: 3 } })
// 부모에서 수신: data-action="tutor-guide:completed->parent#handleStep"
```

- **자식→부모**: `this.dispatch()`
- **부모→자식**: Stimulus values 변경 또는 target 메서드 호출
- **무관한 컨트롤러**: `window` 이벤트 (최소화)

## 상태 관리

| 상태 유형 | 저장소 |
|----------|--------|
| UI 상태 | Stimulus values (반응형) |
| 세션 상태 | sessionStorage |
| 영구 상태 | 서버 (Turbo) |
| 전역 상태 | **금지** |

## Turbo 통합

```javascript
connect() {
  this.element.addEventListener("turbo:submit-start", this.disable.bind(this))
  this.element.addEventListener("turbo:submit-end", this.enable.bind(this))
}

disconnect() {
  this.element.removeEventListener("turbo:submit-start", this.disable.bind(this))
  this.element.removeEventListener("turbo:submit-end", this.enable.bind(this))
}
```

## XSS 방지 (JavaScript)

```javascript
// ✅ textContent로 텍스트 삽입 (자동 이스케이핑)
element.textContent = userInput

// ✅ DOM API로 요소 생성
const div = document.createElement('div')
div.textContent = userInput
parent.appendChild(div)

// ✅ Turbo Stream (서버 렌더링된 HTML)
Turbo.renderStreamMessage(serverResponse)

// ❌ innerHTML 금지
```

## CSRF 토큰 접근

```javascript
// ✅ Stimulus value 사용 (권장)
static values = { csrfToken: String }

// ✅ Optional chaining
const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ''

// ❌ null 체크 없이 직접 접근 금지 (TypeError 위험)
```

---

## 접근성 (A11y)

### 필수 속성

```erb
<%# 아이콘 버튼: aria-label 필수 %>
<button type="button" aria-label="메뉴 열기">
  <svg aria-hidden="true">...</svg>
</button>

<%# 폼 요소: for/id 연결 필수 %>
<label for="email">이메일</label>
<input id="email" type="email" aria-describedby="email-hint">
<p id="email-hint" class="text-sm text-gray-500">업무용 이메일을 입력하세요</p>

<%# 모달 %>
<div role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">제목</h2>
</div>

<%# 동적 알림: aria-live 필수 %>
<div role="alert" aria-live="polite">저장되었습니다.</div>

<%# 이미지: alt 필수 (장식용은 빈 alt) %>
<img src="profile.jpg" alt="김철수 프로필 사진">
<img src="decoration.svg" alt="">
```

### 키보드 네비게이션

- `tabindex="0"` — 기본 순서에 포함
- `tabindex="-1"` — 프로그래밍으로만 포커스
- `tabindex="1+"` — **사용 금지!** (순서 혼란)
- 모달 내 Tab Trap 구현 필수

### Escape 키 닫기

```javascript
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") this.close()
})
```

### 색상 대비

- 일반 텍스트: 최소 4.5:1
- 큰 텍스트 (18px+): 최소 3:1
- `text-gray-300 on bg-gray-100` ❌ → `text-gray-700 on bg-gray-100` ✅

### 포커스 표시

```erb
<%# ❌ 포커스 링 제거 금지 %>
<button class="focus:outline-none">

<%# ✅ focus-visible 사용 (클릭 시 미표시, 키보드 시 표시) %>
<button class="focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2">
```

---

## 모바일 퍼스트 디자인

| # | 규칙 | 이유 |
|---|------|------|
| 1 | 터치 타겟 최소 44x44px | Apple HIG + WCAG 2.5.5 |
| 2 | 모바일 본문 최소 16px | 가독성 + iOS 폼 줌 방지 |
| 3 | 빈 상태 반드시 디자인 | "데이터 없음"은 UX 실패 |
| 4 | 에러 복구 경로 항상 제공 | 다음 행동 안내 필수 |
| 5 | 진행 표시기로 사용자 안내 | 로딩/처리 중 피드백 필수 |
| 6 | `overscroll-behavior` 설정 | pull-to-refresh 충돌 방지 |

### 안티패턴 탐지

| 안티패턴 | 대안 |
|---------|------|
| 이모지를 아이콘으로 사용 | Heroicons SVG |
| 호버 없는 클릭 요소 | `transition-colors` + `hover:` 추가 |
| `h-screen` 사용 | `dvh` 사용 (모바일 주소창) |
| 작은 터치 타겟 | `min-h-[44px] min-w-[44px]` |
| 하드코딩 색상 | 프로젝트 색상 변수 사용 |
| `aspect-ratio` 없는 `<img>` | `aspect-video` / `aspect-square` (CLS 방지) |

### 디자인 리뷰 우선순위

| 순위 | 영역 | 심각도 |
|------|------|--------|
| 1 | 접근성 | CRITICAL |
| 2 | 터치 & 인터랙션 | CRITICAL |
| 3 | 성능 | HIGH |
| 4 | 레이아웃 | HIGH |
| 5 | 타이포 & 색상 | MEDIUM |

---

## Tailwind 패턴

### 반응형 (Mobile First)

```erb
<div class="flex flex-col md:flex-row lg:gap-8">
<%# sm: 640px+ / md: 768px+ / lg: 1024px+ / xl: 1280px+ %>
```

### 간격 시스템

```
p-2 (8px) 아이콘 패딩 / p-4 (16px) 기본 / p-6 (24px) 카드
gap-2 아이콘-텍스트 / gap-4 요소 간격 / gap-6 카드 간격
카드 내부: space-y-N 시리즈 사용 (혼합 mb-2/mb-4 금지)
```

### 컴포넌트

```erb
<%# 버튼: 터치 타겟 필수 %>
<button class="px-4 py-2 bg-primary hover:bg-primary-dark text-white font-medium
  rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed
  min-h-[44px]">

<%# 입력 필드: 16px 필수 (iOS 줌 방지) %>
<input class="w-full px-4 py-2 border border-gray-300 rounded-lg
  focus:ring-2 focus:ring-primary focus:border-primary
  placeholder-gray-400 transition-colors text-base">

<%# 카드 %>
<div class="bg-white rounded-xl shadow-sm hover:shadow-md border border-gray-100
  p-6 transition-shadow">
```

### 이미지 최적화

```erb
<img src="..." alt="설명"
     class="aspect-video object-cover w-full h-full rounded-lg"
     loading="lazy">
```

### 성능 규칙

| 금지 | 권장 | 이유 |
|------|------|------|
| `@apply` 남용 | 직접 유틸리티 클래스 | 번들 크기 증가 |
| `h-screen` | `dvh` | 모바일 주소창 |
| `h-6 w-6` | `size-6` | 단축형 |

### 애니메이션 규칙

- `duration-150` ~ `duration-300` (UI 요소)
- hover 시 반드시 `transition-colors` / `transition-shadow` 동반
- `motion-reduce:animate-none` 지원
- 동시 애니메이션 3개 이하

### z-index 체계

| z 값 | 용도 |
|------|------|
| z-0 | 기본 콘텐츠 |
| z-10 | 오버레이 텍스트 |
| z-20 | 플로팅 요소 |
| z-30 | 프로그레스 바 |
| z-40 | 인디케이터 |
| z-50 | 네비게이션 |
