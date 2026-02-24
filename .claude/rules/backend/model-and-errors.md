# 모델 패턴 · 에러 처리

## 모델 선언 순서 (필수 준수)

```ruby
class Post < ApplicationRecord
  # 1. 상수
  CATEGORIES = %w[free question promo hiring seeking].freeze
  MAX_TITLE_LENGTH = 100

  # 2. Concerns/Modules
  include Searchable

  # 3. Associations (belongs_to → has_many → has_one 순)
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_one_attached :image

  # 4. Validations
  validates :title, presence: true, length: { maximum: MAX_TITLE_LENGTH }
  validates :content, presence: true
  validates :category, inclusion: { in: CATEGORIES }

  # 5. Callbacks (최소화!)
  before_save :sanitize_content

  # 6. Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :published, -> { where(published: true) }

  # 7. Class Methods
  # 8. Instance Methods

  private
  # Private Methods
end
```

## Association 규칙

### dependent 옵션 필수

```ruby
# ❌ 고아 레코드 발생 위험
has_many :comments

# ✅ dependent 명시
has_many :comments, dependent: :destroy
has_many :likes, dependent: :delete_all  # 콜백 불필요 시
```

### Counter Cache 활용

```ruby
belongs_to :post, counter_cache: true
# Migration: add_column :posts, :comments_count, :integer, default: 0
```

## Validation 규칙

### 길이 제한 필수

```ruby
# ❌ 무제한 입력 허용 위험
validates :bio, presence: true

# ✅ 길이 제한 필수
validates :bio, presence: true, length: { maximum: 500 }
validates :name, length: { minimum: 1, maximum: 50 }
```

### 에러 메시지 한국어

```ruby
validates :email,
  presence: { message: "을(를) 입력해주세요" },
  uniqueness: { message: "이(가) 이미 사용 중입니다" }
```

## Scope 규칙

```ruby
# ✅ 체이닝 가능 - ActiveRecord::Relation 반환
scope :active, -> { where(deleted_at: nil) }
scope :recent, -> { order(created_at: :desc) }
# 사용: Post.active.recent.limit(10)

# ❌ 체이닝 불가 - 배열 반환 금지
scope :bad, -> { all.to_a }
```

## Enum 정의

```ruby
enum :status, {
  draft: 0,
  pending: 1,
  published: 2,
  archived: 3
}, prefix: true
# 사용: post.status_published?, post.status_published!
```

---

## 에러 처리

### rescue 최소 범위 원칙

rescue는 예외를 발생시키는 **특정 메서드 내부**에 배치. 컨트롤러 액션 전체를 감싸지 않음.

```ruby
# ❌ 컨트롤러 액션 전체 감싸기 — redirect 누락 위험
def complete_step
  upsert_entry(step_index)
  redirect_to next_path, status: :see_other
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error e.message
  # redirect 실행 안 됨! 204 No Content 반환
end

# ✅ 실패 가능한 메서드 내부에서 rescue
def complete_step
  upsert_entry(step_index)
  redirect_to next_path, status: :see_other
end

private

def upsert_entry(step_index)
  entry = Model.find_or_initialize_by(...)
  entry.save!
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error "[Context] Save failed: #{e.message}"
end
```

### 예외별 처리 전략

| 예외 | 위치 | 처리 |
|------|------|------|
| `RecordNotFound` | Controller (before_action) | 404 렌더링 |
| `RecordInvalid` | 실패 메서드 내부 | 로그 + graceful fallback |
| `RecordNotUnique` | 실패 메서드 내부 | retry (bounded) |
| `Faraday::Error` | Service 객체 내부 | 사용자 친화 메시지 반환 |

### Bounded Retry 패턴

```ruby
MAX_RETRY = 3

def create
  retries ||= 0
  # ... 작업 ...
rescue ActiveRecord::RecordNotUnique
  retries += 1
  retry if retries <= MAX_RETRY
  Rails.logger.error "[Context] Max retries exceeded"
end
```

### Graceful Degradation

- 보조 데이터(대화 기록, 추적 정보) 저장 실패 → 로그 + 계속 진행
- 핵심 데이터(결과물, 사용자 정보) 저장 실패 → 에러 표시 + 재시도 안내
