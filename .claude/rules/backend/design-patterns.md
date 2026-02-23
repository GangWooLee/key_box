# Rails 설계 패턴 — 사용 기준

## 패턴 선택 가이드 (Quick Reference)

| 신호 | 패턴 |
|------|------|
| 컨트롤러 액션 10줄+ | Service Object |
| 2+ 모델 동시 저장 | Form Object |
| 복합 쿼리 (JOIN, 3+ 조건) | Query Object |
| 불변 데이터 (Money, Email) | Value Object |
| View 조건 분기 3+ | Presenter/Decorator |
| 읽기 전용 권한 확인 | Policy Object |

---

## Service Object

**언제**: 여러 모델에 걸친 비즈니스 로직, 외부 API 호출, 복잡한 후처리.

**규칙**:
- `.call` 단일 진입점
- 결과를 Result 객체로 반환
- `app/services/` 하위에 네임스페이스 정리

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

## Form Object

**언제**: 여러 모델 동시 저장, 가상 속성 필요, 다단계 위자드.

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

**언제**: 2+ 테이블 JOIN, 3+ 조건, 여러 곳에서 재사용.

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

**언제**: 불변 데이터, 동등성이 값으로 결정.

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

  def to_s
    "#{emoji} #{name}"
  end
end
```

## Presenter/Decorator

**언제**: View에서 조건 분기 3+, 모델 데이터의 표시 형식 변환, Helper가 5개 이상.

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

  def completion_rate
    total = Curriculum.count
    completed = user.user_progresses.completed.count
    return "0%" if total.zero?
    "#{(completed * 100.0 / total).round}%"
  end

  private

  attr_reader :user
end
```

## Policy Object

**언제**: 읽기 전용 권한 확인. Service와 구분 — Policy는 읽기, Service는 쓰기.

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
