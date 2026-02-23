# Implementation Plan: [Feature Name]

**Status**: 🔄 In Progress
**Started**: YYYY-MM-DD
**Last Updated**: YYYY-MM-DD
**Estimated Completion**: YYYY-MM-DD

---

**⚠️ CRITICAL INSTRUCTIONS**: After completing each phase:
1. ✅ Check off completed task checkboxes
2. 🧪 Run all quality gate validation commands
3. ⚠️ Verify ALL quality gate items pass
4. 📅 Update "Last Updated" date above
5. 📝 Document learnings in Notes section
6. ⏱️ Record actual time in Time Tracking table
7. ➡️ Only then proceed to next phase

⛔ **DO NOT skip quality gates or proceed with failing checks**

---

## 📋 Overview

### Feature Description
[What this feature does and why it's needed]

### Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### User Impact
[How this benefits users or improves the product]

---

## 🏗️ Architecture Decisions

| Decision | Rationale | Trade-offs |
|----------|-----------|------------|
| [Decision 1] | [Why this approach] | [What we're giving up] |
| [Decision 2] | [Why this approach] | [What we're giving up] |

---

## 📦 Dependencies

### Required Before Starting
- [ ] Dependency 1: [Description]
- [ ] Dependency 2: [Description]

### Gems / External Dependencies
- Gem 1: version ~> X.Y
- Gem 2: version ~> X.Y

---

## 🧪 Test Strategy

### Testing Approach
**TDD Principle**: Write tests FIRST, then implement to make them pass.
**Framework**: Minitest + Fixtures (Rails default)

### Test Pyramid for This Feature
| Test Type | Coverage Target | Purpose |
|-----------|-----------------|---------|
| **Model Tests** | 100% (validations/associations) | Data integrity, business rules |
| **Controller Tests** | ≥80% | HTTP flow, auth, response format |
| **Service Tests** | ≥80% | Business logic orchestration |
| **System Tests** | ≥60% | Critical user flows (Capybara) |

### Test File Organization
```
test/
├── models/              # Unit tests
│   └── [feature]_test.rb
├── controllers/         # Integration tests
│   └── [feature]_controller_test.rb
├── services/            # Service object tests
│   └── [feature]_service_test.rb
├── system/              # E2E tests (Capybara)
│   └── [feature]_test.rb
└── fixtures/
    └── [feature].yml    # Test data
```

### Coverage Requirements by Phase
- **Phase 1 (Foundation)**: Model tests — validations, associations (100%)
- **Phase 2 (Business Logic)**: Service + controller tests (≥80%)
- **Phase 3 (Integration)**: System tests for critical paths (≥60%)

### Fixture Strategy
```yaml
# test/fixtures/[feature].yml
one:
  # Happy path data
  field: value
  association: one

two:
  # Edge case / alternative data
  field: different_value
  association: two
```

---

## 🚀 Implementation Phases

### Phase 1: [Foundation Phase Name]
**Goal**: [Specific working functionality this phase delivers]
**Estimated Time**: X hours
**Actual Time**: — _(fill after completion)_
**Status**: ⏳ Pending | 🔄 In Progress | ✅ Complete

#### Tasks

**🔴 RED: Write Failing Tests First**
- [ ] **Test 1.1**: Write model tests for [specific functionality]
  - File: `test/models/[feature]_test.rb`
  - Expected: Tests FAIL — model/method doesn't exist yet
  - Test cases:
    - Validations (presence, format, uniqueness)
    - Associations (belongs_to, has_many)
    - Edge cases

- [ ] **Test 1.2**: Write controller tests for [actions]
  - File: `test/controllers/[feature]_controller_test.rb`
  - Expected: Tests FAIL — routes/controller don't exist yet
  - Test cases:
    - Auth-required actions redirect
    - CRUD operations
    - Turbo Stream responses

**🟢 GREEN: Implement to Make Tests Pass**
- [ ] **Task 1.3**: Create migration + model
  - File: `app/models/[feature].rb`
  - Migration: `db/migrate/xxx_create_[features].rb`
  - Goal: Make Test 1.1 pass with minimal code

- [ ] **Task 1.4**: Create controller + routes
  - File: `app/controllers/[features]_controller.rb`
  - Routes: `config/routes.rb`
  - Goal: Make Test 1.2 pass

**🔵 REFACTOR: Clean Up Code**
- [ ] **Task 1.5**: Refactor for code quality
  - Checklist:
    - [ ] Remove duplication (DRY)
    - [ ] Extract concerns if shared behavior
    - [ ] Improve naming clarity
    - [ ] Ensure Law of Demeter compliance

#### Quality Gate ✋

**⚠️ STOP: Do NOT proceed to Phase 2 until ALL checks pass**

**TDD Compliance** (CRITICAL):
- [ ] **Red Phase**: Tests were written FIRST and initially failed
- [ ] **Green Phase**: Production code written to make tests pass
- [ ] **Refactor Phase**: Code improved while tests still pass
- [ ] **Coverage Check**: Test coverage meets requirements

**Validation Commands**:
```bash
# 1. Build — Rails loads without error
bin/rails runner "puts 'OK'"

# 2. Tests — all pass
bin/rails test

# 3. Lint — no offenses
bundle exec rubocop

# 4. Coverage (if SimpleCov configured)
COVERAGE=true bin/rails test
```

**Build & Tests**:
- [ ] `bin/rails runner "puts 'OK'"` — exits 0
- [ ] `bin/rails test` — 0 failures, 0 errors
- [ ] No skipped tests

**Code Quality**:
- [ ] `bundle exec rubocop` — no offenses
- [ ] Code formatted per project standards

**Manual Testing**:
- [ ] Feature works in browser / `rails console`
- [ ] Edge cases verified
- [ ] Error states handled gracefully

---

### Phase 2: [Core Feature Phase Name]
**Goal**: [Specific deliverable]
**Estimated Time**: X hours
**Actual Time**: — _(fill after completion)_
**Status**: ⏳ Pending | 🔄 In Progress | ✅ Complete

#### Tasks

**🔴 RED: Write Failing Tests First**
- [ ] **Test 2.1**: Write tests for [specific functionality]
  - File: `test/[layer]/[feature]_test.rb`
  - Expected: Tests FAIL
  - Test cases: [list scenarios]

**🟢 GREEN: Implement to Make Tests Pass**
- [ ] **Task 2.2**: Implement [component]
  - File: `app/[layer]/[feature].rb`
  - Goal: Make Test 2.1 pass with minimal code

**🔵 REFACTOR: Clean Up Code**
- [ ] **Task 2.3**: Refactor for code quality
  - Checklist:
    - [ ] Remove duplication
    - [ ] Extract Service Object if controller > 10 lines
    - [ ] Verify single responsibility

#### Quality Gate ✋

**⚠️ STOP: Do NOT proceed to Phase 3 until ALL checks pass**

Same validation as Phase 1:
```bash
bin/rails runner "puts 'OK'"
bin/rails test
bundle exec rubocop
```
- [ ] Build passes
- [ ] All tests pass (0 failures, 0 errors)
- [ ] Lint passes
- [ ] TDD cycle followed
- [ ] Manual testing confirms behavior

---

### Phase 3: [Enhancement Phase Name]
**Goal**: [Specific deliverable]
**Estimated Time**: X hours
**Actual Time**: — _(fill after completion)_
**Status**: ⏳ Pending | 🔄 In Progress | ✅ Complete

#### Tasks

**🔴 RED: Write Failing Tests First**
- [ ] **Test 3.1**: Write system tests for [user flow]
  - File: `test/system/[feature]_test.rb`
  - Expected: Tests FAIL
  - Test cases: [critical user journeys]

**🟢 GREEN: Implement to Make Tests Pass**
- [ ] **Task 3.2**: Implement views + Stimulus controllers
  - Files: `app/views/`, `app/javascript/controllers/`
  - Goal: Make Test 3.1 pass

**🔵 REFACTOR: Clean Up Code**
- [ ] **Task 3.3**: Final cleanup
  - Checklist:
    - [ ] View partials extracted where appropriate
    - [ ] Stimulus controllers follow single responsibility
    - [ ] Tailwind classes consistent with design system

#### Quality Gate ✋

**⚠️ STOP: Final validation before marking complete**

```bash
bin/rails runner "puts 'OK'"
bin/rails test
bin/rails test:system
bundle exec rubocop
```
- [ ] Build passes
- [ ] Unit + integration tests pass
- [ ] System tests pass
- [ ] Lint passes
- [ ] TDD cycle followed
- [ ] Full manual walkthrough complete

---

## ⚠️ Risk Assessment

| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|---------------------|
| [Risk 1: e.g., Migration conflicts] | Low/Med/High | Low/Med/High | [Specific steps] |
| [Risk 2: e.g., N+1 queries] | Low/Med/High | Low/Med/High | [Specific steps] |
| [Risk 3: e.g., Auth edge cases] | Low/Med/High | Low/Med/High | [Specific steps] |

---

## 🔄 Rollback Strategy

### If Phase 1 Fails
```bash
# Revert migration
bin/rails db:rollback STEP=N

# Revert code changes
git checkout -- app/models/[feature].rb app/controllers/[features]_controller.rb
git checkout -- config/routes.rb

# Remove test files
rm test/models/[feature]_test.rb test/controllers/[features]_controller_test.rb

# Remove fixtures
rm test/fixtures/[features].yml
```

### If Phase 2 Fails
```bash
# Revert to Phase 1 state
bin/rails db:rollback STEP=N  # if new migrations added
git diff HEAD~X --name-only    # review changed files
git checkout -- [changed files from Phase 2]
```

### If Phase 3 Fails
```bash
# Revert to Phase 2 state
git checkout -- app/views/ app/javascript/controllers/
rm test/system/[feature]_test.rb
```

---

## 📊 Progress Tracking

### Completion Status
- **Phase 1**: ⏳ 0%
- **Phase 2**: ⏳ 0%
- **Phase 3**: ⏳ 0%

**Overall Progress**: 0% complete

### Time Tracking
| Phase | Estimated | Actual | Variance |
|-------|-----------|--------|----------|
| Phase 1 | X hours | — | — |
| Phase 2 | X hours | — | — |
| Phase 3 | X hours | — | — |
| **Total** | **X hours** | **—** | **—** |

> **Rule**: If actual exceeds estimate by ≥50%, re-estimate remaining phases before proceeding.

---

## 📝 Notes & Learnings

### Implementation Notes
- [Add insights discovered during implementation]
- [Document decisions that deviate from original plan]

### Blockers Encountered
- **Blocker 1**: [Description] → [Resolution]

### Improvements for Future Plans
- [What would you do differently next time?]

---

## 📚 References

### Related Files
- Model: `app/models/[feature].rb`
- Controller: `app/controllers/[features]_controller.rb`
- Views: `app/views/[features]/`
- Tests: `test/models/`, `test/controllers/`, `test/system/`
- Routes: `config/routes.rb`

### Related Issues
- Issue #X: [Description]

---

## ✅ Final Checklist

**Before marking plan as COMPLETE**:
- [ ] All phases completed with quality gates passed
- [ ] `bin/rails test` — 0 failures, 0 errors
- [ ] `bin/rails test:system` — system tests pass
- [ ] `bundle exec rubocop` — 0 offenses
- [ ] All time tracking entries filled
- [ ] Documentation updated
- [ ] Performance verified (no N+1 queries)
- [ ] Security reviewed (strong params, auth checks)

---

**Plan Status**: 🔄 In Progress
**Next Action**: [What needs to happen next]
**Blocked By**: [Any current blockers] or None
