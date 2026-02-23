---
name: feature-planner
description: Creates phase-based feature plans with quality gates and incremental delivery structure. Use when planning features, organizing work, breaking down tasks, creating roadmaps, or structuring development strategy. Keywords: plan, planning, phases, breakdown, strategy, roadmap, organize, structure, outline.
---

# Feature Planner

## Purpose
Generate structured, phase-based plans where:
- Each phase delivers complete, runnable functionality
- Quality gates enforce validation before proceeding
- User approves plan before any work begins
- Progress tracked via markdown checkboxes
- Each phase is 1-4 hours maximum

## Planning Workflow

### Step 1: Requirements Analysis
1. Read relevant files to understand codebase architecture
2. Identify dependencies and integration points
3. Assess complexity and risks
4. Determine appropriate scope (small/medium/large)

### Step 2: Phase Breakdown with TDD Integration
Break feature into 3-7 phases where each phase:
- **Test-First**: Write tests BEFORE implementation
- Delivers working, testable functionality
- Takes 1-4 hours maximum
- Follows Red-Green-Refactor cycle
- Has measurable test coverage requirements
- Can be rolled back independently
- Has clear success criteria

**Phase Structure**:
- Phase Name: Clear deliverable
- Goal: What working functionality this produces
- **Test Strategy**: What test types, coverage target, test scenarios
- Tasks (ordered by TDD workflow):
  1. **RED Tasks**: Write failing tests first
  2. **GREEN Tasks**: Implement minimal code to make tests pass
  3. **REFACTOR Tasks**: Improve code quality while tests stay green
- Quality Gate: TDD compliance + validation criteria
- Dependencies: What must exist before starting
- **Coverage Target**: Specific percentage or checklist for this phase

### 마이크로 태스크 분해 (Phase 내부)

각 Phase를 2-5분 단위 Task로 세분화합니다. 이를 통해 진행 추적이 정밀해지고, Agent Teams 연동 시 teammate에게 Task 단위로 배분할 수 있습니다.

**Task 명세 필수 항목**:

| 항목 | 필수 | 설명 |
|------|------|------|
| 파일 경로 | ✅ | 생성/수정할 정확한 파일 경로 |
| 핵심 코드 | ✅ | 시그니처 + 핵심 로직 1-5줄 (의사코드 금지) |
| 테스트 파일 | ✅ | 대응하는 테스트 파일 경로 |
| 검증 명령 | ✅ | Task 완료 확인 명령어 |
| 완전한 구현 | ❌ | 전체 코드는 실행 시 작성 |

**Task 예시**:
```
Task 2.1 (3분): AcademySearchResult 모델 생성
  파일: app/models/academy_search_result.rb
  코드: class AcademySearchResult < ApplicationRecord
          belongs_to :user
          validates :query, presence: true
        end
  테스트: test/models/academy_search_result_test.rb
  검증: bin/rails test test/models/academy_search_result_test.rb
```

**Agent Teams 연동**: Task 단위로 teammate에게 배분 가능. 각 teammate는 자신의 파일 소유권 범위 내 Task만 수행.

### 배치 실행 프로토콜 (Phase 내부)

마이크로 태스크를 3개 단위 배치로 실행합니다.

1. 현재 배치의 3개 태스크 실행 (또는 Phase 내 잔여 태스크)
2. 각 태스크 완료 후 상태를 `completed`로 표시
3. 배치 완료 후 중간 보고:
   - 완료된 태스크 목록
   - 테스트 실행 결과 (`bin/rails test`)
   - 발견된 이슈 또는 계획 이탈 사항
4. 사용자 피드백 대기 (계속/수정/중단)
5. 피드백 반영 후 다음 배치 진행

**배치 크기 조정**: 사용자가 "빠르게" 또는 "멈추지 마" 요청 시 배치 크기를 Phase 전체로 확대.

### 병렬 실행 전략 (Agent Teams)

독립적인 태스크는 순차가 아닌 병렬로 실행:

**병렬 가능 조건** (모두 충족 시):
- 태스크 간 파일 소유권이 겹치지 않음
- 태스크 간 데이터 의존성 없음
- 각 태스크가 독립적으로 검증 가능

