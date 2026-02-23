# 계층 분리 — Controller↔Service↔Model 책임 경계

## 계층 구조 및 의존성 방향

```
Controller → Service → Model → Database
     ↓           ↓
   View      External API
```

의존성은 항상 안쪽(Model)을 향한다.
- Model은 Controller/Service를 모른다.
- Service는 Controller를 모른다.

## 각 계층의 책임

| 계층 | 책임 | 금지 |
|------|------|------|
| **Controller** | HTTP 파싱, 인증/인가, 응답 형식 | 비즈니스 로직, 직접 복합 DB 쿼리 |
| **Service** | 비즈니스 프로세스 조율, 트랜잭션 | HTTP 관련 코드, 뷰 렌더링 |
| **Model** | 데이터 무결성, 유효성, 관계, 스코프 | 외부 API 호출, 알림 발송 |
| **View/Helper** | 표시 형식, UI 로직 | DB 쿼리, 상태 변경 |
| **Concern** | 재사용 가능한 모델 행위 | 비즈니스 프로세스 |

## Controller 슬림화 패턴

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

**기준**: 컨트롤러 액션이 10줄을 초과하면 Service 추출을 검토한다.

## Side Effect 분리 원칙

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

트랜잭션 안에서 외부 API 호출/메일 발송을 하면, 롤백 시 되돌릴 수 없는 부작용이 남는다.

## Model의 콜백 제한

모델 콜백은 최대 3개. 초과 시 Service로 추출.

```ruby
# ❌ 콜백이 5개 — 테스트와 추적이 어려움
class User < ApplicationRecord
  after_create :send_welcome_email
  after_create :create_default_profile
  after_create :notify_admin
  after_create :track_signup
  after_create :sync_to_crm
end

# ✅ 콜백은 데이터 무결성 관련만, 나머지는 Service로
class User < ApplicationRecord
  after_create :create_default_profile  # 데이터 무결성
end
```

## 계층 간 데이터 전달

| 방향 | 방법 |
|------|------|
| Controller → Service | Keyword arguments, params hash |
| Service → Controller | Result object (`success?`, `errors`, `data`) |
| Controller → View | Instance variables (`@user`) |
| Model → View | 직접 접근 금지 → Helper/Presenter 경유 |
