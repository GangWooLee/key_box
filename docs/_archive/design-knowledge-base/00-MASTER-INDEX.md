# Design Knowledge Base — 마스터 인덱스

> **목적**: AI 모델의 UI/UX 디자인 품질을 전문가 수준으로 끌어올리기 위한 종합 커리큘럼
> **대상**: 15년차 UI/UX 디자인 전문가 수준의 지식 체계
> **활용**: 바이브코딩 품질 향상 · 디자인 시스템 구축 · 디자인 리뷰 기준 수립
> **기술 스택**: 플랫폼 무관 (Platform-agnostic Design Theory)

---

## 커리큘럼 구조

### Foundation — 디자인 기초 이론 (Phase 1~3)

| Phase | 문서 | 핵심 주제 |
|-------|------|----------|
| 01 | [시각 인지 & 디자인 기초 원리](./01-visual-perception-foundations.md) | 게슈탈트 원리, 시각적 위계, 인지 부하 이론, 다크 모드 연구, 시각적 균형 |
| 02 | [타이포그래피 심화](./02-typography.md) | 모듈러 스케일, 가변 폰트, 수직 리듬, 줄 길이 연구, CJK/한글, 유동적 타이포그래피 |
| 03 | [색채 이론 & 컬러 시스템](./03-color-theory.md) | OKLCH, APCA 대비, 3-Tier 토큰, 팔레트 생성, 다크 모드, 색각 다양성, 컬러 심리학 |

### Core — 설계 시스템 (Phase 4~6)

| Phase | 문서 | 핵심 주제 |
|-------|------|----------|
| 04 | [레이아웃, 그리드 & 공간 설계](./04-layout-grid-spatial.md) | 8pt 그리드, 반응형 그리드, Container Queries, Subgrid, Utopia 유동 간격, 현대적 레이아웃 |
| 05 | [컴포넌트 설계 원칙](./05-component-design.md) | Compound Components, 접근성 우선 설계, 상태 관리(XState), 폼 설계, 반응형 컴포넌트, Storybook |
| 06 | [디자인 시스템 아키텍처](./06-design-system-architecture.md) | Atomic Design 재고찰, W3C DTCG 토큰 표준, 합성 패턴, Design API, 거버넌스, 토큰 파이프라인 |

### Advanced — 인터랙션 & UX (Phase 7~8)

| Phase | 문서 | 핵심 주제 |
|-------|------|----------|
| 07 | [인터랙션 & 모션 디자인](./07-interaction-motion-design.md) | Disney 12원칙, 마이크로 인터랙션, Scroll-Driven Animations, View Transitions API, 성능 최적화 |
| 08 | [정보 구조 & UX 설계](./08-information-architecture-ux.md) | IA 기초(Wurman/Morville), 카드 소팅, 네비게이션 패턴, 웨이파인딩, 사용자 플로우, 온보딩 UX |

### Expert — 전문 영역 (Phase 9~11)

| Phase | 문서 | 핵심 주제 |
|-------|------|----------|
| 09 | [접근성 & 포용적 디자인](./09-accessibility-inclusive.md) | WCAG 2.2, 시맨틱 HTML/ARIA, 키보드 접근성, 스크린 리더, 인지 접근성, Microsoft Inclusive Design |
| 10 | [디자인 심리학 & 인지과학](./10-design-psychology.md) | Fitts's Law, Hick's Law, Miller's Law, Jakob's Law, Peak-End Rule, Von Restorff, Zeigarnik 효과 |
| 11 | [디자인 QA, 리뷰 & 최신 트렌드](./11-design-qa-trends.md) | Design Lint, Visual Regression, 리뷰 프로세스, 핸드오프, 2024-2026 트렌드, AI 통합, Spatial Design |

---

## 문서 공통 구조

모든 Phase 문서는 동일한 구조를 따릅니다:

1. **개요** — 주제의 중요성과 범위
2. **핵심 이론** — 학술 논문 인용, 정량적 데이터, 원리 설명
3. **실무 적용** — CSS/JS/HTML 코드 예제, 구현 패턴
4. **디자인 리뷰 체크리스트** — 실무에서 즉시 사용 가능한 검증 항목
5. **바이브코딩 가이드** — AI와 협업 시 활용할 프롬프트 패턴
6. **참고 자료** — 논문, 도서, 웹 표준, 도구 링크

---

## 활용 가이드

### 바이브코딩 품질 향상
AI에게 UI 구현을 요청할 때, 해당 Phase 문서의 원칙과 체크리스트를 프롬프트에 포함시키면 전문가 수준의 결과물을 얻을 수 있습니다.

### 디자인 시스템 구축
Phase 3(토큰) → Phase 4(그리드) → Phase 5(컴포넌트) → Phase 6(아키텍처) 순서로 참조하여 체계적인 디자인 시스템을 설계할 수 있습니다.

### 디자인 리뷰 기준
각 Phase의 체크리스트를 조합하여 프로젝트에 맞는 디자인 리뷰 기준을 수립할 수 있습니다.

---

## 메타 정보

- **생성일**: 2026-02-27
- **버전**: 1.0
- **총 문서 수**: 12개 (인덱스 포함)
- **언어**: 한국어 (기술 용어 영문 병기)
