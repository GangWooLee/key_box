# Claude Skills

이 디렉토리는 이 프로젝트를 위한 커스텀 Claude Skills를 포함합니다.

---

## 🎯 Quick Decision Guide: 언제 어떤 스킬을 사용할까?

### 작업 유형별 스킬 선택

| 작업 유형 | 사용할 스킬 | 명령어 예시 |
|-----------|-------------|-------------|
| **새 모델/리소스 생성** | `rails-resource` | "Notification 모델 생성해줘" |
| **테스트 추가** | `test-gen` | "User 모델에 테스트 추가해줘" |
| **API 엔드포인트** | `api-endpoint` | "Posts API 엔드포인트 만들어줘" |
| **복잡한 비즈니스 로직** | `service-object` | "결제 로직을 서비스로 분리해줘" |
| **복잡한 검색/필터** | `query-object` | "고급 검색 쿼리 객체 만들어줘" |
| **백그라운드 작업** | `background-job` | "이메일을 백그라운드로 보내줘" |
| **UI 컴포넌트** | `ui-component` | "알림 카드 컴포넌트 만들어줘" |
| **인터랙션 추가** | `stimulus-controller` | "드롭다운 인터랙션 추가해줘" |
| **UI 개선/디자인** | `ui-ux-pro-max` | "랜딩 페이지 예쁘게 만들어줘" |
| **UI 주석 처리** | `bridge` | `/bridge` 또는 `/bridge yolo` |
| **문서 동기화** | `doc-sync` | "DATABASE.md 업데이트해줘" |
| **DB 헬스 체크** | `database-maintenance` | "데이터베이스 상태 확인해줘" |
| **보안 감사** | `security-audit` | "보안 취약점 스캔해줘" |
| **성능 분석** | `performance-check` | "N+1 쿼리 찾아줘" |
| **통합 코드 리뷰** | `code-review` | "전체 코드 검수해줘" |
| **규칙 준수 검증** | `verify-implementation` | "프로젝트 규칙 준수 검증해줘" |
| **검증 스킬 관리** | `manage-skills` | "검증 스킬 업데이트해줘" |
| **로깅 시스템** | `logging-setup` | "프로덕션 로깅 설정해줘" |
| **Rails 전문 조언** | `rails-dev` | "Rails 아키텍처 조언해줘" |

### 워크플로우별 스킬 조합

#### 🚀 새 기능 개발 워크플로우
```
1. rails-resource    → 모델, 컨트롤러, 뷰 생성
2. test-gen          → 테스트 추가
3. stimulus-controller → 인터랙션 추가
4. ui-component      → UI 컴포넌트 스타일링
5. doc-sync          → 문서 업데이트
```

#### 🔍 코드 품질 검수 워크플로우
```
1. code-review           → 통합 코드 검수 (권장)
   또는 개별 실행:
   - security-audit      → 보안 검사
   - performance-check   → 성능 분석
   - database-maintenance → DB 상태 확인
2. verify-implementation → 프로젝트 규칙 준수 검증
```

#### 🎨 UI 개선 워크플로우
```
1. bridge (Drawbridge) → 브라우저에서 UI 주석 생성
2. ui-ux-pro-max     → 데이터 기반 디자인 시스템 생성
3. ui-component       → 컴포넌트 일관성
```

#### 🤝 팀 기반 개발 워크플로우
```
1. parallel-feature-development → 기능 Phase 병렬 분배
2. parallel-debugging           → 경쟁 가설 병렬 조사
3. dispatching-parallel-agents  → 병렬 에이전트 오케스트레이션
4. team-communication-protocols → 팀원 간 구조화된 통신
```

**팀 템플릿**: `.claude/workflows/teams/` (feature-dev, review, debugging)
**가이드**: `.claude/docs/agent-teams-guide.md`

#### 📦 배포 전 체크리스트
```
1. test-gen          → 테스트 커버리지 확인
2. code-review       → 통합 검수
3. logging-setup     → 로깅 설정 확인
4. doc-sync          → 문서 최신화
```

---

## 📁 관련 문서

### Standards (코드 품질 기준)
개발 시 준수해야 할 규칙들입니다. 스킬 실행 시 자동으로 참조됩니다.

| 문서 | 내용 | 언제 참조? |
|------|------|-----------|
| [standards/rails-backend.md](../standards/rails-backend.md) | Rails 백엔드 규칙 | 모델, 컨트롤러 작업 시 |
| [standards/tailwind-frontend.md](../standards/tailwind-frontend.md) | Tailwind/Stimulus 규칙 | UI 작업 시 |
| [standards/testing.md](../standards/testing.md) | 테스트 표준 | 테스트 작성 시 |

