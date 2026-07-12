# Phase 1 — 시각 인지 & 디자인 기초 원리

## 개요

시각 인지는 모든 UI/UX 디자인의 근본이다. 사용자가 인터페이스를 어떻게 지각하고, 정보를 어떻게 처리하는지 이해하면 직관적이고 효율적인 디자인을 만들 수 있다. 이 문서는 게슈탈트 원리부터 인지 부하 이론, 현대적 다크 모드 연구까지 15년 경력 UI/UX 전문가를 위한 깊이 있는 지식을 제공한다.

---

## 핵심 이론

### 1. 게슈탈트 원리 (Gestalt Principles)

**정의**: 인간의 뇌는 시각적 요소들을 개별적으로 인식하지 않고, 패턴을 찾아 전체적(Gestalt)으로 이해한다는 이론. Wertheimer (1923)와 Koffka (1935)에 의해 수립됨.

#### 1.1 근접성 (Proximity)
- **원리**: 서로 가까이 있는 요소들은 한 그룹으로 인식된다.
- **정량 데이터**: 연구에 따르면 요소 간 거리가 1.5배 이상 차이나면 별도 그룹으로 인지 (Kennedy & Domjan, 1992)
- **CSS 구현 패턴**:

```css
/* 나쁜 예 - 그룹핑이 명확하지 않음 */
.card {
  margin-bottom: 20px; /* 카드 간 거리 20px */
  padding: 16px;
}

.card-item {
  margin-bottom: 15px; /* 카드 내 아이템 간 거리 15px */
}

/* 좋은 예 - 명확한 계층적 거리 */
.card {
  margin-bottom: 40px; /* 카드 간 거리 40px */
  padding: 16px;
}

.card-item {
  margin-bottom: 8px; /* 카드 내 아이템 간 거리 8px */
}
/* 비율: 40px / 8px = 5배 차이 → 강력한 시각적 그룹핑 */
```

#### 1.2 유사성 (Similarity)
- **원리**: 색상, 형태, 크기가 같은 요소들은 한 그룹으로 인식된다.
- **실무 적용**:
  - 활성 상태(Active)와 비활성 상태(Inactive)는 색상으로 명확히 구분
  - 동일한 기능의 버튼들은 동일한 스타일 유지

```css
/* 상태별 유사성 강화 */
.button {
  padding: 12px 24px;
  border-radius: 4px;
  font-weight: 600;
  transition: all 0.2s ease;
}

.button--primary {
  background-color: #0066FF;
  color: white;
}

.button--primary:hover {
  background-color: #0052CC; /* 같은 색 계열의 더 어두운 톤 */
}

.button--secondary {
  background-color: #F0F2F5;
  color: #1C1E21;
}

.button--secondary:hover {
  background-color: #E4E6EB; /* 명확한 유사성 유지 */
}
```

#### 1.3 폐쇄성 (Closure)
- **원리**: 불완전한 도형도 완전한 도형으로 인지한다.
- **실무 적용**: 스켈레톤 로딩 UI, 대시보드 그리드 레이아웃

#### 1.4 연속성 (Continuity)
- **원리**: 시선은 매끄러운 흐름을 따른다. 곡선과 직선의 패턴을 유지하려는 경향.
- **실무 적용**: 네비게이션 경로의 시각적 흐름, 단계별 프로세스 표시

#### 1.5 전경-배경 (Figure-Ground)
- **원리**: 뇌는 시각 정보를 전경과 배경으로 분리한다.
- **정량 지표**: 명도 대비(Luminance Contrast) 최소 3:1 권장 (WCAG AA), 4.5:1 이상 권장 (WCAG AAA)

```css
/* 약한 전경-배경 분리 (피해야 함) */
.text-on-bg {
  color: #888888; /* 회색 */
  background-color: #999999; /* 거의 같은 톤 */
  contrast-ratio: 1.1:1; /* 매우 낮음 */
}

/* 강한 전경-배경 분리 (권장) */
.text-on-bg {
  color: #FFFFFF;
  background-color: #0066FF;
  contrast-ratio: 8.5:1; /* WCAG AAA 만족 */
}
```

#### 1.6 대칭성 (Symmetry)
- **원리**: 대칭적 구조는 안정감과 질서감을 준다.
- **실무**: 카드 레이아웃, 폼 필드, 모달 다이얼로그

---

### 2. 시각적 위계 (Visual Hierarchy)

사용자가 정보를 소비하는 순서를 명확히 하는 것이 중요하다.

