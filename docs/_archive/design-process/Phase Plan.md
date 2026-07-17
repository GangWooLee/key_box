# KeyBox — Phase Plan

> 구현 계획, Quality Gate, 진행 상황 추적

## Phase 개요

```
Phase 0: Core Infrastructure        ✅ 완료
Phase 1: Secret CRUD + Search       ⬜ 예정
Phase 2: Team + Security 강화       ⬜ 추후
Phase 3: API + Integrations         ⬜ 추후
```

---

## Phase 0: Core Infrastructure ✅

**목표**: 유저 인증 + 암호화 파이프라인 + 기본 레이아웃

### 완료된 작업

| # | 작업 | 핵심 파일 | 상태 |
|---|------|----------|------|
| 1 | Rails 8 앱 부트스트랩 | Gemfile, config/ | ✅ |
| 2 | DB 마이그레이션 6개 | db/migrate/ | ✅ |
| 3 | 모델 6개 (검증, 관계, 스코프) | app/models/ | ✅ |
| 4 | 암호화 서비스 3종 | app/services/encryption/ | ✅ |
| 5 | 인증 시스템 | Authentication concern + controllers | ✅ |
| 6 | 레이아웃 + 인증 뷰 | app/views/ | ✅ |
| 7 | 테스트 작성 | test/ (13개 파일) | ✅ |
| 8 | Quality Gate 통과 | 빌드 + 테스트 + 린트 | ✅ |

### Quality Gate 결과

```
✅ bin/rails runner "puts 'OK'"     → OK
✅ bin/rails test                   → 101 runs, 158 assertions, 0 failures
✅ bundle exec rubocop              → 57 files, 0 offenses
```

### 생성된 파일 구조

```
app/
├── controllers/
│   ├── application_controller.rb       # Authentication 포함
│   ├── concerns/authentication.rb      # 인증 concern
│   ├── sessions_controller.rb          # 로그인/로그아웃
│   ├── registrations_controller.rb     # 회원가입
│   └── vaults_controller.rb            # 대시보드
├── models/
│   ├── user.rb                         # has_secure_password, 암호화 키
│   ├── vault.rb                        # enum vault_type
│   ├── membership.rb                   # enum role
│   ├── folder.rb                       # counter_cache
│   ├── secret.rb                       # 암호화된 값
│   └── audit_event.rb                  # 불변 로그
├── services/
│   ├── encryption/
│   │   ├── key_derivation_service.rb   # PBKDF2
│   │   ├── master_key_service.rb       # MEK wrap/unwrap
│   │   └── secret_encryption_service.rb # AES-256-GCM
│   └── users/
│       └── registration_service.rb     # 회원가입 오케스트레이션
└── views/
    ├── layouts/application.html.erb    # Tailwind 레이아웃
    ├── sessions/new.html.erb           # 로그인 페이지
    ├── registrations/new.html.erb      # 회원가입 페이지
    └── vaults/show.html.erb            # 대시보드

test/
├── models/ (6 files)                   # 모델 검증/관계 테스트
├── services/
│   ├── encryption/ (3 files)           # 암호화 라운드트립 테스트
│   └── users/ (1 file)                 # 회원가입 통합 테스트
├── controllers/ (3 files)              # 인증 플로우 테스트
└── fixtures/ (6 files)                 # ERB + !!binary 인코딩
```

---

## Phase 1: Secret CRUD + Search ⬜

**목표**: 시크릿 저장, 검색, 복사 — 핵심 사용자 경험

### 작업 계획 + 수용 기준

| # | 작업 | 핵심 파일 | 의존성 | 상태 |
|---|------|----------|--------|------|
| 1 | Secret CRUD 서비스 | `app/services/secrets/` | Phase 0 | ⬜ |
| 2 | Secrets 컨트롤러 (CRUD + copy) | `secrets_controller.rb` | #1 | ⬜ |
| 3 | Folders 컨트롤러 (CRUD) | `folders_controller.rb` | Phase 0 | ⬜ |
| 4 | Vault 대시보드 확장 (시크릿 목록) | `vaults/show.html.erb` | #2, #3 | ⬜ |
| 5 | 검색 Query Object | `secrets/search_query.rb` | #1 | ⬜ |
| 6 | 검색 컨트롤러 + Turbo Stream 뷰 | `search_controller.rb` | #5 | ⬜ |
| 7 | 실시간 검색 Stimulus | `search_controller.js` | #6 | ⬜ |
| 8 | 클립보드 복사 Stimulus (30초 클리어) | `clipboard_controller.js` | #2 | ⬜ |
| 9 | 시크릿 보기/숨기기 Stimulus | `secret_reveal_controller.js` | #2 | ⬜ |
| 10 | AuditEvent 로거 서비스 | `audit/event_logger_service.rb` | Phase 0 | ⬜ |
| 11 | 감사 로그 뷰 (읽기 전용) | `audit_events/index.html.erb` | #10 | ⬜ |
| 12 | 라우트 확장 | `config/routes.rb` | All above | ⬜ |
| 13 | 전체 테스트 | `test/` | All above | ⬜ |

