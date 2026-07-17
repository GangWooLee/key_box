# Phase 9 — 접근성 & 포용적 디자인

## 개요

접근성(Accessibility, A11y)과 포용적 디자인(Inclusive Design)은 더 이상 선택사항이 아닌 필수 요소입니다. 전체 사용자의 15-20%가 영구적 장애를 가지고 있으며, 모든 사용자가 일시적 장애(팔 부상, 시끄러운 환경)나 상황적 제약(햇빛 아래 보기, 한 손으로 조작)을 경험합니다.

WCAG 2.2 준수는 법적 요구사항이자 윤리적 책임입니다. 이 문서는 15년 경력의 UI/UX 전문가를 위해 WCAG 2.2 AA 레벨을 중심으로, 실무 적용 가능한 전략과 코드 패턴을 제시합니다.

---

## 핵심 이론

### 1. WCAG 2.2의 4원칙

WCAG는 웹 콘텐츠 접근성 가이드(Web Content Accessibility Guidelines)로, 다음 4가지 원칙을 기반으로 합니다.

#### 1.1 인식가능(Perceivable)
사용자가 콘텐츠를 감지할 수 있어야 합니다.

**핵심 기준:**
- **1.4.3 대비비(Contrast)**: 텍스트와 배경의 색상 대비
  - **AA**: 일반 텍스트 4.5:1, 큰 텍스트(18px 이상) 3:1
  - **AAA**: 일반 텍스트 7:1, 큰 텍스트 4.5:1
- **1.4.11 비텍스트 대비(Non-Text Contrast)**: UI 요소, 그래프 요소 3:1 (AA)
- **1.1.1 논-텍스트 콘텐츠(Non-Text Content)**: 모든 이미지에 대체 텍스트 필요
- **1.4.5 이미지 텍스트(Images of Text)**: 텍스트는 이미지가 아닌 실제 텍스트로 제공

#### 1.2 운용가능(Operable)
사용자가 인터페이스를 조작할 수 있어야 합니다.

**핵심 기준:**
- **2.1.1 키보드(Keyboard)**: 모든 기능을 키보드로 조작 가능 (함정: click만 가능한 커스텀 요소)
- **2.1.2 키보드 함정 없음(No Keyboard Trap)**: 포커스가 요소에 갇히면 안 됨
- **2.4.7 포커스 표시(Focus Visible)**: 포커스 인디케이터가 항상 보여야 함 (:focus-visible, 최소 2px)
- **2.5.8 타겟 크기(Target Size)**: 모든 클릭 대상 24x24 CSS px 이상 (AA)
- **2.4.3 포커스 순서(Focus Order)**: Tab 순서가 논리적이고 예측 가능

#### 1.3 이해가능(Understandable)
사용자가 콘텐츠를 이해할 수 있어야 합니다.

**핵심 기준:**
- **3.1.1 페이지 언어(Page Language)**: `<html lang="ko">` 필수
- **3.2.1 포커스 시 변화 없음(On Focus)**: 포커스만으로 예상 밖의 문맥 변화 금지
- **3.3.1 오류 식별(Error Identification)**: 폼 오류를 텍스트로 명확히 표시
- **3.3.4 오류 예방(Error Prevention)**: 중요한 작업 전 확인, 되돌리기 가능
- **3.3.3 오류 제안(Error Suggestion)**: 특히 법적/금융 거래에서

#### 1.4 견고성(Robust)
다양한 보조기술과 호환되어야 합니다.

**핵심 기준:**
- **4.1.2 이름·역할·값(Name, Role, Value)**: 모든 UI 컴포넌트가 보조기술에 의해 올바르게 해석됨
- **4.1.3 상태 변경 알림(Status Messages)**: 동적 변경사항이 스크린 리더에서 감지됨

### 1.2 WCAG 레벨

- **A**: 최소 준수 수준
- **AA**: 권장 수준 (대부분의 산업 표준)
- **AAA**: 최고 준수 수준 (모든 요구사항 충족이 어려울 수 있음)

이 문서는 **WCAG 2.2 AA** 레벨을 기준으로 작성되었습니다.

---

## 실무 적용

### 2. 시맨틱 HTML & ARIA

#### 2.1 시맨틱 HTML이 최우선

**원칙: "No ARIA is better than bad ARIA"**

올바른 HTML 요소를 선택하는 것이 가장 중요합니다. ARIA는 보조 역할만 합니다.

