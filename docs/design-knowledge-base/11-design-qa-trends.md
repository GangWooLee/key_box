# Phase 11 — 디자인 QA, 리뷰 프로세스 & 최신 트렌드

## 개요

디자인 품질 보증(Design QA)은 더 이상 선택이 아닌 필수이다. 2024년부터 대규모 조직들은 코드 리뷰처럼 디자인도 자동화된 검사 및 체계적인 프로세스를 요구한다. 본 장에서는 Design Lint, Visual Regression Testing, 현대적 디자인 리뷰 프로세스, 그리고 2024-2026년 주요 트렌드(Bento Grid, Glassmorphism, Spatial Design, AI-assisted Design)를 다룬다.

---

## 핵심 이론

### Design QA의 4가지 레이어

| 레이어 | 담당 | 타이밍 | 도구 |
|--------|------|--------|------|
| **Automated Lint** | CI/CD | 커밋 시 | Design Lint, Polaris, Stark |
| **Visual Regression** | CI/CD | 배포 전 | Chromatic, Percy, BackstopJS |
| **Manual Design Review** | 설계자/리더 | 스프린트 중 | Figma, Loom, Google Meet |
| **QA Validation** | QA 엔지니어 | 배포 전 | Storybook, 브라우저 테스트 |

### Design System이 QA의 핵심

Design Tokens의 도입으로 "디자인-코드 갭"이 좁혀지고 있다:
- **토큰 기반 관리**: 색상, 타이포그래피, 간격을 JSON으로 정의
- **자동 동기화**: 변경 시 자동으로 모든 플랫폼에 반영
- **일관성 검증**: 린트가 토큰 사용을 자동으로 검사

---

## 실무 적용

### 1. 디자인 린트(Design Lint) — 자동화된 품질 검사

#### 개념
코드 린트(ESLint, Prettier)처럼, 디자인 파일도 자동으로 일관성을 검사한다.

#### 주요 도구

**Figma Design Lint** (by Daniel Destefanis)
```
검사 항목:
- 문자 레이어의 마진이 8pt 배수인지 확인
- 모든 텍스트가 정의된 스타일을 사용하는지 확인
- 색상 토큰의 정의되지 않은 색 사용 감지
- 컴포넌트 누락: 재사용 가능한 요소가 컴포넌트인지 확인
- 이름 규칙 준수: "Frame/Button/Primary" 형태 검증
```

**Stark** (Accessibility + Design QA)
- 색 대비 검사 (WCAG AA/AAA)
- 이미지 텍스트 감지
- 포커스 순서 검증
- 다양한 색맹 시뮬레이션

**Polaris Lint**
- Shopify Design System 검증
- 컴포넌트 사용 규칙 강제
- 디자인 토큰 준수 확인

#### 커스텀 린트 규칙 구현

```javascript
// Design Lint 커스텀 규칙 예시 (Node.js)
const designLintRules = {
  spacingConsistency: {
    name: "Spacing must be 4pt or 8pt multiples",
    check: (layer) => {
      const padding = layer.absoluteBoundingBox;
      return padding.x % 4 === 0 && padding.y % 4 === 0;
    }
  },

  colorTokenUsage: {
    name: "Only use defined color tokens",
    check: (shape) => {
      const definedTokens = ['primary', 'secondary', 'neutral'];
      return definedTokens.includes(shape.fill.colorToken);
    }
  },

  typographyScale: {
    name: "Font size must match design system scale",
    check: (text) => {
      const scale = [12, 14, 16, 18, 20, 24, 28, 32];
      return scale.includes(text.fontSize);
    }
  },

  componentNaming: {
    name: "Components must follow 'Category/Type/State' naming",
    pattern: /^[A-Z][a-z]+\/[A-Z][a-z]+\/[A-Za-z]+$/,
    check: (component) => pattern.test(component.name)
  }
};
```

#### CI/CD 통합 예시

```yaml
# GitHub Actions + Figma Linter
name: Design QA
on: [pull_request]
jobs:
  design-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Design Lint
        run: |
          npm install design-lint-cli
          design-lint --figma-token ${{ secrets.FIGMA_TOKEN }} \
                      --file-key ${{ env.FIGMA_FILE }} \
                      --rules ./design-lint-rules.json
      - name: Comment Results
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '## Design Lint Report\n' + lintResults
            })
```

---

### 2. 시각적 회귀 테스트(Visual Regression Testing)

#### 개념
UI 변경 후 의도하지 않은 시각적 변화가 없는지 자동으로 검증한다.

#### 도구 비교

