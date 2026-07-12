# Full Product Lifecycle Team Workflow

시장조사부터 런칭까지 전 과정을 10역할 Agent Team으로 수행하는 워크플로우.
5개 Wave로 순차 배치하여 동시 에이전트 수를 3명 이하로 유지.

---

## 팀 구성 (10역할, 5 Wave)

### Wave 1: Research (시장조사 + 데이터 분석)

| 역할 | agent name | subagent_type | model | mode |
|------|-----------|---------------|-------|------|
| 시장조사 | market-researcher | general-purpose | opus | plan |
| 데이터 분석 | data-analyst | general-purpose | sonnet | plan |

### Wave 2: Planning & Design (기획 + 디자이너)

| 역할 | agent name | subagent_type | model | mode |
|------|-----------|---------------|-------|------|
| 기획 | product-manager | general-purpose | opus | plan |
| 디자이너 | designer | general-purpose | opus | default |

### Wave 3: Build (코어 + 프론트엔드 + 인프라)

| 역할 | agent name | subagent_type | model | mode |
|------|-----------|---------------|-------|------|
| 코어 개발 | core-dev | general-purpose | sonnet | default |
| 프론트엔드 | frontend-dev | general-purpose | sonnet | default |
| 인프라/플랫폼 | platform-dev | general-purpose | sonnet | default |

### Wave 4: Quality (보안 + QA)

| 역할 | agent name | subagent_type | model | mode |
|------|-----------|---------------|-------|------|
| 보안 | security-eng | general-purpose | opus | plan |
| QA | qa-engineer | general-purpose | opus | default |

### Wave 5: Launch (마케팅)

| 역할 | agent name | subagent_type | model | mode |
|------|-----------|---------------|-------|------|
| 마케팅 | marketer | general-purpose | sonnet | plan |

### 에이전트 생성 예시

```
"팀 공유 볼트 기능을 full lifecycle team으로 개발해줘"
```

---

## Wave 실행 흐름

```
Wave 1: Research (2명)          ← market-researcher + data-analyst
  │     [Gate 1: 시장조사 결과 리뷰]
  ▼
Wave 2: Planning & Design (2명)  ← product-manager + designer
  │     [Gate 2: PRD + 디자인 승인]
  ▼
Wave 3: Build (3명)              ← core-dev + frontend-dev + platform-dev
  │     [Quality Gate: build + analyze + test]
  ▼
Wave 4: Quality (2명)            ← security-eng + qa-engineer
  │     [Gate 3: 보안 + QA 통과]
  ▼
Wave 5: Launch (1명)             ← marketer
  │     [Gate 4: 런칭 계획 승인]
  ▼
Done
```

---

## Wave별 상세 실행

### Wave 1: Research

**Spawn**:
```
Task(name="market-researcher", subagent_type="general-purpose", model="opus", mode="plan")
Task(name="data-analyst", subagent_type="general-purpose", model="sonnet", mode="plan")
```

**작업**:
- market-researcher: 경쟁사 분석, 시장 트렌드, 사용자 니즈 → `docs/research/`
- data-analyst: 이벤트 트래킹 설계, KPI 정의 → `docs/analytics/`

**Gate 1 조건**:
- `docs/research/market-analysis.md` 존재
- `docs/research/competitor-matrix.md` 존재
- `docs/analytics/event-tracking-plan.md` 존재
- Lead 리뷰 및 승인

**종료**: Gate 1 통과 후 `shutdown_request` → Wave 1 에이전트 종료

---

### Wave 2: Planning & Design

**입력**: Wave 1 산출물 (`docs/research/`, `docs/analytics/`)

**Spawn**:
```
Task(name="product-manager", subagent_type="general-purpose", model="opus", mode="plan")
Task(name="designer", subagent_type="general-purpose", model="opus")
```

**작업**:
- product-manager: PRD 작성 → `docs/plans/PRD-{feature}.md` + TaskCreate로 태스크 분해
  - `plan` 모드 → ExitPlanMode → Lead의 `plan_approval_response` 대기
- designer: 디자인 시스템 + 컴포넌트 설계 → `docs/design/` + `.pen` 파일
  - Anti-Generic AI Protocol 필수 적용

