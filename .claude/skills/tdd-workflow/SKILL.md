---
name: tdd-workflow
description: "Rails TDD 워크플로우. Minitest + fixtures 기반 RED → GREEN → REFACTOR 사이클."
---

# TDD 워크플로우 스킬

## 7단계 프로세스

### 1. 사용자 시나리오 작성
구현할 기능의 사용자 관점 시나리오를 정의합니다.

### 2. 테스트 케이스 생성
시나리오를 Minitest 테스트로 변환합니다.

```ruby
# test/models/order_test.rb
class OrderTest < ActiveSupport::TestCase
  test "주문 총액은 항목 합계와 일치해야 한다" do
    order = orders(:pending)
    assert_equal 15_000, order.total_amount
  end

  test "재고 부족 시 주문을 거부해야 한다" do
    assert_raises(Order::InsufficientStockError) do
      Order.create_from_cart(carts(:overstock))
    end
  end
end
```

### 3. 테스트 실행 — 실패 확인 (RED)
```bash
bin/rails test test/models/order_test.rb
```
**반드시 실패해야 합니다.** 통과하면 테스트가 의미 없습니다.

### 4. 최소 구현 (GREEN)
테스트를 통과하는 **최소한의** 코드만 작성합니다.

### 5. 테스트 재실행
```bash
bin/rails test test/models/order_test.rb
```
모든 테스트가 통과하는지 확인합니다.

### 6. 리팩토링 (REFACTOR)
테스트가 통과하는 상태에서 코드 품질을 개선합니다.
- 중복 제거
- 메서드 추출
- 네이밍 개선

### 7. 커버리지 확인
```bash
bin/rails test  # 전체 테스트 통과 확인
```

## 테스트 유형별 패턴

### 모델 테스트
```ruby
class UserTest < ActiveSupport::TestCase
  # 유효성 검사
  test "이메일 없이 저장하면 실패" do
    user = User.new(name: "테스트")
    assert_not user.valid?
    assert_includes user.errors[:email], "을(를) 입력해 주세요"
  end

  # 스코프
  test "active 스코프는 활성 사용자만 반환" do
    assert_includes User.active, users(:active_user)
    assert_not_includes User.active, users(:inactive_user)
  end

  # 비즈니스 로직
  test "비밀번호 재설정 토큰 생성" do
    user = users(:one)
    user.generate_reset_token!
    assert_not_nil user.reset_token
    assert user.reset_token_expires_at > Time.current
  end
end
```

### 컨트롤러 테스트
```ruby
class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    log_in_as(@user)
  end

  test "인증 없이 접근하면 리디렉트" do
    log_out
    get posts_url
    assert_redirected_to login_url
  end

  test "게시글 생성 성공" do
    assert_difference("Post.count") do
      post posts_url, params: { post: { title: "새 글", body: "내용" } }
    end
    assert_redirected_to post_url(Post.last)
  end
end
```

### 시스템 테스트 (Capybara)
```ruby
class LoginFlowTest < ApplicationSystemTestCase
  test "사용자 로그인 후 대시보드 표시" do
    visit login_url
    fill_in "이메일", with: users(:one).email
    fill_in "비밀번호", with: "password123"
    click_on "로그인"

    assert_selector "h1", text: "대시보드"
    assert_text users(:one).name
  end
end
```

## 커버리지 기준

| 영역 | 최소 커버리지 |
|------|-------------|
| 인증/결제 | 100% |
| 컨트롤러 | 80% |
| 모델 | 80% |
| 시스템 테스트 | 60% |

## 핵심 원칙
> **항상 테스트를 먼저 작성하고, 테스트를 통과하는 코드를 구현합니다.**

### 해야 할 것
- ✅ 테스트 먼저 작성
- ✅ 실패 확인 후 구현
- ✅ fixtures 활용
- ✅ 엣지 케이스 테스트 (nil, 빈 값, 경계값)

### 하지 말아야 할 것
- ❌ 구현 후 테스트 작성
- ❌ 테스트 실행 생략
- ❌ 구현 세부사항 테스트 (내부 구조가 아닌 동작 테스트)
- ❌ 테스트 간 의존성