**예시**:
```
# 병렬 가능
Task 2.1: User 모델 테스트 (teammate-A)
Task 2.2: Post 모델 테스트 (teammate-B)

# 병렬 불가 — Post가 User에 의존
Task 3.1: User 서비스 구현 (먼저)
Task 3.2: Post 서비스 구현 (3.1 완료 후)
```

**배치 확대**: 독립 태스크 3개 이상이면 teammate 수만큼 병렬. `run_in_background` 활용.

### Step 3: Plan Document Creation
Use plan-template.md to generate: `docs/plans/PLAN_<feature-name>.md`

Include:
- Overview and objectives
- Architecture decisions with rationale
- Complete phase breakdown with checkboxes
- Quality gate checklists
- Risk assessment table
- Rollback strategy per phase
- Progress tracking section
- Notes & learnings area

### Step 4: User Approval
**CRITICAL**: Use AskUserQuestion to get explicit approval before proceeding.

Ask:
- "Does this phase breakdown make sense for your project?"
- "Any concerns about the proposed approach?"
- "Should I proceed with creating the plan document?"

Only create plan document after user confirms approval.

### Step 5: Document Generation
1. Create `docs/plans/` directory if not exists
2. Generate plan document with all checkboxes unchecked
3. Add clear instructions in header about quality gates
4. Inform user of plan location and next steps

## Quality Gate Standards

Each phase MUST validate these items before proceeding to next phase:

**Build & Compilation**:
- [ ] Project builds/compiles without errors
- [ ] No syntax errors

**Test-Driven Development (TDD)**:
- [ ] Tests written BEFORE production code
- [ ] Red-Green-Refactor cycle followed
- [ ] Unit tests: ≥80% coverage for business logic
- [ ] Integration tests: Critical user flows validated
- [ ] Test suite runs in acceptable time (<5 minutes)

**Testing**:
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Test coverage maintained or improved

**Code Quality**:
- [ ] Linting passes with no errors
- [ ] Type checking passes (if applicable)
- [ ] Code formatting consistent

**Functionality**:
- [ ] Manual testing confirms feature works
- [ ] No regressions in existing functionality
- [ ] Edge cases tested

**Security & Performance**:
- [ ] No new security vulnerabilities
- [ ] No performance degradation
- [ ] Resource usage acceptable

**Documentation**:
- [ ] Code comments updated
- [ ] Documentation reflects changes

## Progress Tracking Protocol

Add this to plan document header:

```markdown
**CRITICAL INSTRUCTIONS**: After completing each phase:
1. ✅ Check off completed task checkboxes
2. 🧪 Run all quality gate validation commands
3. ⚠️ Verify ALL quality gate items pass
4. 📅 Update "Last Updated" date
5. 📝 Document learnings in Notes section
6. ➡️ Only then proceed to next phase

⛔ DO NOT skip quality gates or proceed with failing checks
```

## Phase Sizing Guidelines

**Small Scope** (2-3 phases, 3-6 hours total):
- Single component or simple feature
- Minimal dependencies
- Clear requirements
- Example: Add dark mode toggle, create new form component

**Medium Scope** (4-5 phases, 8-15 hours total):
- Multiple components or moderate feature
- Some integration complexity
- Database changes or API work
- Example: User authentication system, search functionality

**Large Scope** (6-7 phases, 15-25 hours total):
- Complex feature spanning multiple areas
- Significant architectural impact
- Multiple integrations
- Example: AI-powered search with embeddings, real-time collaboration

## Risk Assessment

Identify and document:
- **Technical Risks**: API changes, performance issues, data migration
- **Dependency Risks**: External library updates, third-party service availability
- **Timeline Risks**: Complexity unknowns, blocking dependencies
- **Quality Risks**: Test coverage gaps, regression potential

For each risk, specify:
- Probability: Low/Medium/High
- Impact: Low/Medium/High
- Mitigation Strategy: Specific action steps

## Rollback Strategy

For each phase, document how to revert changes if issues arise.
Consider:
- What code changes need to be undone
- Database migrations to reverse (if applicable)
- Configuration changes to restore
- Dependencies to remove

## Test Specification Guidelines

### Test-First Development Workflow

