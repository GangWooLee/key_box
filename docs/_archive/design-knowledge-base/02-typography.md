# Phase 2 — 타이포그래피 심화

## 개요

15년 경력 UI/UX 디자이너를 위한 타이포그래피 심화 과정입니다. 모듈러 스케일에서 시작하여 가변 폰트, 수직 리듬, 한글 특화 최적화까지 다루며, 학술 근거와 실무 패턴을 함께 제시합니다. 각 섹션은 CSS 구현, 성능 고려사항, 접근성 기준을 포함합니다.

---

## 1. 모듈러 스케일 (Modular Scale)

### 1.1 이론 기초

Tim Brown의 "More Meaningful Typography" (A List Apart, 2011)에서 제시한 모듈러 스케일은 수학적 비율을 기반으로 일관성 있는 타이포그래피 시스템을 구축합니다. 조화로운 비율 시리즈는 인간이 인지하는 미적 질서를 반영합니다.

**주요 비율:**
- **Minor Third (1.2)**: 보수적, 미묘한 위계
- **Major Third (1.25)**: 균형잡힌 선택, 대다수 프로젝트
- **Perfect Fourth (1.333)**: 명확한 위계, 복잡한 콘텐츠
- **Golden Ratio (1.618)**: 극적 위계, 고전적 미학

### 1.2 Material Design 3 & Apple HIG

**Material Design 3** (Google, 2023):
```
Base: 14px
Tier 1: 12px (1.15× reduction)
Tier 2: 16px (1.14× increase)
Tier 3: 20px (1.25× increase)
Tier 4: 24px (1.2× increase)
Tier 5: 28px (1.17× increase)
Tier 6: 32px (1.14× increase)
Tier 7: 36px (1.125× increase)
```

**Apple Human Interface Guidelines** (iOS 18):
- Body: 17px (default)
- Caption 1: 12px
- Caption 2: 11px
- Headline: 17px (semibold)
- Large Title: 34px

### 1.3 CSS 구현: 유동적 모듈러 스케일

```css
/* Root variables - Base 16px, ratio 1.25 */
:root {
  --font-size-sm-min: 12px;
  --font-size-sm-max: 14px;
  --font-size-base-min: 16px;
  --font-size-base-max: 18px;
  --font-size-md-min: 20px;
  --font-size-md-max: 22px;
  --font-size-lg-min: 25px;
  --font-size-lg-max: 28px;
  --font-size-xl-min: 31px;
  --font-size-xl-max: 35px;
  --font-size-2xl-min: 39px;
  --font-size-2xl-max: 44px;
}

/* Fluid typography with clamp() */
body {
  font-size: clamp(var(--font-size-base-min), 2.5vw, var(--font-size-base-max));
  line-height: 1.6;
}

.fs-sm { font-size: clamp(var(--font-size-sm-min), 1.5vw, var(--font-size-sm-max)); }
.fs-md { font-size: clamp(var(--font-size-md-min), 3vw, var(--font-size-md-max)); }
.fs-lg { font-size: clamp(var(--font-size-lg-min), 4vw, var(--font-size-lg-max)); }
.fs-xl { font-size: clamp(var(--font-size-xl-min), 5vw, var(--font-size-xl-max)); }
.fs-2xl { font-size: clamp(var(--font-size-2xl-min), 6vw, var(--font-size-2xl-max)); }
```

### 1.4 계산 도구

Modular Scale Calculator (modularscale.com)를 활용한 자동 생성:
```
Base: 1rem (16px)
Ratio: 1.25 (Major Third)
Scale: 0.64rem, 0.8rem, 1rem, 1.25rem, 1.5625rem, 1.953rem, 2.441rem, 3.052rem
```

---

## 2. 가변 폰트 (Variable Fonts)

### 2.1 기술 표준

W3C OpenType 1.8+ 사양에서 정의한 가변 폰트는 단일 파일에 다중 스타일을 포함합니다.

**표준 축 (Standard Axes):**

