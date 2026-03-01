---
paths:
  - "app/models/**"
  - "app/controllers/**"
  - "app/services/**"
  - "db/migrate/**"
---

# 아키텍처 원칙 — 설계 패턴 · 계층 분리 · SOLID

## 설계 패턴 선택 가이드

| 신호 | 패턴 |
|------|------|
| 컨트롤러 액션 10줄+ | Service Object |
| 2+ 모델 동시 저장 | Form Object |
| 복합 쿼리 (JOIN, 3+ 조건) | Query Object |
| 불변 데이터 (Money, Email) | Value Object |
| View 조건 분기 3+ | Presenter/Decorator |
| 읽기 전용 권한 확인 | Policy Object |

## Service Object

`.call` 단일 진입점, Result 객체 반환, `app/services/` 하위 네임스페이스.

```ruby
class Users::RegistrationService
  def initialize(params:, session:)
    @params = params
    @session = session
  end

  def call
    user = User.create!(@params)
    send_welcome_email(user)
    track_signup(user)
    Result.new(success: true, user: user)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success: false, errors: e.record.errors)
  end

  private

  def send_welcome_email(user)
    UserMailer.welcome(user).deliver_later
  end

  def track_signup(user)
    Analytics.track("signup", user_id: user.id)
  end
end
```

### Controller 슬림화

```ruby
# ❌ Fat Controller
def create
  @user = User.new(user_params)
  if @user.save
    UserMailer.welcome(@user).deliver_later
    Analytics.track("signup", user_id: @user.id)
    session[:user_id] = @user.id
    redirect_to root_path
  else
    render :new
  end
end

# ✅ Slim Controller
def create
  result = Users::RegistrationService.new(params: user_params).call
  if result.success?
    session[:user_id] = result.user.id
    redirect_to root_path, status: :see_other
  else
    @user = result.user
    render :new, status: :unprocessable_entity
  end
end
```

## Form Object

여러 모델 동시 저장, 가상 속성, 다단계 위자드.

```ruby
class Onboarding::CompletionForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :level_id, :integer
  attribute :topic_ids, array: true

  validates :level_id, presence: true
  validates :topic_ids, length: { minimum: 1, maximum: 3 }

  def save
    return false unless valid?
    ActiveRecord::Base.transaction do
      user.update!(level: level)
      user.interests = topics
    end
    true
  end
end
```

## Query Object

2+ 테이블 JOIN, 3+ 조건, 여러 곳에서 재사용.

```ruby
class ContentItems::TrendingQuery
  def initialize(relation: ContentItem.all)
    @relation = relation
  end

  def call(period: 7.days.ago, limit: 20)
    @relation
      .joins(:video_watches)
      .where(video_watches: { created_at: period.. })
      .group(:id)
      .order("COUNT(video_watches.id) DESC")
      .limit(limit)
  end
end
```

## Value Object

불변 데이터, 동등성이 값으로 결정.

```ruby
class LevelBadge
  attr_reader :level, :name, :emoji

  BADGES = {
    1 => { name: "입문", emoji: "🌱" },
    2 => { name: "초급", emoji: "🌿" },
    3 => { name: "중급", emoji: "🌳" },
    4 => { name: "고급", emoji: "🏔️" }
  }.freeze

  def initialize(level)
    @level = level
    badge = BADGES.fetch(level, BADGES[1])
    @name = badge[:name]
    @emoji = badge[:emoji]
  end

  def ==(other)
    other.is_a?(self.class) && level == other.level
  end
end
```

## Presenter/Decorator

View 조건 분기 3+, Helper 5개 이상 시 추출.

```ruby
class UserPresenter
  delegate :name, :email, to: :user

  def initialize(user)
    @user = user
  end

  def level_display
    return "미설정" unless user.level
    LevelBadge.new(user.level.name).to_s
  end

  private

  attr_reader :user
end
```

## Policy Object

읽기 전용 권한 확인. Service(쓰기)와 구분.

