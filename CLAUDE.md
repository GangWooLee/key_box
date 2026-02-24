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
├── Agents (7개) ─── 전문가 역할 (Task tool로 호출)
│   ├── quality/   code-review-expert, security-expert,
│   │              data-integrity-expert, performance-expert
│   ├── domain/    ui-ux-expert
│   ├── workflow/  planner
│   └── utility/   doc-updater
│
├── Skills (19개 커스텀 + 외부) ─── 실행 가능 스킬 (키워드 자동 감지)
│   └── See `.claude/skills/README.md`
│
├── Workflows (4개) ─── 팀 작업 템플릿
│   ├── feature-development.md      # 단독 기능 개발 5단계
│   └── teams/
│       ├── feature-dev-team.md     # 팀 기반 기능 개발
│       ├── review-team.md          # 팀 기반 코드 리뷰
│       └── debugging-team.md       # 팀 기반 디버깅
│
└── Commands (10개) ─── 사용자 단축 명령 (/로 호출)
```

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

---

## Agent Roles

7개 전문가 에이전트. Task tool로 호출하여 병렬 리뷰 가능.

| 에이전트 | 역할 | 팀 역할 | 핵심 관심사 |
|---------|------|---------|-----------|
| **code-review-expert** | 코드 품질 리뷰 | code-reviewer | 아키텍처, DRY, 복잡도 |
| **security-expert** | 보안 취약점 분석 | security-reviewer | OWASP, SQL Injection, XSS, CSRF |
| **data-integrity-expert** | 데이터 정합성 검증 | data-reviewer | Race Condition, 트랜잭션, 동시성 |
| **performance-expert** | 성능 최적화 | performance-reviewer | N+1, 캐싱, 인덱스, 페이지네이션 |
| **ui-ux-expert** | UI/UX 품질 | frontend-dev | 접근성, 터치, 반응형, Tailwind |
| **planner** | 기능 설계 | architect | 계획 수립, 리스크 평가 |
| **doc-updater** | 문서 관리 | docs-writer | 코드맵, 문서-코드 동기화 |

### 에이전트 활용 시점

| 시점 | 호출할 에이전트 |
|------|---------------|
| 기능 설계 단계 | planner |
| PR 전 코드 리뷰 | code-review-expert + security-expert (병렬) |
| 성능 문제 의심 | performance-expert |
| DB 마이그레이션 | data-integrity-expert |
| UI 컴포넌트 리뷰 | ui-ux-expert |
| 기능 완료 후 문서화 | doc-updater |

### 팀 워크플로우별 에이전트 배치

| 워크플로우 | 참여 에이전트 |
|-----------|-------------|
| **review-team** | code-review-expert + security-expert + performance-expert + data-integrity-expert |
| **feature-dev-team** | planner + 구현 에이전트들 (Phase별 배치) |
| **debugging-team** | 원인 도메인별 전문가 투입 |

---

## Workflow Templates

4개 워크플로우 템플릿. 팀 기반 작업 시 `.claude/workflows/` 참조.

| 워크플로우 | 파일 | 사용 시점 |
|-----------|------|----------|
| **feature-development** | `workflows/feature-development.md` | 단독 기능 개발 (5단계 프로세스) |
| **feature-dev-team** | `workflows/teams/feature-dev-team.md` | Medium+ 스코프, 팀 병렬 개발 |
| **review-team** | `workflows/teams/review-team.md` | PR 전 전문가 병렬 리뷰 |
| **debugging-team** | `workflows/teams/debugging-team.md` | 복잡 버그, 경쟁 가설 병렬 조사 |

### 워크플로우 선택 기준

```
작업 규모 판단
├── Small (1-2 파일, 1 Phase) → 단독 개발 (워크플로우 없이)
├── Medium (3-5 파일, 2-3 Phase) → feature-development (단독)
├── Large (6+ 파일, 4+ Phase) → feature-dev-team (팀)
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
- **Agents** (7): code-review-expert, security-expert, data-integrity-expert, performance-expert, planner, ui-ux-expert, doc-updater
- **Commands** (10): /plan, /tdd, /verify, /checkpoint, /update-docs, /wrap-up, /skills-manage, /bridge, /verify-rules, /manage-rules
- **Skills** (19+): See `.claude/skills/README.md` for full list
- **Rules** (10): Backend (3), Frontend (1), Common (5), Testing (1)
- **Standards** (3): rails-backend, tailwind-frontend, testing
- **Workflows** (4): feature-development, feature-dev-team, review-team, debugging-team

---

## Project-Specific Notes
- bkit 플러그인 비활성화 (2026-02-23): 프로젝트 자체 프레임워크(agents/commands/skills/rules)와 충돌. `.claude/settings.json`에서 `false` 처리.
- ui-ux-pro-max 도입 (2026-02-23): frontend-design 스킬 교체. BM25 검색 엔진 + 24 CSV 데이터셋 + 3 Python 스크립트. 소스: nextlevelbuilder/ui-ux-pro-max-skill.
- Superpowers 참조 (2026-02-23): 신규 프로젝트에서 커스텀 프레임워크 구축 전 obra/superpowers 플러그인 권장. 설치: `/plugin marketplace add obra/superpowers-marketplace` → `/plugin install superpowers@superpowers-marketplace`.
- find-skills 설치 (2026-02-24): skills.sh (Vercel Labs) 마켓플레이스 검색 스킬. 기존 skillsmp-search(SkillsMP 대상)와 공존. `npx skills add`는 `.agent/`, `.agents/`, `.claude/`, `.kiro/`, `.windsurf/` 5개 에이전트 디렉토리에 동시 설치. `skills-lock.json`은 스킬 버전 lock 파일로 반드시 커밋.
- Obsidian MCP 연동 (2026-02-24): `claude-code-mcp` v1.1.8 (iansinnott) 플러그인으로 Obsidian vault 연결. SSE transport `http://localhost:22360/sse`. Vault: `/Users/igangu/Documents/Obsidian Vault`. 도구 7개 (get_workspace_files, get_current_file, view, create, str_replace, insert, obsidian_api) 검증 완료. BRAT 불필요 — `community-plugins.json`에 ID 추가 + 파일 배치로 활성화.
