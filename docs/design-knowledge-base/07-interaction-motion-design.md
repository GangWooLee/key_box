# Phase 7 — 인터랙션 & 모션 디자인

## 개요

모션 디자인은 단순한 시각적 효과가 아니라 **사용자 경험의 핵심 언어**입니다. 마이크로 인터랙션부터 페이지 전환까지, 의도적이고 목적 있는 모션은 인터페이스를 생생하게 만들고 사용자의 이해를 돕습니다. 이 Phase에서는 Disney의 애니메이션 원칙, Material Design의 과학적 접근, 최신 Web API, 그리고 접근성까지 다루는 실무 중심의 가이드를 제시합니다.

**핵심 가치:**
- 모션은 피드백(Feedback)을 제공합니다
- 모션은 상태 변화를 명확히 합니다
- 모션은 공간감과 깊이를 표현합니다
- 모션은 브랜드 성격을 드러냅니다
- **모션은 반드시 접근성을 고려해야 합니다**

---

## 1. 모션 디자인 원칙

### 1.1 Disney 12 Principles of Animation

Disney가 1930년대 개발한 12가지 애니메이션 원칙은 디지털 UI 모션에도 완벽하게 적용됩니다.

#### **Squash & Stretch (찌그러짐과 늘어남)**
탄력감과 무게감을 표현합니다. 버튼 클릭 시 약간의 압축, 토스트 메시지 나타남 시 신축성 있는 움직임.

```css
/* 버튼 클릭 시 Squash & Stretch */
@keyframes buttonPress {
  0% {
    transform: scale(1);
  }
  50% {
    transform: scale(0.95) scaleY(1.05);
  }
  100% {
    transform: scale(1);
  }
}

button:active {
  animation: buttonPress 200ms cubic-bezier(0.68, -0.55, 0.265, 1.55);
}
```

#### **Anticipation (예상)**
사용자가 곧 일어날 일을 예측하도록 돕습니다. 모달 열기 전 배경 흐려짐, 메뉴 확장 전 작은 이동.

```css
/* 모달 열기 전 Anticipation */
@keyframes anticipateOpen {
  0% {
    transform: scale(0.95);
    opacity: 0;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

.modal.opening {
  animation: anticipateOpen 300ms ease-out;
}
```

#### **Staging (무대 설정)**
화면에서 주의를 집중시킬 요소를 명확히 하는 원칙. 중요 요소는 밝게, 배경은 약화.

```css
/* Staging 효과 */
.backdrop {
  animation: fadeBackdrop 400ms ease-in-out forwards;
}

@keyframes fadeBackdrop {
  from {
    background-color: transparent;
  }
  to {
    background-color: rgba(0, 0, 0, 0.5);
  }
}
```

#### **Timing (타이밍)**
애니메이션의 속도와 밀도를 조절합니다. 빠른 모션은 긴장감, 느린 모션은 우아함을 표현.

#### **Ease In/Out (가속/감속)**
현실 세계처럼 자연스러운 속도 변화. Material Design에서 권장하는 easing 함수:

```css
/* Standard curve - 대부분의 UI 요소 */
transition: all 300ms cubic-bezier(0.4, 0, 0.2, 1);

/* Emphasized - 진입/종료 시 강조 */
transition: all 300ms cubic-bezier(0.8, 0.15, 0.15, 0.85);

/* Decelerate - 나가면서 감속 */
transition: all 300ms cubic-bezier(0.3, 0, 1, 1);

/* Accelerate - 빨라지면서 진입 */
transition: all 300ms cubic-bezier(0, 0, 0.7, 0);
```

#### **그 외 원칙들**
- **Follow Through & Overlapping Action**: 여러 요소의 모션이 겹쳐서 자연스럽게 이어짐
- **Arcing**: 직선이 아닌 호(arc) 모양으로 움직임
- **Secondary Action**: 주 동작 후 보조 동작 (e.g., 버튼 클릭 후 물결 효과)

### 1.2 Material Design 모션 가이드