| 도구 | 장점 | 단점 | 가격 |
|------|------|------|------|
| **Chromatic** | Storybook 통합, 우수한 UI | 설정 필요 | 시작 무료 |
| **Percy** | 정확한 diff, 응답 빠름 | 비쌈 | $100+/mo |
| **BackstopJS** | 오픈소스, 자체 호스팅 가능 | 셋업 복잡 | 무료 |
| **Playwright** | 모던 테스트 프레임워크 | 학습곡선 | 무료 |

#### Pixel Diff vs Perceptual Diff

```javascript
// Pixel Diff: 모든 픽셀 변화를 감지 (민감함)
// 문제: 반올림 오차, 폰트 렌더링 차이로 오양성 높음

// Perceptual Diff (SSIM, DSSIM): 인간의 눈으로 감지 가능한 변화만
// 예: 1-2px 차이는 무시하고 5px 이상 변화만 플래그

// Chromatic의 Perceptual 비교 알고리즘
const perceptualDiff = {
  threshold: 0.15,  // 15% 이상의 지각적 변화만 오류
  ignoreAntialiasing: true,
  ignoreColors: false,
  includeAA: true
};
```

#### Chromatic 구현 예시

```json
// .chromatic.json
{
  "projectToken": "YOUR_TOKEN",
  "buildScriptName": "build",
  "onlyStoryFiles": ["src/stories/*.stories.tsx"],
  "exitZeroOnChanges": false,
  "exitOnceUploadedDone": true,
  "skipBuildScript": false,
  "debug": false,
  "only": "",
  "skip": false,
  "diagnosticsFile": false
}
```

#### Storybook Visual Test

```typescript
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  component: Button,
  parameters: {
    chromatic: { delay: 300 } // 애니메이션 대기
  }
};

export default meta;

export const Primary: StoryObj = {
  args: { variant: 'primary', children: 'Click me' },
  play: async ({ canvasElement }) => {
    // 상호작용 테스트
    const button = canvasElement.querySelector('button');
    await fireEvent.hover(button);
  }
};

export const Hover: StoryObj = {
  ...Primary,
  parameters: {
    pseudo: { hover: true }
  }
};

export const Pressed: StoryObj = {
  ...Primary,
  parameters: {
    pseudo: { active: true }
  }
};
```

#### 반응형 테스트

```javascript
// BackstopJS 설정
module.exports = {
  viewports: [
    { name: 'mobile', width: 375, height: 667 },
    { name: 'tablet', width: 768, height: 1024 },
    { name: 'desktop', width: 1440, height: 900 }
  ],
  scenarios: [
    {
      label: 'Homepage Mobile',
      url: 'http://localhost:3000',
      selectors: ['body'],
      viewports: ['mobile']
    }
  ]
};
```

---

### 3. 디자인 리뷰 프로세스

#### Design Critique vs Design Review

| 구분 | Design Critique | Design Review |
|------|-----------------|---|
| **목적** | 아이디어 평가 및 개선 | 실행 품질 검증 |
| **시기** | 초안 단계 (낮은 충실도) | 완성 단계 |
| **참여자** | 동료 디자이너 | 디자이너 + 개발자 + 제품 |
| **피드백 형태** | 개방적, 창의적 | 구체적, 기준 기반 |

#### Liz Lerman의 Critical Response Process

1. **Affirmations** (칭찬): "나는 이 디자인이 좋은 이유는..."
2. **Clarifying Questions** (질문): "이 패턴은 왜 선택했나요?"
3. **Concerns** (우려): "앞으로 이 부분이 문제가 될 수 있을 것 같아요"
4. **Suggestions** (제안): "이렇게 해보면 어떨까요?"

#### Stanford d.school 피드백 프레임워크

```
I LIKE: ___________________
(구체적인 요소를 칭찬하세요. 왜 좋은지 설명하세요.)

I WISH: ___________________
(더 있었으면 좋겠는 요소가 있나요? 더 강화되면 좋을 부분?)

WHAT IF: ___________________
(대담한 아이디어나 가능성? 디자인을 다르게 해석할 방법?)
```

#### 리뷰 단계별 체크리스트

**단계 1: Concept Review (설계 초기)**
- [ ] 문제 정의가 명확한가?
- [ ] 사용자 니즈를 해결하는가?
- [ ] 경쟁 제품 대비 차별성이 있는가?

**단계 2: Design Review (중간 검토)**
- [ ] 디자인 시스템 준수
- [ ] 접근성 기준 충족 (WCAG 2.1 AA)
- [ ] 반응형 설계 적용
- [ ] 마이크로인터랙션 명시
- [ ] 로딩/에러/빈 상태 디자인

