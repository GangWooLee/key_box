# KeyBox — Product Design

> 개발자를 위한 검색 중심 시크릿 관리 웹 앱

## 문제 정의

API 키, 토큰, 비밀번호 등 민감한 개발 정보를 **카카오톡 나에게 보내기**, **메모장**, **Slack DM** 등에 분산 보관하는 개발자가 많다.

| 현재 방식 | 문제점 |
|----------|--------|
| 카카오톡 나에게 보내기 | 다른 메시지와 섞여 검색 불가, 암호화 없음 |
| .env 파일 | 프로젝트별 분산, 실수로 커밋 위험 |
| 메모장/노트앱 | 비구조화, 암호화 없음, 감사 로그 없음 |
| Slack DM | 검색 가능하나 팀 관리자에게 노출 위험 |

**핵심 니즈**: 간편 저장 → 빠른 검색 → 원클릭 복사

---

## 경쟁 분석

### 엔터프라이즈 솔루션

| 제품 | 특징 | 한계 |
|------|------|------|
| **Doppler** | 팀/CI/CD 통합, 환경별 관리 | 구독 모델, 개인 사용에 과도 |
| **Infisical** | 오픈소스, self-host 가능 | 설정 복잡, 팀 중심 설계 |
| **HashiCorp Vault** | 업계 표준, 동적 시크릿 | 학습 곡선 높음, 운영 부담 |

### 범용 비밀번호 관리자

| 제품 | 특징 | 한계 |
|------|------|------|
| **1Password** | CLI 도구 제공, 브라우저 통합 | 월 구독, 개발자 특화 X |
| **Bitwarden** | 오픈소스, 무료 플랜 | API 키/토큰 관리에 최적화되지 않음 |

### KeyBox 차별점

```
┌─────────────────────────────────────────────────┐
│                   KeyBox                         │
│                                                  │
│  ✦ 검색 우선 UX (타이핑 즉시 필터링)             │
│  ✦ 개발자 특화 (API 키, 토큰, 환경별 분류)       │
│  ✦ 원클릭 복사 + 자동 클립보드 클리어 (30초)     │
│  ✦ 개인 개발자 + 소규모 팀 타겟                  │
│  ✦ Self-hosted, 구독 없음                        │
│  ✦ 감사 로그 내장                                │
│  ✦ 심플 — 5분 안에 시작 가능                     │
└─────────────────────────────────────────────────┘
```

---

## 타겟 사용자

### Primary: 개인 개발자
- 여러 서비스의 API 키를 관리하는 프리랜서/인디 개발자
- 10~100개 시크릿 보유
- CLI 도구 사용에 익숙

### Secondary: 소규모 팀 (2-5명)
- 공유 API 키/인프라 인증 정보 관리 필요
- 전용 솔루션 도입 비용이 부담

---

## 핵심 사용자 플로우

### 1. 시크릿 저장 (3초 이내)
```
대시보드 → "+" 버튼 → 이름/값 입력 → 태그/서비스 선택 → 저장
```

### 2. 시크릿 검색 (2초 이내)
```
검색창 포커스 (Cmd+K) → 타이핑 → 실시간 필터링 → 결과 클릭
```

### 3. 시크릿 복사 (1초 이내)
```
시크릿 카드 → 복사 아이콘 클릭 → 클립보드 복사 → 30초 후 자동 클리어
```

---

## MVP 범위

### In Scope (Phase 0-1)
- [x] 사용자 인증 (이메일/비밀번호)
- [x] AES-256-GCM 암호화
- [x] 개인 Vault + 폴더 구조
- [ ] 시크릿 CRUD
- [ ] 실시간 검색 (Turbo Stream)
- [ ] 원클릭 복사 + 자동 클리어
- [ ] 감사 로그 (읽기 전용)

### Out of Scope (Phase 2+)
- 팀 Vault, 멤버 초대, 역할 기반 권한
- 2FA (TOTP)
- REST API + CLI 도구
- `.env` 파일 import/export
- Hotwire Native 모바일 앱

---

## 화면 목록 (Screen Inventory)

### 인증

| 화면 | 라우트 | Phase | 설명 |
|------|--------|-------|------|
| 로그인 | `/login` | 0 ✅ | 이메일/비밀번호 입력, Remember Me |
| 회원가입 | `/signup` | 0 ✅ | 이름/이메일/비밀번호, Vault+폴더 자동 생성 |

### 메인

| 화면 | 라우트 | Phase | 설명 |
|------|--------|-------|------|
| 대시보드 | `/` | 1 | 폴더 사이드바 + 시크릿 목록 (2패널) |
| 시크릿 생성 폼 | `/vaults/:id/folders/:id/secrets/new` | 1 | 타입/이름/값/태그/환경/메모 입력 |
| 시크릿 상세 | `/secrets/:id` | 1 | 마스킹 값 + 복사 + 메타데이터 + 수정/삭제 |
| 시크릿 수정 폼 | `/secrets/:id/edit` | 1 | 기존 값 수정 (값은 복호화 후 표시) |
| 검색 오버레이 | Cmd+K (모달) | 1 | 실시간 필터링, Turbo Stream 결과 |

