---
globs: "app/**/*.rb,lib/**/*.rb"
---

# SOLID 원칙 — Rails/Ruby 맞춤 가이드

## S — Single Responsibility Principle (단일 책임)

**판단 기준**: "이 클래스를 변경해야 하는 이유가 2가지 이상인가?"

| 계층 | 책임 | 분리 대상 |
|------|------|----------|
| Model | 데이터 무결성 + 비즈니스 규칙 | 알림, 외부 API 호출 → Service |
| Controller | HTTP 요청 처리 + 응답 | 비즈니스 로직 → Service/Model |
| Stimulus | 하나의 UI 관심사 | video-player ≠ suggestion-banner |

```ruby
# ❌ 모델이 알림까지 담당
class Order < ApplicationRecord
  after_create :send_confirmation_email
  after_create :notify_slack
end

# ✅ 모델은 데이터만, 부작용은 Service로
class Order < ApplicationRecord
  # 유효성, 관계, 스코프만
end

class Orders::CreationService
  def call
    order = Order.create!(params)
    OrderMailer.confirmation(order).deliver_later
    SlackNotifier.notify(order)
  end
end
```

## O — Open/Closed Principle (개방/폐쇄)

확장에 열려 있고, 수정에 닫혀 있어야 한다.

```ruby
# ❌ 타입 추가마다 기존 코드 수정
def notify(type, message)
  if type == :email
    send_email(message)
  elsif type == :sms
    send_sms(message)
  elsif type == :push
    send_push(message)
  end
end

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

- Concern으로 기능 확장 (기존 모델 수정 없이)
- Strategy 패턴: 동작을 클래스로 분리하고 주입

## L — Liskov Substitution Principle (리스코프 치환)

자식 클래스는 부모 클래스를 대체할 수 있어야 한다.

```ruby
# ❌ STI 자식이 부모 계약을 위반
class Payment < ApplicationRecord
  def process!
    # 공통 로직
  end
end

class BitcoinPayment < Payment
  def process!
    raise NotImplementedError  # 부모 계약 위반!
  end
end

# ✅ 의미 있는 기본 구현 또는 공통 인터페이스 보장
class BitcoinPayment < Payment
  def process!
    validate_wallet!
    submit_to_blockchain
  end
end
```

- 테스트: 부모 테스트가 모든 자식에도 통과해야 함
- `raise NotImplementedError` 대신 의미 있는 기본 구현 제공

## I — Interface Segregation Principle (인터페이스 분리)

사용하지 않는 메서드를 강제하는 모듈 include 금지.

```ruby
# ❌ God Concern — 모든 기능을 하나에
module ContentManageable
  extend ActiveSupport::Concern
  # 검색, 태깅, 댓글, 좋아요, 공유... 30개 메서드
end

# ✅ 관심사별 분리 (각 3~5개 메서드)
module Searchable
  extend ActiveSupport::Concern
  included { scope :search, ->(q) { where("name ILIKE ?", "%#{q}%") } }
end

module Taggable
  extend ActiveSupport::Concern
  # 태그 관련만
end
```

## D — Dependency Inversion Principle (의존성 역전)

고수준 모듈이 저수준 모듈에 의존하지 않아야 한다.

```ruby
# ❌ Service가 구체 클래스에 직접 의존
class ReportService
  def generate
    data = PostgresQuery.new.fetch  # 구체 클래스 하드코딩
    PdfRenderer.new.render(data)    # 교체 불가
  end
end

# ✅ 생성자 주입 — 테스트에서 mock 교체 가능
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
