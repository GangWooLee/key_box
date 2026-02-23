---
paths: app/views/**/*.erb, app/javascript/**/*.js
---

# Tailwind + Stimulus 패턴

## 컴포넌트 패턴

### 버튼
```erb
<%# Primary %>
<button class="btn-primary">

<%# Secondary %>
<button class="btn-secondary">

<%# 커스텀 Primary — 프로젝트 색상 변수 사용 %>
<button class="px-4 py-2 bg-primary hover:bg-primary-dark text-white font-medium rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed min-h-[44px]">

<%# Danger %>
<button class="px-4 py-2 bg-red-500 hover:bg-red-600 text-white font-medium rounded-lg transition-colors min-h-[44px]">
```

### 카드
```erb
<%# 프로젝트 표준 카드 %>
<div class="card-elevated">
  <%# 콘텐츠 %>
</div>

<%# 커스텀 카드 %>
<div class="bg-white rounded-xl shadow-sm hover:shadow-md border border-gray-100 p-6 transition-shadow">
  <%# 콘텐츠 %>
</div>
```

### 입력 필드
```erb
<input class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary placeholder-gray-400 transition-colors text-base">
<%# text-base (16px) 필수 — iOS에서 줌 방지 %>
```

## XSS 방지 (JavaScript)

| 금지 패턴 | 안전한 대안 |
|----------|-----------|
| 동적 HTML 삽입 | Turbo Stream 사용 (서버 렌더링) |
| DOM 문자열 파싱 | DOM API로 요소 생성 |

```javascript
// 안전한 방법
element.textContent = userInput
Turbo.renderStreamMessage(serverResponse)

const div = document.createElement('div')
div.textContent = userInput
parent.appendChild(div)
```

## 반응형 디자인

```erb
<%# Mobile First 접근 %>
<div class="
  flex flex-col      <%# 모바일: 세로 %>
  md:flex-row        <%# 태블릿+: 가로 %>
  lg:gap-8           <%# 데스크톱: 넓은 간격 %>
">

<%# 브레이크포인트 %>
sm:   <%# 640px+ %>
md:   <%# 768px+ %>
lg:   <%# 1024px+ %>
xl:   <%# 1280px+ %>
```

## 간격 시스템

```
p-2  (8px)   # 아이콘 패딩
p-4  (16px)  # 기본 패딩
p-6  (24px)  # 카드 패딩

gap-2 (8px)  # 아이콘-텍스트 간격
gap-4 (16px) # 요소 간격
gap-6 (24px) # 카드 간격

# 카드 내부: space-y-N 시리즈 사용 (혼합 mb-2/mb-4 금지)
space-y-2    # 밀접한 요소
space-y-4    # 기본 요소 간격
space-y-6    # 섹션 간격
```

---

## 이미지 최적화 (HIGH)

```erb
<%# 필수: aspect-ratio + lazy loading %>
<img src="..." alt="설명"
     class="aspect-video object-cover w-full h-full rounded-lg"
     loading="lazy">

<%# 정사각형 이미지 %>
<img src="..." alt="프로필"
     class="aspect-square object-cover rounded-full"
     loading="lazy">

<%# SVG: 명시적 크기 필수 %>
<svg width="24" height="24" aria-hidden="true">...</svg>
```

**규칙:**
- `aspect-video` / `aspect-square`로 CLS 방지
- `object-cover w-full h-full` 조합
- `loading="lazy"` 필수 (above-the-fold 제외)
- SVG에 명시적 `width` / `height` 속성

## 애니메이션 규칙 (MEDIUM)

```erb
<%# UI 요소: 150-300ms %>
<button class="transition-colors duration-200 hover:bg-primary-dark">

<%# 카드 호버: transition-shadow %>
<div class="card-elevated transition-shadow duration-200 hover:shadow-lg">

<%# 단일 CTA 바운스 (남용 금지) %>
<button class="animate-bounce">지금 시작하기</button>

<%# reduced-motion 지원 %>
<div class="animate-fade-in-up motion-reduce:animate-none">
```

