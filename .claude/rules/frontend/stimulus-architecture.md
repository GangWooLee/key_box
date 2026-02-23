---
paths: app/javascript/controllers/**/*.js
---

# Stimulus 아키텍처 — 조합, 이벤트 통신, 상태 관리

> 기본 구조와 보안 규칙은 `stimulus-patterns.md` 참고. 이 파일은 아키텍처 수준의 패턴을 다룬다.

## 컨트롤러 내부 구조 (순서 규칙)

```javascript
export default class extends Controller {
  // 1. 선언부
  static targets = [...]
  static values = { ... }
  static classes = [...]

  // 2. 상수
  static DEBOUNCE_MS = 300

  // 3. 라이프사이클
  connect() {}
  disconnect() {}  // 필수: 리스너/타이머/RAF 정리

  // 4. Public Actions (data-action에서 호출)
  toggle() {}
  submit() {}

  // 5. Value Change Callbacks
  openValueChanged() {}

  // 6. Private Methods (# prefix)
  #render() {}
  #validate() {}

  // 7. Getters/Setters
  get #isValid() {}
}
```

## 컨트롤러 조합 패턴

| 패턴 | 용도 | 예시 |
|------|------|------|
| 부모-자식 | 중첩된 DOM 구조 | snap-scroll → video-player |
| 이벤트 디스패치 | 느슨한 결합 통신 | video-player dispatch → snap-scroll listen |
| Outlet | 형제 컨트롤러 참조 | tab-navigation → 각 탭 패널 |
| 공유 Value | 서버에서 공통 데이터 주입 | `data-*-value` 속성 |

## 이벤트 통신 규칙

```javascript
// 자식 → 부모: dispatch
this.dispatch("completed", { detail: { stepId: 3 } })

// 부모에서 수신 (HTML):
// data-action="tutor-guide:completed->parent#handleStep"
```

- **자식→부모**: `this.dispatch("eventName", { detail: { ... } })`
- **부모→자식**: Stimulus values 변경 또는 target 메서드 호출
- **무관한 컨트롤러**: `window` 이벤트 (최소화할 것)
- **이벤트명 형식**: `controller-name:event-name`

## 상태 관리 원칙

| 상태 유형 | 저장소 | 예시 |
|----------|--------|------|
| UI 상태 | Stimulus values (반응형) | 열림/닫힘, 현재 탭 |
| 세션 상태 | sessionStorage | 임시 폼 데이터 |
| 영구 상태 | 서버 (Turbo) | 사용자 설정, 진행도 |
| 전역 상태 | **금지** (`window.*` 사용 금지) | — |

## 재사용성 원칙

- **1 컨트롤러 = 1 관심사** (작고 집중된 컨트롤러 선호)
- **Generic 컨트롤러**: `toggle`, `clipboard`, `debounce` 등 — 3곳 이상 사용 시 추출
- **Domain 컨트롤러**: `video-player`, `onboarding` 등 — 특정 기능 전용

## 성능 패턴

- `disconnect()`에서 **반드시** 정리: 타이머(`clearTimeout`), 이벤트 리스너, `requestAnimationFrame`
- `IntersectionObserver`로 뷰포트 진입/이탈 감지 (스크롤 이벤트 대신)
- 무거운 초기화는 `requestIdleCallback` 또는 lazy 로딩
- DOM 조작 최소화 — CSS class 토글 선호 (`classList.toggle`)