Google의 Material Design은 **과학적이고 일관된** 모션 시스템을 제시합니다.

#### **Duration (지속 시간)**
```
- Subtle interactions (토글, 체크박스): 100ms
- Standard transitions (화면 전환, 오버레이): 200-300ms
- Large area transitions (페이지 레이아웃 변경): 300-500ms
- 일반 규칙: 느낄 수 있는 최소 시간은 100ms, 최대는 500ms
```

#### **Easing Curves (Material Design 3)**
```css
/* Standard easing - 대부분의 경우 */
--easing-standard: cubic-bezier(0.2, 0, 0, 1);

/* Emphasized easing - 주의 끌어야 할 때 */
--easing-emphasized: cubic-bezier(0.3, 0, 0.8, 0.15);

/* Decelerate - 화면을 떠날 때 */
--easing-decelerate: cubic-bezier(0, 0, 0, 1);

/* Accelerate - 화면에 들어올 때 */
--easing-accelerate: cubic-bezier(0.3, 0, 1, 1);
```

#### **모션 시스템 예제**
```css
:root {
  /* Duration */
  --duration-short: 100ms;
  --duration-medium: 200ms;
  --duration-long: 300ms;
  --duration-xlarge: 500ms;

  /* Easing */
  --easing-standard: cubic-bezier(0.2, 0, 0, 1);
  --easing-emphasized: cubic-bezier(0.3, 0, 0.8, 0.15);
}

/* 사용 */
.button {
  transition: background-color var(--duration-medium) var(--easing-standard);
}

.modal {
  animation: enterModal var(--duration-long) var(--easing-emphasized);
}
```

### 1.3 Apple HIG (Human Interface Guidelines) 모션

Apple은 **정교함과 세련됨**을 강조합니다.

- **Responsive**: 사용자 입력에 즉각 반응 (적어도 100ms 이내)
- **Natural**: 현실 세계의 물리 법칙을 따름
- **Purposeful**: 모든 모션은 목적이 있어야 함 (장식성 피함)
- **Brief**: 짧고 명확한 모션 (200-300ms 권장)

---

## 2. 마이크로 인터랙션 프레임워크

Dan Saffer의 **Microinteractions** 프레임워크는 작은 모션/피드백을 설계하는 필수 도구입니다.

### 2.1 Dan Saffer의 4단계 프레임워크

#### **Trigger (트리거)**
인터랙션을 시작하는 신호.
- **User-initiated**: 버튼 클릭, 터치 제스처
- **System-initiated**: 시간 경과, 네트워크 상태 변화

#### **Rules (규칙)**
트리거 후 무엇이 일어나는지.
```javascript
// 예: 토글 스위치 규칙
if (toggle.checked) {
  showDescription();
  updateSettings();
} else {
  hideDescription();
}
```

#### **Feedback (피드백)**
사용자가 인지할 수 있는 시각적/청각적 반응.
- 색상 변화
- 아이콘 회전
- 사운드 (신중하게 사용)

#### **Loops & Modes (루프와 모드)**
인터랙션이 반복되거나 상태가 변할 때.
- 토글은 켜짐/꺼짐 모드
- 무한 로딩은 루프

### 2.2 실무 마이크로 인터랙션 예제

#### **버튼 피드백 시스템**
```css
/* 호버 상태 */
button {
  background-color: #2196F3;
  transition: background-color 200ms cubic-bezier(0.4, 0, 0.2, 1),
              box-shadow 200ms cubic-bezier(0.4, 0, 0.2, 1);
}

button:hover {
  background-color: #1976D2;
  box-shadow: 0 4px 12px rgba(33, 150, 243, 0.3);
}

/* 활성 상태 (클릭) */
button:active {
  transform: scale(0.98);
}

/* 비활성 상태 */
button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

#### **체크박스 애니메이션**
```css
.checkbox-wrapper {
  position: relative;
}

.checkbox-icon {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 2px solid #999;
  border-radius: 4px;
  transition: all 150ms ease-out;
}

