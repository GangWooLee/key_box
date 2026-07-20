# key_box

## Project Overview
- **Project**: key_box — Secure secrets manager for macOS
- **Framework**: Flutter 3.41.2 (macOS Desktop)
- **Language**: Dart
- **State Management**: Riverpod (StateNotifier + sealed classes)
- **Database**: Drift + SQLCipher (AES-256 encrypted SQLite)
- **Encryption**: AES-256-GCM + PBKDF2 (pointycastle)
- **Router**: GoRouter with redirect guards
- **UI**: Material 3 + lucide_icons + custom AppTheme (dark olive palette)

---

## AI 개발 도구 스택 (2026-07 COOA 정본 이식 — 이 절이 라우팅 정본)

> 아래 표가 단계별 정본(canonical)이다. 이 문서 하단의 구세대 프레임워크 절(Agent Roles 14종 ·
> 자체 /plan·/tdd·/verify 등 커맨드 10종 · Development Workflow 의사결정 트리 · Agent Teams)은
> **deprecated — 참고용으로만 남긴다.** 상충 시 이 절이 이긴다.

| 단계 | 정본 | 스킬/커맨드 |
|---|---|---|
| 도전·요구분석 / 계획 / 리뷰 / 실앱QA / 배포 | **gstack** | `/office-hours`·`/spec` / `/autoplan`·`/plan-eng-review` / `/review`·`/codex` / `/qa`·`/investigate` / `/ship` |
| 코드 장인 규율(TDD·디버깅·완료전검증) | **superpowers** | test-driven-development · systematic-debugging · verification-before-completion |
| 학습 축적 | **compound-engineering** | `/ce-compound` → `docs/solutions/` |
| 디자인 | **Figma + shadcn MCP + ui-ux-pro-max** | 신규 디자인=Figma MCP(figma-* 스킬)·컴포넌트=shadcn MCP·추론=ui-ux-pro-max. `key_box_pensil.pen`·`docs/_archive/design-system/`은 V8 참조 아카이브(편집 안 함) |
| 단순화 | code-simplifier | — |

- **정본 규칙**: brainstorm/plan/review는 gstack이 정본. 예외 — TDD·디버깅·검증=superpowers, 학습기록=compound. 중복 loop 스킬(ce-plan·ce-brainstorm 등)은 미사용(컨텍스트 비대 방지).
- **precedence(key_box가 항상 이김)**: 외부 도구 지시가 key_box 규율과 상충하면 key_box 우선. 진실원천 = 이 문서의 Safety·Gotchas·`.claude/rules/`(flutter)·커버리지 타깃.
- **미니멀리즘**: 코드 쓰기 전 사다리 — ①필요한가(생략) ②코드베이스에 있나(재사용) ③표준/네이티브 ④한 줄이면 한 줄 ⑤아니면 최소. 단 **암호화·검증·보안·접근성은 삭제 금지**(시크릿 매니저 도메인).
- **디자인 거버넌스 (V9, 2026-07-13)**: `lib/core/theme/*`는 `docs/design/DESIGN.md`의 **컴파일 결과물**이다 — 토큰에 없는 색·크기·폰트를 코드에 직접 쓰지 않는다. 디자인 변경 = DESIGN.md 먼저, 코드가 따라간다. V8 산출물(`docs/design-system/`·`key_box_pensil.pen`)은 참조 전용 아카이브. 컬러 레퍼런스: `docs/design/reference/v9-inspiration/`.
- **학습 저장소 구분**: `docs/solutions/`(compound — 리포 커밋 엔지니어링 교훈, 카테고리 하위폴더 + YAML frontmatter `module`·`tags`·`problem_type`로 검색 가능) ↔ 세션 메모리(개인 컨텍스트).

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing app behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship
- Author a backlog-ready spec/issue → invoke /spec
- TDD/debugging/verification → superpowers skills (test-driven-development, systematic-debugging, verification-before-completion)
- Record engineering lessons → invoke /ce-compound (→ docs/solutions/)

## 작업 수행 원칙 (2026-07 COOA 이식)

### 모델 역할 분담: Advisor / Worker