**단계 3: Dev Handoff Review**
- [ ] Figma Dev Mode에서 사양 명확
- [ ] 디자인 토큰 동기화
- [ ] 마진/패딩/색상 정의 완료
- [ ] 컴포넌트 상태(normal, hover, active, disabled) 모두 정의

**단계 4: QA Review (배포 전)**
- [ ] 브라우저 호환성
- [ ] 성능 (LCP < 2.5s)
- [ ] 접근성 자동 검사 통과

#### 비동기 디자인 리뷰 (Async Design Review)

Figma Comments를 활용한 비동기 리뷰:

```
# Figma Comment Workflow

1. 리뷰어가 컴포넌트 위에 코멘트 추가
   @designer "이 버튼의 hover 상태는?"

2. 디자이너가 Figma 내에서 답변
   "hover 상태를 component variant로 추가했습니다"

3. 리뷰어가 resolved 마크
4. GitHub 이슈 자동 생성 (Figma<->GitHub 연동)
```

---

### 4. 디자인 핸드오프 프로세스

#### Figma Dev Mode (2023+)

Dev Mode는 개발자가 필요한 모든 정보를 Figma에서 직접 추출할 수 있게 한다.

```
Figma Dev Mode 정보:
- CSS 코드 자동 생성: margin, padding, border, shadow
- 컴포넌트 경로: Button → Primary → Large
- 변수 참조: var(--color-primary, #0066FF)
- 리소스 다운로드: SVG, PNG (다양한 비율)
```

#### Design Tokens 기반 핸드오프

```json
// tokens.json (Design Tokens Format)
{
  "color": {
    "primary": {
      "value": "#0066FF",
      "type": "color"
    },
    "primary-hover": {
      "value": "#0052CC",
      "type": "color"
    },
    "primary-active": {
      "value": "#0039A6",
      "type": "color"
    }
  },
  "spacing": {
    "xs": { "value": "4px", "type": "dimension" },
    "sm": { "value": "8px", "type": "dimension" },
    "md": { "value": "16px", "type": "dimension" },
    "lg": { "value": "24px", "type": "dimension" }
  },
  "typography": {
    "heading-1": {
      "value": {
        "fontFamily": "Inter",
        "fontSize": "32px",
        "fontWeight": 700,
        "lineHeight": "40px"
      },
      "type": "typography"
    }
  }
}
```

#### 개발자 핸드오프 체크리스트

```markdown
# Developer Handoff Checklist

## Figma Setup
- [ ] Dev Mode에서 모든 컴포넌트 검사 가능
- [ ] 토큰이 JSON으로 내보내기 가능
- [ ] 마진/패딩이 일관되게 적용됨 (8pt 그리드)
- [ ] 색상이 토큰으로 정의됨 (#123ABC 사용 금지)

## Component Documentation
- [ ] 모든 상태 정의: normal, hover, focus, active, disabled
- [ ] 상호작용: 클릭, 드래그, 스와이프 명시
- [ ] 반응형: 모바일, 태블릿, 데스크톱 변형
- [ ] 애니메이션: 속도, easing, delay 명시

## Specification
- [ ] 타이포그래피: 폰트, 크기, 굵기, 행간
- [ ] 색상: RGB/HEX와 토큰명 모두 기록
- [ ] 간격: 마진/패딩 명시 (pt 기준)
- [ ] 그림자: blur, spread, offset, color 정의
- [ ] 경계: 너비, 스타일, 색상

## Storybook Integration
- [ ] 모든 컴포넌트가 Storybook에 등록됨
- [ ] Argon (controls)로 props 조정 가능
- [ ] Visual test 설정됨
```

#### Code Generation: Figma to Code

```
자동 코드 생성 도구:
1. Locofy (AI-powered)
   - Figma → React/Next.js 자동 생성
   - 정확도: 80~85%

2. Figma 플러그인: Builder.io
   - 드래그드롭 기반
   - Responsive CSS 자동 생성

3. Custom Integration (고급)
   - Figma API + 템플릿 엔진
   - 조직 규칙에 맞춰 커스터마이징
```

---

## 2024-2026 디자인 트렌드 종합

### 1. Bento Grid 레이아웃 (Apple-inspired)

```css
/* Bento Grid: 비대칭 그리드 (Apple 영감) */
.bento-container {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;

  /* 비대칭 아이템 */
  .item-featured {
    grid-column: span 2;
    grid-row: span 2;
  }

  .item-tall {
    grid-row: span 2;
  }

  .item-wide {
    grid-column: span 2;
  }
}

/* 모바일: 단순화 */
@media (max-width: 768px) {
  .bento-container {
    grid-template-columns: repeat(2, 1fr);

    .item-featured,
    .item-wide {
      grid-column: span 1;
      grid-row: span 1;
    }
  }
}
```