.checkbox-input:checked ~ .checkbox-icon {
  background-color: #2196F3;
  border-color: #2196F3;
  animation: checkmark 250ms cubic-bezier(0.68, -0.55, 0.265, 1.55);
}

@keyframes checkmark {
  0% {
    transform: scale(0.5);
  }
  50% {
    transform: scale(1.2);
  }
  100% {
    transform: scale(1);
  }
}
```

#### **프로그레스 인디케이터**
```css
/* 선형 프로그레스 */
.progress-bar {
  width: 100%;
  height: 4px;
  background-color: #e0e0e0;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background-color: #2196F3;
  transition: width 400ms cubic-bezier(0.4, 0, 0.2, 1);
}

/* 불확정적 프로그레스 (로딩) */
@keyframes progressIndeterminate {
  0% {
    transform: translateX(-100%);
  }
  50% {
    transform: translateX(100%);
  }
  100% {
    transform: translateX(-100%);
  }
}

.progress-fill.indeterminate {
  animation: progressIndeterminate 1.5s infinite;
}
```

#### **풀 투 리프레시 (Pull-to-Refresh)**
```javascript
let startY = 0;
let currentY = 0;
const threshold = 80;

element.addEventListener('touchstart', (e) => {
  startY = e.touches[0].clientY;
});

element.addEventListener('touchmove', (e) => {
  if (scrollTop === 0) {
    currentY = e.touches[0].clientY;
    const distance = currentY - startY;

    if (distance > 0) {
      const progress = Math.min(distance / threshold, 1);
      indicator.style.transform = `rotate(${progress * 360}deg)`;
      indicator.style.opacity = progress;
    }
  }
});

element.addEventListener('touchend', () => {
  if ((currentY - startY) > threshold) {
    refreshData();
  }
});
```

---

## 3. CSS Scroll-Driven Animations

최신 Web Animations API를 활용한 스크롤 기반 애니메이션.

### 3.1 Scroll Timeline 개념

```css
/* 스크롤 진행도 추적 */
.scroller {
  animation: scrollProgress linear;
  animation-timeline: view();
}

@keyframes scrollProgress {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

### 3.2 Scroll Progress Indicator

```html
<div class="scroll-progress-bar"></div>
```

```css
.scroll-progress-bar {
  position: fixed;
  top: 0;
  left: 0;
  height: 4px;
  background: linear-gradient(to right, #2196F3, #00BCD4);
  animation: progressBar linear forwards;
  animation-timeline: view();
  transform-origin: left;
}

@keyframes progressBar {
  from {
    width: 0%;
  }
  to {
    width: 100%;
  }
}
```

### 3.3 Reveal on Scroll 패턴

```css
.reveal-item {
  opacity: 0;
  transform: translateY(30px);
  animation: revealOnScroll ease-out forwards;
  animation-timeline: view();
  animation-range: entry 0% cover 30%;
}

@keyframes revealOnScroll {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

### 3.4 브라우저 지원 및 폴백

```javascript
// Scroll-driven animations 지원 확인
if (CSS.supports('animation-timeline', 'view()')) {
  // 네이티브 Scroll-driven animations 사용
  console.log('Scroll-driven animations supported');
} else {
  // Intersection Observer 폴백
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  });

  document.querySelectorAll('.reveal-item').forEach(el => {
    observer.observe(el);
  });
}
```

---

## 4. View Transitions API

페이지 전환 시 매끄러운 애니메이션을 제공하는 최신 API.

### 4.1 기본 사용법

```javascript
// 문서 업데이트 시 View Transition 적용
if (document.startViewTransition) {
  document.startViewTransition(() => {
    // DOM 업데이트 수행
    updatePageContent();
  });
} else {
  // 폴백
  updatePageContent();
}
```

### 4.2 SPA/MPA 전환

```javascript
// SPA에서의 View Transition
async function navigateTo(path) {
  if (!document.startViewTransition) {
    window.location.href = path;
    return;
  }

  document.startViewTransition(() => {
    // 새 페이지 콘텐츠 로드
    return fetch(path)
      .then(res => res.text())
      .then(html => {
        document.body.innerHTML = html;
      });
  });
}

