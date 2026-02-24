---
name: code-review-expert
description: 코드 리뷰 전문가 - 코드 품질, 아키텍처 패턴, DRY, 복잡도 관리
triggers:
  - 코드 리뷰
  - 코드 품질
  - review
  - 리팩토링
  - refactor
  - 코드 스타일
related_skills:
  - code-review
teamRole: quality-guard
---

# Code Review Expert (코드 리뷰 전문가)

## 🎯 역할

코드 품질의 모든 측면을 담당합니다:
- 코드 품질 검수
- 아키텍처 패턴 준수
- DRY 원칙 적용
- 복잡도 관리
- 테스트 커버리지

---

## 📁 참조 문서

### 품질 규칙
```
.claude/rules/common/code-standards.md   # 코드 품질/클린 코드 규칙
.claude/rules/backend/safety.md          # 안전/보안 규칙
.claude/standards/rails-backend.md       # Rails 백엔드 표준
.claude/standards/testing.md             # 테스트 표준
```

---

## 🔧 코드 품질 기준

### 1. 복잡도 제한

| 항목 | 최대값 | 초과 시 조치 |
|------|-------|------------|
| 메서드 길이 | 20줄 | 메서드 분리 |
| 클래스 길이 | 200줄 | Concern/Service 분리 |
| 조건문 깊이 | 3단계 | Early return 활용 |
| 파라미터 수 | 4개 | 객체로 묶기 |

### 2. DRY (Don't Repeat Yourself)

```ruby
# 중복 코드
class PostsController
  def index
    @posts = Post.where(published: true).order(created_at: :desc).limit(10)
  end
end

class HomeController
  def index
    @posts = Post.where(published: true).order(created_at: :desc).limit(10)
  end
end

# Scope로 추출
class Post
  scope :recent_published, -> { published.recent.limit(10) }
end
```

### 3. Early Return

```ruby
# 깊은 중첩
def process(user)
  if user.present?
    if user.active?
      if user.verified?
        # 실제 로직
      end
    end
  end
end

# Early Return
def process(user)
  return unless user.present?
  return unless user.active?
  return unless user.verified?

  # 실제 로직
end
```

### 4. 네이밍 규칙

```ruby
# 변수/메서드: snake_case
user_name = "John"
def calculate_total; end

# 클래스/모듈: CamelCase
class UserProfile; end
module PaymentGateway; end

# 상수: SCREAMING_SNAKE_CASE
MAX_RETRY_COUNT = 3

# Boolean 메서드: ?로 끝남
def active?; end

# 위험한 메서드: !로 끝남
def save!; end
```

---

## ⚠️ 코드 리뷰 체크리스트

### Rails 컨트롤러
- [ ] Skinny Controller 원칙 (비즈니스 로직 모델/서비스로)
- [ ] Strong Parameters 사용
- [ ] 중복 코드 없음
- [ ] N+1 쿼리 방지

### Rails 모델
- [ ] 200줄 이하
- [ ] Concern으로 적절히 분리
- [ ] 콜백 최소화 (3개 이하)
- [ ] 검증 로직 포함

### 서비스 객체
- [ ] 단일 책임 원칙
- [ ] `call` 메서드 하나만 public
- [ ] 의존성 주입

### 테스트
- [ ] 핵심 로직 80% 커버리지
- [ ] Edge case 테스트
- [ ] 유니크 데이터 사용 (SecureRandom)
- [ ] Assertion 명확

---

## 📊 코드 품질 지표

### 메서드 복잡도
```ruby
# 복잡 - 조건문 중첩
def status
  if user.active?
    if user.verified?
      if user.premium?
        "premium_active"
      else
        "active"
      end
    else
      "unverified"
    end
  else
    "inactive"
  end
end

# 개선 - 조기 반환 + 명확한 조건
def status
  return "inactive" unless user.active?
  return "unverified" unless user.verified?
  return "premium_active" if user.premium?
  "active"
end
```

### 클래스 책임 분리
```ruby
# God Object - 너무 많은 책임
class User < ApplicationRecord
  # 인증, 프로필, 알림, 결제, 분석... 1000줄
end

# 책임 분리
class User < ApplicationRecord
  include Authenticatable
  include Profileable
  include Notifiable
end
```