```html
<!-- ❌ 나쁜 예: 시맨틱 없음 -->
<div onclick="navigate()" role="button" tabindex="0">클릭하세요</div>

<!-- ✅ 좋은 예: 시맨틱 HTML -->
<button>클릭하세요</button>
```

**시맨틱 요소별 역할:**

| 요소 | 역할 | 사용 시기 |
|------|------|---------|
| `<button>` | button | 액션, 폼 제출 |
| `<a>` | link | 네비게이션, 페이지 이동 |
| `<input type="checkbox">` | checkbox | 선택 옵션 |
| `<input type="radio">` | radio | 단일 선택 |
| `<select>` | combobox | 드롭다운 |
| `<nav>` | navigation | 주 네비게이션 |
| `<main>` | main | 페이지 주요 콘텐츠 |
| `<header>` | banner | 페이지 헤더 (페이지당 1개) |
| `<footer>` | contentinfo | 페이지 푸터 (페이지당 1개) |
| `<section>` | region | 제목이 있는 의미있는 섹션 |
| `<article>` | article | 독립적인 콘텐츠 |
| `<aside>` | complementary | 보조 콘텐츠 |

#### 2.2 Landmarks (랜드마크)

랜드마크는 페이지 구조를 스크린 리더 사용자에게 제공합니다.

```html
<body>
  <header role="banner">
    <nav role="navigation">
      <ul>
        <li><a href="/">홈</a></li>
        <li><a href="/about">소개</a></li>
      </ul>
    </nav>
  </header>

  <main role="main">
    <article>
      <h1>제목</h1>
      <p>콘텐츠</p>
    </article>
  </main>

  <aside role="complementary">
    <h2>관련 링크</h2>
  </aside>

  <footer role="contentinfo">
    <p>&copy; 2026 Company</p>
  </footer>
</body>
```

#### 2.3 ARIA 속성 사용 가이드

**aria-label**: 요소를 설명할 텍스트가 시각적으로 보이지 않을 때
```html
<button aria-label="메뉴 닫기">✕</button>
<button aria-label="검색"><span aria-hidden="true">🔍</span></button>
```

**aria-labelledby**: 기존 텍스트를 라벨로 참조
```html
<h2 id="dialog-title">사용자 정보 편집</h2>
<div role="dialog" aria-labelledby="dialog-title">
  <!-- 다이얼로그 콘텐츠 -->
</div>
```

**aria-describedby**: 추가 설명 제공
```html
<input type="password" aria-describedby="pwd-hint" />
<p id="pwd-hint">최소 8자, 대문자와 숫자 포함</p>
```

**aria-live**: 동적 콘텐츠 변화 알림
```html
<!-- polite: 읽는 도중 방해하지 않음 -->
<div aria-live="polite" aria-atomic="true">
  상품이 장바구니에 추가되었습니다.
</div>

<!-- assertive: 즉시 읽음 (오류 메시지) -->
<div aria-live="assertive" role="alert">
  필수 필드입니다.
</div>
```

**aria-hidden**: 스크린 리더에서 숨김 (시각적으로는 보임)
```html
<!-- 아이콘 또는 장식용 요소 -->
<span aria-hidden="true">→</span>
```

---

### 3. 키보드 접근성

#### 3.1 Tab 순서와 포커스 관리

```html
<!-- ✅ 자연스러운 탭 순서 -->
<form>
  <label for="name">이름</label>
  <input id="name" type="text" />

  <label for="email">이메일</label>
  <input id="email" type="email" />

  <button type="submit">제출</button>
</form>
```

```css
/* ✅ 포커스 인디케이터 (최소 2px, 명확한 대비) */
button:focus-visible {
  outline: 3px solid #0066cc;
  outline-offset: 2px;
}

/* ❌ 기본 outline 제거 후 대체물 없음 */
button:focus {
  outline: none; /* 위험! */
}
```

#### 3.2 Tabindex 사용 규칙

```html
<!-- ✅ 자연스러운 DOM 순서 (tabindex 불필요) -->
<button>첫 번째</button>
<button>두 번째</button>

<!-- ⚠️ 포커스 가능하게 만들기 (tabindex="0") -->
<div tabindex="0" role="button">클릭 가능한 div</div>

<!-- ⚠️ DOM 순서와 다른 탭 순서 (권장하지 않음) -->
<div tabindex="1">두 번째</div>
<div tabindex="0">첫 번째</div>

<!-- ❌ 음수 tabindex (포커스 불가, JS로만 접근) -->
<div tabindex="-1">키보드로 도달 불가</div>
```