**2026 트렌드**: Bento Grid는 더 이상 모던함의 상징이 아니라 **정보 계층**의 표준이 됨.

### 2. Glassmorphism 진화 & 블러 효과

```css
/* Glassmorphism 2024 버전 */
.glass-card {
  backdrop-filter: blur(12px);
  background: rgba(255, 255, 255, 0.15);
  border: 1px solid rgba(255, 255, 255, 0.25);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  border-radius: 12px;

  /* 2024 추가 요소: 색상 필터 */
  mix-blend-mode: multiply;

  /* 동적 블러: 배경에 따라 조정 */
  --blur-amount: var(--background-complexity);
  filter: brightness(1.1);
}

/* 극단적 Glassmorphism (2024+) */
.ultra-glass {
  backdrop-filter: blur(20px) saturate(180%);
  background: rgba(0, 0, 0, 0.05);
  border-radius: 8px;
}
```

**주의**: 2024년부터 과도한 glassmorphism은 성능 저하 (GPU 사용↑) 때문에 지양.

### 3. 3D 요소와 평면 디자인의 하이브리드

```html
<!-- 3D CSS Transform + Flat Design -->
<div class="card-container">
  <div class="card" style="transform: perspective(1000px) rotateX(5deg);">
    <div class="content">Flat content here</div>
  </div>
</div>

<style>
.card {
  transform: translateZ(20px);
  transition: transform 0.3s ease;
}

.card:hover {
  transform: translateZ(50px) rotateZ(2deg);
  box-shadow: 0 20px 40px rgba(0,0,0,0.2);
}

/* 3D 아이콘 on flat background */
.icon-3d {
  --rotateX: 0deg;
  --rotateY: 0deg;
  transform: perspective(1000px) rotateX(var(--rotateX)) rotateY(var(--rotateY));
}
</style>
```

### 4. Variable Fonts 디자인 요소로 활용

```css
/* Variable Font 범위 활용 */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap');

.text {
  font-family: 'Inter', sans-serif;
  font-size: 18px;
}

/* 무게를 애니메이션으로 조작 */
.text.animated {
  animation: fontWeight 3s ease-in-out infinite;
  font-weight: 400;
}

@keyframes fontWeight {
  0%, 100% { font-weight: 400; }
  50% { font-weight: 700; }
}

/* 광학 크기 조정 (읽기 쉬워짐) */
.body-text {
  font-size: 14px;
  font-optical-sizing: auto;
}

.headline {
  font-size: 48px;
  font-optical-sizing: auto;
}
```

### 5. 마이크로 애니메이션 & 스크롤 트리거 효과

```javascript
// Scroll-triggered animation (GSAP + ScrollTrigger)
gsap.registerPlugin(ScrollTrigger);

gsap.utils.toArray('.fade-in').forEach(element => {
  gsap.to(element, {
    opacity: 1,
    y: 0,
    duration: 0.6,
    ease: 'power2.out',
    scrollTrigger: {
      trigger: element,
      start: 'top 80%',
      toggleActions: 'play none none reverse'
    }
  });
});

// Parallax on scroll (2024 트렌드)
gsap.to('.parallax-bg', {
  y: (i, target) => -ScrollTrigger.getScrollRatio(target) * 100,
  ease: 'none',
  scrollTrigger: {
    trigger: '.parallax-container',
    scrub: true
  }
});
```

### 6. Dark Mode를 기본으로 설계

```css
/* prefers-color-scheme 활용 */
:root {
  color-scheme: light dark;

  --bg-primary: #ffffff;
  --text-primary: #000000;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: #121212;
    --text-primary: #e0e0e0;
  }
}

body {
  background: var(--bg-primary);
  color: var(--text-primary);
}

/* Toggle로 수동 제어 */
[data-theme='dark'] {
  --bg-primary: #121212;
  --text-primary: #e0e0e0;
}

[data-theme='light'] {
  --bg-primary: #ffffff;
  --text-primary: #000000;
}
```

### 7. AI 생성 이미지와 UI의 통합

```html
<!-- AI 이미지 활용 시 고려사항 -->
<div class="ai-image-container">
  <img
    src="image-generated-by-dall-e.png"
    alt="Generated background"
    loading="lazy"
  />
  <!-- 위에 overlay로 텍스트 보호 -->
  <div class="overlay"></div>
  <div class="content">
    <h1>Text over AI image</h1>
  </div>
</div>

<style>
.ai-image-container {
  position: relative;
  background-image: url('ai-generated.jpg');

  /* 이미지 품질 저하 보정 */
  filter: contrast(1.05) brightness(1.02);
}

.overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(to bottom, transparent, rgba(0,0,0,0.5));
}
</style>
```