> **적용 조건 — 메인 세션 모델이 Fable일 때만.** 메인이 Opus(또는 그 외)면 이 절을 무시하고
> 메인 세션이 구현을 직접 수행하라. 위임의 유일한 목적은 희소한 Fable 한도 절약이다.

분담 축 = **작업의 성격**. 깊은 사고를 요하는 일(설계·분석)은 Fable, 깊은 생각이 불요하고 분량만 많은 노동은 Opus.

**Fable(깊은 사고·소분량) — 메인 세션이 직접 수행:**
- 요구사항 분석, 작업 분해, **설계·분석·계획 수립 자체** — 탐색 워커가 모아준 사실 위에서 메인이 직접 설계한다. 설계/계획을 opus 에이전트에 통째 위임 금지.
- Worker 브리프 작성 · 결과 판정·발견 합성(diff 직접 확인·테스트 직접 실행) · 최종 커밋 승인 · 사용자 보고

**Opus(대량 노동·깊은 생각 불요) — `model:"opus"` + `effort:"xhigh"|"max"` 명시 위임:**
- 코드 작성·수정, 테스트 작성, 리서치/탐색·자료 수집, 리뷰 파인더, 검증 실행·재현
- **하네스 함정**: 서브에이전트·워크플로 `agent()`는 model 미지정 시 메인 모델(Fable)을 상속한다 — 모든 위임 호출에 명시하라
- 서로 독립적인 작업은 병렬로 위임한다

**브리프 기준:**
- Advisor가 이미 파악한 컨텍스트를 브리프에 동봉해 Worker가 재탐색하지 않게 하라 (브리프 품질이 전부다)
- 파일 경로, 프로젝트 컨벤션, 완료 기준(통과해야 할 게이트)을 포함하라
- key_box 특유 함정을 해당 시 명시: `flutter test` 동시 실행 금지(SQLite BusyException — 한 번에 하나) · Drift 스키마 변경 후 `dart run build_runner build --delete-conflicting-outputs` · `pumpAndSettle()`은 무한 애니메이션에서 타임아웃 · sqlcipher/sqlite3 flutter_libs 동시 사용 금지

**경계:**
- **Worker의 완료 보고를 그대로 믿지 마라.** Advisor가 diff와 테스트로 직접 확인한 뒤 승인하라. "이탈 없음" 보고와 실제 diff가 다른 사례가 실재한다.
- 검증 실패는 수정 브리프로 재위임하라. 직접 수정은 사소한 마무리에만 허용된다
- 한두 줄 수정·즉답 조회처럼 위임 오버헤드가 더 큰 작업은 직접 처리해도 된다

### 검증 규율 — "테스트 그린 ≠ 앱 작동"

- DoD(완료 기준) = `dart analyze` 0건 + `flutter test` 전건 green + (UI·네이티브·라우팅 변경 시) `flutter build macos --debug` 성공. 테스트가 못 보는 결함(네이티브 의존·entitlements·창 관리)은 실빌드가 잡는다.
- 증거 없이 완료 선언 금지 — 진실원천은 `.claude/rules/common/verification-discipline.md`(자동 로드). 이 절은 포인터다.
- 게이트를 새로 만들면 **뮤테이션으로 실증하라**: 결함을 일부러 주입해 게이트가 RED가 되는 것을 확인한 뒤 채택한다(통과만 확인한 게이트는 장식이다).

### git 규율

- **커밋·푸시는 사용자가 명시 지시할 때만.** Claude 커밋은 트레일러 2종(Co-Authored-By·Claude-Session)을 함께 동봉 — commit-msg 훅이 완전성을 강제한다.
- 훅 우회(`--no-verify`)는 동등한 검증을 로컬에서 직접 완주했을 때만 쓰고, GHA 서버측 결과로 이중 확인하라.
- 대규모 미커밋 WIP가 있으면 새 작업 변경과 얽지 마라 — 추가형 파일로 분리하고 커밋 단위를 사용자가 고를 수 있게 하라.

### 판단·보고 원칙