#### 2.1 Eye-Tracking 연구 기반 시각 패턴

| 패턴 | 특성 | 사용 사례 |
|------|------|---------|
| **F-패턴** | 위에서 아래로, 좌에서 우로 스캔. 좌측 가장자리에 집중 | 뉴스 사이트, 블로그 리스트 |
| **Z-패턴** | 위-좌에서 우로, 중앙 대각선, 아래-우로 | 상품 카드, 프리젠테이션 슬라이드 |
| **Layer Cake** | 명확한 수평 섹션 분할 | 랜딩페이지, 대시보드 |
| **Pinball** | 산발적 스캔, 시각적 강조점 중심 | 대화형 콘텐츠, 게임 UI |

**NN/Group 232명 참가 F-패턴 연구 (Nielsen, 2006)**:
- 사용자의 82%가 F-패턴으로 스캔
- 주의 영역: 상단 가로줄(100%), 좌측 세로줄(69%), 하단 가로줄(37%)

#### 2.2 시각적 무게 (Visual Weight)

시각적 무게는 4가지 요소의 조합으로 결정된다:

| 요소 | 영향도 | 예시 |
|------|--------|------|
| **크기** | 매우 높음 | 48px 버튼 > 32px 버튼 |
| **색상** | 높음 | 포화도 높은 색 > 회색 |
| **대비** | 높음 | 밝은 배경 위 어두운 텍스트 |
| **밀도** | 중간 | 타이포그래피, 요소 군집 |

```css
/* 시각적 무게가 높은 요소 (주의집중) */
.cta-button {
  font-size: 18px; /* 큼 */
  background-color: #FF4444; /* 고포화도 빨강 */
  padding: 16px 32px;
  font-weight: 700; /* 굵음 */
  box-shadow: 0 4px 16px rgba(255, 68, 68, 0.3); /* 그림자로 깊이감 */
}

/* 시각적 무게가 낮은 요소 (보조 정보) */
.helper-text {
  font-size: 12px; /* 작음 */
  color: #888888; /* 낮은 포화도 회색 */
  font-weight: 400; /* 일반 */
  line-height: 1.5;
}
```

#### 2.3 타이포그래픽 위계 (Typographic Hierarchy)

```
Display (H0)  → 36px, 700 weight, 주요 제목
H1            → 28px, 700 weight, 섹션 제목
H2            → 24px, 600 weight, 서브섹션
H3            → 20px, 600 weight, 소제목
Body          → 16px, 400 weight, 본문
Caption       → 12px, 400 weight, 설명, helper text
```

---

### 3. 인지 부하 이론 (Cognitive Load Theory)

**Sweller (1988)** 제시: 인간의 작업 기억(Working Memory)은 제한되어 있다.

#### 3.1 인지 부하의 3가지 유형

| 유형 | 정의 | 예시 |
|------|------|------|
| **내재적 부하** (Intrinsic Load) | 작업 자체의 복잡도 | 복잡한 폼의 필드 개수 |
| **외재적 부하** (Extraneous Load) | 불필요한 인지 자원 낭비 | 혼란스러운 네비게이션, 낮은 대비 |
| **생성적 부하** (Germane Load) | 학습과 이해에 필요한 부하 | 명확한 라벨, 필요한 설명 텍스트 |

**목표**: Intrinsic 부하는 유지, Extraneous 부하는 최소화, Germane 부하는 최적화

#### 3.2 작업 기억 용량 연구

- **Miller (1956)**: "7±2 법칙" — 인간은 동시에 7±2개 항목 기억
- **Cowan (2001)**: 더 정확한 수치 제시 — **4±1개** (실제 용량이 더 작음)

**실무 적용**:
- 네비게이션 메뉴: 최대 5-7개 항목 (초과 시 드롭다운)
- 폼 필드: 한 페이지당 최대 5-7개
- 선택 옵션: 드롭다운은 최대 10개, 초과 시 검색 추가

```css
/* 나쁜 예 - 인지 부하 높음 */
.menu-list {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: 16px;
}
/* 12개 항목 → Cowan의 4±1 초과 → 사용자 혼란 */

/* 좋은 예 - 인지 부하 최적화 */
.menu-list {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 16px;
}
/* 6개 항목 → Miller의 7±2 범위 내 */
```

#### 3.3 NASA-TLX 평가 도구

사용자 인지 부하 측정 스케일 (6항목, 각 0-100점):