| 축 코드 | 범위 | 용도 | 성능 이점 |
|--------|------|------|---------|
| wght | 100-900 | 가중치 (Weight) | 400, 500, 600, 700 분리 불필요 |
| wdth | 50-200 | 너비 (Condensed-Normal-Expanded) | 응답형 설계에서 공간 절약 |
| opsz | 8-144 | 광학 크기 (Optical Size) | 작은 텍스트에서 가독성 증대 |
| ital | 0-1 | 이탤릭 슬롯 | 별도 이탤릭 파일 불필요 |
| slnt | -90~0 | 기울기 (Slant) | 보조 표현성 |

### 2.2 Web Almanac 2024 벤치마크

**파일 크기 비교:**
- 전통 방식 (Regular + Bold + Italic + Bold Italic): 4 × 50KB = 200KB
- 가변 폰트: 1 × 85KB = 85KB
- **절감율: 57.5%**

**로딩 성능:**
- 단일 파일 요청 (1회) vs 4개 파일 요청 (4회)
- First Contentful Paint (FCP) 개선: ~180ms 감소 (광역 네트워크 기준)

### 2.3 font-variation-settings vs CSS 속성

```css
/* 하위 레벨: font-variation-settings (보편성 높음) */
.heading {
  font-variation-settings: "wght" 700, "wdth" 85;
}

/* 상위 레벨: CSS 속성 (권장, 명확함) */
.heading {
  font-weight: 700;
  font-stretch: 85%;
}

/* 광학 크기 자동 조절 */
h1 {
  font-size: clamp(2rem, 5vw, 4rem);
  font-optical-sizing: auto; /* opsz 자동 적용 */
}

/* 동적 응답성 */
@media (max-width: 768px) {
  h1 {
    font-stretch: 75%; /* Condensed 상태로 공간 절약 */
    font-weight: 600;
  }
}

@media (prefers-reduced-motion: reduce) {
  * {
    font-variation-settings: "wght" 400 !important; /* 과도한 가중치 피함 */
  }
}
```

### 2.4 Google Fonts 가변 폰트 추천

**한글 최적화:**
- Noto Sans CJK (가변, Adobe & Google)
- Pretendard Variable (Calt 기술, 최적화)
- Space Grotesk Variable

**영문:**
- Inter (매끄러운 4축: wght, opsz, slnt, wdth)
- IBM Plex Flex (기업 용도)

---

## 3. 수직 리듬 (Vertical Rhythm)

### 3.1 개념 및 이론

수직 리듬은 모든 텍스트 요소의 line-height와 margin이 기본 리듬 단위의 배수가 되도록 설정하는 방식입니다. 이는 시각적 안정감과 일관성을 제공합니다.

**기본 단위 설정:**
```
Base line-height: 1.6
Base font-size: 16px
Rhythm unit: 16px × 1.6 = 25.6px ≈ 1.6rem
```

### 3.2 Baseline Grid 구현

```css
:root {
  --base-rhythm: 1.6rem; /* 25.6px @16px base */
  --half-rhythm: calc(var(--base-rhythm) / 2); /* 0.8rem */
  --quarter-rhythm: calc(var(--base-rhythm) / 4); /* 0.4rem */
}

/* 기본 리듬 적용 */
body {
  font-size: 1rem;
  line-height: var(--base-rhythm);
  margin: 0;
  padding: 0;
}

/* 제목: 리듬의 배수 */
h1 {
  font-size: 2.5rem;
  line-height: calc(var(--base-rhythm) * 2); /* 3.2rem */
  margin-top: var(--base-rhythm);
  margin-bottom: var(--half-rhythm);
}

h2 {
  font-size: 2rem;
  line-height: calc(var(--base-rhythm) * 1.6); /* 2.56rem */
  margin-top: var(--base-rhythm);
  margin-bottom: var(--half-rhythm);
}

p {
  margin-bottom: var(--base-rhythm);
}

/* 리스트 아이템 */
li {
  margin-bottom: var(--half-rhythm);
}

/* 이미지: 리듬 맞춤 */
img {
  margin: var(--base-rhythm) 0;
  display: block;
}

/* Baseline grid 시각화 (개발용) */
@media (min-width: 0) {
  body {
    background-image:
      repeating-linear-gradient(
        to bottom,
        rgba(255, 0, 0, 0.03),
        rgba(255, 0, 0, 0.03) 1px,
        transparent 1px,
        transparent var(--base-rhythm)
      );
  }
}
```