**규칙:**
- `duration-150` ~ `duration-300` (UI 요소)
- `animate-bounce`는 단일 CTA에만 사용
- hover 시 반드시 `transition-colors` / `transition-shadow` 동반
- `motion-reduce:animate-none` 지원
- 동시 애니메이션 3개 이하

## 접근성 (CRITICAL)

```erb
<%# 스크린 리더 전용 텍스트 %>
<span class="sr-only">닫기</span>

<%# focus-visible (클릭 시 미표시, 키보드 시 표시) %>
<button class="focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2">

<%# 아이콘 버튼: aria-label 필수 %>
<button aria-label="좋아요" class="min-h-[44px] min-w-[44px]">
  <svg aria-hidden="true">...</svg>
</button>

<%# 터치 타겟 최소 크기 %>
<a href="..." class="inline-flex items-center min-h-[44px] min-w-[44px]">
```

**규칙:**
- `sr-only`로 스크린 리더 텍스트 제공
- `focus-visible:ring-2` 사용 (`focus:ring-2` 대신 — 클릭 시 미표시)
- 아이콘 버튼에 `aria-label` 필수
- `min-h-[44px] min-w-[44px]` 터치 타겟

## z-index 체계

Tailwind 스케일 사용을 권장합니다:

| z 값 | 용도 |
|------|------|
| z-0 | 기본 콘텐츠 |
| z-10 | 오버레이 텍스트 |
| z-20 | 플로팅 요소 |
| z-30 | 프로그레스 바 |
| z-40 | 인디케이터 |
| z-50 | 네비게이션 |

- `z-[9999]` 같은 임의값 지양 (코치마크 등 극소수 예외만)
- 커스텀 값 필요 시 `z-[5]`, `z-[60]` 등 10 단위 사이에 배치

## 폼 규칙 (MEDIUM)

```erb
<%# disabled 상태 %>
<button disabled class="disabled:opacity-50 disabled:cursor-not-allowed">

<%# placeholder 색상 %>
<input placeholder="검색어 입력" class="placeholder:text-gray-400">

<%# focus 스타일: outline-none만 단독 사용 금지 %>
<input class="focus:ring-2 focus:ring-primary focus:outline-none">

<%# 모바일 input type %>
<input type="email" inputmode="email">     <%# 이메일 키보드 %>
<input type="tel" inputmode="tel">         <%# 전화번호 키패드 %>
<input type="number" inputmode="numeric">  <%# 숫자 키패드 %>
```

**규칙:**
- `disabled:opacity-50 disabled:cursor-not-allowed` 필수
- `placeholder:text-gray-400` (어두운 placeholder 금지)
- `focus:ring-2` + `focus:outline-none` 조합 (outline-none만 쓰지 않기)
- 모바일에서 적절한 `inputmode` 사용

## 카드 패턴 (MEDIUM)

```erb
<%# 클릭 가능한 카드 %>
<div class="card-elevated cursor-pointer hover:shadow-lg transition-shadow press-effect">

<%# 카드 내부 간격 통일 %>
<div class="card-elevated p-6 space-y-4">
  <h3>...</h3>
  <p>...</p>
  <button>...</button>
</div>
```

**규칙:**
- 클릭 가능한 카드: `hover:shadow-lg transition-shadow` + `press-effect`
- 카드 내부: `space-y-4` (혼합 `mb-2`/`mb-4` 금지)
- 프로젝트 표준: `card-elevated` 또는 `selection-card` 사용

## 성능 (MEDIUM)

| 금지 | 권장 | 이유 |
|------|------|------|
| `@apply` 남용 | 직접 유틸리티 클래스 사용 | 번들 크기 증가 |
| `flex-shrink-0` | `shrink-0` | 단축형 |
| `h-6 w-6` | `size-6` | 단축형 |
| `h-screen` | `screen-fixed` + `dvh` | 모바일 주소창 |

## 색상 사용 규칙

```erb
<%# 프로젝트 색상 변수 사용 (프로젝트에 맞게 정의) %>
<%# 금지: 임의 색상 하드코딩 %>
<%# bg-teal-500, bg-orange-400 등 → 프로젝트 변수 사용 %>
```