**주의사항**:
- AI 이미지는 상업용 라이선스 확인 필수
- 저작권 투명성 표시
- 다양성과 포용성 고려 (편향 검토)

### 8. 접근성을 경쟁 우위로

```html
<!-- WCAG 2.1 AAA 기준 준수 -->
<button
  aria-label="Close dialog"
  aria-pressed="false"
  class="close-button"
>
  ✕
</button>

<input
  type="text"
  placeholder="Search products"
  aria-label="Product search"
  aria-describedby="search-help"
/>
<span id="search-help">Type a product name or SKU</span>

<!-- 포커스 관리 -->
<style>
button:focus-visible {
  outline: 3px solid var(--focus-color);
  outline-offset: 2px;
}

/* 색상만으로 정보 전달하지 않기 */
.input-error {
  border-color: #cc0000;
  background-image: url('icon-error.svg');
}
</style>
```

### 9. 디지털 탄소 발자국 (Sustainability)

```css
/* 에너지 효율적 색상 선택 (OLED 기준) */
:root {
  --bg-dark: #0a0a0a;     /* OLED에서 가장 효율적 */
  --bg-medium: #1a1a1a;   /* 약간 밝음 */
  --text-on-dark: #ffffff;
}

/* 불필요한 애니메이션 제거 */
@media (prefers-reduced-motion: reduce) {
  * {
    animation: none !important;
    transition: none !important;
  }
}

/* 이미지 최적화: WebP + 반응형 */
<picture>
  <source srcset="image-large.webp" media="(min-width: 1024px)" type="image/webp">
  <source srcset="image-medium.webp" media="(min-width: 512px)" type="image/webp">
  <source srcset="image-small.webp" type="image/webp">
  <img src="image-fallback.jpg" alt="...">
</picture>
```

### 10. Design System 성숙도 & 거버넌스

**2024-2026 추세**: 디자인 시스템은 단순한 컴포넌트 라이브러리가 아니라 **조직의 기술 전략**이 됨.

```yaml
# Design System 거버넌스 구조
governance:
  stewards:
    - design-system-team
    - platform-leads

  proposal-process:
    stage-1: RFC (Request for Comments)
    stage-2: Design Review
    stage-3: Implementation
    stage-4: Release
    stage-5: Adoption Metrics

  component-lifecycle:
    alpha: "개발 초기, 피드백 수렴"
    beta: "검증됨, 일부 사용"
    stable: "프로덕션, 모든 팀 사용"
    deprecated: "대체 컴포넌트 권고"
    archived: "레거시"

  contribution-model:
    lightweight: "아이콘, 컬러 추가"
    standard: "컴포넌트 제안"
    heavyweight: "새로운 패턴 정의"
```

### 11. Voice UI & 대화형 인터페이스

```html
<!-- Voice Command + Visual Feedback -->
<div class="voice-interface">
  <button class="voice-toggle" aria-pressed="false">
    🎤 Voice On
  </button>
  <div class="voice-visualizer" id="waveform">
    <!-- 음량 시각화 -->
  </div>
  <p id="transcript" role="status">Listening...</p>
</div>

<script>
const recognition = new webkitSpeechRecognition();

recognition.onstart = () => {
  document.querySelector('#transcript').textContent = 'Listening...';
  document.querySelector('.voice-visualizer').classList.add('active');
};

recognition.onresult = (event) => {
  const transcript = Array.from(event.results)
    .map(result => result[0].transcript)
    .join('');
  document.querySelector('#transcript').textContent = transcript;
};

recognition.onend = () => {
  document.querySelector('.voice-visualizer').classList.remove('active');
};
</script>
```

### 12. Motion as Brand Identity

```css
/* 브랜드 고유 모션 언어 */
@keyframes brand-entrance {
  0% {
    opacity: 0;
    transform: scale(0.95) translateY(-10px);
  }
  100% {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

/* cubic-bezier로 브랜드 곡선 정의 */
:root {
  --ease-brand: cubic-bezier(0.34, 1.56, 0.64, 1);  /* 탄력적 */
  --ease-subtle: cubic-bezier(0.25, 0.46, 0.45, 0.94); /* 부드러움 */
}

.component-entrance {
  animation: brand-entrance 0.6s var(--ease-brand);
}

/* 상호작용별 다른 타이밍 */
button {
  transition: transform 0.2s var(--ease-brand),
              background-color 0.15s linear;
}

button:active {
  transform: scale(0.98);
}
```