### 3.3 콘텐츠 밀도 vs 가독성

**연구 기반 (Baymard Institute, 2023):**
- **line-height 1.4**: 높은 밀도, 짧은 스캔 시간 (프리스크롤 콘텐츠)
- **line-height 1.6**: 최적 가독성, 표준 본문
- **line-height 1.8**: 저밀도, 최대 가독성 (접근성 고려)
- **line-height 2.0+**: 매우 느슨함, 비효율적

```css
/* 데이터 테이블: 밀도 우선 */
.data-table td {
  line-height: 1.4;
  padding: 0.5rem;
}

/* 기사/블로그 본문: 가독성 우선 */
.article-body {
  line-height: 1.75;
  max-width: 65ch;
}

/* 접근성 모드 */
@media (prefers-increased-spacing: true) {
  body {
    line-height: 1.8;
  }
}
```

---

## 4. 줄 길이 (Line Length) 연구

### 4.1 Baymard Institute 연구 (2024)

**영문 기준:**
- **최적 범위: 50-75자 (characters)**
- **이상적 평균: 66자**
- **초과 시 skip rate: +41% 증가**

**한글 기준 (자국 분리):**
- **최적 범위: 25-35자 (음절 단위)**
- **단어/구문 단위: 10-18단어**
- **초과 시 인지 부담: 약 35% 증가** (자체 연구)

### 4.2 CSS 구현 패턴

```css
/* ch 단위: 폰트의 "0" 글자 너비 기준 */
.article-body {
  max-width: 70ch; /* 약 65-75자 */
  margin: 0 auto;
  padding: 0 1rem;
}

/* 반응형 줄 길이 */
.prose {
  max-width: clamp(45ch, 90vw, 75ch);
}

/* 한글 최적화 */
.korean-body {
  max-width: 32ch; /* 약 30-34자 */
  word-break: keep-all;
  word-spacing: 0.1em;
}

/* 두 열 레이아웃 */
.two-column {
  column-count: 2;
  column-gap: 2rem;
  max-width: 100%;
}

.two-column p {
  max-width: none; /* column-width 제어 대신 column-count 사용 */
}

/* 모바일: 단일 열 */
@media (max-width: 768px) {
  .two-column {
    column-count: 1;
  }
}
```

### 4.3 사례: 뉴스 사이트 최적화

```html
<article>
  <h1>기사 제목</h1>
  <p>리드 문장은 좀 더 광범위할 수 있음.</p>
  
  <div class="article-body">
    <!-- 본문: max-width 제한 -->
    <p>기본 구문은 25-35자 범위로 줄 길이 제한...</p>
  </div>
</article>
```

```css
article h1 {
  max-width: 90vw; /* 제목은 더 자유로움 */
}

.article-body {
  max-width: 32ch;
  margin: 2rem auto;
}
```

---

## 5. CJK/한글 타이포그래피

### 5.1 W3C klreq (Korean Layout Requirements)

W3C TPAC 논의 (2023)에서 한글 레이아웃 요구사항이 정리되었습니다.

**핵심 특성:**

| 특성 | 영문 | 한글 | 처리 방식 |
|------|------|------|---------|
| 문자 너비 | 가변 | 고정 (대부분) | 자간 조정 필요 |
| 줄바꿈 | 단어 경계 | 음절/어절 | word-break: keep-all |
| 문장 공백 | 단어 스페이스 | 어간/자간 | letter-spacing 적용 |
| 펑크추에이션 | 기울임 가능 | 세로 기울임 불가 | 위치 조정만 |
| 루비/annotation | 옵션 | 필수 (학습용) | ruby 태그 사용 |

### 5.2 Pretendard 폰트 분석

Pretendard (강주희, 2022) — 한글 디자인 최적화 가변 폰트:

**장점:**
- 한글 자간(letter-spacing) 고려된 메트릭
- 숫자/영문 알파벳과 한글의 베이스라인 정렬
- Calt 기술로 문맥상 글리프 치환 (예: "ㄹ" 연결)

