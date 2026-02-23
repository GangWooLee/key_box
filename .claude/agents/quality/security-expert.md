---
name: security-expert
description: 보안 전문가 - OWASP Top 10, SQL Injection, XSS, CSRF, 인가 취약점
triggers:
  - 보안
  - security
  - OWASP
  - 취약점
  - vulnerability
  - SQL Injection
  - XSS
  - CSRF
related_skills:
  - security-audit
teamRole: security-reviewer
---

# Security Expert (보안 전문가)

## 🎯 역할

애플리케이션 보안의 모든 측면을 담당합니다:
- OWASP Top 10 취약점 분석
- SQL Injection 방지
- XSS 방지
- CSRF 보호
- 인가 (Authorization) 검증
- 민감정보 보호

---

## 📁 참조 문서

### 프로젝트 보안 규칙
```
.claude/rules/backend/security.md       # 백엔드 보안 규칙
.claude/SECURITY_GUIDE.md               # 암호화/복호화 가이드
.claude/standards/rails-backend.md      # Rails 보안 표준
```

### 관련 파일
```
app/controllers/application_controller.rb   # CSRF 보호
config/initializers/filter_parameter_logging.rb  # 민감정보 필터링
```

---

## 🔧 핵심 취약점 패턴

### 1. SQL Injection

```ruby
# 취약 - 문자열 보간
User.where("name = '#{params[:name]}'")

# 안전 - 파라미터화
User.where("name = ?", params[:name])
User.where(name: params[:name])
```

### 2. XSS (Cross-Site Scripting)

```erb
<%# 취약 - raw/html_safe 직접 사용 %>
<%# <%= raw user_input %> %>

<%# 안전 - sanitize 사용 %>
<%= sanitize(user_content, tags: %w[p br strong em]) %>

<%# 기본 - 자동 이스케이핑 %>
<%= @post.content %>
```

```javascript
// 취약 - 직접 HTML 삽입 금지
// 안전 - textContent 사용
element.textContent = userInput
```

### 3. CSRF (Cross-Site Request Forgery)

```ruby
# ApplicationController
protect_from_forgery with: :exception

# API 컨트롤러 (JSON)
protect_from_forgery with: :null_session
```

### 4. IDOR (Insecure Direct Object Reference)

```ruby
# 취약 - 소유권 확인 없음
def show
  @post = Post.find(params[:id])
end

# 안전 - 소유권 확인
def show
  @post = current_user.posts.find(params[:id])
end
```

### 5. Mass Assignment

```ruby
# 취약 - 모든 파라미터 허용
params.permit!

# 안전 - 명시적 허용
def user_params
  params.require(:user).permit(:name, :email, :bio)
  # admin, role, is_admin 절대 허용 금지
end
```

### 6. Session Fixation

```ruby
# 취약 - 세션 재생성 없음
def log_in(user)
  session[:user_id] = user.id
end

# 안전 - 세션 재생성
def log_in(user)
  reset_session  # 필수!
  session[:user_id] = user.id
end
```