### 폴더

| 화면 | 라우트 | Phase | 설명 |
|------|--------|-------|------|
| 폴더 생성 | 인라인/모달 | 1 | 이름 + 아이콘 선택 |
| 폴더 수정 | 인라인/모달 | 1 | 이름/아이콘 수정, 삭제 확인 |

### 감사

| 화면 | 라우트 | Phase | 설명 |
|------|--------|-------|------|
| 감사 로그 목록 | `/vaults/:id/audit` | 1 | 이벤트 타임라인 + 행위자 + 필터 |

### 설정 (Phase 2+)

| 화면 | 라우트 | Phase | 설명 |
|------|--------|-------|------|
| 프로필 설정 | `/settings/profile` | 2 | 이름/이메일 변경, 비밀번호 변경 |
| 보안 설정 | `/settings/security` | 2 | 2FA(TOTP) 등록/해제, 복구 코드 |
| 팀 멤버 관리 | `/vaults/:id/members` | 2 | 초대, 역할 변경, 제거 |

---

## 상세 유저 플로우

### Flow 1: 회원가입 → 온보딩

```
회원가입 폼 ──→ 클라이언트 검증 (이름/이메일/비밀번호)
  │
  ├─ 실패 → 인라인 에러 표시 (필수 필드, 이메일 형식, 비밀번호 8자+)
  │
  └─ 성공 → RegistrationService.call
               │
               ├─ salt 생성 → PBKDF2로 PDK 유도
               ├─ 랜덤 MEK 생성 → PDK로 MEK 래핑
               ├─ 트랜잭션:
               │    User + Vault("Personal") + Membership(owner) + Folder("General")
               │
               ├─ 실패 → 폼 재표시 (이메일 중복 등)
               └─ 성공 → 자동 로그인 → 대시보드 (빈 상태)
                           │
                           └─ "Add your first secret" CTA 표시
```

### Flow 2: 로그인 → 대시보드

```
로그인 폼 ──→ 이메일 + 비밀번호 입력
  │
  ├─ 인증 실패 → flash "Invalid email or password" (타이밍 공격 방지: 일관된 메시지)
  │
  └─ 인증 성공 → reset_session (Session Fixation 방지)
                  │
                  ├─ PBKDF2로 PDK 유도 → MEK 언래핑 → 세션에 MEK 저장
                  ├─ Remember Me 체크 시 → encrypted cookie (30일)
                  ├─ AuditEvent(user.login) 기록
                  └─ redirect_back_or(대시보드)
```

### Flow 3: 시크릿 생성

```
대시보드 ──→ "+" 버튼 클릭 ──→ 생성 폼
  │
  ├─ 폴더 선택 (드롭다운, 현재 폴더가 기본 선택)
  ├─ 타입 선택 (api_key | token | password | credential | certificate | ssh_key | other)
  ├─ 이름 입력 (필수, 200자 이내)
  ├─ 값 입력 (필수, 마스킹 입력 + 표시 토글)
  ├─ 서비스명 (선택, 100자)
  ├─ 환경 (선택: production | staging | development | test)
  ├─ 태그 (선택, 쉼표 구분)
  └─ 메모 (선택, 2000자)
  │
  ├─ 검증 실패 → 인라인 에러 (이름 누락, 값 누락 등)
  │
  └─ 저장 → SecretEncryptionService.encrypt(value, MEK)
             │
             ├─ 트랜잭션: Secret 저장 + counter_cache 업데이트
             ├─ AuditEvent(secret.create) 기록
             │
             ├─ 실패 → 폼 재표시 + 에러
             └─ 성공 → 시크릿 상세 페이지 + toast "Secret saved"
```

### Flow 4: 시크릿 검색 (Cmd+K)

```
아무 페이지 ──→ Cmd+K 또는 검색 아이콘 클릭
  │
  └─ 검색 모달 오픈 (포커스 자동 이동)
       │
       ├─ 타이핑 → 300ms 디바운스
       │    │
       │    └─ GET /search?q=... → Turbo Stream
       │         │
       │         ├─ 결과 있음 → 시크릿 카드 목록 (이름, 서비스, 환경 하이라이트)
       │         │    │
       │         │    ├─ 클릭 → 시크릿 상세 페이지
       │         │    └─ 키보드 ↑↓ → 포커스 이동, Enter → 선택
       │         │
       │         └─ 결과 없음 → "No secrets match your search" + 필터 초기화 링크
       │
       └─ ESC 또는 배경 클릭 → 모달 닫기
```

### Flow 5: 시크릿 복사