```ruby
class TutorSession::AccessPolicy
  def initialize(user:, curriculum:)
    @user = user
    @curriculum = curriculum
  end

  def can_start?
    user.onboarding_complete? && prerequisites_met?
  end

  private

  attr_reader :user, :curriculum

  def prerequisites_met?
    return true if curriculum.position == 1
    previous = curriculum.class.where("position < ?", curriculum.position)
    previous.all? { |c| user.completed?(c) }
  end
end
```

---

## 계층 분리 (Controller → Service → Model)

```
Controller → Service → Model → Database
     ↓           ↓
   View      External API
```

의존성은 항상 안쪽(Model)을 향한다. Model은 Controller/Service를 모른다.

| 계층 | 책임 | 금지 |
|------|------|------|
| **Controller** | HTTP 파싱, 인증/인가, 응답 형식 | 비즈니스 로직, 직접 복합 DB 쿼리 |
| **Service** | 비즈니스 프로세스 조율, 트랜잭션 | HTTP 관련 코드, 뷰 렌더링 |
| **Model** | 데이터 무결성, 유효성, 관계, 스코프 | 외부 API 호출, 알림 발송 |
| **View/Helper** | 표시 형식, UI 로직 | DB 쿼리, 상태 변경 |
| **Concern** | 재사용 가능한 모델 행위 | 비즈니스 프로세스 |

### Side Effect 분리

```ruby
# 트랜잭션 내: 데이터 변경만
ActiveRecord::Base.transaction do
  order.save!
  inventory.decrement!
end

# 트랜잭션 밖: 부작용 (이메일, 알림, 외부 API)
OrderMailer.confirmation(order).deliver_later
broadcast_order_update(order)
```

### Model 콜백 제한

최대 3개. 데이터 무결성 관련만. 초과 시 Service로 추출.

```ruby
# ❌ 콜백 5개 — Service로 분리 필요
class User < ApplicationRecord
  after_create :send_welcome_email
  after_create :create_default_profile
  after_create :notify_admin
  after_create :track_signup
  after_create :sync_to_crm
end

# ✅ 콜백은 데이터 무결성만, 나머지는 Service
class User < ApplicationRecord
  after_create :create_default_profile
end
```

### 계층 간 데이터 전달

| 방향 | 방법 |
|------|------|
| Controller → Service | Keyword arguments |
| Service → Controller | Result object (`success?`, `errors`, `data`) |
| Controller → View | Instance variables (`@user`) |
| Model → View | 직접 접근 금지 → Helper/Presenter 경유 |

---

## SOLID 원칙

### S — 단일 책임 (Single Responsibility)

변경 이유가 2가지 이상이면 분리. Model은 데이터만, 부작용은 Service로.

### O — 개방/폐쇄 (Open/Closed)

확장에 열려 있고, 수정에 닫혀 있어야 한다. Concern/Strategy 패턴으로 기존 코드 수정 없이 확장.

```ruby
# ✅ 새 notifier 추가 시 기존 코드 수정 불필요
class NotificationService
  def initialize(notifier: EmailNotifier.new)
    @notifier = notifier
  end

  def call(message)
    @notifier.deliver(message)
  end
end
```

### L — 리스코프 치환 (Liskov Substitution)

자식 클래스는 부모 계약 준수. `raise NotImplementedError` 대신 의미 있는 구현 제공.

### I — 인터페이스 분리 (Interface Segregation)

God Concern 금지. 관심사별 Concern 분리 (각 3~5개 메서드).

```ruby
# ❌ 30개 메서드의 God Concern
module ContentManageable; end

# ✅ 관심사별 분리
module Searchable; end
module Taggable; end
```

### D — 의존성 역전 (Dependency Inversion)

생성자 주입으로 구체 클래스 하드코딩 방지. 테스트에서 mock 교체 가능.

```ruby
class ReportService
  def initialize(query: PostgresQuery.new, renderer: PdfRenderer.new)
    @query = query
    @renderer = renderer
  end

  def generate
    data = @query.fetch
    @renderer.render(data)
  end
end
```