---

## AI 통합 인터페이스 설계

### 1. AI-assisted Design Tools

**Figma AI** (2024+):
- 자동 레이아웃 제안
- 색상 팔레트 생성
- 텍스트 변형 (tone of voice)

**Framer AI**:
- 프롬프트 → 컴포넌트 자동 생성
- 상호작용 자동 추가

**Galileo AI**:
- 와이어프레임 → 고충실도 디자인
- 정확도: 70~80%

### 2. AI Copilot 인터페이스 패턴

```tsx
// Chat-in-app 패턴
interface AICopilotUI {
  // 1. 사이드패널 채팅
  sidePanel: {
    input: string;
    suggestions: string[];  // "Change color", "Add animation"
    history: Message[];
  };

  // 2. 명령 팔레트 (Cmd+K)
  commandPalette: {
    query: string;
    results: AICommand[];
  };

  // 3. 인라인 제안
  inlineSuggestions: {
    trigger: 'text-selection' | 'hover' | 'manual';
    options: DesignAlternative[];
  };

  // 4. 프롬프트 가이드
  promptTemplates: {
    templates: PromptTemplate[];
  };
}

// 사용 예시
const promptTemplate = `
Redesign this button for [target audience]:
- Primary color: [hex]
- Context: [use case]
- Tone: [formal|playful|minimal]
`;
```

### 3. Generative UI 패턴

```typescript
// 데이터 기반 동적 레이아웃
interface GenerativeUILayout {
  // 1. 데이터 → 레이아웃 자동 생성
  items: Array<{
    id: string;
    priority: 'high' | 'medium' | 'low';
    contentLength: number;
  }>;

  // AI가 최적 레이아웃 결정
  layout: 'grid' | 'list' | 'masonry' | 'bento';

  // 2. 반응형 자동 조정
  responsive: {
    mobile: { columns: 1, gap: 12 };
    tablet: { columns: 2, gap: 16 };
    desktop: { columns: 3, gap: 20 };
  };
}

// 예: Dashboard 자동 구성
const dashboard = {
  widgets: [
    { type: 'metric', importance: 1 },
    { type: 'chart', importance: 0.8 },
    { type: 'table', importance: 0.6 }
  ],
  // AI가 배치 결정
  layoutFromAI: 'metric takes 2x2, chart takes 2x1, table fills rest'
};
```

### 4. Ethical AI in Design

```
AI 사용 가이드라인:

1. 편향(Bias) 검토
   - 생성된 이미지의 다양성 확인
   - 성별, 인종, 나이 표현 검수

2. 투명성
   - "AI-assisted" 표시 필수
   - 프롬프트 로깅

3. 저작권
   - 학습 데이터 출처 명시
   - 라이선스 준수

4. 효율성 vs 창의성
   - AI는 아이디어 스케칭 도구
   - 최종 디자인 의사결정은 인간
```

---

## Spatial Design (Apple Vision Pro 영향)

### Apple visionOS 설계 원칙

```swift
// visionOS의 세 가지 차원

1. Window (2D)
   - 전통적 UI를 3D 공간에 배치
   - 테두리가 있는 직사각형 표면

2. Volume (3D)
   - 깊이가 있는 상호작용 객체
   - 사용자가 손으로 조작 가능

3. Space (몰입형)
   - 완전 3D 환경
   - 사용자의 움직임 추적
```

### Spatial UI 구현 예시

```swift
// SwiftUI + RealityKit
struct SpatialButton: View {
  @State private var isPressed = false

  var body: some View {
    Button {
      isPressed.toggle()
    } label: {
      // 깊이 표현: 1. Z축 offset
      ZStack {
        // Back layer (더 어두움)
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.blue.opacity(0.3))
          .offset(z: -5)

        // Front layer
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.blue)
          .offset(z: isPressed ? 0 : 10)

        // Text
        Text("Tap me")
          .foregroundColor(.white)
      }
      .frame(width: 120, height: 60)
    }
  }
}

// 손 제스처 인식
struct GestureHandling {
  // Direct touch
  @GestureState var isTouching = false

  // Pinch gesture
  var pinchGesture: some Gesture {
    MagnificationGesture()
      .onChanged { value in
        scale = value
      }
  }
}
```

### Responsive Design for Spatial Computing

```
기존 2D 규칙을 3D로 확장:

| 2D 개념 | 3D 공간 적응 |
|--------|------------|
| 여백(margin) | 공간상 거리(z-axis) |
| 계층(z-index) | 깊이(depth) |
| 그림자(shadow) | 체적감(volume) |
| 호버(hover) | 응시(gaze) |
| 클릭(click) | 손 제스처 |

반응형 공간 설계:
- 근처 (0-1m): 매우 상세한 컨트롤
- 중간거리 (1-3m): 큰 제스처
- 원거리 (3m+): 제스처 인식 어려움
```