```
시크릿 상세 또는 목록 카드 ──→ 복사 아이콘 클릭
  │
  ├─ 세션에 MEK 없음 → flash "Session expired. Please log in again." → 로그인
  │
  └─ MEK 존재 → SecretEncryptionService.decrypt
       │
       ├─ 복호화 실패 (auth_tag 불일치) → flash error "Failed to decrypt. Data may be corrupted."
       │
       └─ 복호화 성공 → navigator.clipboard.writeText(value)
            │
            ├─ 클립보드 API 미지원 → fallback textarea + document.execCommand
            │
            └─ 성공 → toast "Copied to clipboard" (초록)
                       │
                       ├─ AuditEvent(secret.copy) 기록
                       ├─ access_count + 1, last_accessed_at 업데이트
                       └─ 30초 타이머 → clipboard.writeText("") → toast "Clipboard cleared" (회색)
```

### Flow 6: 시크릿 수정/삭제

```
시크릿 상세 ──→ "Edit" 버튼 → 수정 폼 (기존 메타데이터 + 현재 값 복호화 표시)
  │
  ├─ 수정 → 새 값 암호화 → AuditEvent(secret.update) → redirect 상세 + toast "Updated"
  │
  └─ "Delete" 버튼 → 확인 모달 "Are you sure? This cannot be undone."
       │
       ├─ 취소 → 모달 닫기
       └─ 확인 → Secret 삭제 + counter_cache 감소 + AuditEvent(secret.delete)
                  → redirect 대시보드 + toast "Secret deleted"
```

### Flow 7: 폴더 CRUD

```
사이드바 ──→ "New Folder" 버튼 → 인라인 입력 또는 모달
  │
  ├─ 이름 입력 (필수, 100자, Vault 내 고유)
  ├─ 아이콘 선택 (기본: folder)
  │
  ├─ 검증 실패 → 에러 (이름 누락, 중복)
  └─ 성공 → AuditEvent(folder.create) → 사이드바에 폴더 추가

폴더 우클릭/메뉴 ──→ "Rename" → 인라인 편집 → AuditEvent(folder.update)
                  ──→ "Delete" → 확인 "This will delete N secrets. Are you sure?"
                       │
                       ├─ 시크릿 존재 → 삭제 확인 필수 (시크릿 수 표시)
                       └─ 삭제 → dependent: :destroy → AuditEvent(folder.delete)
```

### Flow 8: 에러/엣지케이스 플로우

```
세션 만료:
  시크릿 접근 시 세션 만료 감지 →
    flash "Your session has expired. Please log in again." →
    store_location (현재 URL) → 로그인 → 재인증 → MEK 재유도 →
    redirect_back_or (원래 페이지)

복호화 실패:
  암호화된 값 손상 또는 MEK 불일치 →
    flash error "Unable to decrypt this secret. The data may be corrupted." →
    시크릿 메타데이터는 표시 (이름, 서비스, 태그), 값만 "[Decryption failed]"

네트워크 에러:
  Turbo Stream 요청 실패 →
    검색: "Search unavailable. Please try again." (로컬 폴백 없음)
    CRUD: 폼 재표시 + flash "Something went wrong. Please try again."

권한 없음 (Phase 2+):
  다른 사용자의 Vault 접근 시도 →
    redirect 대시보드 + flash "You don't have access to this vault."

빈 Vault:
  회원가입 직후 또는 모든 시크릿 삭제 후 →
    빈 상태 일러스트레이션 + "Add your first secret" CTA
```

---

## 빈 상태 / 온보딩 UX

| 상태 | 화면 | 표시 내용 | CTA |
|------|------|----------|-----|
| 첫 사용자 (시크릿 0개) | 대시보드 | 일러스트 + "Welcome! Start by adding your first secret." | "Add Secret" 버튼 |
| 검색 결과 0개 | 검색 모달 | "No secrets match your search." | "Clear search" 링크 |
| 폴더 내 시크릿 0개 | 대시보드 (폴더 선택) | "This folder is empty." | "Add Secret" 버튼 |
| 감사 로그 0개 | 감사 로그 | "No activity recorded yet." | — |
| 로딩 | 전체 | 스피너 또는 스켈레톤 | — |
| 에러 | 전체 | "Something went wrong." + 재시도 안내 | "Try again" 버튼 |

---

## UI 언어 및 디자인 방향

- **UI 언어**: 영어 (글로벌 개발자 타겟)
- **디자인 시스템**: Tailwind CSS, Indigo 프라이머리 컬러
- **레이아웃**: 사이드바(폴더) + 메인(시크릿 목록) 2패널
- **반응형**: Mobile-first, 44px 터치 타겟, 16px 최소 폰트
- **접근성**: WCAG 2.1 AA 준수 목표

---

## 배포 계획

| 항목 | 결정 |
|------|------|
| 호스팅 | 추후 결정 (DigitalOcean or AWS) |
| DB | SQLite (MVP) → PostgreSQL (팀 기능 시) |
| 공개 | GitHub private 시작 |
| 도메인 | 미정 |

---

## 관련 문서

- [[Technical Architecture]] — DB 스키마, 암호화, 서비스 구조
- [[Phase Plan]] — 구현 계획, Quality Gate, 진행 상황
