# key_box

## Project Overview
- **Project**: key_box
- **Framework**: Ruby on Rails
- **Language**: Ruby, JavaScript (Stimulus), HTML (ERB), CSS (Tailwind)

---

## Architecture Map

이 프로젝트의 `.claude/` 프레임워크 구성요소와 관계:

```
CLAUDE.md (진입점, 항상 로드)
│
├── Rules (10개, 자동 로드) ─── 필수 준수 규칙 (간결, 원칙 중심)
│   ├── backend/   architecture.md, model-and-errors.md, safety.md
│   ├── frontend/  frontend.md
│   ├── common/    code-standards.md, context-management.md,
│   │              git-workflow.md, skill-enforcement.md, verification-discipline.md
│   └── testing/   testing.md
│
├── Standards (3개, 수동 참조) ─── 상세 구현 패턴 (코드 예시 풍부)
│   ├── rails-backend.md        # 백엔드 상세 패턴
│   ├── tailwind-frontend.md    # Tailwind/Stimulus 상세 패턴
│   └── testing.md              # 테스트 상세 패턴
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
├── Skills (19개 커스텀 + 외부) ─── 실행 가능 스킬 (키워드 자동 감지)
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

도메인별 rules는 `paths:` frontmatter로 조건부 로딩됨. 해당 파일 작업 시에만 활성화되어 컨텍스트 효율 향상:
- `backend/*.md` → `app/models/**`, `app/controllers/**`, `app/services/**`, `db/migrate/**`
- `frontend/frontend.md` → `app/views/**`, `app/javascript/**`, `app/assets/**`
- `testing/testing.md` → `test/**`
- `common/*.md` → paths 없이 항상 로드 (모든 파일에 적용)

### Rules vs Standards — 이중 체계

| 구분 | Rules | Standards |
|------|-------|-----------|
| **로딩** | 자동 (매 세션) | 수동 (필요 시 참조) |
| **분량** | 간결 (원칙 중심) | 상세 (코드 예시 풍부) |
| **역할** | "반드시 따라야 하는 핵심 원칙" | "구현 시 참조하는 상세 패턴" |
| **충돌 시** | **Rules 우선** | Standards는 Rules에 종속 |
| **파일 수** | 10개 (총 ~1,500줄) | 3개 (총 ~1,900줄) |

**Standards 참조 시점**:
- `rails-backend.md` → 모델, 컨트롤러, 서비스 작성 시
- `tailwind-frontend.md` → UI 컴포넌트, Stimulus 컨트롤러 작성 시
- `testing.md` → 테스트 스위트 작성 시

---

## Development Workflow — 의사결정 트리

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
├── UI 작업? → ui-ux-pro-max + ui-component
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

```
/plan          — 기능 계획 수립 (Manus 스타일 파일 기반)
/tdd           — TDD 워크플로우 (RED → GREEN → REFACTOR)
/verify        — 6단계 검증 (빌드, 린트, 테스트, 보안)
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

10개 Rules 파일의 핵심 요약. 상세 내용은 각 파일 참조.

### Backend (architecture + model-and-errors + safety)

**설계 패턴 선택**:
- 컨트롤러 10줄+ → Service Object (`.call` + Result 객체)
- 2+ 모델 동시 저장 → Form Object
- 복합 쿼리 (JOIN, 3+ 조건) → Query Object
- View 조건 분기 3+ → Presenter/Decorator

**계층 분리**: Controller → Service → Model → DB. 의존성은 항상 안쪽(Model) 방향.
- Controller: HTTP 파싱, 인증/인가, 응답 형식만
- Service: 비즈니스 프로세스 조율, 트랜잭션
- Model: 데이터 무결성, 유효성, 관계, 스코프만

**모델 규칙**:
- 선언 순서: 상수 → Concerns → Associations → Validations → Callbacks → Scopes → Methods
- `dependent:` 필수, 콜백 최대 3개 (데이터 무결성 관련만)
- 길이 제한 필수 (`validates :bio, length: { maximum: 500 }`)
- Enum: `prefix: true` 사용

**에러 처리**:
- rescue는 실패 메서드 내부 (컨트롤러 액션 전체 감싸기 금지)
- 구체적 예외만 rescue (bare `rescue => e` 금지)
- 보조 데이터 실패 → 로그 + 계속, 핵심 데이터 실패 → 에러 표시

**보안**:
- SQL injection: 항상 파라미터화 쿼리, `params.permit!` 절대 금지
- XSS: `raw`/`html_safe` 금지, `sanitize` 또는 자동 이스케이핑 사용
- IDOR: `current_user.posts.find(params[:id])` — 소유권 확인 필수
- N+1: `includes`/`joins` 필수, `User.all` 금지 (페이지네이션 필수)
- 세션: 로그인 시 `reset_session` 필수 (Session Fixation 방지)

### Frontend (frontend.md)

**Stimulus**:
- 1 컨트롤러 = 1 관심사, `disconnect()`에서 반드시 cleanup
- 선언 순서: targets → values → classes → 상수 → 라이프사이클 → Actions → Callbacks → Private → Getters
- 전역 변수 금지: `window.*` 대신 Stimulus values 사용
- XSS: `innerHTML` 금지 → `textContent` 또는 Turbo Stream

**접근성 (CRITICAL)**:
- 터치 타겟 최소 44x44px, 모바일 본문 최소 16px
- `aria-label` (아이콘 버튼), `for`/`id` (폼 라벨) 필수
- 색상 대비: 일반 텍스트 4.5:1, 큰 텍스트 3:1
- `focus-visible:ring-2` (포커스 링 제거 금지)

**Tailwind**:
- Mobile-first (`flex flex-col md:flex-row`)
- `@apply` 금지, `dvh` (not `h-screen`), `size-6` (not `h-6 w-6`)
- 간격: `space-y-N` 시리즈 (혼합 `mb-2`/`mb-4` 금지)

### Testing (testing.md)

- Minitest + fixtures, BCrypt `cost: 4` (테스트 속도)
- 커버리지: 모델/인증 100%, 서비스/컨트롤러 80%, 시스템 테스트 60%
- `sleep` 금지 → `wait:` 옵션 사용
- ESC 키: `document.dispatchEvent` 사용 (`send_keys(:escape)` 금지)
- Stimulus 타이밍: `assert_selector "[data-controller='x']", wait: 5`
- Turbo Stream 후 요소 재참조 (Stale Element 방지)

### Common (code-standards + verification-discipline + skill-enforcement)

**코드 품질**:
- 메서드 20줄, 클래스 200줄, 조건문 깊이 3단계, 파라미터 4개 최대
- Early return 활용, Magic Number 금지 (상수 사용)
- 디미터 법칙: 최대 1단계 체이닝 (`delegate` 활용)
- 네이밍: `snake_case` 변수/메서드, `CamelCase` 클래스, 축약 금지

**검증 규율**:
- 증거 없이 완료 선언 금지 (Evidence before claims, always)
- 6단계: 명령어 식별 → 새로 실행 → 출력 확인 → 일치 확인 → 증거 첨부 → 재검증
- "아마 될 것입니다" → 중단 후 명령어 실행으로 확인

**스킬 강제 호출**: 적용 가능한 스킬이 있으면 반드시 호출 (면제: 1줄 수정, 순수 탐색, 사용자 명시 면제)

---

## Skill Routing Guide

### 작업 유형별 핵심 스킬

| 작업 유형 | 필수 스킬 | 비고 |
|----------|----------|------|
| 새 기능 시작 | `/plan` | 5줄 이하 면제 |
| 기능 구현 | `implement` (rails-resource, service-object 등) | Phase 0 설계 합의 필수 |
| 버그 수정 | `bugfix` | 근본 원인 추적 의무 |
| 리팩토링 | `code-review` → 수정 → `/verify` | |
| 테스트 추가 | `/tdd` 또는 `test-gen` | RED→GREEN→REFACTOR |
| UI 작업 | `ui-ux-pro-max` + `ui-component` | |
| Rails 리소스 | `rails-resource` (자동 라우팅) | 모델/컨트롤러/뷰/테스트 |
| 보안 점검 | `security-audit` | PR 전 또는 주기적 |
| PR 전 검증 | `/verify` (전체 6단계) | |
| 작업 완료 | `/wrap-up` | 교훈 추출 + 커밋 |

### 워크플로우별 스킬 조합

**새 기능 개발**: `rails-resource` → `test-gen` → `stimulus-controller` → `ui-component` → `doc-sync`

**코드 품질 검수**: `code-review` (통합) 또는 개별 (`security-audit` + `performance-check` + `database-maintenance`)

**UI 개선**: `bridge` (UI 주석) → `ui-ux-pro-max` (디자인 시스템) → `ui-component` (컴포넌트)

**팀 기반 개발**: `parallel-feature-development` + `dispatching-parallel-agents` + `team-communication-protocols`

전체 스킬 목록 및 결정 가이드: `.claude/skills/README.md`

### 도메인별 자동 라우팅

작업 유형 결정 후, 요청의 **도메인 키워드**를 감지하여 해당 도메인의 전체 툴킷을 활성화한다.

| 도메인 | 감지 키워드 | 스킬 | 에이전트 | Standard (자동 READ) |
|--------|-----------|------|---------|---------------------|
| **Frontend** | UI, 화면, 컴포넌트, Stimulus, Tailwind, 접근성, 반응형, 디자인 | `ui-ux-pro-max` `ui-component` `stimulus-controller` | ui-ux-expert | `tailwind-frontend.md` |
| **Backend** | 모델, 컨트롤러, 서비스, API, 마이그레이션, 라우트, 비즈니스 로직 | `rails-resource` `service-object` `query-object` `rails-dev` | planner, code-review-expert | `rails-backend.md` |
| **Database** | 데이터베이스, DB, 쿼리, 인덱스, N+1, 트랜잭션, 성능 최적화 | `database-maintenance` `query-object` `performance-check` | data-integrity-expert, performance-expert | `rails-backend.md` |
| **Security** | 보안, 취약점, XSS, CSRF, SQL injection, 인증, 인가 | `security-audit` | security-expert | `rails-backend.md` |
| **Testing** | 테스트, 커버리지, TDD, fixture, 시스템 테스트 | `test-gen` `/tdd` | code-review-expert | `testing.md` |
| **Quality** | 리뷰, 리팩토링, 코드 품질, 클린 코드 | `code-review` `performance-check` | code-review-expert, performance-expert | `rails-backend.md` |

**적용 규칙**:
1. 도메인 감지 시 → 해당 Standard 파일을 **즉시 READ**하여 상세 패턴 참조
2. 복수 도메인 감지 시 (예: "모델 + 테스트") → 관련 Standard 모두 READ
3. 에이전트는 팀 워크플로우 또는 리뷰 시 활성화 (단독 작업 시 선택적)

---

## Agent Roles

14개 전문가 에이전트. Task tool로 호출하여 병렬 리뷰 가능.

### 기술 에이전트 (quality + domain + workflow + utility)

| 에이전트 | 역할 | 팀 역할 | 핵심 관심사 |
|---------|------|---------|-----------|
| **code-review-expert** | 코드 품질 리뷰 | code-reviewer | 아키텍처, DRY, 복잡도 |
| **security-expert** | 보안 취약점 분석 | security-reviewer | OWASP, SQL Injection, XSS, CSRF |
| **data-integrity-expert** | 데이터 정합성 검증 | data-reviewer | Race Condition, 트랜잭션, 동시성 |
| **performance-expert** | 성능 최적화 | performance-reviewer | N+1, 캐싱, 인덱스, 페이지네이션 |
| **ui-ux-expert** | UI/UX 품질 | frontend-dev | 접근성, 터치, 반응형, Tailwind |
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

### Phase-Based TDD
- 각 Phase는 독립적 RED/GREEN/REFACTOR 사이클
- Phase 간 전환 시 Quality Gate 필수 통과
- Quality Gate 실패 상태에서 다음 Phase 진행 금지

### Quality Gate (Phase 간 체크포인트)
1. `bin/rails runner "puts 'OK'"` — 빌드 통과
2. `bin/rails test` — 전체 테스트 통과
3. `bundle exec rubocop` — 린트 통과
4. TDD 준수 — 테스트가 구현보다 먼저 작성됨
5. 수동 테스트 — Phase 기능 동작 확인

### Test Coverage Targets
| 영역 | 최소 커버리지 |
|------|-------------|
| 모델 (Validations/Associations) | 100% |
| 인증/결제 | 100% |
| 서비스 객체 | 80% |
| 컨트롤러 | 80% |
| 시스템 테스트 | 60% |

### Risk-First Planning
- 새 기능 계획 시 Risk Assessment 포함
- Probability x Impact 매트릭스
- Phase별 Rollback 전략 문서화

---

## Development Environment

### Available Tools
- **Agents** (14): code-review-expert, security-expert, data-integrity-expert, performance-expert, planner, ui-ux-expert, doc-updater + business/ (market-researcher, product-manager, designer, backend-ops, qa-engineer, marketer, data-analyst)
- **Commands** (10): /plan, /tdd, /verify, /checkpoint, /update-docs, /wrap-up, /skills-manage, /bridge, /verify-rules, /manage-rules
- **Skills** (19+): See `.claude/skills/README.md` for full list
- **Rules** (10): Backend (3), Frontend (1), Common (5), Testing (1)
- **Standards** (3): rails-backend, tailwind-frontend, testing
- **Workflows** (5): feature-development, feature-dev-team, review-team, debugging-team, full-lifecycle-team

---

## Gotchas — 자칫 실수할 수 있는 공식 문서 핵심 사항

### Hook 관련
- **PreCompact는 차단 불가** — exit 2를 반환해도 압축은 진행됨. 저장만 가능
- **Stop hook 무한루프** — Stop hook에서 도구를 호출하면 무한루프. `stop_hook_active` 가드 필수
- **Hook exit code 의미**: 0=허용, 1=비차단 에러(경고만), 2=차단(PreToolUse만 유효)
- **Hook 입력은 stdin JSON** — `jq -r '.tool_input.command'`로 파싱. `$1`이 아님
- **PostToolUse matcher 문법** — `Edit|Write` (정규식), `Bash` (단일 도구명)

### Permissions 관련
- **`Read(.env)` 문법** — 파일 경로는 프로젝트 루트 기준 상대 경로
- **deny > ask > allow** — 우선순위: deny가 최우선. 같은 패턴이 allow와 deny에 있으면 deny
- **`settings.local.json`** — 프로젝트 설정보다 높은 우선순위. 반드시 `.gitignore`에 포함

### Agent/Skill 관련
- **`permissionMode: plan`** — 에이전트가 read-only 모드로 시작. Edit/Write/Bash 불가
- **`memory: project`** — 프로젝트별 영속 메모리. `.claude/memory/` 디렉토리에 저장
- **`disable-model-invocation: true`** — AI가 자동으로 스킬 트리거하는 것 방지 (부작용 스킬용)
- **`model: opus|sonnet|haiku`** — 명시하지 않으면 부모 모델 상속. 비용 관리에 중요
- **`npx skills add` symlink 구조** — `.agents/skills/`가 원본, `.claude/skills/` 등은 symlink. 원본 디렉토리 삭제 시 모든 symlink 깨짐. 정리 시 반드시 원본→대상 복사 후 삭제

### Context 관련
- **AUTOCOMPACT 80%** — 기본 95%보다 80%에서 시작하면 요약 품질이 향상
- **SessionStart 4개 matcher** — `startup`, `resume`, `clear`, `compact`. 각각 다른 시점
- **`/compact <지시>`** — 지시 없이 compact하면 중요 컨텍스트 유실 위험

---

## Context Management Best Practices (Anthropic 공식)

- `/clear` — 무관한 작업 간 전환 시 컨텍스트 리셋
- `/compact <지시>` — 특정 주제에 집중하여 압축 (예: `/compact API 변경에 집중`)
- Subagent 활용 — 탐색/조사는 subagent에 위임하여 메인 컨텍스트 보존
- 2회 이상 수정 실패 시 → `/clear` 후 더 구체적인 프롬프트로 재시작
- Rules `paths:` — 도메인별 rules가 조건부 로딩되어 컨텍스트 효율 자동 최적화

---

## Work Style & Session Rules (Insights 기반, 2026-03-01)

130개 세션 분석에서 도출된 실증적 행동 규칙.

### 세션 이어가기
- 이전 세션/계획에서 이어질 때, 파일 재읽기/재계획/계획 모드 종료 시도 없이 **즉시 계획 실행 시작**
- 진정으로 막힌 경우에만 명확화 요청

### 작업 방식
- 이슈를 **하나씩 세심하게** 처리. 모든 것을 한꺼번에 처리하려 하지 말 것
- 하나의 변경 완료 → 검증 → 다음으로 이동

### 계획 수립
- 새 계획/디자인 방향 만들기 전에 **기존 계획 문서/디자인 문서/참조 자료 확인** (Obsidian vault, `docs/`, `planning/`)
- 기존 계획을 따르고 새로 만들지 말 것

### Pencil MCP 안전 수칙
1. 색상 일괄 작업 후 **rgba/알파 보존 확인** (replace_all_matching_properties는 알파를 제거함)
2. 변수 참조는 **Dark vs Light 모드에서 다르게 해석** — 화면 프레임에 테마 설정 확인
3. 화면 누락 주장 전 **캔버스 위치 확인** (y=8700 같은 높은 오프셋일 수 있음)

### Shell/Bash 안전 수칙
- 파일/디렉토리 삭제 시 먼저 **심링크가 가리키고 있는지 확인**
- 심링크 의존성 확인 없이 `rm -rf` 금지
- 여러 명령에 파이핑 전 `INPUT=$(cat)` 패턴으로 **stdin을 변수에 저장**

### 설정/연동 작업
- 수동 지시 대신 **설정 파일을 직접 조작**
- 파일 복사만이 아닌 **End-to-End 작동 검증** 필수

---

## Referenced Documents

@.claude/docs/agent-teams-guide.md
@.claude/skills/README.md

---

## Project-Specific Notes
- bkit 플러그인 비활성화 (2026-02-23): 프로젝트 자체 프레임워크(agents/commands/skills/rules)와 충돌. `.claude/settings.json`에서 `false` 처리.
- ui-ux-pro-max 도입 (2026-02-23): frontend-design 스킬 교체. BM25 검색 엔진 + 24 CSV 데이터셋 + 3 Python 스크립트. 소스: nextlevelbuilder/ui-ux-pro-max-skill.
- Superpowers 참조 (2026-02-23): 신규 프로젝트에서 커스텀 프레임워크 구축 전 obra/superpowers 플러그인 권장. 설치: `/plugin marketplace add obra/superpowers-marketplace` → `/plugin install superpowers@superpowers-marketplace`.
- find-skills 설치 (2026-02-24): skills.sh (Vercel Labs) 마켓플레이스 검색 스킬. 기존 skillsmp-search(SkillsMP 대상)와 공존. `npx skills add`는 5개 디렉토리에 동시 설치하나, `.claude/skills/`만 유지 (2026-02-26 정리 완료). **주의**: `.agents/`가 원본, 나머지는 symlink — 원본 삭제 시 전부 깨짐. 재설치 후 symlink→실제 파일 교체 필요. `skills-lock.json`은 스킬 버전 lock 파일로 반드시 커밋.
- Obsidian MCP 연동 (2026-02-24): `claude-code-mcp` v1.1.8 (iansinnott) 플러그인으로 Obsidian vault 연결. SSE transport `http://localhost:22360/sse`. Vault: `key_box/docs/` (프로젝트 내부, 2026-02-26 이전). 도구 7개 (get_workspace_files, get_current_file, view, create, str_replace, insert, obsidian_api) 검증 완료. `.obsidian/workspace.json` 및 `plugins/*/data.json`은 `.gitignore` 처리.
- Hook 안정성 강화 (2026-02-26): 5개 신규 hook 추가 (compact/PreCompact/Stop/Notification/PostToolUseFailure). stdin 소비 문제 발견 — `jq` 다중 호출 시 `INPUT=$(cat)` 패턴 필수. Read deny 규칙으로 시크릿 노출 차단. 에이전트 14개 전부 model 명시 (opus 5, sonnet 9). AUTOCOMPACT 80%.
