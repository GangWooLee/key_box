---
name: code-review
description: Comprehensive code review and health check. Use when user needs project audit, code quality check, conflict detection, or says "review code", "check project", "audit codebase", "health check", "find issues", "code quality".
---

# Code Review (통합 코드 검수)

프로젝트 전체에 대한 체계적인 코드 리뷰, 충돌 감지, 안정성 검증을 수행합니다.
기존 security-audit, performance-check, database-maintenance skills를 통합하여 일관된 검수를 제공합니다.

## Quick Start

```
/code-review        # 전체 검수 실행
/code-review quick  # 빠른 검수 (핵심만)
/code-review deep   # 심층 검수 (전체 분석)
```

## Review Categories

### 1. Model Layer (모델 계층)
- 관계(associations) 정합성
- 검증(validations) 일관성
- Callback 부작용 검사
- Concern 충돌 감지
- Enum 정의 확인

### 2. Controller Layer (컨트롤러 계층)
- Strong Parameters 검증
- 인증/인가 before_action
- N+1 쿼리 가능성
- 응답 형식 일관성
- 에러 처리 패턴

### 3. Database Layer (데이터베이스 계층)
- Migration 상태 확인
- Schema 정합성
- 인덱스 최적화
- 외래키 무결성
- Counter cache 정확도

### 4. Security (보안)
- SQL Injection 취약점
- XSS 취약점
- CSRF 보호
- Mass Assignment
- 인증 우회 가능성

### 5. Performance (성능)
- N+1 쿼리 패턴
- 누락된 인덱스
- 불필요한 eager loading
- 메모리 사용 패턴
- 캐싱 기회

### 6. Code Quality (코드 품질)
- DRY 원칙 준수
- Fat Controller/Model
- 매직 넘버/스트링
- 미사용 코드
- 테스트 커버리지

### 7. Flow & Architecture (플로우/아키텍처)
- 라우팅 일관성
- RESTful 패턴 준수
- 뷰-컨트롤러 매핑
- JavaScript 컨트롤러 연결
- Turbo Stream 흐름

## Automation Script

```bash
# 전체 검수 실행
ruby .claude/skills/code-review/scripts/full_review.rb

# 특정 영역만 검수
ruby .claude/skills/code-review/scripts/full_review.rb --models
ruby .claude/skills/code-review/scripts/full_review.rb --controllers
ruby .claude/skills/code-review/scripts/full_review.rb --database
ruby .claude/skills/code-review/scripts/full_review.rb --security
ruby .claude/skills/code-review/scripts/full_review.rb --performance
```

## Review Workflow

```
Task Progress (copy and check off):
- [ ] 1. Model Layer 검수
  - [ ] 관계 정합성 확인
  - [ ] 검증 규칙 확인
  - [ ] Callback 검토
- [ ] 2. Controller Layer 검수
  - [ ] Strong Parameters 확인
  - [ ] 인증/인가 확인
  - [ ] 응답 처리 확인
- [ ] 3. Database Layer 검수
  - [ ] Migration 상태 확인
  - [ ] 인덱스 최적화 확인
  - [ ] 데이터 무결성 확인
- [ ] 4. Security 검수
  - [ ] Brakeman 스캔
  - [ ] 취약점 확인
- [ ] 5. Performance 검수
  - [ ] N+1 쿼리 확인
  - [ ] 인덱스 분석
- [ ] 6. Test 실행
  - [ ] 전체 테스트 통과 확인
- [ ] 7. 결과 보고서 작성
```

## Common Issues & Fixes

### Issue: 모델 관계 불일치
```ruby
# 문제: belongs_to 없이 has_many만 정의
class Post < ApplicationRecord
  has_many :comments
end

class Comment < ApplicationRecord
  # belongs_to :post 누락!
end

# 해결
class Comment < ApplicationRecord
  belongs_to :post
end
```

### Issue: Strong Parameters 누락
```ruby
# 문제: 민감한 필드 허용
def user_params
  params.require(:user).permit(:email, :name, :admin)  # admin 위험!
end

# 해결
def user_params
  params.require(:user).permit(:email, :name)
  # admin은 별도 인가 필요
end
```

### Issue: N+1 쿼리
```ruby
# 문제
@posts = Post.all
@posts.each { |p| p.user.name }  # N+1!

# 해결
@posts = Post.includes(:user).all
```

### Issue: 누락된 인덱스
```ruby
# 문제: 자주 조회하는 컬럼에 인덱스 없음
Post.where(status: 'published')

# 해결
add_index :posts, :status
```

## Integration with Other Skills

이 skill은 다음 skills와 연동됩니다:

- **security-audit**: 보안 취약점 상세 분석
- **performance-check**: 성능 최적화 상세 분석
- **database-maintenance**: 데이터베이스 건강 상태
- **test-gen**: 테스트 커버리지 개선

## Output Format

검수 결과는 다음 형식으로 출력됩니다:

```
═══════════════════════════════════════════════════════════════
  CODE REVIEW REPORT
  Date: 2025-12-23
═══════════════════════════════════════════════════════════════

📊 SUMMARY
───────────────────────────────────────────────────────────────
  Total Issues: 5
  Critical: 1 | High: 2 | Medium: 1 | Low: 1

🔴 CRITICAL ISSUES
───────────────────────────────────────────────────────────────
  1. [Security] SQL Injection in SearchController#index
     Location: app/controllers/search_controller.rb:15
     Fix: Use parameterized query

🟠 HIGH PRIORITY
───────────────────────────────────────────────────────────────
  1. [Performance] N+1 query in PostsController#index
     Location: app/controllers/posts_controller.rb:8
     Fix: Add .includes(:user)

🟡 MEDIUM PRIORITY
───────────────────────────────────────────────────────────────
  ...

✅ PASSED CHECKS
───────────────────────────────────────────────────────────────
  - All migrations applied
  - No orphaned records
  - Tests passing (24 assertions)
  - CSRF protection enabled
```

## Checklist Reference

상세 체크리스트는 `reference/` 디렉토리를 참조하세요:

- `reference/model-checklist.md` - 모델 검수 체크리스트
- `reference/controller-checklist.md` - 컨트롤러 검수 체크리스트
- `reference/security-checklist.md` - 보안 검수 체크리스트
- `reference/performance-checklist.md` - 성능 검수 체크리스트

## Best Practices

1. **정기적 실행**: 주요 기능 개발 후 매번 실행
2. **CI/CD 통합**: 배포 전 자동 검수
3. **점진적 개선**: Critical → High → Medium 순서로 수정
4. **테스트 보완**: 발견된 이슈에 대한 테스트 추가
5. **문서화**: 주요 결정사항 기록
