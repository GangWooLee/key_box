# 코드 품질 · 클린 코드 표준

## 복잡도 제한

| 항목 | 최대값 | 초과 시 조치 |
|------|-------|------------|
| 메서드 길이 | 20줄 | 메서드 분리 |
| 클래스 길이 | 200줄 | Concern/Service 분리 |
| 조건문 깊이 | 3단계 | Early return 활용 |
| 파라미터 수 | 4개 | 객체로 묶기 |

## Early Return

```ruby
# ❌ 깊은 중첩
def process(user)
  if user.present?
    if user.active?
      if user.verified?
        # 실제 로직
      end
    end
  end
end

# ✅ Early Return
def process(user)
  return unless user.present?
  return unless user.active?
  return unless user.verified?
  # 실제 로직
end
```

## DRY (Don't Repeat Yourself)

```ruby
# ❌ 중복 코드
class PostsController
  def index
    @posts = Post.where(published: true).order(created_at: :desc).limit(10)
  end
end

# ✅ Scope로 추출
class Post
  scope :recent_published, -> { published.recent.limit(10) }
end
```

## 상수 사용 (Magic Number 금지)

```ruby
# ❌ Magic Number
if user.posts.count > 10

# ✅ 상수로 의미 부여
MAX_FREE_POSTS = 10
if user.posts.count > MAX_FREE_POSTS
```

## Law of Demeter (디미터 법칙)

최대 1단계 체이닝. "친구의 친구에게 말하지 마라."

```ruby
# ❌ 3단계 체이닝
order.user.address.city

# ✅ delegate로 1단계
class Order < ApplicationRecord
  delegate :city, to: :user, prefix: true  # order.user_city
end
```

**예외**: ActiveRecord 쿼리 체이닝은 허용 (같은 추상화 수준).

## Tell, Don't Ask

객체의 상태를 묻고 외부에서 결정하지 말고, 객체에게 행동을 시켜라.

```ruby
# ❌ 상태를 묻고 외부에서 결정
if user.subscription.active? && user.subscription.plan.premium?
  grant_premium_access(user)
end

# ✅ 결정은 객체 내부에서
user.grant_access_if_eligible!
```

## Command-Query Separation (CQS)

| 유형 | 역할 | 반환 |
|------|------|------|
| Command | 상태 변경 | void (또는 self) |
| Query | 상태 읽기 | 값 |

## KISS & YAGNI

- 현재 필요한 최소한만 구현 (미래 요구사항 예측 금지)
- 추상화는 3번째 중복부터 (Rule of Three)
- 설정 가능성(configurability) 추가는 실제 요청이 있을 때만

## 네이밍 규칙

```ruby
# 변수/메서드: snake_case
user_name = "John"
def calculate_total; end

# 클래스/모듈: CamelCase
class UserProfile; end

# 상수: SCREAMING_SNAKE_CASE
MAX_RETRY_COUNT = 3

# Boolean 메서드: ?로 끝남
def active?; end

# 위험한 메서드: !로 끝남
def save!; end
```

- 축약 금지: `btn` → `button`, `mgr` → `manager`
- 의미 있는 이름: `d` → `elapsed_days_since_creation`
- 컬렉션은 복수형: `items`, `users`
- 메서드는 동사 시작: `calculate_total`, `send_notification`

## 메서드 설계 원칙

- **한 가지 일만** 수행
- **추상화 수준 통일** — 고수준 + 저수준 혼합 금지
- **부작용 명시** — `!` 접미사 또는 명확한 이름
- **파라미터 3개 초과** → Keyword Arguments로 래핑

## 주석 규칙

```ruby
# ❌ 불필요한 주석 — "무엇"을 설명
# 사용자를 찾는다
user = User.find(id)

# ✅ 필요한 주석 — "왜"를 설명
# OAuth 사용자는 비밀번호가 없으므로 건너뜀
return if user.oauth_only?

# ✅ TODO 주석 (기한 포함)
# TODO: N+1 쿼리 최적화 필요 (2026-02-01까지)
```

## 파일 구조

```ruby
# 한 파일에 하나의 주요 클래스
# app/services/users/deletion_service.rb
module Users
  class DeletionService; end
end
```

## 에러 처리 기본

```ruby
# ✅ 구체적인 예외 처리
begin
  external_api.call
rescue Timeout::Error => e
  Rails.logger.warn "[API] Timeout: #{e.message}"
  retry_later
rescue ExternalApi::AuthError => e
  Rails.logger.error "[API] Auth failed: #{e.message}"
  raise
end

# ❌ 모든 예외 무시 금지
begin
  risky_operation
rescue => e
  # 아무것도 안 함 - 금지!
end
```