- **기계적 정합 금지**: 주변과 맞춘다는 이유만으로 편집하지 마라. 논리적으로 옳고 최적일 때만 편집한다.
- 서브에이전트가 준 줄번호·수치·주장은 직접 검증 후 사용한다.
- **정직 보고**: 실패는 출력과 함께 실패라고, 생략은 생략이라고 말한다. 문서·README의 현재 상태 서술은 과장 없이 사실만(정직 배너 문화 — 한계를 아는 것이 읽기의 출발점).

### 문서 원칙 — 포인터, 복제 금지

- CLAUDE.md는 네비게이션이다. 상세 규율의 진실원천은 `.claude/rules/`·`docs/`의 해당 파일이며, **내용을 여기에 복제하지 마라**(이중화가 드리프트를 낳는다). 새 규율이 생기면 진실원천 파일을 만들고 여기엔 포인터만 추가한다.

---

## Architecture Map

이 프로젝트의 `.claude/` 프레임워크 구성요소와 관계:

```
CLAUDE.md (진입점, 항상 로드)
│
├── Rules (9개, 자동 로드) ─── 필수 준수 규칙 (간결, 원칙 중심)
│   ├── flutter/   architecture.md, widgets-and-state.md, safety.md
│   ├── common/    code-standards.md, context-management.md,
│   │              git-workflow.md, skill-enforcement.md, verification-discipline.md
│   └── testing/   testing.md
│
├── Standards (3개, 수동 참조) ─── 상세 구현 패턴 (코드 예시 풍부)
│   ├── flutter-architecture.md   # Riverpod, Drift, GoRouter, 암호화 패턴
│   ├── flutter-widgets.md        # 위젯, 테마, 폼, 접근성, macOS 특화
│   └── flutter-testing.md        # flutter_test, mocktail, ProviderContainer
│
├── Agents (14개) ─── 전문가 역할 (Task tool로 호출)
│   ├── quality/   code-review-expert, security-expert,
│   │              data-integrity-expert, performance-expert
│   ├── domain/    ui-ux-expert
│   ├── workflow/  planner
│   ├── utility/   doc-updater
│   └── business/  market-researcher, product-manager, designer,
│                  backend-ops, qa-engineer, marketer, data-analyst
│
├── Skills (19+ 커스텀 + 7 Flutter + 외부) ─── 실행 가능 스킬
│   └── See `.claude/skills/README.md`
│
├── Workflows (5개) ─── 팀 작업 템플릿
│   ├── feature-development.md      # 단독 기능 개발 5단계
│   └── teams/
│       ├── feature-dev-team.md     # 팀 기반 기능 개발
│       ├── review-team.md          # 팀 기반 코드 리뷰
│       ├── debugging-team.md       # 팀 기반 디버깅
│       └── full-lifecycle-team.md  # 10역할 제품 라이프사이클
│
└── Commands (10개) ─── 사용자 단축 명령 (/로 호출)
```

### Rules 조건부 로딩 (paths)

도메인별 rules는 `paths:` frontmatter로 조건부 로딩됨:
- `flutter/architecture.md` → `lib/core/**`, `lib/features/**`, `lib/services/**`
- `flutter/widgets-and-state.md` → `lib/features/**/presentation/**`, `lib/features/**/domain/**`
- `flutter/safety.md` → `lib/**`
- `testing/testing.md` → `test/**`
- `common/*.md` → paths 없이 항상 로드 (모든 파일에 적용)

### Rules vs Standards — 이중 체계

| 구분 | Rules | Standards |
|------|-------|-----------|
| **로딩** | 자동 (매 세션) | 수동 (필요 시 참조) |
| **분량** | 간결 (원칙 중심) | 상세 (코드 예시 풍부) |
| **역할** | "반드시 따라야 하는 핵심 원칙" | "구현 시 참조하는 상세 패턴" |
| **충돌 시** | **Rules 우선** | Standards는 Rules에 종속 |

**Standards 참조 시점**:
- `flutter-architecture.md` → Provider, Drift DAO, GoRouter, 암호화 구현 시
- `flutter-widgets.md` → 화면, 위젯, 테마, 폼, macOS 특화 작업 시
- `flutter-testing.md` → 테스트 스위트 작성 시

---

## Development Workflow — 의사결정 트리

> ⚠️ **Deprecated (2026-07)** — 라우팅 정본은 상단 "AI 개발 도구 스택" 절. 이 절은 참고용.