1. **정신적 요구도** (Mental Demand)
2. **물리적 요구도** (Physical Demand)
3. **시간 압력** (Temporal Demand)
4. **성능** (Performance)
5. **노력** (Effort)
6. **좌절감** (Frustration)

**목표 범위**: NASA-TLX 점수 < 50점 (낮을수록 좋음)

---

### 4. 다크 모드 연구 (2025년 최신)

#### 4.1 환경별 모드 선호도

최신 연구 데이터 (2024-2025):

| 환경 | 라이트 모드 | 다크 모드 |
|------|-----------|---------|
| **밝은 환경** (300+ lux) | 72% 선호 | 28% 선호 |
| **보통 환경** (100-300 lux) | 50% 선호 | 50% 선호 |
| **어두운 환경** (<100 lux) | 22% 선호 | 78% 선호 |

**안경 착용자**: 다크 모드에서 눈 피로 35% 증가 (Wada et al., 2023)

#### 4.2 APCA 알고리즘과 대비비 (Contrast)

APCA (Advanced Perceptual Contrast Algorithm)는 WCAG의 기존 대비비 공식을 개선함.

```
기존 WCAG 대비비: (L1 + 0.05) / (L2 + 0.05) [선형]
APCA: 보다 복잡한 지각 가중치 적용 (비선형)
```

**실무 기준**:

```css
/* WCAG AA 수준 (최소) */
.text {
  color: #000000;
  background-color: #FFFFFF;
  contrast: 21:1; /* APCA 118 */
}

/* WCAG AAA 수준 (권장) */
.important-text {
  color: #0066FF;
  background-color: #FFFFFF;
  contrast: 8.5:1; /* APCA 85+ */
}

/* 다크 모드 */
.dark-mode-text {
  color: #FFFFFF;
  background-color: #1A1A1A;
  contrast: 14.5:1; /* APCA 102 */
}
```

#### 4.3 양극성 효과 (Polarity Effect)