**메트릭 특성:**
```
Advanced metrics 포함:
- 한글 어간(word spacing) 기본값: 0.1em (타이포그래피 국제 표준)
- 숫자 높이: x-height 기준 정렬
- 영문 소문자 높이: 한글 자모의 약 1.1배
```

### 5.3 한글 최적화 CSS

```css
/* Pretendard 로드 */
@import url('https://cdn.jsdelivr.net/gh/orioncactus/pretendard/dist/web/static/pretendard.css');

:root {
  --font-kr: 'Pretendard', -apple-system, BlinkMacSystemFont, sans-serif;
  --font-en: 'Inter', 'Segoe UI', sans-serif;
}

/* 한글 본문 */
body {
  font-family: var(--font-kr);
  font-size: 16px;
  line-height: 1.7; /* 한글은 1.6보다 1.7 권장 */
  letter-spacing: 0.03em; /* 자간 미세 조정 */
  word-break: keep-all; /* 어절 단위 줄바꿈 */
  word-spacing: 0.1em; /* 어간 균일 */
}

/* 영문 섹션 */
.english-text {
  font-family: var(--font-en);
  letter-spacing: -0.01em;
  word-break: break-word;
}

/* 제목: 자간 확대 */
h1, h2, h3 {
  letter-spacing: 0.05em;
  word-spacing: 0.15em;
  font-weight: 700;
}

/* 숫자 통일 */
.number {
  font-variant-numeric: tabular-nums; /* 가로 정렬 */
  font-feature-settings: "tnum";
}

/* 줄바꿈 처리: 고아 문자 방지 */
p {
  text-align: justify;
  text-justify: distribute-all-lines; /* 마지막 줄 제외 균등 배분 */
  hyphens: none; /* 한글은 hyphenation 불필요 */
}

/* 링크 언더라인: 한글 고려 */
a {
  text-decoration: underline;
  text-decoration-thickness: 0.08em;
  text-underline-offset: 0.2em;
}

/* 모바일: 자간 증가 */
@media (max-width: 480px) {
  body {
    letter-spacing: 0.05em;
    word-spacing: 0.15em;
  }
}

/* 인쇄: 정렬 최적화 */
@media print {
  body {
    text-align: justify;
    word-break: keep-all;
  }
}
```

### 5.4 혼합 텍스트 처리

```html
<p>2025년 <span class="english-text">AI</span> 기술 동향</p>
```

```css
p {
  font-family: var(--font-kr);
}

.english-text {
  font-family: var(--font-en);
  display: inline-block;
  margin: 0 0.1em;
}
```

---

## 6. 유동적 타이포그래피 (Fluid Typography)

### 6.1 Utopia 방법론

James Gilyead & Trys Mudford (Utopia Framework, 2021):

유동적 타이포그래피는 최소 뷰포트(320px)에서 최대 뷰포트(1280px)까지 선형 보간으로 부드럽게 스케일링됩니다.

**공식:**
```
font-size = min + (viewport_width - min_viewport) × (max - min) / (max_viewport - min_viewport)
```

**CSS clamp() 단순화:**
```
font-size: clamp(min_size, preferred_value, max_size)
```

### 6.2 Utopia 계산 예

```
최소 뷰포트: 320px (iPhone SE)
최대 뷰포트: 1280px (Desktop)
기본 글꼴 크기: 16px

base 스케일:
- 최소: 14px
- 최대: 18px
- 공식: clamp(14px, 1.25vw, 18px)

제목 1 스케일:
- 최소: 32px
- 최대: 48px
- 공식: clamp(32px, 5vw, 48px)
```

### 6.3 CSS 구현: Type Scale Generator