### 수용 기준 (Acceptance Criteria)

**#1 — Secret CRUD 서비스**
- [ ] `Secrets::CreationService.call(params, vault, folder, mek)` → Result(success?, secret, errors)
- [ ] `Secrets::UpdateService.call(secret, params, mek)` → Result
- [ ] `Secrets::DeletionService.call(secret)` → Result
- [ ] 생성/수정 시 값이 AES-256-GCM으로 암호화되어 DB에 저장됨
- [ ] 복호화 라운드트립 테스트 통과 (encrypt → save → reload → decrypt = 원본)
- [ ] 유효성 검사 실패 시 에러 메시지가 Result에 포함됨

**#2 — Secrets 컨트롤러**
- [ ] RESTful 7 액션 (index, show, new, create, edit, update, destroy) + copy
- [ ] 인증 필수 (미인증 시 `/login` 리다이렉트)
- [ ] 소유권 검증 (current_user의 vault에 속한 secret만 접근 가능)
- [ ] `copy` 액션: 복호화된 값 반환 (JSON) + AuditEvent 기록 + access_count 증가
- [ ] 세션에 MEK 없을 때 적절한 에러 처리 (재로그인 안내)
- [ ] flash 메시지: 생성 "Secret saved", 수정 "Secret updated", 삭제 "Secret deleted"

**#3 — Folders 컨트롤러**
- [ ] CRUD 4 액션 (new, create, edit, update, destroy) — show는 대시보드에서 처리
- [ ] 폴더 삭제 시 확인 필요 (소속 시크릿 수 표시)
- [ ] `dependent: :destroy` — 폴더 삭제 시 소속 시크릿도 삭제
- [ ] Vault 내 폴더 이름 고유성 검증 (중복 시 에러)
- [ ] AuditEvent 기록 (folder.create, folder.update, folder.delete)

**#4 — Vault 대시보드 확장**
- [ ] 좌측 사이드바: 폴더 목록 (이름 + secrets_count 배지 + 아이콘)
- [ ] 우측 메인: 선택된 폴더의 시크릿 카드 목록
- [ ] 시크릿 카드: 이름, 서비스명, 환경 배지, 타입 아이콘, 마지막 접근, 복사 버튼
- [ ] 빈 상태: 시크릿 0개 시 "Add your first secret" CTA
- [ ] 폴더 비어있을 때: "This folder is empty" + "Add Secret" CTA
- [ ] Mobile-first 반응형: 모바일에서 사이드바 토글

**#5 — 검색 Query Object**
- [ ] `Secrets::SearchQuery.new(vault, query).call` → ActiveRecord::Relation
- [ ] 검색 대상: name, service_name, tags, notes (평문 메타데이터)
- [ ] 대소문자 무시 (case-insensitive LIKE)
- [ ] 환경/타입 필터 (선택적)
- [ ] 결과 정렬: relevance → last_accessed_at DESC
- [ ] SQL injection 방지 (파라미터화 쿼리)

**#6 — 검색 컨트롤러 + Turbo Stream**
- [ ] `GET /search?q=...` → Turbo Stream 응답
- [ ] HTML fallback (Turbo 미사용 시 전체 페이지)
- [ ] 빈 결과: "No secrets match your search" 메시지
- [ ] 결과 목록: 시크릿 카드 (이름, 서비스, 환경 하이라이트)

**#7 — 실시간 검색 Stimulus**
- [ ] Cmd+K (Mac) / Ctrl+K (Windows) → 검색 모달 오픈
- [ ] 300ms 디바운스 후 서버 요청
- [ ] Turbo Stream으로 결과 영역 업데이트
- [ ] ESC → 모달 닫기
- [ ] 키보드 내비게이션: ↑↓ 이동, Enter 선택
- [ ] `disconnect()`에서 이벤트 리스너 cleanup