**Gate 2 조건**:
- PRD 승인 (plan_approval_response)
- 디자인 시스템 문서 존재
- 디자인 스크린샷 Lead 확인
- 차별화 체크리스트 5항목 통과

**종료**: Gate 2 통과 후 `shutdown_request` → Wave 2 에이전트 종료

---

### Wave 3: Build

**입력**: PRD (`docs/plans/`), 디자인 스펙 (`docs/design/`), 태스크 목록

**Spawn**:
```
Task(name="core-dev", subagent_type="general-purpose", model="sonnet")
Task(name="frontend-dev", subagent_type="general-purpose", model="sonnet")
Task(name="platform-dev", subagent_type="general-purpose", model="sonnet")
```

**파일 소유권** (충돌 방지):

| 소유자 | 파일 범위 |
|--------|----------|
| core-dev | `lib/core/database/`, `lib/core/encryption/`, `lib/features/*/domain/`, `lib/core/router/` |
| frontend-dev | `lib/features/*/presentation/`, `lib/core/theme/`, `assets/` |
| platform-dev | `lib/services/`, `lib/core/constants/`, `macos/`, `pubspec.yaml` |

**작업**:
- core-dev: Drift 테이블/DAO, Provider/StateNotifier, 암호화, GoRouter
- frontend-dev: Screen/Widget 구현, 테마 적용, Material 3 (디자이너 스펙 기반)
- platform-dev: macOS 플랫폼 설정, Entitlements, 윈도우 서비스, 의존성 관리

**Quality Gate 조건**:
1. `flutter build macos --debug` — 빌드 통과
2. `flutter test` — 전체 테스트 통과
3. `dart analyze` — 정적 분석 통과

**종료**: Quality Gate 통과 후 `shutdown_request` → Wave 3 에이전트 종료

---

### Wave 4: Quality

**입력**: Wave 3 구현 코드

**Spawn**:
```
Task(name="security-eng", subagent_type="general-purpose", model="opus", mode="plan")
Task(name="qa-engineer", subagent_type="general-purpose", model="opus")
```

**작업**:
- security-eng: 암호화 구현 감사, 키 관리, SQLCipher 설정, Entitlements 검증 → `docs/security/audit-report-{date}.md`
  - `plan` 모드 (읽기 전용 분석 → 발견사항 보고 → Lead가 수정 지시)
  - `.claude/agents/quality/security-expert.md` 체크리스트 사용
- qa-engineer: 테스트 작성 + 실행, 커버리지 분석 → `test/`, `docs/qa/test-strategy.md`
  - flutter_test + mocktail + ProviderContainer 패턴

**Gate 3 조건**:
- 보안 감사 Critical 발견 0건
- `flutter test` 전체 통과
- 커버리지 목표 달성 (암호화 100%, 인증 100%, Provider 80%, Widget 60%)
- 발견사항 수정 완료 (Lead 직접 또는 재spawn)

**종료**: Gate 3 통과 후 `shutdown_request` → Wave 4 에이전트 종료

---

### Wave 5: Launch

**입력**: 전체 산출물 (시장조사 + 제품 + 코드)

**Spawn**:
```
Task(name="marketer", subagent_type="general-purpose", model="sonnet", mode="plan")
```

**작업**:
- marketer: 런칭 전략, ASO, 콘텐츠 캘린더 → `docs/marketing/`

**Gate 4 조건**:
- 런칭 계획서 존재
- Lead가 사용자에게 최종 승인 요청
- 사용자 승인

**종료**: Gate 4 통과 후 `shutdown_request` → Wave 5 에이전트 종료

---

## 승인 게이트 요약

| 게이트 | 시점 | 승인자 | 조건 |
|--------|------|--------|------|
| **Gate 1** | Wave 1 → 2 | Lead | 시장 분석 + 이벤트 설계 리뷰 |
| **Gate 2** | Wave 2 → 3 | Lead | PRD 승인 + 디자인 스크린샷 확인 |
| **Gate 3** | Wave 3-4 → 5 | Lead | 테스트 통과 + 보안 감사 Critical 0건 |
| **Gate 4** | Wave 5 완료 | Lead → User | 런칭 계획 사용자 최종 승인 |

---

## 통신 계층

