# 안전 · 보안 규칙 — 안티패턴 방지 + OWASP 기반

## SQL Injection 방지

```ruby
# ❌ 취약 - 문자열 보간 금지
User.where("name = '#{params[:name]}'")
User.where("id IN (#{ids.join(',')})")

# ✅ 안전 - 파라미터화
User.where("name = ?", params[:name])
User.where(name: params[:name])
User.where(id: ids)
```

## XSS 방지

```erb
<%# ❌ 취약 - raw/html_safe 직접 사용 금지 %>
<%= raw user_input %>
<%= user_input.html_safe %>

<%# ✅ 안전 - sanitize 필수 %>
<%= sanitize(user_content, tags: %w[p br strong em]) %>

<%# ✅ 기본 자동 이스케이핑 활용 %>
<%= @post.content %>
```

## CSRF 보호

```ruby
protect_from_forgery with: :exception        # 일반 컨트롤러
protect_from_forgery with: :null_session     # API 컨트롤러
```

## Strong Parameters (Mass Assignment 방지)

```ruby
# ❌ 절대 금지
params.permit!
user.update(params[:user])

# ✅ 명시적 허용
def user_params
  params.require(:user).permit(:name, :email, :bio)
end
# 절대 허용 금지: :admin, :role, :is_admin
```

## N+1 쿼리 방지

```ruby
# ❌ N+1 발생 - 절대 금지
@posts.each { |post| post.user.name }

# ✅ includes 사용
@posts = Post.includes(:user, :comments).all

# ✅ joins + select (집계용)
Post.joins(:comments).select("posts.*, COUNT(comments.id) as comments_count").group("posts.id")
```

## 페이지네이션 필수

```ruby
# ❌ 전체 조회 금지
User.all
Post.where(published: true)

# ✅ 페이지네이션 필수
User.page(params[:page]).per(20)
Post.where(published: true).page(params[:page])
```

## 인증 규칙

### 세션 관리

```ruby
# 로그인 시 세션 재생성 (Session Fixation 방지)
def log_in(user)
  reset_session  # 필수!
  session[:user_id] = user.id
end

# 로그아웃 시 완전 초기화
def log_out
  reset_session
  @current_user = nil
end
```

### 비밀번호 정책

```ruby
validates :password, length: { minimum: 8 }
# 권장: 12자 이상, 대소문자+숫자 포함
```

## 인가 — 리소스 소유권 확인 필수

```ruby
# ❌ IDOR 취약 - 누구나 접근 가능
@post = Post.find(params[:id])

# ✅ 안전 - 소유권 확인
@post = current_user.posts.find(params[:id])

# 또는 별도 인가 체크
before_action :authorize_post, only: [:edit, :update, :destroy]
```

## 파일 업로드 검증

```ruby
validate :acceptable_file

def acceptable_file
  return unless file.attached?
  unless file.content_type.in?(%w[image/jpeg image/png image/gif])
    errors.add(:file, "은(는) JPEG, PNG, GIF만 허용됩니다")
  end
  if file.byte_size > 5.megabytes
    errors.add(:file, "은(는) 5MB 이하만 허용됩니다")
  end
end
```

## 민감정보 필터링

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password, :password_confirmation,
  :credit_card, :card_number,
  :ssn, :api_key, :token, :secret
]
```

## 로깅 규칙

```ruby
# ❌ 민감정보 로깅 금지
Rails.logger.info "Password: #{password}"
Rails.logger.info "Token: #{api_token}"

# ✅ 컨텍스트만 로깅
Rails.logger.info "[AUTH] User##{user.id} logged in"
Rails.logger.error "[PAYMENT] Order##{order.id} failed: #{e.class}"
```

## Rate Limiting

```ruby
Rack::Attack.throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == '/login' && req.post?
end
```

## 프로덕션 환경 금지 명령어

```bash
# ❌ 절대 금지 (데이터 손실)
rails db:reset
rails db:drop
User.destroy_all
Post.delete_all
git push --force origin main
```