// MPA에서의 View Transition
document.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', (e) => {
    if (!link.target && document.startViewTransition) {
      e.preventDefault();
      document.startViewTransition(() => {
        window.location.href = link.href;
      });
    }
  });
});
```

### 4.3 커스텀 전환 효과

```css
/* 크로스 페이드 효과 */
::view-transition-old(root) {
  animation: fadeOut 300ms ease-out forwards;
}

::view-transition-new(root) {
  animation: fadeIn 300ms ease-out forwards;
}

@keyframes fadeOut {
  from { opacity: 1; }
  to { opacity: 0; }
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* 모프 트랜지션 (같은 요소의 위치/크기 변경) */
::view-transition-old(hero) {
  animation: slideOut 400ms ease-out forwards;
}

::view-transition-new(hero) {
  animation: slideIn 400ms ease-out forwards;
}

@keyframes slideOut {
  from { transform: translateX(0); }
  to { transform: translateX(-100vw); }
}

@keyframes slideIn {
  from { transform: translateX(100vw); }
  to { transform: translateX(0); }
}
```

### 4.4 특정 요소별 전환

```css
/* 영웅 이미지만 다른 전환 */
.hero-image {
  view-transition-name: hero;
}

/* 현재 페이지의 영웅 */
::view-transition-old(hero) {
  animation: heroOut 500ms ease-out forwards;
}

/* 새 페이지의 영웅 */
::view-transition-new(hero) {
  animation: heroIn 500ms ease-out forwards;
}
```

---

## 5. 접근성 고려사항

모션은 모든 사용자를 배려해야 합니다.

### 5.1 prefers-reduced-motion 미디어 쿼리

```css
/* 기본: 풍부한 모션 */
.animated-element {
  transition: all 300ms cubic-bezier(0.4, 0, 0.2, 1);
  animation: slideIn 500ms ease-out;
}

/* 사용자가 모션 감소를 선호할 때 */
@media (prefers-reduced-motion: reduce) {
  .animated-element {
    transition: none;
    animation: none;
  }

  /* 또는 더 간단한 모션으로 대체 */
  .animated-element {
    transition: opacity 100ms linear;
    animation: none;
  }
}
```

### 5.2 전정기관 장애 (Vestibular Disorders) 고려

```css
/* 과도한 모션 피하기 */
@media (prefers-reduced-motion: reduce) {
  /* 회전, 높은 속도의 모션 제거 */
  .loading-spinner {
    animation: none;
  }

  /* 대신 정적인 로딩 인디케이터 표시 */
  .loading-spinner::after {
    content: '로딩 중...';
  }

  /* 패닝(panning) 모션 제거 */
  .parallax-bg {
    background-attachment: scroll;
  }
}
```

### 5.3 JavaScript에서의 접근성 확인

```javascript
// 사용자의 모션 선호도 확인
const prefersReducedMotion = window.matchMedia(
  '(prefers-reduced-motion: reduce)'
).matches;

if (prefersReducedMotion) {
  // 간단한 모션만 사용하거나 모션 제거
  element.style.animation = 'none';
  element.style.transition = 'opacity 100ms linear';
} else {
  // 풍부한 모션 사용
  element.style.animation = 'complexAnimation 500ms ease-out';
}

// 런타임에 사용자 설정 변경 감지
const motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
motionQuery.addEventListener('change', () => {
  applyMotionPreferences();
});
```

### 5.4 WCAG 2.3.3 준수

- 3초 이상의 자동 재생 애니메이션 제거
- 깜빡이는 콘텐츠는 초당 3-4회 이상 금지
- 사용자가 애니메이션을 일시 중지할 수 있도록 제공

```css
/* 자동 재생 애니메이션 일시 중지 버튼 제공 */
.carousel.autoplay:hover {
  animation-play-state: paused;
}

button[aria-label="일시 중지"] {
  position: absolute;
  top: 10px;
  right: 10px;
}
```

---

## 6. 성능 최적화

매끄러운 60fps 모션은 사용자 경험의 핵심입니다.

### 6.1 will-change 사용법

```css
/* 곧 애니메이션될 요소를 미리 알림 */
.will-animate {
  will-change: transform, opacity;
  /* 변경 완료 후 제거 권장 */
}

.animated {
  animation: slideIn 300ms ease-out;
}

/* 애니메이션 완료 후 will-change 제거 */
@supports (animation-timeline: view()) {
  .animated {
    will-change: auto;
  }
}
```

### 6.2 GPU 가속 속성

```css
/* GPU 가속 활성화 (변환, 불투명도) */
.gpu-accelerated {
  /* 이 속성들은 GPU에서 처리됨 */
  animation: moveAndFade 300ms ease-out;
}

@keyframes moveAndFade {
  from {
    transform: translate(0, 100px);
    opacity: 0;
  }
  to {
    transform: translate(0, 0);
    opacity: 1;
  }
}

/* 피해야 할 속성들 (메인 스레드 처리) */
.bad-performance {
  animation: badAnimation 300ms ease-out;
}

@keyframes badAnimation {
  from {
    width: 0;
    height: 0;
  }
  to {
    width: 100px;
    height: 100px;
  }
}
```

### 6.3 Layout Thrashing 방지

```javascript
// 나쁜 예: Layout thrashing
elements.forEach(el => {
  el.style.left = el.offsetLeft + 10 + 'px'; // 레이아웃 리드
  // 리플로우 발생 → 스타일 쓰기 → 리플로우 반복
});

// 좋은 예: 배치 처리
const positions = Array.from(elements).map(el => el.offsetLeft);
elements.forEach((el, i) => {
  el.style.left = positions[i] + 10 + 'px';
});

// 더 나은 예: CSS로 처리
elements.forEach(el => {
  el.classList.add('animate-right');
});
```

### 6.4 requestAnimationFrame 활용

```javascript
// 브라우저 리페인트와 동기화
let animationFrameId;

function smoothScroll(target) {
  const currentScroll = window.scrollY;
  const distance = target - currentScroll;
  let start = null;

  function animate(timestamp) {
    if (start === null) start = timestamp;
    const progress = (timestamp - start) / 1000; // 1초에 완료

    if (progress < 1) {
      window.scrollTo(0, currentScroll + distance * progress);
      animationFrameId = requestAnimationFrame(animate);
    } else {
      window.scrollTo(0, target);
    }
  }

  animationFrameId = requestAnimationFrame(animate);
}

// 중단 가능
function cancelAnimation() {
  cancelAnimationFrame(animationFrameId);
}
```

### 6.5 DevTools에서 성능 측정

```javascript
// 성능 측정
performance.mark('animation-start');
// 애니메이션 실행
performance.mark('animation-end');
performance.measure('animation', 'animation-start', 'animation-end');

const measure = performance.getEntriesByName('animation')[0];
console.log(`애니메이션 시간: ${measure.duration}ms`);
```

---

## 7. 모션 스펙 작성 가이드

디자인과 개발 간의 정확한 커뮤니케이션을 위한 모션 스펙.

### 7.1 모션 스펙 문서 템플릿

```markdown
## 모션: [인터랙션 이름]

| 항목 | 값 |
|------|-----|
| **대상 요소** | .button, .modal |
| **트리거** | hover, click, page-load |
| **Duration** | 300ms |
| **Easing** | cubic-bezier(0.4, 0, 0.2, 1) |
| **Delay** | 0ms |
| **Property** | transform, opacity |
| **From** | scale(1), opacity(1) |
| **To** | scale(1.05), opacity(1) |
| **반복** | 1회 (loop하지 않음) |
| **Figma 연결** | [링크] |
| **비고** | 호버 시 미묘한 확대로 피드백 전달 |

### 코드 예제
\`\`\`css
.button:hover {
  animation: buttonHover 300ms cubic-bezier(0.4, 0, 0.2, 1) forwards;
}

@keyframes buttonHover {
  from {
    transform: scale(1);
    opacity: 1;
  }
  to {
    transform: scale(1.05);
    opacity: 1;
  }
}
\`\`\`
```

### 7.2 실무 모션 스펙 예제

#### **모달 열기**
```
Duration: 400ms
Easing: cubic-bezier(0.3, 0, 0.8, 0.15) [Emphasized]
Properties:
  - Backdrop: opacity (0 → 0.5)
  - Modal: transform (scale 0.9, translateY 20px) → scale 1, translateY 0
  - Modal: opacity (0 → 1)
```

#### **토스트 알림**
```
Duration: 200ms (진입), 100ms (종료)
Easing: cubic-bezier(0.4, 0, 0.2, 1) [Standard]
Properties:
  - Transform: translateY (30px → 0) 진입, translateY (0 → -30px) 종료
  - Opacity: 0 → 1 진입, 1 → 0 종료
Auto-dismiss: 3초
```

#### **버튼 로딩**
```
Duration: 600ms (무한 반복)
Easing: linear
Properties:
  - Rotation: 0 → 360deg
Status 변경 시 상태:
  - Loading → Complete: 체크마크로 변환 (200ms)
  - 이후 자동으로 원래 상태로 복구 (300ms)
```

### 7.3 Figma 프로토타이핑 연계

```
Figma 프로토타이핑 설정:
1. Interaction 추가: On Tap → Animate to [다음 화면]
2. Animation Type: Move in (또는 Custom Animation)
3. Duration: 300ms
4. Easing: iOS Easing (또는 Custom curve 입력)
5. Delay: 0ms
6. Design specs 내보내기 → 개발 문서에 첨부
```

---

## 8. 디자인 리뷰 체크리스트

모션 디자인의 품질을 보증하기 위한 체크리스트.

### 리뷰 기준

- [ ] **목적 명확성**: 모든 모션이 명확한 목적을 가지고 있는가?
- [ ] **타이밍 일관성**: 같은 종류의 인터랙션은 동일한 duration을 사용하는가?
- [ ] **이징 일관성**: Material Design 또는 정의된 easing 시스템을 따르는가?
- [ ] **접근성**: prefers-reduced-motion을 반영했는가?
- [ ] **성능**: 60fps를 유지하는가? will-change와 GPU 가속을 사용했는가?
- [ ] **반응성**: 사용자 입력에 100ms 이내 반응하는가?
- [ ] **자연스러움**: Disney 원칙 (anticipation, ease-in/out 등)을 적용했는가?
- [ ] **일관성**: 브랜드 모션 가이드라인을 따르는가?
- [ ] **오버킬 방지**: 불필요한 모션은 제거했는가?
- [ ] **문서화**: 모션 스펙이 명확히 작성되었는가?

### 리뷰 프로세스

1. **디자인 리뷰**: 개발 시작 전 디자인 팀과 모션 스펙 확인
2. **코드 리뷰**: 개발 완료 후 성능과 접근성 확인
3. **QA 테스트**: 다양한 브라우저, 디바이스에서 테스트
4. **성능 측정**: Chrome DevTools Performance 탭으로 fps 확인

---

## 9. 모션 설계 바이브코딩 가이드 (Vibe Coding)

"바이브 감각"으로 모션을 설계하고 느끼는 법.

### 9.1 모션의 "성격" 파악

**프리미엄/고급 브랜드**
- Easing: Emphasized (cubic-bezier(0.3, 0, 0.8, 0.15))
- Duration: 300-400ms (조금 느림)
- 특징: 미묘하고 우아한 모션

```css
.premium-button {
  transition: all 300ms cubic-bezier(0.3, 0, 0.8, 0.15);
}
```

**친근한/캐주얼 브랜드**
- Easing: Standard (cubic-bezier(0.4, 0, 0.2, 1))
- Duration: 150-250ms (빠름)
- 특징: 생동감 있고 활발한 모션

```css
.casual-button {
  transition: all 150ms cubic-bezier(0.4, 0, 0.2, 1);
}
```

**효율성 중심 (업무용)**
- Easing: Accelerate (cubic-bezier(0.3, 0, 1, 1))
- Duration: 100-200ms (매우 빠름)
- 특징: 최소한의 모션, 즉각적 반응

```css
.utility-button {
  transition: all 100ms cubic-bezier(0.3, 0, 1, 1);
}
```

### 9.2 "느낌" 기반 모션 선택 가이드

| 감정/톤 | 추천 Easing | Duration | 예제 |
|--------|-----------|----------|------|
| 우아함 | Emphasized | 300ms+ | 모달 진입 |
| 에너지 | Standard | 150-250ms | 버튼 호버 |
| 긴박감 | Accelerate | 100-150ms | 에러 알림 |
| 부드러움 | Decelerate | 200-300ms | 스크롤 진입 |
| 재미 | Custom Bounce | 300-500ms | 장난스러운 UI |

### 9.3 "리듬감" 있는 모션

여러 요소가 계단식(cascade)으로 움직일 때:

```css
.cascade-item {
  animation: slideIn 300ms ease-out forwards;
}

.cascade-item:nth-child(1) { animation-delay: 0ms; }
.cascade-item:nth-child(2) { animation-delay: 50ms; }
.cascade-item:nth-child(3) { animation-delay: 100ms; }
.cascade-item:nth-child(4) { animation-delay: 150ms; }

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

### 9.4 모션 테스트: "보는 것"과 "느끼는 것"

```javascript
// 모션의 느낌을 테스트하는 프로토타입
function testMotion(element, duration, easing) {
  element.style.transition = `all ${duration}ms ${easing}`;
  element.style.transform = 'scale(1.1)';

  setTimeout(() => {
    element.style.transform = 'scale(1)';
  }, 100);
}

// 여러 easing으로 비교
testMotion(button, 200, 'cubic-bezier(0.4, 0, 0.2, 1)');
// vs
testMotion(button, 200, 'cubic-bezier(0.3, 0, 0.8, 0.15)');
```

---

## 10. 참고 자료 및 리소스

### 핵심 참고 문헌
- **Disney Animation: The Illusion of Life** - 12가지 원칙의 근원
- **Material Design Motion Guidelines** - google.com/design/spec/motion
- **Apple Human Interface Guidelines** - developer.apple.com/design/human-interface-guidelines
- **Dan Saffer: Microinteractions** - 마이크로 인터랙션 설계 바이블

### 온라인 도구
- **Easing Functions**: easings.net (easing 곡선 비교)
- **Animate.css**: CSS 애니메이션 라이브러리
- **Framer Motion**: React 모션 라이브러리
- **GSAP**: 고급 애니메이션 라이브러리

### 성능 도구
- **Chrome DevTools**: Performance 탭에서 fps 측정
- **Lighthouse**: 접근성 및 성능 감사
- **WebPageTest**: 실제 네트워크 환경에서의 애니메이션 성능 테스트

### 웹 표준 명세
- **Web Animations API**: W3C 표준
- **CSS Animations Module**: CSS 기반 애니메이션
- **View Transitions API**: 페이지 전환 애니메이션
- **Scroll-driven Animations**: 스크롤 기반 애니메이션

---

## 결론

모션 디자인은 **기술과 예술의 완벽한 조화**입니다. Disney의 시대를 초월한 애니메이션 원칙부터 최신 Web API, 접근성까지 모두 고려할 때, 사용자는 진정으로 매력적이고 포용적인 인터페이스를 경험합니다.

**핵심 정리:**
1. 모든 모션은 **목적**을 가져야 합니다
2. 타이밍과 이징은 **일관되고 과학적**이어야 합니다
3. 성능은 **필수**이며 60fps는 기본입니다
4. 접근성은 **선택**이 아닌 **의무**입니다
5. 모션 스펙은 **명확하고 문서화**되어야 합니다

이 가이드를 따르면, 아무리 복잡한 인터랙션도 우아하고 효율적으로 설계할 수 있습니다.