```
Lead (나)
├── DM ← market-researcher (Wave 1)
├── DM ← data-analyst (Wave 1)
├── DM ← product-manager (Wave 2, PRD 승인 요청)
├── DM ← designer (Wave 2, 디자인 리뷰 요청)
├── DM ← core-dev (Wave 3)
├── DM ← frontend-dev (Wave 3)
├── DM ← platform-dev (Wave 3)
├── DM ← security-eng (Wave 4)
├── DM ← qa-engineer (Wave 4)
└── DM ← marketer (Wave 5)
```

**규칙**:
- `broadcast` 사용 최소화 (동일 Wave 내 critical issue만)
- Wave 간 통신은 Lead가 중재
- 산출물은 `docs/` 파일로 전달 (메시지로 긴 내용 전달 금지)

---

## 디렉토리 구조 (비코드 산출물)

```
docs/
├── research/
│   ├── market-analysis.md
│   ├── competitor-matrix.md
│   └── user-personas.md
├── plans/
│   └── PRD-{feature}.md
├── design/
│   ├── design-system.md
│   ├── component-specs.md
│   └── *.pen
├── analytics/
│   ├── event-tracking-plan.md
│   └── metrics-dashboard.md
├── security/
│   └── audit-report-{date}.md
├── qa/
│   └── test-strategy.md
└── marketing/
    ├── launch-plan.md
    ├── aso-strategy.md
    └── content-calendar.md
```

---

## 비용 최적화

| 역할 | 모델 | 근거 |
|------|------|------|
| market-researcher | opus | 분석적 추론 필요 |
| data-analyst | sonnet | 구조화된 데이터 작업 |
| product-manager | opus | 전략적 의사결정 |
| designer | opus | 창의적 + 기술적 판단 |
| core-dev | sonnet | 패턴 기반 코드 생성 |
| frontend-dev | sonnet | Material 3 위젯 작성 |
| platform-dev | sonnet | 설정/인프라 작업 |
| security-eng | opus | 암호화/보안 분석 정확도 |
| qa-engineer | opus | 테스트 품질/엣지케이스 탐지 |
| marketer | sonnet | 콘텐츠 생성 |

**절감 전략**:
- Wave별 종료 → 유휴 에이전트 비용 0
- sonnet 6명 / opus 4명 비율
- `plan` 모드 에이전트(4명)는 코드 수정 안 함 → 안전 + 저비용

---

## 기존 팀 vs Full Lifecycle 사용 기준

| 기준 | 3명 팀 (feature-dev-team) | 10명 팀 (full-lifecycle-team) |
|------|--------------------------|------------------------------|
| 스코프 | 단일 기능 구현 | 새 제품/대형 기능 런칭 |
| 기간 | 1 세션 | 다중 세션 |
| 시장조사 필요 | 불필요 | 필요 |
| 디자인 필요 | 기존 시스템 따름 | 새 디자인 필요 |
| 마케팅 필요 | 불필요 | 필요 |
| 예시 | "시크릿 CRUD 추가" | "팀 공유 볼트 기능 전체 개발" |

---

## Lead 실행 절차 (요약)

```
1. TeamCreate("lifecycle-{feature}")
2. 기능 요청 분석, 초기 태스크 생성

3. Wave 1 — Spawn: market-researcher, data-analyst
   → shutdown Wave 1 → [Gate 1]

4. Wave 2 — Spawn: product-manager, designer
   → shutdown Wave 2 → [Gate 2]

5. Wave 3 — Spawn: core-dev, frontend-dev, platform-dev
   → Quality Gate → shutdown Wave 3

6. Wave 4 — Spawn: security-eng, qa-engineer
   → [Gate 3] → 발견사항 수정 → shutdown Wave 4

7. Wave 5 — Spawn: marketer
   → [Gate 4] → shutdown Wave 5

8. Lead: /verify → /wrap-up → TeamDelete
```

---

## 참조

- [Agent Teams Guide](../../docs/agent-teams-guide.md)
- [Feature Dev Team](feature-dev-team.md) — 3-4명 기능 개발 팀
- [Review Team](review-team.md) — 리뷰 전문 팀
- [Debugging Team](debugging-team.md) — 디버깅 전문 팀
- [Agent Definitions](../../agents/business/) — 비즈니스 에이전트 정의