### Workflows (작업 프로세스)
복잡한 작업의 단계별 프로세스입니다.

| 문서 | 내용 | 언제 사용? |
|------|------|-----------|
| [workflows/feature-development.md](../workflows/feature-development.md) | 기능 개발 5단계 | 새 기능 구현 시 |

---

## 📦 Available Skills

### Backend Skills

#### 1. rails-resource
**완전한 Rails 리소스 생성 (모델, 컨트롤러, 뷰, 테스트)**

프로젝트의 기존 패턴을 따라 새로운 리소스를 빠르게 생성합니다.

- **Trigger keywords**: "create model", "add feature", "generate resource", "build system"
- **Includes**: Migration, Model, Controller, Views, Tests, Fixtures
- **Pattern matching**: Tailwind CSS, Enum i18n, Counter caches, Authorization
- **Scripts**: `generate_resource.rb` - Automated resource generation

#### 2. test-gen
**포괄적인 Minitest 테스트 스위트 생성**

빈 테스트 파일을 실용적인 테스트 스위트로 변환합니다.

- **Trigger keywords**: "add tests", "test coverage", "write tests for", "generate tests"
- **Includes**: Model tests, Controller tests, Realistic fixtures
- **Coverage goals**: Core models 90%+, Feature models 85%+
- **Scripts**:
  - `run_tests.sh` - Test runner with coverage analysis
  - `generate_fixtures.rb` - Automatic fixture generation

#### 3. api-endpoint
**JSON API 엔드포인트 생성 (인증 및 버전 관리 포함)**

RESTful JSON API를 빠르게 생성하고 인증을 추가합니다.

- **Trigger keywords**: "create API", "add endpoint", "JSON response", "API for mobile"
- **Includes**: API controller, Authentication, Serialization, Error handling
- **Features**: Token-based auth, Versioning (v1, v2), CORS support
- **Response format**: `{ data: {}, meta: {} }`

#### 4. background-job ✨ **NEW!**
**비동기 작업 처리 (Solid Queue 사용)**

백그라운드 작업을 위한 Job 클래스를 생성합니다.

- **Trigger keywords**: "send email in background", "process async", "create job", "schedule task"
- **Includes**: Job class, Error handling, Retry logic, Queue configuration
- **Use cases**: Email sending, Notifications, Data processing, Scheduled cleanup
- **Features**: Queue priorities, Monitoring dashboard

#### 5. service-object ✨ **NEW!**
**복잡한 비즈니스 로직 분리**

Fat Controller/Model을 Service Object로 리팩토링합니다.

- **Trigger keywords**: "extract logic", "create service", "business logic", "refactor controller"
- **Includes**: Service class, Error collection, Transaction safety
- **Use cases**: User registration, Payment processing, Data import, Multi-model operations
- **Patterns**: Result object, Error handling, Chainable methods

#### 6. query-object ✨ **NEW!**
**복잡한 데이터베이스 쿼리 관리**

복잡하고 재사용 가능한 쿼리를 Query Object로 추출합니다.

- **Trigger keywords**: "complex query", "search", "filter posts", "advanced search", "query builder"
- **Includes**: Query class, Chainable filters, Performance optimization
- **Use cases**: Advanced search, Multi-filter queries, Analytics, Reporting
- **Features**: Eager loading, Counter caches, Batch processing

### DevOps & Maintenance Skills

#### 7. logging-setup
**프로덕션급 로그 시스템 구축**

구조화된 로깅, 성능 모니터링, 에러 추적을 위한 완전한 로깅 시스템을 자동으로 설정합니다.

- **Trigger keywords**: "setup logging", "add logging", "log management", "monitoring", "track errors"
- **Includes**: Lograge (JSON), Business logger, Performance tracking, Error tracking (Sentry)
- **Use cases**: Production monitoring, Performance analysis, Error debugging, Audit logging
- **Scripts**: `setup_logging.rb` - Full automated setup (9 steps)
- **Features**: Log rotation, Custom loggers, Request/Job tracking, Structured JSON output

#### 8. database-maintenance 🆕 **NEW!**
**데이터베이스 유지보수 및 헬스 체크**

마이그레이션 안전성, 데이터 정합성, 인덱스 최적화 등 데이터베이스 유지보수 작업을 수행합니다.