### 작업 시작 시 판단 흐름

```
작업 요청 수신
├── 1줄 오타/설정 수정? → 직접 수정 (스킬 면제)
├── 새 기능 개발?
│   ├── Small (5줄 이하) → 직접 구현
│   ├── Medium → /plan → /tdd → /verify
│   └── Large (Multi-Phase) → /plan → feature-dev-team 워크플로우
├── 버그 수정?
│   ├── 명확한 원인 → bugfix 스킬
│   └── 복잡/3회 실패 → parallel-debugging 스킬
├── 리팩토링? → code-review → 수정 → /verify
├── UI 작업? → flutter-expert + flutter-adaptive-ui
└── PR 준비? → /verify (full) → commit → PR
    ↓
[도메인 감지] → 해당 Standard 자동 READ (도메인별 자동 라우팅 테이블 참조)
```

### 기능 개발 Phase 흐름

```
Phase 0: 계획 (/plan)
  ↓ Quality Gate 통과
Phase 1-N: TDD 구현 (/tdd per phase)
  ↓ Quality Gate 통과 (매 Phase)
최종: 검증 (/verify) → 마무리 (/wrap-up)
```

### Commands Quick Reference

> ⚠️ **Deprecated (2026-07)** — 라우팅 정본은 상단 "AI 개발 도구 스택" 절. 이 절은 참고용.

```
/plan          — 기능 계획 수립 (Manus 스타일 파일 기반)
/tdd           — TDD 워크플로우 (RED → GREEN → REFACTOR)
/verify        — 5단계 검증 (빌드, 분석, 테스트, 품질, Git)
/checkpoint    — 진행 상태 저장/검증/조회
/update-docs   — 문서 동기화
/wrap-up       — 작업 마무리 (교훈 추출 + 커밋)
/bridge        — Drawbridge UI 주석 처리
/verify-rules  — 프로젝트 규칙 준수 검증
/manage-rules  — 검증 스킬 생성/업데이트
/skills-manage — 외부 스킬 관리
```

---

## Key Rules Summary (Always-Loaded)

9개 Rules 파일의 핵심 요약. 상세 내용은 각 파일 참조.

### Flutter Architecture (architecture.md)

**설계 패턴 선택**:
- 복잡한 상태 전이 (3+ 상태) → StateNotifier + Sealed Class
- 단순 on/off 상태 → StateProvider
- DB CRUD 조합 → DAO 메서드 + FutureProvider
- 위젯 80줄+ → 별도 위젯으로 추출
- 3+ Provider 조합 → 중간 Provider로 합성

**계층 분리**: Presentation → Domain → Data. 의존성은 항상 안쪽(Data) 방향.
- Presentation: UI 렌더링, 사용자 입력, 내비게이션
- Domain: 비즈니스 상태 관리 (StateNotifier, Provider)
- Data: DB 쿼리 (Drift DAO), 암호화 서비스

**Riverpod 규칙**:
- `ref.watch()` in build, `ref.read()` in callbacks
- build()에서 ref.read() 금지, 콜백에서 ref.watch() 금지
- Provider 정의: `camelCase` + `Provider` 접미사

### Widgets & State (widgets-and-state.md)

**Widget 선택**: ConsumerWidget (상태 없음) vs ConsumerStatefulWidget (TextController, FocusNode 등)
- `dispose()`에서 반드시 Controller/FocusNode/Timer cleanup
- const 생성자 가능하면 항상 사용
- Key: `ValueKey`/`ObjectKey` (인덱스 단독 금지)
- `AsyncValue.when(data:, loading:, error:)` 패턴
- 접근성: `Semantics`, `tooltip`, 터치 타겟 44x44

### Safety (safety.md)

- 마스터 키 메모리에만 보유, 디스크 저장 절대 금지
- 복호화 값 로깅 금지 (`debugPrint`로 컨텍스트만)
- Drift 파라미터화 쿼리만 (문자열 보간 SQL 금지)
- 클립보드 30초 후 자동 삭제
- `Uint8List` 민감 데이터 사용 후 0으로 덮어쓰기

### Testing (testing.md)