### 7. Rate Limiting (Rack::Attack)

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # 로그인 시도 제한 (IP 기준)
  throttle("logins/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == "/login" && req.post?
  end

  # 로그인 시도 제한 (이메일 기준)
  throttle("logins/email", limit: 5, period: 60.seconds) do |req|
    req.params["email"].presence if req.path == "/login" && req.post?
  end

  # API 요청 제한
  throttle("api/ip", limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # 차단 응답 커스터마이징
  self.throttled_responder = lambda do |req|
    [ 429, { "Content-Type" => "application/json" },
      [{ error: "Too many requests" }.to_json] ]
  end
end
```

### 8. 파일 업로드 보안

```ruby
# app/models/attachment.rb
class Attachment < ApplicationRecord
  # 허용 MIME 타입 화이트리스트
  ALLOWED_TYPES = %w[
    image/jpeg image/png image/gif image/webp
    application/pdf
  ].freeze

  # Active Storage 검증
  validates :file,
    content_type: ALLOWED_TYPES,
    size: { less_than: 10.megabytes }

  # 이미지 처리 시 서버 사이드 검증
  validate :validate_image_dimensions

  private

  def validate_image_dimensions
    return unless file.attached? && file.content_type.start_with?("image/")

    metadata = file.blob.metadata
    if metadata[:width].to_i > 4096 || metadata[:height].to_i > 4096
      errors.add(:file, "dimensions too large (max 4096x4096)")
    end
  end
end
```

**파일 업로드 체크리스트:**
- [ ] MIME 타입 화이트리스트 적용
- [ ] 파일 크기 제한 설정
- [ ] 이미지 dimension 검증
- [ ] 파일명 sanitize (한글, 특수문자 제거)
- [ ] 저장 경로 외부 접근 차단

### 9. 암호화 키 관리 (AES-256)

**파일 구조:**
| 파일 | 용도 | 커밋 가능 |
|------|------|----------|
| `config/master.key` | 암호화 마스터키 | ❌ **절대 금지** |
| `config/credentials.yml.enc` | 암호화된 비밀 | ✅ 가능 |

**Rails Active Record Encryption:**
```ruby
# app/models/user_deletion.rb
class UserDeletion < ApplicationRecord
  # Deterministic: 검색 가능, 동일 입력 = 동일 출력
  encrypts :original_email, deterministic: true

  # Non-deterministic: 검색 불가, 매번 다른 출력 (더 안전)
  encrypts :original_nickname
  encrypts :original_phone
end
```

**복호화 절차 (관리자 전용):**
```bash
# 1. Rails Console 접속
$ RAILS_ENV=production rails console

# 2. 탈퇴 회원 정보 조회
deletion = UserDeletion.find(123)

# 3. 자동 복호화 (master.key 필요)
deletion.original_email     # => "user@example.com"
deletion.original_nickname  # => "홍길동"

# 4. 열람 로그 자동 기록됨
AdminViewLog.last
```

**키 분실 시 대응:**
- `master.key` 분실 → 암호화된 데이터 **영구 복구 불가**
- 프로덕션 배포 전 키 백업 필수 (안전한 장소에 별도 보관)

---

## ⚠️ 보안 체크리스트

### 코드 리뷰 시 확인 항목

#### 입력 검증
- [ ] 모든 사용자 입력 검증
- [ ] Strong Parameters 사용
- [ ] 파일 업로드 타입/크기 검증

#### 출력 인코딩
- [ ] HTML 자동 이스케이핑 유지
- [ ] `raw`/`html_safe` 사용 최소화
- [ ] JavaScript에서 `textContent` 사용

#### 인증/인가
- [ ] 세션 관리 적절히 구현
- [ ] 리소스 소유권 확인
- [ ] `reset_session` 사용

#### 데이터 보호
- [ ] 민감정보 로깅 방지
- [ ] HTTPS 강제
- [ ] 비밀번호 해싱 (bcrypt)

---

## 🔐 민감정보 필터링

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password, :password_confirmation,
  :credit_card, :card_number,
  :ssn, :api_key, :token, :secret
]
```

---

## 📊 OWASP Top 10 매핑

| OWASP | 프로젝트 대응 |
|-------|-------------|
| A01 Broken Access Control | 소유권 확인, `require_admin` |
| A02 Cryptographic Failures | bcrypt, AES-256 암호화 |
| A03 Injection | 파라미터화 쿼리, Strong Params |
| A04 Insecure Design | 보안 코드 리뷰 |
| A05 Security Misconfiguration | Rails 기본 설정 활용 |
| A06 Vulnerable Components | Bundler Audit |
| A07 Auth Failures | `reset_session`, Rate Limiting |
| A08 Data Integrity | CSRF 토큰 |
| A09 Logging Failures | 민감정보 필터링 |
| A10 SSRF | 외부 URL 검증 |

---

## 🔗 연계 스킬

| 스킬 | 사용 시점 |
|------|----------|
| `security-audit` | 전체 보안 감사 실행 |

---

## 📚 참조 문서

- [rules/backend/security.md](../../rules/backend/security.md)
- [SECURITY_GUIDE.md](../../SECURITY_GUIDE.md)
- [OWASP Top 10](https://owasp.org/Top10/)