**For Each Feature Component**:
1. **Specify Test Cases** (before writing ANY code)
   - What inputs will be tested?
   - What outputs are expected?
   - What edge cases must be handled?
   - What error conditions should be tested?

2. **Write Tests** (Red Phase)
   - Write tests that WILL fail
   - Verify tests fail for the right reason
   - Run tests to confirm failure
   - Commit failing tests to track TDD compliance

3. **Implement Code** (Green Phase)
   - Write minimal code to make tests pass
   - Run tests frequently (every 2-5 minutes)
   - Stop when all tests pass
   - No additional functionality beyond tests

4. **Refactor** (Blue Phase)
   - Improve code quality while tests remain green
   - Extract duplicated logic
   - Improve naming and structure
   - Run tests after each refactoring step
   - Commit when refactoring complete

### Test Types

**Unit Tests**:
- **Target**: Individual functions, methods, classes
- **Dependencies**: None or mocked/stubbed
- **Speed**: Fast (<100ms per test)
- **Isolation**: Complete isolation from external systems
- **Coverage**: ≥80% of business logic

**Integration Tests**:
- **Target**: Interaction between components/modules
- **Dependencies**: May use real dependencies
- **Speed**: Moderate (<1s per test)
- **Isolation**: Tests component boundaries
- **Coverage**: Critical integration points

**End-to-End (E2E) Tests**:
- **Target**: Complete user workflows
- **Dependencies**: Real or near-real environment
- **Speed**: Slow (seconds to minutes)
- **Isolation**: Full system integration
- **Coverage**: Critical user journeys

### Test Coverage Calculation

**Coverage Thresholds** (standards/testing.md 기준):
- **모델 (Validations/Associations)**: 100%
- **인증/결제**: 100%
- **서비스 객체**: ≥80%
- **컨트롤러**: ≥80%
- **시스템 테스트**: ≥60%
- **헬퍼**: ≥50%

**Coverage Commands (Rails/Minitest)**:
```bash
# 전체 테스트
bin/rails test

# 시스템 테스트
bin/rails test:system

# 커버리지 측정 (SimpleCov 설정 시)
COVERAGE=true bin/rails test

# 특정 파일
bin/rails test test/models/user_test.rb

# 특정 테스트 (라인 번호)
bin/rails test test/models/user_test.rb:25

# 린트
bundle exec rubocop

# 빌드 확인
bin/rails runner "puts 'OK'"
```

### Common Test Patterns (Minitest)

**AAA 패턴 — Model Test**:
```ruby
class UserTest < ActiveSupport::TestCase
  fixtures :users

  test "should require unique email" do
    # Arrange
    existing = users(:one)
    duplicate = existing.dup

    # Act
    duplicate.email = existing.email.upcase

    # Assert
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end
end
```

**Controller Test — Integration Style**:
```ruby
class PostsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :posts

  setup do
    @user = users(:one)
    @post = posts(:one)
  end

  test "should create post when logged in" do
    log_in_as(@user)

    assert_difference "Post.count", 1 do
      post posts_url, params: {
        post: { title: "New Post", content: "Content" }
      }
    end

    assert_redirected_to post_url(Post.last)
  end

  test "should redirect create when not logged in" do
    post posts_url, params: { post: { title: "Test" } }
    assert_redirected_to login_url
  end
end
```

**Stubbing Dependencies**:
```ruby
class ExternalApiServiceTest < ActiveSupport::TestCase
  test "should handle API failure gracefully" do
    # stub으로 외부 의존성 대체
    ExternalClient.stub :fetch, ->(_) { raise Faraday::Error } do
      service = ExternalApiService.new
      result = service.call

      assert_not result.success?
      assert_includes result.errors, "외부 서비스 연결 실패"
    end
  end
end
```

### Test Documentation in Plan

**In each phase, specify**:
1. **Test File Location**: Exact path where tests will be written
2. **Test Scenarios**: List of specific test cases
3. **Expected Failures**: What error should tests show initially?
4. **Coverage Target**: Percentage for this phase
5. **Dependencies to Mock**: What needs mocking/stubbing?
6. **Test Data**: What fixtures/factories are needed?

## Supporting Files Reference
- [plan-template.md](plan-template.md) - Complete plan document template