#### 3.3 모달의 포커스 트랩

```javascript
// 모달 내 포커스를 모달 내에만 가두기
class Modal {
  constructor(element) {
    this.modal = element;
    this.firstFocusableElement = this.modal.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    this.lastFocusableElement = Array.from(this.modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')).pop();
  }

  handleKeydown(event) {
    if (event.key !== 'Tab') return;

    if (event.shiftKey) {
      // Shift+Tab: 첫 포커스 가능 요소로 가야 할 때
      if (document.activeElement === this.firstFocusableElement) {
        event.preventDefault();
        this.lastFocusableElement.focus();
      }
    } else {
      // Tab: 마지막 포커스 가능 요소에서
      if (document.activeElement === this.lastFocusableElement) {
        event.preventDefault();
        this.firstFocusableElement.focus();
      }
    }
  }

  open() {
    this.modal.setAttribute('aria-hidden', 'false');
    this.firstFocusableElement.focus();
    this.modal.addEventListener('keydown', this.handleKeydown.bind(this));
  }

  close() {
    this.modal.setAttribute('aria-hidden', 'true');
    this.modal.removeEventListener('keydown', this.handleKeydown.bind(this));
  }
}
```

#### 3.4 Skip Navigation Link

```html
<a href="#main-content" class="skip-link">
  메인 콘텐츠로 바로 가기
</a>

<header>...</header>

<main id="main-content">
  <!-- 주요 콘텐츠 -->
</main>
```

```css
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: #000;
  color: #fff;
  padding: 8px;
  text-decoration: none;
}

.skip-link:focus {
  top: 0;
}
```

---

### 4. 스크린 리더 호환성

#### 4.1 숨김 텍스트 패턴 (.sr-only)

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

```html
<!-- ✅ 시각적으로는 숨김, 스크린 리더로는 읽음 -->
<button>
  <span aria-hidden="true">→</span>
  <span class="sr-only">다음 페이지로 이동</span>
</button>
```

#### 4.2 이미지 대체 텍스트

```html
<!-- ✅ 의미있는 이미지 -->
<img src="product.jpg" alt="파란색 스니커즈, 앞에서 본 모습" />

<!-- ✅ 순전히 장식용 -->
<img src="divider.svg" alt="" aria-hidden="true" />

<!-- ⚠️ 복잡한 이미지 (차트, 인포그래픽) -->
<figure>
  <img src="chart.svg" alt="2024년 매출 트렌드 차트" />
  <figcaption>
    <p>Q1: 50만원, Q2: 75만원, Q3: 90만원, Q4: 120만원</p>
  </figcaption>
</figure>
```

#### 4.3 폼 라벨 연결

```html
<!-- ✅ 명시적 연결 -->
<label for="email">이메일</label>
<input id="email" type="email" required />

<!-- ⚠️ 암묵적 연결 (구체적이지 않음) -->
<label>
  이메일
  <input type="email" />
</label>

<!-- ⚠️ 라벨 없음 (장애인 사용자에게 혼란) -->
<input type="email" placeholder="이메일 입력" />
```

#### 4.4 동적 콘텐츠와 aria-live

```html
<!-- 검색 결과 업데이트 -->
<div aria-live="polite" aria-atomic="true" role="status">
  검색 중...
</div>

<script>
fetch('/api/search?q=' + query)
  .then(res => res.json())
  .then(data => {
    document.querySelector('[aria-live]').textContent =
      `${data.results.length}개 결과 찾음`;
  });
</script>
```

---

### 5. 색상 및 시각 접근성

#### 5.1 색상 대비 검증

```css
/* ✅ AA 레벨: 4.5:1 이상 (일반 텍스트) */
body {
  color: #1a1a1a;        /* 검은색에 가까움 */
  background-color: #fff; /* 흰색 */
  /* 대비비: 21:1 ✓ */
}

/* ✅ AA 레벨: 3:1 이상 (큰 텍스트 18px+) */
h1 {
  color: #0066cc;
  background-color: #fff;
  /* 대비비: 3.5:1 ✓ */
}

/* ❌ 불충족: 2.5:1 (AA 미달) */
.muted-text {
  color: #999;           /* 밝은 회색 */
  background-color: #fff;
  /* 대비비: 2.5:1 ✗ */
}
```

**색상 대비 검증 도구:**
- WebAIM Contrast Checker
- Colour Contrast Analyser
- axe DevTools

#### 5.2 색상만으로 정보 전달 금지