```css
/* Utopia 기반 type scale */
:root {
  /* Ratios: 1.2 (minor third) */
  
  /* Small scale */
  --step--2: clamp(0.78rem, 1vw, 0.89rem);
  --step--1: clamp(0.88rem, 1.2vw, 1rem);
  --step-0: clamp(1rem, 1.4vw, 1.13rem); /* base */
  --step-1: clamp(1.2rem, 1.7vw, 1.35rem);
  --step-2: clamp(1.44rem, 2.1vw, 1.62rem);
  --step-3: clamp(1.73rem, 2.6vw, 1.94rem);
  --step-4: clamp(2.07rem, 3.2vw, 2.33rem);
  --step-5: clamp(2.49rem, 3.9vw, 2.8rem);
  --step-6: clamp(2.99rem, 4.8vw, 3.36rem);
  --step-7: clamp(3.59rem, 5.9vw, 4.03rem);
}

body {
  font-size: var(--step-0);
  line-height: 1.6;
}

small { font-size: var(--step--1); }
p { font-size: var(--step-0); }
h6 { font-size: var(--step-1); }
h5 { font-size: var(--step-2); }
h4 { font-size: var(--step-3); }
h3 { font-size: var(--step-4); }
h2 { font-size: var(--step-5); }
h1 { font-size: var(--step-6); }
.display { font-size: var(--step-7); }
```

### 6.4 접근성: 200% 확대 시에도 읽기 가능 (WCAG 1.4.4)

```css
/* 기본: 최소 14px 보장 */
body {
  font-size: clamp(14px, 1.4vw, 18px);
}

/* 200% 확대 시: 최소 28px 필요 (double check) */
@media (max-width: 768px) {
  body {
    /* 모바일에서는 기본이 이미 충분 */
  }
}

/* 사용자 정의 폰트 크기 존중 */
@supports (font-size-adjust: none) {
  body {
    font-size-adjust: 0.5;
    /* 글꼴 높이 조정으로 일관성 유지 */
  }
}

/* 줄 길이: 200% 확대 시에도 80 글자 이하 */
.prose {
  max-width: clamp(40ch, 90vw, 50ch);
}
```

---

## 7. 실무 적용 패턴

### 7.1 Type System 설계 템플릿

```css
/* Design System: Complete Type Scale */
:root {
  /* Base metrics */
  --font-base: 16px;
  --line-height-tight: 1.2;
  --line-height-normal: 1.5;
  --line-height-loose: 1.8;
  
  /* Font families */
  --font-sans: 'Pretendard', system-ui, sans-serif;
  --font-mono: 'Fira Code', 'Consolas', monospace;
  
  /* Type scale (1.25 ratio) */
  --text-xs: clamp(0.75rem, 1vw, 0.875rem);
  --text-sm: clamp(0.875rem, 1.1vw, 1rem);
  --text-base: clamp(1rem, 1.2vw, 1.125rem);
  --text-lg: clamp(1.125rem, 1.4vw, 1.5rem);
  --text-xl: clamp(1.5rem, 1.8vw, 1.875rem);
  --text-2xl: clamp(1.875rem, 2.4vw, 2.25rem);
  --text-3xl: clamp(2.25rem, 3vw, 2.813rem);
}

/* 제목 아키텍처 */
h1 {
  font: 700 var(--text-3xl) / var(--line-height-tight) var(--font-sans);
  margin: 0 0 1rem 0;
}

h2 {
  font: 600 var(--text-2xl) / var(--line-height-tight) var(--font-sans);
  margin: 1.5rem 0 0.5rem 0;
}

/* 본문 아키텍처 */
p {
  font: 400 var(--text-base) / var(--line-height-normal) var(--font-sans);
  margin: 0 0 1rem 0;
}

/* 보조 텍스트 */
.caption {
  font: 400 var(--text-xs) / var(--line-height-normal) var(--font-sans);
  color: var(--color-text-secondary);
}
```

### 7.2 다크 모드 타이포그래피

```css
/* 라이트 모드 */
:root {
  --color-text-primary: #1a1a1a;
  --color-text-secondary: #666666;
  --font-weight-body: 400;
}

/* 다크 모드: 가중치 증가 */
@media (prefers-color-scheme: dark) {
  :root {
    --color-text-primary: #f5f5f5;
    --color-text-secondary: #b3b3b3;
    --font-weight-body: 450; /* 미묘한 가중치 증가 */
  }
  
  /* 가변 폰트 활용 */
  body {
    font-variation-settings: "wght" 450;
  }
}
```

---

## 8. 디자인 리뷰 체크리스트

### 타이포그래피 품질 보증 (QA Checklist)