- `flutter_test` + `mocktail`, in-memory Drift DB
- `ProviderContainer` + `overrides:` 패턴
- Coverage: Encryption 100%, Auth 100%, Providers 80%, Widgets 60%
- `pumpAndSettle()` 타임아웃 주의 (무한 애니메이션 = 타임아웃)
- `sleep` 금지 → `pump()` / `pumpAndSettle()` 사용

### Common (code-standards + verification-discipline + skill-enforcement)

**코드 품질**:
- 메서드 20줄, 클래스 200줄, 조건문 깊이 3단계, 파라미터 5개 최대
- Early return 활용, Magic Number 금지 (상수 사용)
- 네이밍: `camelCase` 변수/함수, `PascalCase` 클래스, `_` 접두사 private

**검증 규율**:
- 증거 없이 완료 선언 금지 (Evidence before claims, always)
- 6단계: 명령어 식별 → 새로 실행 → 출력 확인 → 일치 확인 → 증거 첨부 → 재검증
- "아마 될 것입니다" → 중단 후 명령어 실행으로 확인

**스킬 강제 호출**: 적용 가능한 스킬이 있으면 반드시 호출 (면제: 1줄 수정, 순수 탐색, 사용자 명시 면제)

---

## Skill Routing Guide

> ⚠️ **Deprecated (2026-07)** — 라우팅 정본은 상단 "AI 개발 도구 스택" 절. 이 절은 참고용.

### 작업 유형별 핵심 스킬

| 작업 유형 | 필수 스킬 | 비고 |
|----------|----------|------|
| 새 기능 시작 | `/plan` | 5줄 이하 면제 |
| 기능 구현 | `implement` + `flutter-architecture` | Phase 0 설계 합의 필수 |
| 버그 수정 | `bugfix` | 근본 원인 추적 의무 |
| 리팩토링 | `code-review` → 수정 → `/verify` | |
| 테스트 추가 | `/tdd` + `flutter-testing` | RED→GREEN→REFACTOR |
| 위젯/UI | `flutter-expert` + `flutter-adaptive-ui` | |
| Riverpod 상태 | `flutter-riverpod-expert` | Provider 패턴 준수 |
| Drift DB | `dart-drift` | 테이블/DAO/마이그레이션 |
| 보안 점검 | `security-audit` | PR 전 또는 주기적 |
| PR 전 검증 | `/verify` (전체 5단계) | |
| 작업 완료 | `/wrap-up` | 교훈 추출 + 커밋 |

### 워크플로우별 스킬 조합

**새 기능 개발**: `flutter-architecture` → `dart-drift` → `flutter-riverpod-expert` → `flutter-testing` → `doc-sync`

**코드 품질 검수**: `code-review` (통합) 또는 개별 (`security-audit` + `performance-check`)

**팀 기반 개발**: `parallel-feature-development` + `dispatching-parallel-agents` + `team-communication-protocols`

### 도메인별 자동 라우팅

| 도메인 | 감지 키워드 | 스킬 | 에이전트 | Standard (자동 READ) |
|--------|-----------|------|---------|---------------------|
| **Widget/UI** | 위젯, 화면, 스크린, UI, Theme, 접근성, 애니메이션 | `flutter-expert` `flutter-adaptive-ui` `flutter-animations` | ui-ux-expert | `flutter-widgets.md` |
| **Architecture** | Provider, Notifier, 아키텍처, 상태관리, Riverpod, GoRouter | `flutter-architecture` `flutter-riverpod-expert` | planner, code-review-expert | `flutter-architecture.md` |
| **Database** | Drift, DAO, 테이블, 쿼리, SQLCipher, 마이그레이션 | `dart-drift` | data-integrity-expert | `flutter-architecture.md` |
| **Security** | 암호화, 보안, 마스터키, AES, 복호화, encryption | `security-audit` | security-expert | `flutter-architecture.md` |
| **Testing** | 테스트, 커버리지, TDD, mocktail, flutter_test | `/tdd` `flutter-testing` | qa-engineer | `flutter-testing.md` |
| **Performance** | 성능, 리빌드, const, select, 메모리 | `performance-check` | performance-expert | `flutter-architecture.md` |