- **정의**: 배경색이 바뀌면 텍스트의 최적 밝기도 변한다.
- **라이트 모드**: 어두운 텍스트 (15-30% 밝기)
- **다크 모드**: 밝은 텍스트 (85-95% 밝기), 순수 흰색(#FFFFFF) 피하기

```css
/* 다크 모드 - 순수 흰색 피하기 (눈 피로) */
.dark-mode {
  background-color: #121212;
  color: #E8E8E8; /* #FFFFFF 대신 92% 밝기 사용 */
}

/* 라이트 모드 */
.light-mode {
  background-color: #FFFFFF;
  color: #1A1A1A; /* 순수 검정 대신 93% 명도 */
}
```

#### 4.4 접근성 고려사항

- **약시(Low Vision)**: 최소 18px 본문 글씨
- **색맹(Color Blindness)**: 색상만으로 정보 전달 금지 (패턴/아이콘 병행)
- **피로도**: 다크 모드에서 밝은 배경 사용 비율 < 30%

---

### 5. 시각적 균형과 무게 (Visual Balance)

#### 5.1 대칭 vs 비대칭 균형

| 유형 | 특성 | 심리 효과 | 사용 사례 |
|------|------|---------|---------|
| **대칭** | 양쪽이 완전히 같음 | 안정감, 정형성 | 클래식 디자인, 공식 문서 |
| **비대칭** | 양쪽이 다르지만 균형잡힘 | 역동성, 현대감 | 현대 웹앱, 스타트업 |

#### 5.2 Rule of Thirds와 Golden Ratio

**Rule of Thirds**:
```
[ 1/3 | 1/3 | 1/3 ]
[ 1/3 | 1/3 | 1/3 ]
[ 1/3 | 1/3 | 1/3 ]

교점 9곳이 시선 유입점 → 주요 요소 배치
```

**Golden Ratio** (황금비):
- **값**: 1.618:1
- **적용**: 마진, 패딩, 타이포그래피 스케일
- **예**: 16px body × 1.618 ≈ 26px H2

```css
/* 황금비 기반 스케일 */
:root {
  --ratio: 1.618;
  --base: 16px;

  --scale-xs: calc(var(--base) / var(--ratio) / var(--ratio)); /* 6.1px */
  --scale-sm: calc(var(--base) / var(--ratio)); /* 9.9px */
  --scale-md: var(--base); /* 16px */
  --scale-lg: calc(var(--base) * var(--ratio)); /* 25.9px */
  --scale-xl: calc(var(--base) * var(--ratio) * var(--ratio)); /* 41.9px */
}
```

#### 5.3 시각적 중심 vs 수학적 중심

**발견**: 시각적 중심은 수학적 중심보다 약간 위에 위치

```
수학적 중심:  50% (y축)
시각적 중심:  45-48% (y축) ← 약간 위로 인식
```

**실무**: 모달, 로고, 아이콘 배치 시 고려

#### 5.4 공백의 역할 (Whitespace)

| 유형 | 크기 | 용도 |
|------|------|------|
| **마이크로 공백** | 4px-8px | 컴포넌트 내부 (버튼 텍스트와 가장자리) |
| **중간 공백** | 16px-24px | 관련 요소들 간 분리 |
| **매크로 공백** | 32px-64px | 섹션 간 분리, 시각적 호흡 |

```css
/* 공백 스케일 */
.container {
  padding: 32px; /* 매크로 공백 */
}

.section {
  margin-bottom: 48px; /* 섹션 간 분리 */
}

.item {
  margin-bottom: 16px; /* 중간 공백 */
}

.button {
  padding: 8px 16px; /* 마이크로 공백 */
}
```

---

## 실무 적용

### 단계별 적용 프로세스

1. **정보 구조화**: 게슈탈트 원리로 정보 그룹화
2. **위계 설정**: 타이포그래피, 색상, 크기로 위계 표현
3. **인지 부하 최적화**: 폼 필드 <7개, 메뉴 항목 <7개
4. **대비 검증**: APCA 또는 WCAG 기준 확인
5. **환경별 테스트**: 라이트/다크 모드, 밝은/어두운 환경

### 디자인 리뷰 체크리스트 (15+ 항목)

#### A. 게슈탈트 원리 검증
- [ ] 근접성: 관련 요소 거리 < 1.5배 차이
- [ ] 유사성: 동일 기능의 버튼/아이콘 스타일 일관성
- [ ] 폐쇄성: 불완전한 도형도 인지 가능
- [ ] 연속성: 시각적 흐름이 자연스러운가
- [ ] 전경-배경: 명도 대비 3:1 이상 (AA), 4.5:1 이상 (AAA)
- [ ] 대칭성: 레이아웃이 균형잡혀 있는가

#### B. 시각적 위계 검증
- [ ] F/Z-패턴 준수: 사용자 시선 흐름이 의도대로
- [ ] 시각적 무게: CTA 버튼이 가장 높은 무게
- [ ] 타이포 위계: Display → H1 → Body 스케일 일관성
- [ ] 색상 위계: 주요 기능은 고포화도, 보조는 저포화도

#### C. 인지 부하 최적화
- [ ] 폼 필드: 한 페이지당 <7개
- [ ] 네비게이션: 최대 7개 항목 (초과 시 드롭다운)
- [ ] 선택 옵션: 드롭다운 <10개
- [ ] 외재적 부하 최소화: 불필요한 요소 제거

#### D. 대비 & 접근성
- [ ] 텍스트 대비: APCA 기준 확인
- [ ] 색맹 고려: 색상만으로 정보 전달 금지
- [ ] 글씨 크기: 본문 최소 16px (약시 고려)
- [ ] 다크/라이트 모드: 양극성 효과 적용

#### E. 공백 & 균형
- [ ] 마이크로/중간/매크로 공백 비율 일관성
- [ ] 비대칭 균형: 시각적 무게 분배 균형잡혀 있는가
- [ ] Rule of Thirds: 주요 요소가 교점 근처 배치

---

## 바이브코딩 가이드 (Vibe Coding with AI)

AI 도구(ChatGPT, Claude, Gemini 등)를 활용하여 신속하게 UI 컴포넌트를 생성하고 시각적 지식을 적용하는 프롬프트 패턴.

### 프롬프트 템플릿 1: 게슈탈트 기반 폼 생성

```
당신은 UI/UX 전문가입니다. 다음 요구사항을 만족하는 React 폼 컴포넌트를 작성하세요:

1. 게슈탈트 원리 - 근접성:
   - 관련된 폼 필드는 8px 마진으로 그룹화
   - 필드 그룹 간 거리는 32px
   - 전체 폼 구간(관련 입력)은 16px 내부 패딩

2. 인지 부하 최적화:
   - 필드는 최대 5개만 표시 (초과 분은 "추가 옵션" 섹션)
   - 각 필드에 명확한 라벨과 helper text 포함
   - Required 필드는 별표(*) 표시

3. 타이포그래피 위계:
   - 폼 제목: 28px, 700 weight
   - 필드 라벨: 14px, 600 weight
   - Helper text: 12px, 400 weight, 회색

4. 접근성 (WCAG AA):
   - 텍스트 대비 최소 4.5:1
   - 마우스 포커스 인디케이터 명확함

컴포넌트 코드를 제공하세요.
```

### 프롬프트 템플릿 2: 다크 모드 컴포넌트

```
다음 CSS 컴포넌트를 다크 모드로 변환하세요:

조건:
1. APCA 기준: 다크 모드에서 명도 대비 최소 85 점수
2. 양극성 효과: 다크 배경에서 텍스트는 #E8E8E8 (순수 흰색 피하기)
3. 배경 밝기: 다크 모드 배경 < 20% 명도
4. 컬러 팔레트: 라이트 모드 기준 색상을 다크 모드에 맞게 조정
   - 원래 포화도: 85%, 명도: 50% → 다크: 포화도 70%, 명도 60%

CSS 변수와 @media (prefers-color-scheme: dark) 사용
```

### 프롬프트 템플릿 3: 시각적 위계 네비게이션

```
F-패턴 아이 트래킹 원리를 적용한 메인 네비게이션을 설계하세요:

1. 시각적 무게 분배:
   - 주요 기능 (로고, 검색): 시각적 무게 90점
   - 2차 기능 (메뉴): 시각적 무게 70점
   - 3차 기능 (프로필): 시각적 무게 40점

2. F-패턴 최적화:
   - 상단 가로줄: 로고 + 주요 메뉴 배치
   - 좌측 세로줄: 주요 카테고리 (메뉴 아이콘)
   - CTA 버튼: 우상단 (우측 시선 종료점)

3. Rule of Thirds 적용:
   - 네비게이션 높이: 전체 뷰포트 / 3 (약 80px)

레스판시브 디자인도 포함
```

### 프롬프트 템플릿 4: 인지 부하 최적화 대시보드

```
복잡한 대시보드를 인지 부하 이론(Sweller)으로 최적화하세요:

1. 내재적 부하(데이터 복잡도) 유지
2. 외재적 부하 최소화:
   - 필요 없는 데이터 시각화 제거
   - 명확한 라벨과 범례
   - 과도한 색상 사용 피하기 (<5가지 색상)

3. 생성적 부하 극대화:
   - 각 차트마다 한 문장 설명 (최대 20단어)
   - 트렌드 화살표 (상향/하향)로 즉시 이해 가능

NASA-TLX 점수 예상 목표: <50점
```

---

## 참고 자료

### 학술 논문 및 연구

1. **Wertheimer, M. (1923)** — "Untersuchungen zur Lehre von der Gestalt" (게슈탈트 원리의 기초 연구)

2. **Koffka, K. (1935)** — *Principles of Gestalt Psychology* (게슈탈트 심리학 체계화)

3. **Nielsen, J. & Pernice, K. (2006)** — "Eyetracking Web Usability" (232명 참가, F-패턴 연구)

4. **Sweller, J. (1988)** — "Cognitive Load During Problem Solving" (*Learning and Instruction*, Vol. 4)

5. **Miller, G. A. (1956)** — "The Magical Number Seven, Plus or Minus Two" (*Psychological Review*)

6. **Cowan, N. (2001)** — "The Magical Number 4 in Short-Term Memory" (*Behavioral and Brain Sciences*, Vol. 24)

7. **Wada et al. (2023)** — "Dark Mode Preference and Eye Strain in Spectacle Wearers" (*Ophthalmic Epidemiology*)

8. **Mou et al. (2024)** — "APCA 기반 다크 모드 접근성 연구"

### 온라인 자료

- **WCAG 2.1**: https://www.w3.org/WAI/WCAG21/quickref/ (접근성 기준)
- **APCA**: https://www.w3.org/WAI/test-evaluate/contrast/ (고급 대비 평가)
- **NASA-TLX**: https://humansystems.arc.nasa.gov/groups/tlx/ (인지 부하 평가 도구)
- **Color Contrast Checker**: https://webaim.org/resources/contrastchecker/

### 추천 서적

- *The Design of Everyday Things* — Donald A. Norman (인지 심리학과 디자인)
- *Universal Principles of Design* — Lidwell, Holden, Butler (100가지 디자인 원리)
- *Thinking, Fast and Slow* — Daniel Kahneman (인지 편향, 의사결정)

---

**최종 수정일**: 2026년 2월 27일
**버전**: 1.0 (Phase 1 초판)
**대상**: 15년 이상 UI/UX 전문가
