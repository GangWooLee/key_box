# KeyBox — Technical Architecture

> Rails 8 + Hotwire + Tailwind CSS + SQLite 기반 기술 아키텍처

## 기술 스택

| 레이어 | 기술 | 버전 |
|--------|------|------|
| Framework | Ruby on Rails | 8.1.2 |
| Language | Ruby | 3.4.7 |
| Frontend | Hotwire (Turbo + Stimulus) | Rails 8 기본 |
| CSS | Tailwind CSS | v4.2.0 |
| Database | SQLite | 개발/MVP |
| 암호화 | Ruby OpenSSL (AES-256-GCM) | 표준 라이브러리 |
| 비밀번호 | bcrypt | ~> 3.1.7 |
| 에셋 | Propshaft + Importmap | Rails 8 기본 |

---

## 암호화 아키텍처 (2-Layer Key Hierarchy)

### 전체 흐름도

```
User Password
    │  PBKDF2-HMAC-SHA256 (600K iterations, per-user salt)
    ▼
Password-Derived Key (PDK)     ← 메모리에만 존재, 저장 안 함
    │  AES-256-GCM unwrap
    ▼
Master Encryption Key (MEK)    ← users.encrypted_master_key에 래핑 저장
    │  AES-256-GCM per-secret
    ▼
Secret Values                  ← secrets.encrypted_value에 암호화 저장
```

### 왜 2단계인가?

| 시나리오 | 1단계 (직접 암호화) | 2단계 (Key Hierarchy) |
|---------|--------------------|-----------------------|
| 비밀번호 변경 | 모든 시크릿 재암호화 O(n) | MEK 래퍼만 재암호화 O(1) |
| 시크릿 추가 | OK | OK |
| 비밀번호 분실 | 모든 데이터 손실 | 모든 데이터 손실 (동일) |

### 암호화 파라미터

| 파라미터 | 값 | 이유 |
|---------|----|----|
| PBKDF2 iterations | 600,000 | OWASP 2023 권장값 |
| PBKDF2 digest | SHA-256 | 표준 |
| Salt 길이 | 32 bytes | Per-user 고유 |
| MEK 길이 | 32 bytes | AES-256 요구사항 |
| AES mode | GCM | 기밀성 + 무결성 동시 보장 |
| Auth tag 길이 | 16 bytes | GCM 표준 |
| IV 길이 | 12 bytes | GCM 표준 |

### 세션과 MEK 라이프사이클

```
로그인 시:
  1. 사용자 비밀번호 입력
  2. PBKDF2로 PDK 유도 (salt는 DB에서 로드)
  3. PDK로 encrypted_master_key 언래핑 → MEK 획득
  4. MEK를 Base64 인코딩하여 서버 세션에 저장
  5. PDK는 메모리에서 즉시 폐기

세션 만료 시:
  - MEK 자동 소멸 (세션과 함께)
  - 사용자는 재로그인하여 MEK 재유도 필요
  - 암호화된 데이터는 DB에 안전하게 유지

Remember Me:
  - 쿠키에 remember_token만 저장 (MEK 미포함)
  - Remember 인증 시 로그인 세션만 생성
  - 시크릿 접근 시 비밀번호 재입력 필요 (세션에 MEK 없으므로)
```

### 보안 설계 결정

| 결정 | 이유 |
|------|------|
| 외부 암호화 gem 미사용 | 핵심 가치 = 암호화. 공급망 리스크 최소화 |
| 메타데이터 평문 저장 | 검색 기능 제공을 위해. 1Password, Bitwarden도 동일 트레이드오프 |
| MEK 서버 세션 저장 | 클라이언트에 절대 노출 안 됨. 서버 메모리에만 존재 |
| Remember Me 시 MEK 미저장 | 비밀번호 재입력으로 MEK 재유도 필수 |
| GCM 모드 선택 | 암호문 변조 탐지 (auth_tag). CBC는 padding oracle 취약 |

---

## 데이터베이스 스키마

### ERD

```
┌─────────┐     ┌─────────────┐     ┌─────────┐
│  users  │────<│ memberships │>────│ vaults  │
└────┬────┘     └─────────────┘     └────┬────┘
     │                                    │
     │                              ┌─────┴─────┐
     │                              │            │
     │                         ┌────────┐  ┌─────────┐
     │                         │ folders│──│ secrets │
     │                         └────────┘  └────┬────┘
     │                                          │
     │              ┌──────────────┐             │
     └─────────────>│ audit_events │<────────────┘
                    └──────────────┘
```

### users

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| email | string | NOT NULL, UNIQUE | 로그인 식별자 |
| name | string(50) | NOT NULL | 표시 이름 |
| password_digest | string | NOT NULL | bcrypt 해시 |
| remember_digest | string | nullable | 30일 기억 토큰 해시 |
| master_key_salt | binary(32) | NOT NULL | PBKDF2 salt (per-user) |
| encrypted_master_key | binary(60) | NOT NULL | PDK로 래핑된 MEK |
| last_login_at | datetime | nullable | 마지막 로그인 시각 |
| last_login_ip | string(45) | nullable | IPv6 지원 |

