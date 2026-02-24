# 테스팅 — 규칙 · CI 트러블슈팅

## 테스트 파일 구조

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:one)
  end

  # ===== Validations =====
  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  # ===== Associations =====
  # ===== Scopes =====
end
```

## 네이밍 규칙

```ruby
# 파일명
test/models/user_test.rb
test/controllers/posts_controller_test.rb
test/services/users/deletion_service_test.rb

# 테스트 메서드명 (한글 가능)
test "should validate presence of title" do
test "로그인 후 리다이렉트" do
```

## Fixture 규칙

```yaml
# test/fixtures/users.yml
one:
  email: user1@example.com
  name: 테스트 사용자 1
  password_digest: <%= BCrypt::Password.create('password123', cost: 4) %>
# cost: 4 사용 — 테스트 속도 향상 (기본 12 대비 ~1000배 빠름)
```

## 컨트롤러 테스트

```ruby
class PostsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect create when not logged in" do
    post posts_url, params: { post: { title: "Test" } }
    assert_redirected_to login_url
  end

  test "should create post when logged in" do
    log_in_as(@user)
    assert_difference "Post.count", 1 do
      post posts_url, params: { post: { title: "New", content: "Content" } }
    end
  end
end
```

## 금지 패턴

```ruby
# ❌ sleep 사용 금지
sleep 2
assert_text "결과"

# ✅ wait 옵션 사용
assert_text "결과", wait: 5

# ❌ 하드코딩된 ID → ✅ Fixture 사용: users(:one)
# ❌ 테스트 간 의존성 → ✅ 각 테스트 독립적으로 데이터 생성
```

## 커버리지 목표

| 영역 | 최소 커버리지 |
|------|-------------|
| 모델 Validations/Associations | 100% |
| 인증/인가/결제 | 100% |
| 서비스 객체 | 80% |
| 컨트롤러 (핵심) | 80% |
| 시스템 테스트 | 60% |

## 테스트 실행

```bash
bin/rails test                              # 전체
bin/rails test test/models/user_test.rb     # 특정 파일
SKIP_ASSET_BUILD=true bin/rails test        # CI용
```

---

## CI 트러블슈팅

### 1. Stale Element Reference (20%)

Turbo Stream이 DOM을 업데이트하면 기존 참조가 무효화됨.

```ruby
# ❌ 반복문 외부에서 캐시된 요소 참조
input = find("[data-comment-form-target='input']")
3.times do
  page.execute_script("arguments[0].dispatchEvent(...)", input)  # stale!
end

# ✅ 반복문 내부에서 매번 새로 찾기
3.times do
  page.execute_script(<<~JS)
    const input = document.querySelector("[data-comment-form-target='input']");
    if (input) { input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })); }
  JS
end
```

### 2. ESC 키 모달 닫기 (10%)

```ruby
# ❌ send_keys(:escape) — 포커스 문제
page.send_keys(:escape)

# ✅ document 레벨 이벤트
page.execute_script(<<~JS)
  document.dispatchEvent(new KeyboardEvent('keydown', {
    key: 'Escape', keyCode: 27, bubbles: true
  }));
JS
```

### 3. Stimulus Controller 타이밍 (25%)

```ruby
# ❌ 컨트롤러 연결 대기 없이 조작
visit some_path
find("[data-some-target='button']").click

# ✅ 컨트롤러 연결 대기 후 조작
visit some_path
assert_selector "[data-controller='some']", wait: 5
find("[data-some-target='button']").click
```

### 4. Dropdown 경쟁 조건 (15%)

```ruby
# ✅ 옵션 표시 대기 후 선택
find("[data-combobox-target='input']").click
assert_selector "[data-combobox-target='option']", wait: 5
find("[data-combobox-target='option']", text: "옵션").click
```

### 5. 상태 오염 (5%)

```ruby
# ✅ 유니크 식별자 사용
unique_text = "테스트 댓글 #{SecureRandom.hex(4)}"
fill_in "내용", with: unique_text
assert_text unique_text
```

### 6. JavaScript 클릭 (5%)

```ruby
# ✅ 오버레이 문제 시 JavaScript 직접 클릭
page.execute_script("arguments[0].click()", find(".hidden-button"))
```

### 7. 리다이렉트 체인 타이밍 (10%)

```ruby
# ✅ Turbo 완료 대기 후 확인
visit some_protected_path
assert_no_selector ".turbo-progress-bar", wait: 10
assert_current_path login_path, wait: 10
```

## CI 에러 → 패턴 매칭

| 에러 키워드 | 패턴 |
|------------|------|
| `StaleElementReferenceError` | #1 Stale Element |
| `keydown`, `Escape` | #2 ESC 키 |
| `data-controller`, `not found` | #3 Stimulus 타이밍 |
| `Unable to find option` | #4 Dropdown 경쟁 |
| `Expected X but got Y` | #5 상태 오염 |
| `not clickable` | #6 클릭 문제 |
| `Expected "/path" but actual is` | #7 리다이렉트 |

## System Test 체크리스트

- Turbo Stream 후 요소 재참조
- Stimulus 컨트롤러 연결 대기 (`assert_selector wait: 5`)
- 유니크 식별자 사용 (`SecureRandom`/`Time.now`)
- ESC 키는 `document.dispatchEvent` 사용
- 드롭다운 옵션 표시 대기
- 숨겨진 요소는 JavaScript 클릭
- `sleep` 대신 `assert_selector`/`assert_text` wait 사용
- 보호된 경로: Turbo 로딩 완료 대기
- `assert_current_path`에 `wait:` 옵션 사용