```html
<!-- ❌ 나쁜 예: 색상만으로 상태 표시 -->
<div style="background-color: red;">오류</div>
<div style="background-color: green;">성공</div>

<!-- ✅ 좋은 예: 색상 + 아이콘 + 텍스트 -->
<div style="background-color: red; padding: 10px;">
  <span aria-hidden="true">✗</span> 오류: 필수 필드입니다.
</div>
<div style="background-color: green; padding: 10px;">
  <span aria-hidden="true">✓</span> 성공: 저장되었습니다.
</div>
```

#### 5.3 고대비 모드 지원

```css
/* prefers-contrast 미디어 쿼리 */
@media (prefers-contrast: more) {
  body {
    color: #000;
    background-color: #fff;
  }

  button {
    border: 2px solid #000;
    font-weight: bold;
  }
}
```

#### 5.4 다크 모드 접근성

```css
@media (prefers-color-scheme: dark) {
  body {
    background-color: #1a1a1a;
    color: #e0e0e0;
  }

  /* 다크 모드에서도 대비비 유지 */
  a {
    color: #66b3ff; /* #0066cc보다 밝음 */
  }
}

/* 포커스도 다크 모드에서 보이도록 */
@media (prefers-color-scheme: dark) {
  button:focus-visible {
    outline-color: #66b3ff;
  }
}
```

---

### 6. 인지 접근성

#### 6.1 읽기 수준 최적화

```html
<!-- ❌ 복잡한 용어, 긴 문장 -->
<p>
  본 조항에서 명시된 조건들을 충족하지 못한 경우,
  귀 회사는 즉시 본 계약 관계를 종료할 수 있습니다.
</p>

<!-- ✅ 간단한 언어, 짧은 문장 -->
<p>조건을 지키지 않으면 계약이 끝날 수 있습니다.</p>

<!-- ✅ 복잡한 개념은 예시로 설명 -->
<p>
  개인정보 보호는 다음을 의미합니다:
  <ul>
    <li>당신의 이름과 주소를 공개하지 않음</li>
    <li>당신의 이메일을 다른 곳에 팔지 않음</li>
    <li>당신이 요청할 때 정보 삭제</li>
  </ul>
</p>
```

#### 6.2 명확한 에러 메시지

```html
<!-- ❌ 애매한 메시지 -->
<div role="alert">오류 발생</div>

<!-- ✅ 명확한 메시지: 무엇이 잘못되었는지, 어떻게 고칠 것인지 -->
<div role="alert">
  <strong>이메일 형식이 올바르지 않습니다.</strong>
  예: user@example.com
</div>

<!-- ✅ 필드 옆에도 메시지 표시 -->
<div>
  <label for="email">이메일 *</label>
  <input id="email" type="email" aria-describedby="email-error" />
  <span id="email-error" role="alert" style="color: red;">
    example@domain.com 형식으로 입력하세요.
  </span>
</div>
```

#### 6.3 예측 가능한 네비게이션

```html
<!-- ✅ 일관된 메뉴 구조 -->
<nav>
  <a href="/about">소개</a>
  <a href="/products">상품</a>
  <a href="/contact">연락처</a>
</nav>

<!-- ✅ 명확한 페이지 제목 -->
<h1>상품 목록</h1>

<!-- ✅ 현재 페이지 표시 (aria-current) -->
<nav>
  <a href="/about">소개</a>
  <a href="/products" aria-current="page">상품</a>
  <a href="/contact">연락처</a>
</nav>
```

#### 6.4 충분한 시간 제공

```html
<!-- ❌ 자동으로 사라지는 알림 (시간 부족) -->
<div class="toast">저장되었습니다.</div>

<!-- ✅ 사용자가 닫을 수 있는 알림 -->
<div role="status" aria-live="polite">
  저장되었습니다.
  <button aria-label="알림 닫기">✕</button>
</div>

<!-- ✅ 자동 로그아웃 전 경고 -->
<div role="alertdialog" aria-labelledby="timeout-title">
  <h2 id="timeout-title">세션이 곧 만료됩니다</h2>
  <p>5분 후 로그아웃됩니다.</p>
  <button>계속 사용</button>
</div>
```

---

### 7. 포용적 디자인 원칙

Microsoft가 제시한 3가지 포용적 디자인 원칙:

#### 7.1 Recognize Exclusion (배제를 인식하기)

디자이너와 개발자는 자신의 능력을 기준으로 설계하기 쉽습니다. 모든 사용자의 다양성을 인식하는 것이 첫 번째 단계입니다.

