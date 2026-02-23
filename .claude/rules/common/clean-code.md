# 클린 코드 원칙

## Law of Demeter (디미터 법칙)

최대 1단계 체이닝. "친구의 친구에게 말하지 마라."

```ruby
# ❌ 3단계 체이닝
order.user.address.city

# ✅ delegate로 1단계
class Order < ApplicationRecord
  belongs_to :user
  delegate :city, to: :user, prefix: true  # order.user_city
end
```

**주의**: delegation은 결합도를 숨길 뿐, 해소하지 않음 (Sandi Metz).
과도한 delegation 체인은 설계 문제의 신호.

**예외**: Builder 패턴 — ActiveRecord 쿼리 체이닝은 허용:
```ruby
User.active.where(role: :admin).order(:name)  # ✅ 같은 추상화 수준
```

## Tell, Don't Ask (묻지 말고 시켜라)

객체의 상태를 물어보고 외부에서 결정하지 말고, 객체에게 행동을 시켜라.

```ruby
# ❌ 상태를 묻고 외부에서 결정
if user.subscription.active? && user.subscription.plan.premium?
  grant_premium_access(user)
end

# ✅ 결정은 객체 내부에서
user.grant_access_if_eligible!
```

View에서도 동일: 조건 분기 대신 Helper/Presenter 메서드 호출.

```erb
<%# ❌ View에서 로직 %>
<% if user.results.count > 0 && user.level.present? %>
  <%= user.level.name %>
<% end %>

<%# ✅ Helper에서 처리 %>
<%= display_user_level(user) %>
```

## Command-Query Separation (CQS)

"질문이 답을 바꿔서는 안 된다."

| 유형 | 역할 | 반환 |
|------|------|------|
| Command | 상태 변경 | void (또는 self) |
| Query | 상태 읽기 | 값 |

```ruby
# ❌ 하나의 메서드가 둘 다 수행
def next_item
  @index += 1        # 상태 변경 (Command)
  items[@index]      # 값 반환 (Query)
end

# ✅ 분리
def advance!          # Command
  @index += 1
end

def current_item      # Query
  items[@index]
end
```

## KISS & YAGNI

- 현재 필요한 최소한만 구현 (미래 요구사항 예측 금지)
- 추상화는 3번째 중복부터 (Rule of Three)
- 한 줄 메서드가 유틸 클래스보다 나음 (사용처가 1곳이면)
- 설정 가능성(configurability) 추가는 실제 요청이 있을 때만

## 의미 있는 이름 짓기

| 대상 | 규칙 | 예시 |
|------|------|------|
| 불리언 | `?` 접미사 또는 `is_`/`has_`/`can_` | `active?`, `has_subscription?` |
| 컬렉션 | 복수형 | `items`, `users` |
| 메서드 | 동사 시작 | `calculate_total`, `send_notification` |
| 축약 | 금지 | `btn` → `button`, `mgr` → `manager` |
| 맥락 | 의미 제공 | `d` → `elapsed_days_since_creation` |

## 메서드 설계 원칙

- **한 가지 일만** 수행
- **추상화 수준 통일** — 고수준 + 저수준 혼합 금지
- **부작용 명시** — `!` 접미사 또는 명확한 이름 (`save!`, `destroy_all!`)
- **파라미터 3개 초과** → Hash/Keyword Arguments로 래핑

```ruby
# ❌ 추상화 수준 혼합
def process_order(order)
  validate(order)                          # 고수준
  conn = PG.connect(dbname: 'mydb')        # 저수준!
  conn.exec("INSERT INTO orders ...")      # 저수준!
  send_confirmation(order)                 # 고수준
end

# ✅ 추상화 수준 통일
def process_order(order)
  validate(order)
  persist(order)
  send_confirmation(order)
end
```