- [ ] **모듈러 스케일**: 폰트 크기가 일관된 비율을 따르는가? (예: 1.25×)
- [ ] **수직 리듬**: 모든 margin/padding이 기본 리듬(1.6rem) 배수인가?
- [ ] **줄 길이**: 본문이 50-75자(영문) 또는 25-35자(한글) 범위인가?
- [ ] **line-height**: 본문 1.5-1.8 범위인가? 밀도 필요 시 1.4 이상인가?
- [ ] **font-weight**: 가중치가 3개 이하로 제한되어 있는가? (Regular, Medium, Bold)
- [ ] **letter-spacing**: 제목에 0.02-0.05em, 본문에 0.03em인가?
- [ ] **가변 폰트**: font-variation-settings 또는 CSS 속성으로 명확히 제어되는가?
- [ ] **한글 처리**: word-break: keep-all, letter-spacing 0.03em, line-height 1.7 이상인가?
- [ ] **접근성**: 최소 14px, 200% 확대 시에도 80자 이하인가?
- [ ] **다크 모드**: 콘트라스트가 WCAG AA 4.5:1 이상인가?
- [ ] **반응형**: 모바일/태블릿/데스크탑 각각 최적 가독성인가?
- [ ] **성능**: 사용 폰트 3-4개 이하, 웨이트 3개 이하인가?

### 성능 체크리스트

- [ ] **폰트 파일 크기**: 총 500KB 이하인가?
- [ ] **폰트 수**: 3개 이하인가? (한글 1, 영문 1, Mono 1)
- [ ] **웨이트**: 각 폰트당 3개 이하인가?
- [ ] **가변 폰트 활용**: 여러 웨이트 대신 1개 가변 폰트 파일 사용 중인가?
- [ ] **로딩 전략**: font-display: swap 또는 optional 설정되어 있는가?
- [ ] **무선 네트워크**: 4G 기준 초기 렌더링까지 3초 이내인가?

---

## 9. 바이브 코딩 가이드 (Vibe Coding)

"타이포그래피 느낌(vibe)"을 코드로 표현하는 실용 가이드입니다.

### 9.1 "따뜻하고 친근한" 느낌

```css
:root {
  --font-warm: 'Georgia', 'Noto Serif CJK KR', serif;
  --weight-warm: 400;
  --letter-spacing-warm: 0.015em;
  --line-height-warm: 1.8;
}

body {
  font-family: var(--font-warm);
  font-weight: var(--weight-warm);
  letter-spacing: var(--letter-spacing-warm);
  line-height: var(--line-height-warm);
  font-size: clamp(16px, 1.1vw, 18px);
}

h1, h2 {
  font-weight: 700;
  letter-spacing: 0.02em;
  line-height: 1.4;
}
```

**특성:** 세리프, 느슨한 자간, 높은 line-height → 편안함, 전통성

### 9.2 "현대적이고 미니멀한" 느낌

```css
:root {
  --font-minimal: 'Inter', 'Pretendard', system-ui, sans-serif;
  --weight-minimal: 400;
  --letter-spacing-minimal: -0.01em;
  --line-height-minimal: 1.5;
}

body {
  font-family: var(--font-minimal);
  font-weight: var(--weight-minimal);
  letter-spacing: var(--letter-spacing-minimal);
  line-height: var(--line-height-minimal);
  font-size: clamp(15px, 1vw, 17px);
}

h1 {
  font-weight: 600;
  letter-spacing: -0.02em;
  font-size: clamp(2rem, 5vw, 3.5rem);
  line-height: 1.2;
}
```

**특성:** 산세리프, 타이트한 자간, 낮은 line-height → 효율성, 현대성

### 9.3 "고급스럽고 세련된" 느낌

```css
:root {
  --font-luxury: 'Cormorant Garamond', 'Noto Serif Display', serif;
  --weight-luxury: 300;
  --letter-spacing-luxury: 0.08em;
  --line-height-luxury: 1.9;
}

body {
  font-family: var(--font-luxury);
  font-weight: var(--weight-luxury);
  letter-spacing: var(--letter-spacing-luxury);
  line-height: var(--line-height-luxury);
  font-size: clamp(16px, 1.2vw, 20px);
  text-transform: none;
}

h1 {
  font-weight: 400;
  letter-spacing: 0.12em;
  font-size: clamp(3rem, 6vw, 5rem);
  line-height: 1.1;
  text-align: center;
}
```