```
예시: 버튼 디자인
- 색깔로만 표시 → 색맹 사용자 제외
- 아이콘만 사용 → 인지 장애 사용자 제외
- 12px 이하 텍스트 → 저시력 사용자 제외
```

#### 7.2 Solve for One, Extend to Many (하나를 위해 해결하고 많은 사람에게 확장)

장애인을 위해 설계한 기능은 모두에게 도움이 됩니다.

```
예시: 음성 검색
- 설계 대상: 신체 장애로 타이핑 불가 사용자
- 확장 혜택: 운전 중, 손이 더러울 때, 소음 환경 → 모두 활용
```

#### 7.3 Learn from Diversity (다양성에서 배우기)

사용자 테스트에 다양한 배경의 사람들을 포함하세요.

```
테스트 그룹 구성:
- 다양한 연령 (16-75세)
- 다양한 장애 (시각, 청각, 신체, 인지)
- 다양한 기술 수준
- 다양한 장치 (데스크톱, 모바일, 태블릿)
```

#### 7.4 영구적·일시적·상황적 장애

```
예시: 한쪽 팔이 움직이지 않는 상황

영구적 장애:
→ 팔이 마비된 사용자

일시적 장애:
→ 팔 골절로 깁스한 사용자

상황적 제약:
→ 한 팔로 아기를 안고 있는 부모
→ 한 손으로 짐을 들고 있는 사람

해결책: 한 손으로 조작 가능한 UI
→ 모든 요소가 화면의 한쪽에 모아짐
→ 한 손으로 닿을 수 있는 영역 설계
```

---

## 디자인 리뷰 체크리스트

### 시각 설계

- [ ] 텍스트 대비비 최소 4.5:1 (AA) 검증됨
- [ ] 색상만으로 정보 전달하지 않음 (아이콘/텍스트 병행)
- [ ] 포커스 인디케이터 명확함 (최소 2px)
- [ ] 버튼/링크 최소 24x24 CSS px
- [ ] 이미지에 의미있는 alt 텍스트
- [ ] 고대비 모드 지원 검증

### 키보드·마우스

- [ ] 모든 기능을 키보드로 조작 가능
- [ ] Tab 순서가 논리적
- [ ] 포커스가 요소에 갇히지 않음
- [ ] Skip navigation link 포함
- [ ] :focus-visible 스타일 있음
- [ ] 마우스 호버 시 접근성 정보 손실 없음

### HTML & ARIA

- [ ] 시맨틱 HTML 사용 (div, span 남용 없음)
- [ ] button, a, input 등 적절한 요소 사용
- [ ] Landmarks 적절히 배치 (nav, main, footer)
- [ ] 필요한 경우만 ARIA 사용 (No ARIA if native)
- [ ] aria-label, aria-labelledby 올바르게 사용
- [ ] 동적 콘텐츠에 aria-live 사용
- [ ] role 오용 없음

### 스크린 리더

- [ ] 모든 페이지에 고유한 제목 (h1)
- [ ] 폼 필드가 라벨과 연결됨 (`<label for>`)
- [ ] 오류 메시지가 aria-live로 전달됨
- [ ] 숨김 텍스트 (.sr-only) 올바르게 사용
- [ ] aria-hidden 오용 없음
- [ ] 에러 또는 상태 변화 알림 (aria-live="polite")

### 인지 접근성

- [ ] 언어가 간단명료 (읽기 수준 적절)
- [ ] 오류 메시지가 구체적이고 해결 방법 포함
- [ ] 페이지 구조가 명확 (h1 → h2 → h3 순서)
- [ ] 예측 가능한 네비게이션
- [ ] 자동 새로고침/리다이렉트 없음
- [ ] 데이터 손실 전 확인 메시지

### 테스트

- [ ] Lighthouse 접근성 점수 90 이상
- [ ] axe DevTools로 자동 검사 통과
- [ ] 키보드만으로 모든 기능 테스트 완료
- [ ] 스크린 리더 (VoiceOver, NVDA) 테스트 완료
- [ ] 실제 장애인 사용자 테스트 참여

---

## 바이브코딩 가이드

### 접근성은 "나중에"의 문제가 아니다

```javascript
// ❌ "나중에 접근성을 붙이자"는 태도
// 이미 장애인을 배제한 상태에서 추가 작업 → 비효율적

// ✅ 처음부터 접근성을 고려한 설계
// 모든 사용자를 위해 설계 → 효율적, 스케일 가능
```

