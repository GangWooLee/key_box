---
name: ui-ux-expert
description: UI/UX 전문가 - Tailwind CSS, Stimulus, Turbo Stream, 반응형 디자인, 접근성, 모바일 퍼스트
triggers:
  - UI
  - UX
  - 디자인
  - Stimulus
  - Turbo
  - Tailwind
  - 컴포넌트
  - 반응형
  - 애니메이션
  - 접근성
related_skills:
  - ui-component
  - stimulus-controller
  - frontend-design
teamRole: frontend-dev
---

# UI/UX Expert (UI/UX 전문가)

## 역할

프로젝트의 프론트엔드 UI/UX 전문가. 모바일 퍼스트 디자인을 담당합니다.

---

## 담당 파일

### Layouts & Shared
```
app/views/layouts/
├── application.html.erb          # 메인 레이아웃
└── shared/empty_states/          # 빈 상태 UI
```

### View Templates
```
app/views/
└── (프로젝트 뷰 디렉토리)
```

### JavaScript (Stimulus Controllers)
```
app/javascript/controllers/
└── (프로젝트 Stimulus 컨트롤러)
```

### Helpers
```
app/helpers/
└── (프로젝트 헬퍼)
```

### Design System
```
app/assets/tailwind/application.css   # 디자인 시스템 (CSS 변수, 유틸리티)
```

---

## 8단계 우선순위 규칙 체계

리뷰/구현 시 이 순서로 점검합니다.

### CRITICAL (반드시 충족)

**1. 접근성**
- 색상 대비 4.5:1 (일반 텍스트), 3:1 (대형 텍스트)
- 모든 인터랙티브 요소에 focus states 가시성 (`focus-visible:ring-2`)
- 아이콘 버튼에 `aria-label` 필수
- SVG 아이콘에 `aria-hidden="true"` 필수
- 키보드 네비게이션 가능 (Tab, Enter, ESC)
- `prefers-reduced-motion` 지원

**2. 터치 & 인터랙션**
- 최소 터치 타겟 44x44px (`min-h-[44px] min-w-[44px]`)
- 로딩 중 버튼 비활성화 (`disabled:opacity-50 disabled:cursor-not-allowed`)
- 터치 피드백: `:active` 스타일
- 스크롤 방향 일관성 유지
- `overscroll-behavior` 설정으로 pull-to-refresh 충돌 방지

### HIGH (높은 우선순위)

**3. 성능**
- 이미지에 `loading="lazy"` 필수
- `aspect-video` / `aspect-square`로 CLS 방지
- 애니메이션은 `transform` / `opacity` 우선 (reflow 방지)
- `prefers-reduced-motion: reduce` 시 애니메이션 비활성화
- SVG에 명시적 `width` / `height` 속성

**4. 레이아웃 & 반응형**
- 모바일 본문 최소 16px (`text-base`)
- 375px / 768px 기준 반응형 확인
- `dvh` 단위 사용 (모바일 브라우저 주소창 대응)

### MEDIUM (중간 우선순위)

**5. 타이포그래피 & 색상**
- 줄 높이 1.5-1.75 (본문 텍스트)
- 한글 줄 길이 25-35자 권장
- 프로젝트 색상 변수 사용
- 계층 구조: 제목 → 본문 → 보조 텍스트 명확 구분

**6. 애니메이션**
- UI 요소: 150-300ms (`duration-150` ~ `duration-300`)
- 페이지 전환: 300-500ms
- 동시 애니메이션 3개 이하 (단일 focal point)

**7. 스타일 일관성**
- 프로젝트 CSS 유틸리티 클래스 사용
- 카드 내부 간격: `space-y-` 시리즈 (혼합 `mb-2`/`mb-4` 금지)
- Heroicons 아이콘 세트 일관성

### LOW (선택)

**8. 데이터 시각화**
- 진행 바 애니메이션
- 빈 상태 디자인 필수

---

## Pre-Delivery 체크리스트

컴포넌트/페이지 완성 시 반드시 확인:

### 접근성
- [ ] 아이콘 버튼에 `aria-label` 존재
- [ ] SVG 아이콘에 `aria-hidden="true"`
- [ ] 이미지에 `alt` 텍스트 존재 (장식용은 `alt=""`)
- [ ] `focus-visible:ring-2` 포커스 스타일 가시
- [ ] `prefers-reduced-motion` 지원

### 터치 & 인터랙션
- [ ] 인터랙티브 요소에 `cursor-pointer`
- [ ] 최소 터치 타겟 44x44px
- [ ] 호버 상태에 레이아웃 시프트 없음
- [ ] 클릭 가능 요소에 hover/active 상태 존재

### 반응형 & 성능
- [ ] 375px (iPhone SE) 기준 정상 표시
- [ ] 768px (태블릿) 기준 정상 표시
- [ ] 이미지에 `loading="lazy"` 적용
- [ ] CLS 방지 (aspect-ratio 또는 명시적 크기)