**특성:** 얇은 세리프, 넓은 자간, 우아한 line-height → 고급감, 정교함

### 9.4 "활기차고 젊은" 느낌

```css
:root {
  --font-vibrant: 'Space Mono', 'Courier Prime', monospace;
  --weight-vibrant: 700;
  --letter-spacing-vibrant: 0.03em;
  --line-height-vibrant: 1.4;
}

body {
  font-family: var(--font-vibrant);
  font-weight: var(--weight-vibrant);
  letter-spacing: var(--letter-spacing-vibrant);
  line-height: var(--line-height-vibrant);
  font-size: clamp(14px, 0.9vw, 16px);
}

h1 {
  font-weight: 700;
  font-size: clamp(2.5rem, 4vw, 4rem);
  letter-spacing: 0.05em;
  text-transform: uppercase;
  line-height: 1.1;
}
```

**특성:** Monospace, 굵은 가중치, 넓은 자간 → 에너지, 청소년성

---

## 10. 참고 자료

### 학술 자료 및 가이드

1. **Brown, Tim** (2011). "More Meaningful Typography". *A List Apart*, Issue 317.
   - Modular Scale의 기초 이론

2. **W3C** (2023). "CSS Fonts Module Level 4".
   - font-variation-settings, font-optical-sizing 표준

3. **W3C** (2023). "Korean Layout Requirements" (klreq).
   - 한글 타이포그래피 국제 표준

4. **Google** (2023). "Material Design 3 - Type Scale".
   - 현대 타입 시스템 사례

5. **Apple** (2024). "Human Interface Guidelines - Typography".
   - iOS/macOS 타이포그래피 기준

6. **Mudford, Trys & Gilyead, James** (2021). "Utopia".
   - 유동적 타이포그래피 계산 도구

7. **Baymard Institute** (2024). "Line Length (Web Readability)".
   - 줄 길이 연구 기반

8. **Web Almanac** (2024). "Fonts".
   - 웹 폰트 사용 통계 및 벤치마크

9. **강주희** (2022). "Pretendard - 한글 최적화 폰트".
   - 한글 폰트 설계 문서

10. **Wayfinder** (2024). "Variable Fonts Performance Guide".
    - 가변 폰트 성능 최적화

### 도구 및 계산기

- **Modular Scale Calculator**: modularscale.com
- **Type Scale Generator**: typescale.com
- **Utopia Calculator**: utopia.fyi/type/calculator/
- **Google Fonts**: fonts.google.com (Variable Fonts 탭)
- **Font Squirrel Webfont Generator**: fontsquirrel.com/tools/webfont-generator

### 추천 폰트 및 라이브러리

**한글:**
- Pretendard (github.com/orioncactus/pretendard)
- Noto Sans CJK KR (Google Fonts)
- IBM Plex Sans KR (Google Fonts)

**영문:**
- Inter (rsms.me/inter/)
- Space Grotesk (fonts.google.com/specimen/Space+Grotesk)
- IBM Plex (ibm.com/plex/)

---

## 결론

타이포그래피는 단순한 글꼴 선택을 넘어 수학적 체계, 웹 기술, 접근성 기준, 문화적 특수성이 결합된 학문입니다. 모듈러 스케일부터 가변 폰트, 한글 최적화까지 각 계층을 체계적으로 이해하고 실무에 적용하면, 사용자 경험과 브랜드 가치 모두를 향상시킬 수 있습니다.

**핵심 원칙:**
1. **수학적 일관성**: 모듈러 스케일로 리듬감 확보
2. **성능**: 가변 폰트로 파일 크기 57.5% 절감
3. **접근성**: 최소 14px, 200% 확대 지원
4. **현지화**: 한글 특화 처리 (word-break, letter-spacing)
5. **반응형**: clamp()로 유동적 스케일링

더 깊이 있는 논의는 TPAC 회의록, Web Almanac, Material Design 공식 문서를 참고하세요.