**#8 — 클립보드 복사 Stimulus**
- [ ] 복사 버튼 클릭 → `navigator.clipboard.writeText(decryptedValue)`
- [ ] 복사 성공 → toast "Copied to clipboard" (2초 표시)
- [ ] 30초 후 → `navigator.clipboard.writeText("")` → toast "Clipboard cleared"
- [ ] 클립보드 API 미지원 시 fallback (textarea + execCommand)
- [ ] `disconnect()`에서 타이머 cleanup

**#9 — 시크릿 보기/숨기기 Stimulus**
- [ ] 기본 마스킹 상태: `••••••••••••` 표시
- [ ] 토글 클릭 → 서버에서 복호화 값 fetch → 평문 표시
- [ ] 다시 클릭 → 마스킹 복원 (메모리에서 값 제거)
- [ ] 아이콘 변경: 눈(보기) ↔ 눈 감기(숨기기)
- [ ] 에러 시 flash "Unable to reveal secret value"

**#10 — AuditEvent 로거 서비스**
- [ ] `Audit::EventLoggerService.call(user:, vault:, secret:, action:, request:)`
- [ ] IP 주소, User-Agent 자동 캡처
- [ ] metadata (JSON) 저장: 변경 전후 필드명 (값은 저장 안 함)
- [ ] 불변성 보장: update/destroy 시 ReadOnlyRecord 예외
- [ ] 모든 CRUD 작업에서 자동 호출

**#11 — 감사 로그 뷰**
- [ ] `GET /vaults/:id/audit` → 이벤트 타임라인 (최신순)
- [ ] 각 이벤트: 시각, 행위자, 액션, 대상 시크릿/폴더, IP
- [ ] 액션별 아이콘/색상 구분 (create=초록, read=파랑, update=노랑, delete=빨강)
- [ ] 페이지네이션 (기본 50개)
- [ ] 읽기 전용 (수정/삭제 불가)

**#12 — 라우트 확장**
- [ ] nested routes: `vaults > folders > secrets (shallow: true)`
- [ ] `POST /secrets/:id/copy`
- [ ] `GET /search`
- [ ] `GET /vaults/:id/audit`
- [ ] 모든 인증 필요 라우트에 `require_login` before_action

**#13 — 전체 테스트**
- [ ] 서비스 테스트: 암호화 라운드트립, 검증 실패, 트랜잭션 롤백
- [ ] 컨트롤러 테스트: 인증/인가, CRUD 해피 패스, 에러 패스
- [ ] 모델 테스트: 새 검증/스코프/메서드
- [ ] 시스템 테스트: 시크릿 생성→검색→복사 E2E 플로우
- [ ] Fixture: 테스트용 암호화된 시크릿 데이터
- [ ] `bin/rails test` 전체 통과, `bundle exec rubocop` 0 offenses

### Quality Gate 기준

```
□ bin/rails runner "puts 'OK'"     → OK
□ bin/rails test                   → 전체 통과
□ bundle exec rubocop              → 0 offenses
□ 수동: 시크릿 생성 → 검색 → 복사 → 감사 로그 확인
□ 암호화 검증: DB 직접 조회 시 encrypted_value가 읽을 수 없음
```

### Stimulus 컨트롤러 설계

**search_controller.js**
```
Targets: input, results
Values: url (String), debounce (Number, default: 300)
Actions: search (input event, debounced)
Flow: input → debounce 300ms → GET /search?q=... → Turbo Stream replace
```

**clipboard_controller.js**
```
Targets: source, button
Values: clearAfter (Number, default: 30)
Actions: copy (click)
Flow: click → navigator.clipboard.writeText → toast → 30초 → clipboard clear
```

**secret_reveal_controller.js**
```
Targets: value, toggle
Values: revealed (Boolean, default: false)
Actions: toggle (click)
Flow: click → 서버에서 복호화된 값 fetch → 표시/마스킹 토글
```

---

## Phase 2: Team + Security 강화 ⬜

**목표**: 팀 협업 + 보안 강화 (4-5일)