### 스타일 일관성
- [ ] 프로젝트 색상 변수 사용 (하드코딩 색상 금지)
- [ ] 프로젝트 유틸리티 클래스 사용
- [ ] 아이콘 세트 일관 (Heroicons)
- [ ] 이모지를 아이콘 대신 사용하지 않음 (콘텐츠 이모지는 허용)

---

## 핵심 패턴

### 1. Stimulus 컨트롤러 기본 구조

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "button"]
  static values = { open: Boolean }
  static classes = ["hidden", "active"]

  connect() {
    // 초기화
  }

  disconnect() {
    // 정리 (이벤트 리스너, 타이머 제거) — MANDATORY
  }
}
```

### 2. XSS 방지 (JavaScript DOM 조작)

```javascript
// 안전 — 자동 이스케이핑
element.textContent = userInput

// 안전 — DOM API로 요소 생성
const div = document.createElement('div')
div.textContent = userInput
parent.appendChild(div)

// 안전 — Turbo Stream (서버 렌더링)
Turbo.renderStreamMessage(serverResponse)
```

### 3. Turbo Stream 타겟 ID 유일성

```erb
<%# DOM ID 헬퍼 사용 %>
<div id="<%= dom_id(post, :comments) %>">...</div>
```

### 4. 반응형 디자인 (Mobile First)

```erb
<div class="
  flex flex-col       <%# 모바일: 세로 %>
  md:flex-row         <%# 태블릿+: 가로 %>
  lg:gap-8            <%# 데스크톱: 넓은 간격 %>
">
```

### 5. CSS 스택 컨텍스트 주의

```erb
<%# 모달/오버레이는 main 외부에 렌더링 %>
<main>콘텐츠</main>
<div id="modal-container">모달은 여기에</div>
```

---

## 안티패턴 탐지

| 안티패턴 | 탐지 신호 | 대안 |
|---------|----------|------|
| 이모지를 아이콘으로 사용 | ERB에 이모지 직접 삽입 | Heroicons SVG |
| 호버 없는 클릭 요소 | `cursor-pointer` + hover 상태 누락 | `transition-colors` + `hover:` 추가 |
| 일관성 없는 카드 스타일 | `rounded-lg`와 `rounded-xl` 혼용 | 프로젝트 표준 통일 |
| CLS 유발 이미지 | `aspect-ratio` 없는 `<img>` 태그 | `aspect-video` / `aspect-square` |
| 과도한 애니메이션 | 3개 이상 동시 `animate-*` | 단일 focal point 애니메이션 |
| 접근성 누락 | `aria-label` 없는 아이콘 버튼 | 필수 추가 |
| 하드코딩 색상 | 임의 색상값 사용 | 프로젝트 색상 변수 사용 |
| `h-screen` 사용 | 모바일 주소창 문제 | `dvh` 사용 |

---

## CI 테스트 트러블슈팅 (UI 관련)

### ESC 키 모달 닫기 (빈도: 10%)

**문제**: `send_keys(:escape)`가 CI에서 실패

```ruby
# JavaScript 이벤트 발생
page.execute_script(<<~JS)
  document.dispatchEvent(new KeyboardEvent('keydown', {
    key: 'Escape',
    code: 'Escape',
    keyCode: 27,
    bubbles: true
  }))
JS
```

### Dropdown 경쟁 조건 (빈도: 15%)

```ruby
# 옵션 표시 대기 후 클릭
click_button "메뉴"
assert_selector "[data-dropdown-target='menu']", visible: true, wait: 3
find("[data-dropdown-target='menu']").click_link "설정"
```

### 숨겨진 요소 클릭 (빈도: 8%)

```ruby
# 먼저 표시시킨 후 클릭
page.execute_script("document.querySelector('.hidden-button').style.display = 'block'")
find(".hidden-button").click
```

### Turbo 네비게이션 후 요소 찾기

```ruby
# 다음 페이지 콘텐츠로 대기
click_link "다음 페이지"
assert_text "다음 페이지 고유 텍스트"
```

---

## 참조 문서

- [rules/frontend/tailwind-dos-donts.md](../../rules/frontend/tailwind-dos-donts.md) — Tailwind 패턴
- [rules/frontend/design-reasoning.md](../../rules/frontend/design-reasoning.md) — 디자인 추론 규칙
- [rules/frontend/accessibility.md](../../rules/frontend/accessibility.md) — 접근성 규칙
- [rules/frontend/stimulus-patterns.md](../../rules/frontend/stimulus-patterns.md) — Stimulus 패턴
- [rules/frontend/stimulus-architecture.md](../../rules/frontend/stimulus-architecture.md) — Stimulus 아키텍처