---

## Agent Roles

> ⚠️ **Deprecated (2026-07)** — 라우팅 정본은 상단 "AI 개발 도구 스택" 절. 이 절은 참고용. (14 에이전트 · Full Lifecycle Team 등 Agent Teams 관련 내용 포함)

14개 전문가 에이전트. Task tool로 호출하여 병렬 리뷰 가능.

### 기술 에이전트 (quality + domain + workflow + utility)

| 에이전트 | 역할 | 팀 역할 | 핵심 관심사 |
|---------|------|---------|-----------|
| **code-review-expert** | 코드 품질 리뷰 | code-reviewer | 아키텍처, DRY, 복잡도 |
| **security-expert** | 보안 취약점 분석 | security-reviewer | 암호화, SQLCipher, 키 관리 |
| **data-integrity-expert** | 데이터 정합성 검증 | data-reviewer | Drift 트랜잭션, 스키마 무결성 |
| **performance-expert** | 성능 최적화 | performance-reviewer | 위젯 리빌드, const, Riverpod select |
| **ui-ux-expert** | UI/UX 품질 | frontend-dev | 접근성, Material 3, 애니메이션 |
| **planner** | 기능 설계 | architect | 계획 수립, 리스크 평가 |
| **doc-updater** | 문서 관리 | docs-writer | 코드맵, 문서-코드 동기화 |

### 비즈니스 에이전트 (business) — Full Lifecycle Team용

| 에이전트 | 역할 | 팀 역할 | Wave |
|---------|------|---------|------|
| **market-researcher** | 시장조사, 경쟁사 분석 | market-researcher | 1 |
| **data-analyst** | 이벤트 트래킹, KPI 설계 | data-analyst | 1 |
| **product-manager** | PRD 작성, 태스크 분해 | product-manager | 2 |
| **designer** | UI/UX 디자인, 디자인 시스템 | designer | 2 |
| **backend-ops** | 인프라, 모니터링, 배포 | backend-ops | 3 |
| **qa-engineer** | 테스트 전략, 커버리지 | qa-engineer | 4 |
| **marketer** | 런칭 전략, ASO, 콘텐츠 | marketer | 5 |

### 에이전트 활용 시점

| 시점 | 호출할 에이전트 |
|------|---------------|
| 기능 설계 단계 | planner |
| PR 전 코드 리뷰 | code-review-expert + security-expert (병렬) |
| 성능 문제 의심 | performance-expert |
| DB 마이그레이션 | data-integrity-expert |
| UI 컴포넌트 리뷰 | ui-ux-expert |
| 기능 완료 후 문서화 | doc-updater |
| 대형 기능 시장조사 | market-researcher + data-analyst |
| 제품 기획 | product-manager |
| UI/UX 디자인 | designer |
| 런칭 준비 | marketer |

### 팀 워크플로우별 에이전트 배치

| 워크플로우 | 참여 에이전트 |
|-----------|-------------|
| **review-team** | code-review-expert + security-expert + performance-expert + data-integrity-expert |
| **feature-dev-team** | planner + 구현 에이전트들 (Phase별 배치) |
| **debugging-team** | 원인 도메인별 전문가 투입 |
| **full-lifecycle-team** | 10역할 5 Wave 순차 배치 (시장조사→기획→구현→품질→런칭) |

---

## Workflow Templates

> ⚠️ **Deprecated (2026-07)** — 라우팅 정본은 상단 "AI 개발 도구 스택" 절. 이 절은 참고용.

5개 워크플로우 템플릿. 팀 기반 작업 시 `.claude/workflows/` 참조.

| 워크플로우 | 파일 | 사용 시점 |
|-----------|------|----------|
| **feature-development** | `workflows/feature-development.md` | 단독 기능 개발 (5단계 프로세스) |
| **feature-dev-team** | `workflows/teams/feature-dev-team.md` | Medium+ 스코프, 팀 병렬 개발 |
| **review-team** | `workflows/teams/review-team.md` | PR 전 전문가 병렬 리뷰 |
| **debugging-team** | `workflows/teams/debugging-team.md` | 복잡 버그, 경쟁 가설 병렬 조사 |
| **full-lifecycle-team** | `workflows/teams/full-lifecycle-team.md` | 대형 기능, 시장조사~런칭 전과정 |