- **Trigger keywords**: "check database", "optimize DB", "migration rollback", "data consistency", "database health"
- **Includes**: Migration safety, Data integrity checks, Index optimization, Health monitoring
- **Use cases**: Pre-deployment checks, Data validation, Performance optimization, Database recovery
- **Scripts**: `health_check.rb` - Comprehensive database health check
- **Features**: Orphaned records detection, Counter cache validation, Missing index identification

#### 9. security-audit 🆕 **NEW!**
**보안 취약점 스캔 및 감사**

보안 취약점 자동 감지, 의존성 검사, 환경 변수 관리 등 애플리케이션 보안 감사를 수행합니다.

- **Trigger keywords**: "check security", "audit code", "security vulnerabilities", "update gems", "CVE check"
- **Includes**: Brakeman scan, Bundler-audit, Secret exposure check, Security headers
- **Use cases**: Pre-deployment security, Vulnerability scanning, Dependency updates, Compliance
- **Scripts**: `security_audit.rb` - Full security audit runner
- **Features**: SQL injection detection, XSS prevention, CSRF protection, Mass assignment checks

#### 10. performance-check 🆕 **NEW!**
**성능 모니터링 및 최적화**

N+1 쿼리 감지, 느린 쿼리 분석, 메모리 프로파일링 등 성능 최적화 작업을 수행합니다.

- **Trigger keywords**: "performance issue", "slow queries", "N+1 problem", "optimize performance", "memory leak"
- **Includes**: N+1 detection, Missing indexes, Query optimization, Caching strategies
- **Use cases**: Performance bottleneck identification, Query optimization, Memory profiling
- **Scripts**: `performance_check.rb` - Performance analysis and recommendations
- **Features**: Bullet integration, Index analysis, Counter cache detection, Eager loading suggestions

#### 11. code-review 🆕 **NEW!**
**통합 코드 검수 및 프로젝트 건강 상태 확인**

프로젝트 전체에 대한 체계적인 코드 리뷰, 충돌 감지, 안정성 검증을 수행합니다.
기존 security-audit, performance-check, database-maintenance skills를 통합합니다.

- **Trigger keywords**: "review code", "check project", "audit codebase", "health check", "find issues", "code quality"
- **Includes**: Model/Controller/Database/Security/Performance 통합 검수
- **Use cases**: 배포 전 검수, 기능 개발 후 안정성 확인, 정기 코드 리뷰
- **Scripts**: `full_review.rb` - 통합 코드 검수 자동화
- **Features**: 심각도별 이슈 분류, 체크리스트 기반 검수, 다른 스킬과 연동

#### 18. verify-implementation
**프로젝트 규칙 준수 통합 검증**

등록된 모든 `verify-*` 스킬을 순차 실행하여 프로젝트 규칙 준수 여부를 자동 검증합니다.

- **Trigger keywords**: "verify rules", "check conventions", "rule compliance", "검증 실행"
- **Includes**: 순차 실행, 통합 보고서, 자동 수정, Before/After 재검증
- **Use cases**: 기능 구현 후, PR 전, 코드 리뷰 중, 규칙 감사
- **Related**: `/verify-rules` 커맨드, `manage-skills` 스킬

### Skill Management

#### 19. manage-skills
**검증 스킬 자동 생성 및 업데이트**

세션 변경사항(git diff)을 분석하여 검증 스킬의 커버리지 드리프트를 탐지하고 자동 생성/업데이트합니다.

- **Trigger keywords**: "manage skills", "update verify skills", "skill coverage", "검증 스킬 관리"
- **Includes**: git diff 분석, CREATE/UPDATE 결정 트리, 3개 파일 동기화
- **Use cases**: 새 패턴 도입 후, verify 스킬 정비, PR 전 커버리지 확인
- **Related**: `/manage-rules` 커맨드, `verify-implementation` 스킬

### Frontend Skills

#### 20. ui-component
**Tailwind UI 컴포넌트 생성 (프로젝트 디자인 시스템 준수)**

프로젝트의 Tailwind 테마를 사용한 재사용 가능한 UI 컴포넌트를 생성합니다.

- **Trigger keywords**: "create component", "add UI element", "make button/card/form"
- **Components**: Buttons, Cards, Forms, Badges, Modals
- **Includes**: Responsive design, Accessibility, Tailwind patterns
- **Project patterns**: Color variables, Spacing, Typography

#### 21. stimulus-controller
**Stimulus 컨트롤러 생성 (Turbo 통합)**

인터랙티브 UI를 위한 Stimulus 컨트롤러를 빠르게 생성합니다.

- **Trigger keywords**: "add interaction", "make it interactive", "create stimulus controller"
- **Includes**: Controller file, Data attributes, Turbo integration
- **Common patterns**: Modal, Tab, Dropdown, Toggle, Form validation