### vaults

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| name | string(100) | NOT NULL | Vault 이름 |
| description | string(500) | nullable | 설명 |
| vault_type | integer | NOT NULL, default: 0 | 0=personal, 1=team |

### memberships

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| user_id | references | NOT NULL, FK | 사용자 |
| vault_id | references | NOT NULL, FK | Vault |
| role | integer | NOT NULL, default: 0 | 0=owner, 1=admin, 2=member, 3=viewer |

- Unique index: `[user_id, vault_id]`

### folders

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| vault_id | references | NOT NULL, FK | 소속 Vault |
| name | string(100) | NOT NULL | 폴더 이름 |
| icon | string(50) | default: "folder" | 아이콘 식별자 |
| position | integer | NOT NULL, default: 0 | 정렬 순서 |
| secrets_count | integer | NOT NULL, default: 0 | counter_cache |

- Unique index: `[vault_id, name]`

### secrets

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| folder_id | references | NOT NULL, FK | 소속 폴더 |
| vault_id | references | NOT NULL, FK | 소속 Vault (비정규화) |
| name | string(200) | NOT NULL | 시크릿 이름 |
| encrypted_value | binary | NOT NULL | AES-256-GCM 암호문 |
| encrypted_value_iv | binary(12) | NOT NULL | 초기화 벡터 |
| encrypted_value_auth_tag | binary(16) | NOT NULL | 인증 태그 |
| notes | text(2000) | nullable | 평문 메모 (검색용) |
| tags | string(500) | nullable | 쉼표 구분 태그 |
| secret_type | string | NOT NULL, default: "api_key" | 유형 |
| service_name | string(100) | nullable | 서비스명 |
| environment | string(50) | nullable | 환경 |
| last_accessed_at | datetime | nullable | 마지막 접근 |
| access_count | integer | NOT NULL, default: 0 | 접근 횟수 |

- `secret_type` 허용값: api_key, token, password, credential, certificate, ssh_key, other
- `environment` 허용값: production, staging, development, test

### audit_events (append-only, immutable)

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| user_id | references | NOT NULL, FK | 행위자 |
| vault_id | references | NOT NULL, FK | 대상 Vault |
| secret_id | references | nullable, FK | 대상 시크릿 |
| action | string(50) | NOT NULL | 행위 코드 |
| ip_address | string(45) | nullable | 클라이언트 IP |
| user_agent | string(500) | nullable | 브라우저 정보 |
| metadata | json | nullable | 추가 데이터 |
| created_at | datetime | NOT NULL | 발생 시각 |

- `updated_at` 없음 — 불변 레코드
- `before_update` / `before_destroy` → `ReadOnlyRecord` 예외 발생
- 허용 action: secret.create/read/update/delete/copy, vault.create/update, folder.create/update/delete, user.login/logout/signup

### 스키마 설계 결정

| 결정 | 이유 |
|------|------|
| `vault_id` on secrets (비정규화) | 폴더 경유 없이 vault 단위 검색 O(1) |
| `secrets_count` on folders | 사이드바 폴더별 카운트 N+1 방지 |
| `audit_events`에 `updated_at` 없음 | 감사 로그 불변성 보장 |
| `tags` comma-separated string | MVP 단순성. 추후 정규화 가능 |
| `encrypted_value_iv/auth_tag` 별도 컬럼 | GCM 복호화에 개별 접근 필요 |

---

## 서비스 객체 구조

### 암호화 서비스 파이프라인

```
app/services/encryption/
├── key_derivation_service.rb    # PBKDF2: password + salt → PDK
├── master_key_service.rb        # MEK 생성, wrap(PDK→MEK), unwrap(PDK→MEK)
└── secret_encryption_service.rb # AES-256-GCM encrypt/decrypt per-secret
```

**KeyDerivationService** — 비밀번호 → 키 유도

| 메서드 | 입력 | 출력 |
|--------|------|------|
| `.generate_salt` | — | 32-byte random salt |
| `.derive_key(password:, salt:)` | password, salt | 32-byte PDK |

**MasterKeyService** — MEK 생성/래핑

| 메서드 | 입력 | 출력 |
|--------|------|------|
| `.generate_master_key` | — | 32-byte random MEK |
| `.wrap(master_key:, wrapping_key:)` | MEK, PDK | 60-byte wrapped blob |
| `.unwrap(wrapped_key:, wrapping_key:)` | blob, PDK | MEK or nil |

**SecretEncryptionService** — 시크릿 값 암호화

| 메서드 | 입력 | 출력 |
|--------|------|------|
| `.encrypt(value:, key:)` | plaintext, MEK | {encrypted_value, iv, auth_tag} |
| `.decrypt(encrypted_value:, iv:, auth_tag:, key:)` | 암호문+IV+태그, MEK | plaintext or nil |