### XR 생태계 (Meta Quest, Samsung)

```
2024-2026 XR 전망:

Apple Vision Pro: 고가 (>$3500), 열성팬만
Meta Quest: 중가 (~$500), 게임/메타버스
Samsung XR: 추정 2026년, 스마트폰 연동

공통 설계 원칙:
- Hand tracking + eye tracking
- 공간 오디오 활용
- 손목 메뉴 (wrist menu)
- 공간 앵커 (spatial anchors)
```

---

## 디자인 리뷰 체크리스트

### 포괄적 검증 목록

**[ ] 기능성 (Functionality)**
- [ ] 모든 사용 사례가 디자인에 반영됨
- [ ] 에러 상태/빈 상태/로딩 상태 정의
- [ ] 폼 유효성 검사 피드백
- [ ] 시간 초과 처리 (timeout)

**[ ] 접근성 (Accessibility)**
- [ ] 색 대비: 본문 4.5:1, 큰 텍스트 3:1 (WCAG AA)
- [ ] 포커스 인디케이터 명확
- [ ] 스크린 리더: 모든 버튼 aria-label
- [ ] 키보드 네비게이션 가능
- [ ] 색상만으로 정보 전달 금지

**[ ] 반응형 (Responsive)**
- [ ] 모바일 (375px), 태블릿 (768px), 데스크톱 (1440px) 테스트
- [ ] 터치 타겟 최소 44x44px
- [ ] 텍스트 확대(200%) 시 레이아웃 파괴 금지
- [ ] 수평 스크롤 금지 (모바일)

**[ ] 성능 (Performance)**
- [ ] 큰 이미지는 WebP + 반응형
- [ ] 애니메이션: 60fps 유지
- [ ] First Contentful Paint < 1.8s
- [ ] Cumulative Layout Shift < 0.1

**[ ] 일관성 (Consistency)**
- [ ] 디자인 시스템 토큰 사용 (색, 타이포, 간격)
- [ ] 컴포넌트 이름 규칙 준수
- [ ] 아이콘 스타일 통일
- [ ] 마이크로인터랙션 패턴 재사용

**[ ] 보안 (Security)**
- [ ] 민감한 정보 마스킹 (예: 신용카드)
- [ ] 입력 유효성 검사 피드백
- [ ] 2FA 흐름 명확
- [ ] 로그아웃 확인 필수

**[ ] 국제화 (Localization)**
- [ ] RTL 언어 (아랍어, 히브리어) 테스트
- [ ] 한글/중국어 긴 텍스트 공간
- [ ] 날짜/시간 형식 지역 맞춤
- [ ] 아이콘 문화적 민감성

---

## 바이브 코딩(Vibe Coding) 가이드

### 디자인 의도를 코드에 담기

**"Vibe"란?** 디자인의 감정적, 미적 의도를 코드로 표현하는 기술.

### 1. 색상 바이브

```css
/* 차가운 바이브 (Cool & Minimal) */
:root {
  --primary: #0066FF;      /* 진한 청색 */
  --secondary: #00D9FF;    /* 밝은 시안 */
  --background: #F0F4F8;   /* 차가운 회색 */
  --text: #1A202C;         /* 다크 그레이 */
}

/* 따뜻한 바이브 (Warm & Playful) */
:root {
  --primary: #FF6B35;      /* 주황색 */
  --secondary: #FFD93D;    /* 노란색 */
  --background: #FFF8F0;   /* 따뜻한 베이지 */
  --text: #2D1B00;         /* 다크 브라운 */
}

/* 럭셔리 바이브 (Luxury) */
:root {
  --primary: #D4AF37;      /* 골드 */
  --secondary: #2D2D2D;    /* 차콜 */
  --background: #FAFAF8;   /* 약간 따뜻한 화이트 */
  --text: #1A1A1A;         /* 거의 검정 */
}
```

### 2. 타이포그래피 바이브

```css
/* 세리프 + 넉넉한 간격 = 럭셔리/교양있음 */
.luxury-heading {
  font-family: 'Playfair Display', serif;
  font-weight: 700;
  letter-spacing: 0.05em;
  line-height: 1.2;
}

/* Sans-serif + 촘촘한 간격 = 모던/기술적 */
.modern-heading {
  font-family: 'Inter', sans-serif;
  font-weight: 600;
  letter-spacing: -0.02em;
  line-height: 1.3;
}

/* Variable font로 무게 변화 = 역동적 */
.dynamic-text {
  font-family: 'Inter Variable', sans-serif;
  font-weight: 500;
  transition: font-weight 0.3s ease;
}

.dynamic-text:hover {
  font-weight: 700;  /* 무게 변화로 강조 */
}
```