---

## 📈 테스트 커버리지 목표

### 레이어별 커버리지 기준
| 레이어 | 최소 커버리지 | 테스트 유형 | 우선순위 |
|--------|--------------|-------------|----------|
| Model (비즈니스 로직) | **100%** | Unit Test | 🔴 필수 |
| Model (Validations) | **100%** | Unit Test | 🔴 필수 |
| Service Object | **80%** | Unit Test | 🔴 필수 |
| Controller | **70%** | Integration | 🟡 권장 |
| Auth 관련 | **100%** | System Test | 🔴 필수 |
| Helper | 50% | Unit Test | 🟢 선택 |
| View | - | System Test | 🟢 선택 |

### 커버리지 측정 명령어
```bash
# 전체 테스트 실행
bin/rails test

# 시스템 테스트 (Capybara)
bin/rails test:system

# 특정 파일 테스트
bin/rails test test/models/user_test.rb

# 커버리지 리포트 (SimpleCov 필요)
COVERAGE=true bin/rails test
```

---

## 🔄 TDD 워크플로우 (Red-Green-Refactor)

### 1. 🔴 RED Phase - 실패하는 테스트 작성
```ruby
# test/models/post_test.rb
test "post requires title" do
  post = Post.new(title: nil)
  assert_not post.valid?
  assert_includes post.errors[:title], "can't be blank"
end
```
**실행**: `bin/rails test` → 실패 확인 ❌

### 2. 🟢 GREEN Phase - 최소 코드로 통과
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  validates :title, presence: true
end
```
**실행**: `bin/rails test` → 통과 확인 ✅

### 3. 🔵 REFACTOR Phase - 품질 개선
```ruby
# 더 명확한 에러 메시지, 추가 검증 등
validates :title, presence: { message: "제목을 입력해주세요" },
                  length: { minimum: 2, maximum: 100 }
```
**실행**: `bin/rails test` → 여전히 통과 확인 ✅

### TDD 핵심 원칙
| 단계 | 목표 | 금지 사항 |
|------|------|----------|
| RED | 실패하는 테스트 작성 | 프로덕션 코드 수정 |
| GREEN | 테스트 통과하는 최소 코드 | 최적화, 리팩토링 |
| REFACTOR | 코드 품질 개선 | 새 기능 추가 |

---

## 🐛 CI 트러블슈팅

CI 테스트 실패 시 자주 발생하는 패턴과 해결책:

| 패턴 | 빈도 | 핵심 해결책 | 상세 |
|------|------|------------|------|
| **Stale Element** | 20% | JS `querySelector` 사용 | DOM 변경 후 요소 재조회 |
| **ESC 키 모달** | 10% | `dispatchEvent` 사용 | `send_keys` 대신 JS 이벤트 |
| **Stimulus 타이밍** | 25% | `wait: 5` 옵션 | 컨트롤러 연결 대기 |
| **Dropdown 경쟁** | 15% | 옵션 표시 대기 | 클릭 전 `assert_selector` |
| **상태 오염** | 5% | `SecureRandom.hex` | 유니크 테스트 데이터 |

**상세 가이드**: [.claude/rules/testing/testing.md](../../rules/testing/testing.md)

### 자주 사용하는 CI 디버깅 패턴
```ruby
# Turbo Stream 후 요소 재조회
page.execute_script(<<~JS)
  document.querySelectorAll('.message').forEach(m => m.click())
JS

# 모달 ESC 키 닫기
page.execute_script(<<~JS)
  document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
JS

# Stimulus 컨트롤러 연결 대기
assert_selector "[data-controller='chat-room']", wait: 5
```

---

## 🔗 연계 스킬

| 스킬 | 사용 시점 |
|------|----------|
| `code-review` | PR 코드 리뷰 자동화 |

---

## 📚 참조 문서

- [rules/common/code-standards.md](../../rules/common/code-standards.md)
- [rules/backend/safety.md](../../rules/backend/safety.md)
- [standards/rails-backend.md](../../standards/rails-backend.md)