### "사용자"는 누구인가

```javascript
// ❌ "우리 사용자는 건강한 사람"이라는 가정
// 통계: 전체 인구의 15-20%가 영구적 장애 보유
//      모든 사람이 일시적/상황적 제약 경험

// ✅ 모든 사용자의 다양성을 포용
// 설계하는 기능이 최대한 많은 사람들이 사용하도록
```

### 접근성 테스트는 자동화만으로 충분하지 않다

```javascript
// 자동화 도구 (Lighthouse, axe): 60-70% 문제만 감지
// 나머지 30-40%는 수동 테스트와 사용자 테스트에서 발견

// 완전한 접근성 검증:
// 1. 자동화 테스트 (axe, Lighthouse)
// 2. 수동 테스트 (키보드, 스크린 리더)
// 3. 사용자 테스트 (실제 장애인 참여)
```

### 색상 대비는 미학보다 생명선이다

```css
/* 트렌드: 밝은 회색 텍스트 */
color: #999; /* 대비비 2.5:1 - AA 미달 */

/* 접근성: 충분한 대비 */
color: #333; /* 대비비 6.5:1 - AA 충족 */

/* 선택: 둘 다 가능 → 접근성을 우선 */
```

### ARIA는 보조 역할, 시맨틱이 주인공

```html
<!-- ARIA를 남용하는 흔한 패턴 -->
<div role="button" tabindex="0" aria-label="저장">💾</div>

<!-- 항상 더 나은 대안이 있다 -->
<button>💾 저장</button>

<!-- ARIA는 시맨틱으로 해결 불가능할 때만 -->
<div aria-live="polite" aria-atomic="true">
  <!-- 동적 콘텐츠 -->
</div>
```

### 포커스 인디케이터는 미관이 아닌 네비게이션 기본

```css
/* ❌ "기본 outline이 못생겨서 제거" */
button:focus {
  outline: none;
}

/* ✅ "기본 outline 제거 후 더 나은 스타일로 교체" */
button:focus-visible {
  outline: 3px solid #0066cc;
  outline-offset: 2px;
}
```

### 접근성 개선 = UX 개선

```
접근성 개선의 부수 효과:

✓ 코드 품질 향상 (시맨틱 HTML)
✓ SEO 개선 (구조화된 마크업)
✓ 모바일 UX 향상 (큰 버튼, 명확한 라벨)
✓ 성능 개선 (간단한 JavaScript, aria-live 최적화)
✓ 유지보수성 향상 (명확한 구조)
```

### 다양성은 비용이 아닌 초기 투자

```
초기 설계 단계:
- 시간 투자 +10%
- 개발 시간 동일
- 결과: 90% 사용자를 만족시키는 제품

사후 접근성 개선:
- 개발 완료 후 추가 작업
- 재구축 비용 50-100%
- 결과: 버그 위험, 품질 하락
```

---

## 참고 자료

### 공식 문서

- [WCAG 2.2 공식 가이드](https://www.w3.org/WAI/WCAG22/quickref/)
- [WAI-ARIA 사양](https://www.w3.org/WAI/ARIA/apg/)
- [MDN 접근성 가이드](https://developer.mozilla.org/en-US/docs/Web/Accessibility)

### 테스트 도구

| 도구 | 용도 | 자동/수동 |
|------|------|---------|
| [axe DevTools](https://www.deque.com/axe/devtools/) | 웹 접근성 자동 검사 | 자동 |
| [Lighthouse](https://developers.google.com/web/tools/lighthouse) | Chrome 내장 접근성 감시 | 자동 |
| [WAVE](https://wave.webaim.org/) | 페이지 접근성 시각화 | 자동 |
| [Colour Contrast Analyser](https://www.tpgi.com/color-contrast-checker/) | 색상 대비 검증 | 자동 |
| [NVDA](https://www.nvaccess.org/) | Windows 무료 스크린 리더 | 수동 |
| [VoiceOver](https://www.apple.com/accessibility/voiceover/) | macOS/iOS 내장 스크린 리더 | 수동 |

### 학습 리소스

- [The A11y Project](https://www.a11yproject.com/) - 접근성 커뮤니티
- [WebAIM](https://webaim.org/) - 웹 접근성 교육
- [Accessible Colors](https://accessible-colors.com/) - 색상 대비 계산기

---

**최종 원칙: 접근성은 선택사항이 아닙니다. 모든 사용자를 위한 설계가 바로 좋은 설계입니다.**