### 워크플로우 선택 기준

```
작업 규모 판단
├── Small (1-2 파일, 1 Phase) → 단독 개발 (워크플로우 없이)
├── Medium (3-5 파일, 2-3 Phase) → feature-development (단독)
├── Large (6+ 파일, 4+ Phase) → feature-dev-team (팀)
├── X-Large (새 제품/대형 기능 런칭) → full-lifecycle-team (10역할)
└── 버그 수정
    ├── 단순 (원인 명확) → bugfix 스킬
    └── 복잡 (3회+ 실패) → debugging-team
```

### Agent Teams 인프라

- **가이드**: `.claude/docs/agent-teams-guide.md`
- **훅**: TeammateIdle (테스트 자동 실행), TaskCompleted (rubocop + 테스트)
- **관련 스킬**: dispatching-parallel-agents, parallel-feature-development, parallel-debugging, team-communication-protocols

---

## Quality Gates

### 기계적 강제 — lefthook + GHA CI (2026-07)
- **lefthook 하네스**(`lefthook.yml` · 설치 `lefthook install` 1회): pre-commit=`dart format --set-exit-if-changed`+`flutter analyze` / commit-msg=Claude 트레일러 완전성(`.lefthook/commit-msg-trailers`) / pre-push=`flutter test`. 우회 = `git <cmd> --no-verify` 또는 `LEFTHOOK=0 git <cmd>`.
- **GHA CI**(`.github/workflows/ci.yml` · runs-on macos-14): push·PR마다 `flutter pub get → flutter analyze → flutter test`. 포맷 게이트는 CI에서 제외(현재 포맷 드리프트 — 적색 방지).

### Phase-Based TDD
- 각 Phase는 독립적 RED/GREEN/REFACTOR 사이클
- Phase 간 전환 시 Quality Gate 필수 통과
- Quality Gate 실패 상태에서 다음 Phase 진행 금지

### Quality Gate (Phase 간 체크포인트)
1. `flutter build macos --debug` — 빌드 통과
2. `flutter test` — 전체 테스트 통과
3. `dart analyze` — 정적 분석 통과
4. TDD 준수 — 테스트가 구현보다 먼저 작성됨

### Test Coverage Targets
| 영역 | 최소 커버리지 |
|------|-------------|
| Encryption (core/encryption/) | 100% |
| Auth (features/auth/domain/) | 100% |
| Database (core/database/) | 80% |
| Providers (features/*/domain/) | 80% |
| Widgets (features/*/presentation/) | 60% |
| Services (services/) | 70% |

---

## Development Environment

### Available Tools
- **Agents** (14): code-review-expert, security-expert, data-integrity-expert, performance-expert, planner, ui-ux-expert, doc-updater + business/ (7개)
- **Commands** (10): /plan, /tdd, /verify, /checkpoint, /update-docs, /wrap-up, /skills-manage, /bridge, /verify-rules, /manage-rules
- **Skills** (26+): 7 Flutter (`flutter-expert`, `flutter-riverpod-expert`, `dart-drift`, `flutter-architecture`, `flutter-testing`, `flutter-adaptive-ui`, `flutter-animations`) + 19 기존
- **Rules** (9): Flutter (3), Common (5), Testing (1)
- **Standards** (3): flutter-architecture, flutter-widgets, flutter-testing
- **Workflows** (5): feature-development, feature-dev-team, review-team, debugging-team, full-lifecycle-team

---

## Gotchas — Flutter 프로젝트 핵심 주의사항

### Flutter/Dart 관련
- **Drift 코드 생성**: 테이블/DAO 변경 후 `dart run build_runner build --delete-conflicting-outputs` 필수
- **sqlcipher_flutter_libs vs sqlite3_flutter_libs**: 둘 다 SQLite 번들 → 충돌. SQLCipher 사용 시 `sqlite3_flutter_libs` 제거
- **macOS deployment target**: Podfile + project.pbxproj 모두 일치 필수
- **pointycastle GCM**: `getOutputSize()`는 최대 버퍼 크기. 실제 길이는 `processBytes() + doFinal()` 반환값 합
- **pumpAndSettle 타임아웃**: 무한 애니메이션(CircularProgressIndicator) 있으면 타임아웃 → `pump()` 사용
- **dogfood 재빌드**: 실앱 테스트 전 반드시 `scripts/dogfood.sh` — "소스 수정 ≠ 바이너리 재빌드" (2026-07-17 스테일 빌드로 이미 고친 버그가 실앱에서 재보고된 사고)