| # | 작업 | 설명 |
|---|------|------|
| 1 | 팀 Vault 생성 | vault_type: team, 이름/설명 설정 |
| 2 | 멤버 초대 | 이메일로 초대, 역할 할당 |
| 3 | 역할 기반 권한 | owner > admin > member > viewer |
| 4 | 비밀번호 변경 | 기존 PDK로 MEK 언래핑 → 새 PDK로 재래핑 |
| 5 | 2FA (TOTP) | ROTP gem, QR 코드 등록, 로그인 시 검증 |
| 6 | 복구 코드 | 비밀번호 분실 대비 (12단어 니모닉) |
| 7 | PostgreSQL 마이그레이션 | SQLite → PostgreSQL (팀 동시접속) |

### 권한 매트릭스

| 기능 | Owner | Admin | Member | Viewer |
|------|-------|-------|--------|--------|
| 시크릿 보기 | ✅ | ✅ | ✅ | ✅ |
| 시크릿 생성 | ✅ | ✅ | ✅ | ❌ |
| 시크릿 수정 | ✅ | ✅ | ✅ | ❌ |
| 시크릿 삭제 | ✅ | ✅ | ❌ | ❌ |
| 폴더 관리 | ✅ | ✅ | ❌ | ❌ |
| 멤버 관리 | ✅ | ✅ | ❌ | ❌ |
| Vault 설정 | ✅ | ❌ | ❌ | ❌ |
| Vault 삭제 | ✅ | ❌ | ❌ | ❌ |

---

## Phase 3: API + Integrations ⬜

**목표**: 개발 워크플로우 통합 (4-5일)

| # | 작업 | 설명 |
|---|------|------|
| 1 | REST API | `/api/v1/` 네임스페이스, Bearer 토큰 인증 |
| 2 | API 토큰 관리 | 생성, 만료, 권한 범위 (scopes) |
| 3 | CLI 도구 | `keybox get stripe_api_key --env production` |
| 4 | `.env` import | 파일 업로드 → 시크릿 일괄 생성 |
| 5 | `.env` export | 시크릿 → .env 형식 다운로드 |
| 6 | Hotwire Native | iOS/Android 네이티브 래핑 |

### API 엔드포인트 설계

```
POST   /api/v1/auth/token          # 토큰 발급
DELETE /api/v1/auth/token          # 토큰 폐기

GET    /api/v1/secrets             # 목록 (필터, 페이지네이션)
GET    /api/v1/secrets/:id         # 조회 (복호화된 값 포함)
POST   /api/v1/secrets             # 생성
PATCH  /api/v1/secrets/:id         # 수정
DELETE /api/v1/secrets/:id         # 삭제

GET    /api/v1/search?q=...        # 검색

GET    /api/v1/folders              # 폴더 목록
POST   /api/v1/folders              # 폴더 생성
PATCH  /api/v1/folders/:id          # 폴더 수정
DELETE /api/v1/folders/:id          # 폴더 삭제
```

---

## 리스크 평가

| 리스크 | 확률 | 영향 | 대응 | Phase |
|--------|------|------|------|-------|
| 비밀번호 분실 = 데이터 손실 | 중 | 치명 | 복구 코드 추가 | 2 |
| 세션 만료 시 MEK 소실 | 높 | 낮 | "재로그인" UX | 0 ✅ |
| SQLite 동시접속 제한 | 중 | 높 | PostgreSQL 마이그레이션 | 2 |
| PBKDF2 600K = 로그인 ~0.5초 | 낮 | 낮 | 로딩 인디케이터 | 1 |
| XSS로 세션 탈취 | 낮 | 치명 | CSP, httpOnly, 자동 이스케이핑 | 0 ✅ |
| 클립보드 탈취 | 중 | 중 | 30초 자동 클리어 | 1 |

---

## 테스트 커버리지

| 영역 | 목표 | Phase 0 | Phase 1 |
|------|------|---------|---------|
| 모델 Validations | 100% | ✅ | — |
| 모델 Associations | 100% | ✅ | — |
| 인증 | 100% | ✅ | — |
| 암호화 서비스 | 100% | ✅ | — |
| 비즈니스 서비스 | 80% | ✅ | ⬜ |
| 컨트롤러 | 80% | ✅ | ⬜ |
| 시스템 테스트 | 60% | — | ⬜ |

---

## 관련 문서

- [[Product Design]] — 제품 개요, 경쟁 분석, 차별점
- [[Technical Architecture]] — DB 스키마, 암호화, 서비스 구조