### 비즈니스 서비스

```
app/services/users/
└── registration_service.rb  # Result(success?, user, errors)
```

**RegistrationService 트랜잭션 흐름**:
```
1. salt 생성 → PBKDF2로 PDK 유도
2. 랜덤 MEK 생성 → PDK로 MEK 래핑
3. User.new (email, name, password, salt, wrapped_mek)
4. valid? 실패 시 → Result(false, user, errors)
5. 트랜잭션 시작
   5a. user.save!
   5b. Vault.create!(name: "Personal", type: personal)
   5c. Membership.create!(user, vault, role: owner)
   5d. Folder.create!(vault, name: "General")
6. 트랜잭션 커밋 → Result(true, user, [])
```

---

## 인증 시스템

### Authentication Concern 구조

```ruby
module Authentication
  # Helper methods (뷰에서 사용 가능)
  current_user         # → User or nil
  logged_in?           # → Boolean

  # Guards
  require_login        # before_action: 미인증 시 login 리다이렉트

  # Session management
  log_in(user, password:)     # reset_session + MEK 저장
  log_out                      # reset_session + @current_user = nil
  master_encryption_key        # session[:mek] → Base64 디코딩

  # Remember me
  remember(user)       # encrypted cookie (30일)
  forget(user)         # cookie 삭제

  # Redirect helpers
  store_location       # GET 요청 URL 저장
  redirect_back_or     # 저장된 URL 또는 기본값으로 이동
end
```

### 보안 체크리스트

- [x] `reset_session` on login (Session Fixation 방지)
- [x] `cookies.encrypted` for remember token (not signed)
- [x] bcrypt password hashing
- [x] CSRF protection (Rails 기본)
- [x] MEK는 서버 세션에만 저장
- [x] 이메일 대소문자 정규화 (downcase + strip)
- [x] 비밀번호 최소 8자

---

## 라우트 구조

### 현재 (Phase 0)

```
GET    /login   → sessions#new
POST   /login   → sessions#create
DELETE /logout  → sessions#destroy
GET    /signup  → registrations#new
POST   /signup  → registrations#create
GET    /        → vaults#show (대시보드)
GET    /up      → health check
```

### 예정 (Phase 1)

```
GET    /search  → search#index

resources :vaults, only: [:show, :edit, :update] do
  resources :folders, except: [:show] do
    resources :secrets, shallow: true
  end
  resources :audit_events, only: [:index], path: "audit"
end

POST   /secrets/:id/copy → secrets#copy
```

### 예정 (Phase 3)

```
namespace :api do
  namespace :v1 do
    resources :secrets, only: [:index, :show, :create, :update, :destroy]
    resources :folders, only: [:index, :create, :update, :destroy]
    get :search, to: "search#index"
  end
end
```

---

## 모델 관계

```
User ──1:N──> Membership ──N:1──> Vault
User ──1:N──> AuditEvent
Vault ──1:N──> Folder ──1:N──> Secret
Vault ──1:N──> Secret (비정규화 직접 참조)
Vault ──1:N──> AuditEvent
Secret ──0:N──> AuditEvent
```

### 모델별 핵심 규칙

| 모델 | 핵심 규칙 |
|------|----------|
| User | `has_secure_password`, 이메일 unique + downcase, 비밀번호 8자+ |
| Vault | enum vault_type (personal/team), `prefix: true` |
| Membership | unique [user_id, vault_id], enum role (owner/admin/member/viewer) |
| Folder | unique [vault_id, name], `scope :ordered` (position ASC) |
| Secret | `counter_cache: true` on folder, `record_access!` 메서드 |
| AuditEvent | 불변 (update/destroy 시 ReadOnlyRecord 예외) |

---

## 프론트엔드 구조

### 현재 레이아웃

- **Nav**: KeyBox 로고 + 이메일 + Logout
- **Flash**: success (green), alert (red)
- **Dashboard**: 2패널 (폴더 사이드바 + 메인 콘텐츠)

### Phase 1 Stimulus 컨트롤러 계획

| 컨트롤러 | targets | values | actions |
|----------|---------|--------|---------|
| `search` | input, results | url, debounce(300) | search (input) |
| `clipboard` | source, button | clearAfter(30) | copy (click) |
| `secret_reveal` | value, toggle | revealed(false) | toggle (click) |

### Tailwind 디자인 토큰

| 요소 | 클래스 |
|------|--------|
| Primary | `bg-indigo-600 hover:bg-indigo-700` |
| 카드 | `bg-white rounded-xl shadow-sm border border-gray-100 p-6` |
| 입력 | `w-full px-4 py-2 border border-gray-300 rounded-lg text-base` |
| 포커스 | `focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500` |
| 버튼 | `min-h-[44px] focus-visible:ring-2 focus-visible:ring-offset-2` |

---

## 관련 문서

- [[Product Design]] — 제품 개요, 경쟁 분석, 차별점
- [[Phase Plan]] — 구현 계획, Quality Gate, 진행 상황