### 3. 공간(Space) 바이브

```css
/* 밀집형 바이브 (Cozy) */
.cozy-layout {
  --gap: 12px;
  --padding: 16px;
  --border-radius: 16px;  /* 부드러운 모서리 */
}

/* 통풍형 바이브 (Airy) */
.airy-layout {
  --gap: 32px;
  --padding: 40px;
  --border-radius: 8px;   /* 날카로운 모서리 */
}

/* 구조적 바이브 (Rigorous) */
.rigorous-layout {
  --gap: 16px;
  --padding: 24px;
  --border-radius: 0;     /* 각진 모서리 */
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
}
```

### 4. 모션 바이브

```javascript
// 빠른 바이브 (Energetic, 게임/스포츠)
const energeticEase = 'cubic-bezier(0.34, 1.56, 0.64, 1)';
gsap.to(element, {
  duration: 0.3,
  ease: energeticEase,
  scale: 1.1,
  rotation: 5
});

// 부드러운 바이브 (Gentle, 명상/헬스)
const gentleEase = 'cubic-bezier(0.25, 0.46, 0.45, 0.94)';
gsap.to(element, {
  duration: 1.2,
  ease: gentleEase,
  opacity: 1,
  y: 0
});

// 기계적 바이브 (Industrial, B2B)
const mechanicalEase = 'cubic-bezier(0.77, 0, 0.175, 1)';
gsap.to(element, {
  duration: 0.6,
  ease: mechanicalEase,
  x: 100,
  y: -50
});
```

### 5. 그래디언트 바이브

```css
/* 선명한 바이브 */
.vibrant-gradient {
  background: linear-gradient(135deg, #FF6B9D 0%, #FFC948 100%);
  filter: saturate(1.2) brightness(1.05);
}

/* 미니멀 바이브 */
.minimal-gradient {
  background: linear-gradient(135deg, #E8E8E8 0%, #F5F5F5 100%);
  filter: saturate(0.5) brightness(0.98);
}

/* 3D 깊이 바이브 */
.depth-gradient {
  background: linear-gradient(180deg,
    rgba(255,255,255,0.1) 0%,
    rgba(0,0,0,0.2) 100%);
  backdrop-filter: blur(8px);
}
```

### 6. 상호작용 바이브

```typescript
// 반응성 높은 바이브
const highReactivity = {
  hover: {
    scale: 1.1,
    duration: 0.15,
    shadow: '0 10px 30px rgba(0,0,0,0.2)'
  },
  click: {
    scale: 0.95,
    duration: 0.1
  }
};

// 신중한 바이브
const thoughtfulReactivity = {
  hover: {
    scale: 1.02,
    duration: 0.4,
    brightness: 1.05
  },
  click: {
    scale: 1,
    duration: 0.3,
    feedback: 'haptic-light'
  }
};
```

---

## 참고 자료

### 필독서 & 리소스

| 제목 | 저자 | 핵심 내용 |
|------|------|----------|
| **The Design of Everyday Things** | Don Norman | 사용성 원칙 |
| **Thinking with Type** | Ellen Lupton | 타이포그래피 |
| **Design System Handbook** | Figma | 설계 시스템 |
| **Ethical Design** | Yelena Gluzberg | AI 윤리 |

### 도구 스택 추천 (2024)

```
디자인 단계:
├─ Figma (협업)
├─ Framer (프로토타입)
└─ Storybook (컴포넌트 문서)

QA 자동화:
├─ Design Lint (Figma 플러그인)
├─ Chromatic (Visual Testing)
├─ Percy (Screenshot Comparison)
└─ Axe DevTools (Accessibility)

개발 연계:
├─ Figma Dev Mode
├─ Design Tokens Studio
├─ Storybook Addon Controls
└─ Custom Linter Script

모니터링:
├─ Lighthouse CI
├─ WebPageTest
└─ Sentry (Error Tracking)
```

### 커뮤니티

- **Figma Community**: figma.com/community
- **Design Systems Slack**: designsystems.community
- **Smashing Magazine**: smashingmagazine.com
- **A List Apart**: alistapart.com

---

**문서 버전**: 1.0
**마지막 업데이트**: 2026년 2월
**대상 독자**: 15년 경력 이상의 UI/UX 전문가
**키워드**: Design QA, Visual Regression, Design Tokens, visionOS, AI Design, Accessibility, Design Systems