#### 22. ui-ux-pro-max
**데이터 기반 디자인 인텔리전스 (BM25 검색 엔진)**

67개 스타일, 97개 팔레트, 57개 폰트 페어링, 100개 UX 가이드라인을 BM25 검색으로 추천합니다.

- **Trigger keywords**: "frontend design", "beautiful UI", "예쁘게", "디자인 개선", "design system"
- **Design intelligence**: BM25 search across 24 CSV datasets (styles, colors, typography, UX, charts, stacks)
- **Industry reasoning**: 100 reasoning rules for automatic style matching
- **Scripts**: `search.py` (CLI), `core.py` (BM25 engine), `design_system.py` (generator)
- **Source**: [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)

### Rails Expert Skills 🆕 **NEW CATEGORY!**

#### 23. rails-dev
**Rails 개발 통합 스킬 라우터 (13개 전문 스킬)**

복잡한 Rails 작업을 적합한 전문가 스킬로 라우팅합니다.

- **Trigger keywords**: "rails expert", "rails architect", "rails security", "rails api", "rails testing"
- **Includes**: 13개 전문 스킬 (testing, security, api, graphql, devops, business-logic 등)
- **Features**: 자동 스킬 선택, TDD 강제, 보안 기본 설계
- **Source**: [alec-c4/claude-skills-rails-dev](https://github.com/alec-c4/claude-skills-rails-dev)

**주요 하위 스킬**:
- `rails-testing`: Minitest/RSpec 전문가
- `rails-security`: Pundit, Lockbox, 보안 전문가
- `rails-api`: RESTful API 전문가
- `rails-graphql`: GraphQL 전문가
- `rails-devops`: Kamal, Docker 전문가
- `rails-business-logic`: Service Object 전문가
- `rails-project-manager`: 프로젝트 조율 전문가

### UI Workflow Skills

#### 24. bridge
**Drawbridge UI 주석 처리 자동화**

브라우저에서 Drawbridge 확장 프로그램으로 생성한 UI 주석을 코드로 변환합니다.

- **Trigger keywords**: "bridge", "drawbridge", "moat tasks", "process UI", "UI annotations"
- **Modes**: Step (증분), Batch (그룹), YOLO (자동)
- **Includes**: 스크린샷 로드, 의존성 분석, 상태 관리, 프레임워크 감지
- **Files**: `moat-tasks.md`, `moat-tasks-detail.json`, `.moat/screenshots/`
- **Reference**: [reference/workflow.md](bridge/reference/workflow.md) - 상세 워크플로우

**Usage**:
```bash
/bridge          # Step 모드 (기본)
/bridge batch    # Batch 모드
/bridge yolo     # YOLO 모드
```

### Documentation Skills

#### 25. doc-sync
**코드 변경사항으로 문서 자동 동기화**

코드베이스 변경사항을 `.claude/` 문서에 자동으로 반영합니다.

- **Trigger keywords**: "update docs", "sync documentation", "docs out of date"
- **Updates**: DATABASE.md, API.md, TASKS.md, ARCHITECTURE.md
- **Auto-detection**: 파일 변경 → 문서 매핑 자동 감지
- **Scripts**:
  - `sync_database_docs.rb` - DATABASE.md 자동 생성
  - `sync_api_docs.sh` - API.md 자동 생성

## 🎯 Usage

### In Claude Code CLI
스킬은 자동으로 감지되고 적절한 키워드에 반응합니다:

```
You: Create a Notification model with user references and content
Claude: [rails-resource skill activates automatically]

You: Add tests for the User model
Claude: [test-gen skill activates automatically]

You: Update the database documentation
Claude: [doc-sync skill activates automatically]
```

### Manual Skill Execution
스크립트를 직접 실행할 수도 있습니다:

```bash
# Generate a new resource
ruby .claude/skills/rails-resource/scripts/generate_resource.rb Article title:string content:text

# Run tests with coverage
bash .claude/skills/test-gen/scripts/run_tests.sh all

# Sync documentation
ruby .claude/skills/doc-sync/scripts/sync_database_docs.rb
bash .claude/skills/doc-sync/scripts/sync_api_docs.sh

# Setup logging system
ruby .claude/skills/logging-setup/scripts/setup_logging.rb

# Database health check
ruby .claude/skills/database-maintenance/scripts/health_check.rb

# Security audit
ruby .claude/skills/security-audit/scripts/security_audit.rb

# Performance check
ruby .claude/skills/performance-check/scripts/performance_check.rb
```

## 📁 Structure

Each skill follows the official Anthropic skills structure:

```
skill-name/
├── SKILL.md              # Main skill definition (<500 lines)
├── reference/            # Detailed reference documentation
│   └── *.md
├── examples/             # Code examples and patterns
│   └── *.md
└── scripts/              # Executable automation scripts
    └── *.{rb,sh}
```

## 🔧 Development

### Best Practices
이 스킬들은 [Anthropic Skills Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)를 따릅니다:

- ✅ **Progressive disclosure**: Main files are concise, details in separate files
- ✅ **Workflow checklists**: Task tracking for complex operations
- ✅ **Concise instructions**: Assumes Claude knows Rails basics
- ✅ **Project-adaptable**: Follow the current codebase's patterns
- ✅ **Executable scripts**: Automation where possible

### Updating Skills
스킬을 수정할 때:

1. SKILL.md는 200줄 미만으로 유지
2. 상세 내용은 reference/examples 디렉토리로 분리
3. 실행 가능한 스크립트 제공 (가능한 경우)
4. 명확한 트리거 키워드 포함
5. 프로젝트 패턴과 일관성 유지

## 📚 References

- [Official Anthropic Skills Repo](https://github.com/anthropics/skills)
- [Agent Skills Documentation](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Best Practices Guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

## 📊 Statistics

| Skill | Type | SKILL.md Lines | Additional Files | Scripts |
|-------|------|----------------|------------------|---------|
| rails-resource | Backend | 192 | 4 reference docs | 1 generator |
| test-gen | Backend | 189 | 3 example docs | 2 utilities |
| api-endpoint | Backend | ~200 | - | - |
| background-job | Backend | ~220 | - | - |
| service-object | Backend | ~280 | - | - |
| query-object | Backend | ~260 | - | - |
| logging-setup | DevOps | ~260 | - | 1 automation |
| database-maintenance | Maintenance | ~310 | - | 1 health check |
| security-audit | Maintenance | ~390 | - | 1 audit runner |
| performance-check | Maintenance | ~420 | - | 1 analyzer |
| code-review | Quality | ~200 | 3 reference docs | 1 full review |
| ui-component | Frontend | ~200 | 5 reference docs + 2 examples | - |
| stimulus-controller | Frontend | ~180 | 2 examples | - |
| ui-ux-pro-max | Frontend | ~350 | 24 CSV datasets | 3 Python scripts |
| rails-dev | Rails Expert | ~220 | - | - |
| bridge | UI Workflow | ~150 | 1 reference doc | - |
| verify-implementation | Quality | ~230 | - | - |
| manage-skills | Skill Management | ~290 | - | - |
| doc-sync | Documentation | 226 | - | 2 sync scripts |
| **Total** | **19 skills** | **~4,767** | **44 files (20 docs + 24 CSV)** | **13 scripts** |

## 🎯 Skill Coverage

### Backend (35%)
- ✅ Resource generation (rails-resource)
- ✅ Testing (test-gen)
- ✅ API development (api-endpoint)
- ✅ Background jobs (background-job)
- ✅ Business logic (service-object)
- ✅ Complex queries (query-object)

### DevOps (6%)
- ✅ Logging system (logging-setup)

### Maintenance (18%)
- ✅ Database maintenance (database-maintenance)
- ✅ Security audit (security-audit)
- ✅ Performance check (performance-check)

### Quality (11%)
- ✅ Code review (code-review) - 통합 코드 검수
- ✅ Rule verification (verify-implementation) - 프로젝트 규칙 준수 검증

### Skill Management (5%)
- ✅ Skill maintenance (manage-skills) - 검증 스킬 자동 생성/업데이트

### Frontend (18%)
- ✅ UI components (ui-component)
- ✅ Interactivity (stimulus-controller)
- ✅ Design intelligence (ui-ux-pro-max) - 데이터 기반 디자인 시스템

### Rails Expert (6%) 🆕 **NEW CATEGORY!**
- ✅ Rails development router (rails-dev) 🆕 **NEW!** - 13개 전문 스킬 라우터

### UI Workflow (6%)
- ✅ Drawbridge integration (bridge) - UI 주석 자동 처리

### Documentation (6%)
- ✅ Doc synchronization (doc-sync)

---

**Last Updated**: 2026-02-23
**Project**: key_box
**Claude Skills Version**: 8.0.0
**Total Skills**: 19 (6 Backend + 1 DevOps + 3 Maintenance + 2 Quality + 1 Skill Management + 3 Frontend + 1 Rails Expert + 1 UI Workflow + 1 Documentation)