### Hook 관련
- **PreCompact는 차단 불가** — exit 2를 반환해도 압축은 진행됨. 저장만 가능
- **Stop hook 무한루프** — Stop hook에서 도구를 호출하면 무한루프. `stop_hook_active` 가드 필수
- **Hook exit code 의미**: 0=허용, 1=비차단 에러(경고만), 2=차단(PreToolUse만 유효)
- **PostToolUse `Edit|Write` hook**: `.dart` 파일에서만 `dart fix --apply` 실행

### Agent/Skill 관련
- **`npx skills add` symlink 구조** — `.agents/skills/`가 원본, `.claude/skills/` 등은 symlink
- **AUTOCOMPACT 80%** — 기본 95%보다 80%에서 시작하면 요약 품질이 향상

### Pencil (deprecated 2026-07-12 — 참조 전용)
Pencil MCP는 전역 해제됨(`~/.claude.json`). `key_box_pensil.pen` + `docs/_archive/design-system/`은 V8 디자인 시스템 참조 아카이브로 **보존만**(편집 안 함). 신규 디자인은 Figma MCP 사용. (과거 Pencil 작업 교훈은 memory에 참조용으로 남김.)

---

## Context Management Best Practices (Anthropic 공식)

- `/clear` — 무관한 작업 간 전환 시 컨텍스트 리셋
- `/compact <지시>` — 특정 주제에 집중하여 압축
- Subagent 활용 — 탐색/조사는 subagent에 위임
- 2회 이상 수정 실패 시 → `/clear` 후 더 구체적인 프롬프트로 재시작

---

## Work Style & Session Rules (Insights 기반)

### 세션 이어가기
- 이전 세션/계획에서 이어질 때, 파일 재읽기/재계획 없이 **즉시 계획 실행 시작**

### 작업 방식
- 이슈를 **하나씩 세심하게** 처리. 하나의 변경 완료 → 검증 → 다음으로 이동

### 계획 수립
- 새 계획 전에 **기존 계획 문서/참조 자료 확인** (Obsidian vault, `docs/`)

### Shell/Bash 안전 수칙
- 심링크 의존성 확인 없이 `rm -rf` 금지
- `INPUT=$(cat)` 패턴으로 **stdin을 변수에 저장**

---

## Referenced Documents

@.claude/docs/agent-teams-guide.md
@.claude/skills/README.md

---

## Project-Specific Notes
- Rails→Flutter 마이그레이션 완료 (2026-03-03): Phase 0-3 완료, 102+ 테스트 통과. `.claude/` 프레임워크 전체 Flutter용으로 전환.
- Rails 아카이브: `.claude/rules/_archived-rails/`, `.claude/standards/_archived-rails/` — 참조용 보존
- Flutter Skills 설치 (2026-03-03): 7개 Flutter 스킬 설치 (`flutter-expert`, `flutter-riverpod-expert`, `dart-drift`, `flutter-architecture`, `flutter-testing`, `flutter-adaptive-ui`, `flutter-animations`)
- Obsidian MCP 연동: `claude-code-mcp` 플러그인. Vault: `key_box/docs/`
- 디자인 정본 전환 (2026-07-12): Pencil MCP 전역 해제(`~/.claude.json` mcpServers + `~/.claude/settings.json` 권한) → **Figma + shadcn MCP + ui-ux-pro-max**. `key_box_pensil.pen`·`docs/_archive/design-system/`은 V8 참조 아카이브로 보존.
- docs/ 지층 재편 (2026-07-17): 과정 산출물을 `docs/_archive/`로 격리 (rails-reference·V8 design-system·디자인 과정문서·리뷰 리포트·완료 계획·개인 노트). 최상위 = 정본만.
