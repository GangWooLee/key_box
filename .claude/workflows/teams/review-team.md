# Parallel Review Team Workflow

PR 전 전문가 병렬 리뷰를 위한 4명 팀 구성 및 실행 흐름.

---

## 팀 구성

| 역할 | 에이전트 타입 | 포커스 |
|------|-------------|--------|
| lead | Default | 조율, 최종 요약 |
| security-reviewer | general-purpose (plan mode) | 암호화 구현, SQLCipher 설정, 키 관리, Entitlements |
| performance-reviewer | general-purpose (plan mode) | Widget rebuild, const 활용, Riverpod select, 메모리 |
| data-reviewer | general-purpose (plan mode) | Drift 트랜잭션, 스키마 정합성, 동시성, 마이그레이션 |

**리뷰어는 읽기 전용** — plan mode로 실행하여 코드 수정 없음.

### 에이전트 생성 예시

```
"security, performance, data 3명 리뷰 팀으로 현재 브랜치 리뷰해줘"
```

---

## 실행 흐름

### Step 1: 리뷰 범위 결정 (lead)

```bash
git diff main...HEAD
```

변경된 파일 목록으로 리뷰 태스크 생성.

### Step 2: 태스크 생성 + 할당 (lead)

| 태스크 | 할당 | 포커스 |
|--------|------|--------|
| Security Review | security-reviewer | 암호화 무결성, 키 관리, SQLCipher, Entitlements |
| Performance Review | performance-reviewer | Widget rebuild, Provider 구독 최적화, const |
| Data Integrity Review | data-reviewer | Drift 트랜잭션, 스키마 일관성, 마이그레이션 |

### Step 3: 병렬 리뷰 (전원 동시)

각 리뷰어는 독립적으로:
1. 할당된 파일 범위 읽기
2. 전문 영역 관점에서 분석
3. 발견사항을 SendMessage로 lead에게 보고
4. TaskUpdate로 완료 표시

### Step 4: 통합 요약 (lead)

1. 3명의 발견사항 수집
2. 심각도별 분류:
   - **Critical**: 즉시 수정 필수 (암호화 결함, 키 노출, 데이터 손실 가능)
   - **Warning**: 권장 수정 (성능 저하, 잠재적 문제)
   - **Info**: 참고 사항 (코드 스타일, 개선 제안)
3. 통합 리뷰 요약 생성

---

## 리뷰어별 체크리스트

### Security Reviewer

- [ ] 암호화 키 하드코딩 여부 (AES-256-GCM 구현)
- [ ] KeyDerivationService 파라미터 안전성 (Argon2id 설정)
- [ ] SQLCipher 키 관리 (메모리 상주 최소화)
- [ ] macOS Entitlements 최소 권한 원칙
- [ ] 민감 데이터 로그 출력 여부
- [ ] Secure enclave / Keychain 활용 여부
- [ ] Provider dispose 시 암호화 키 정리

### Performance Reviewer

- [ ] 불필요한 Widget rebuild (ref.watch 범위)
- [ ] Riverpod select로 세밀한 구독
- [ ] const 생성자 누락 (Widget, 상수 객체)
- [ ] 대량 데이터 처리 (ListView.builder, 페이지네이션)
- [ ] 이미지/아이콘 캐싱
- [ ] setState 범위 최소화

### Data Integrity Reviewer

- [ ] Drift 트랜잭션 범위 (다중 테이블 조작 시 원자성)
- [ ] 스키마 마이그레이션 안전성 (MigrationStrategy)
- [ ] 유니크 제약 (DB 레벨 + Dart 레벨)
- [ ] 외래 키 정합성 (cascade/restrict 설정)
- [ ] DAO 에러 핸들링 (SqliteException catch)
- [ ] 코드 생성 파일 (.g.dart) 최신 상태 확인

---

## 비용 최적화

| 역할 | 권장 모델 | 근거 |
|------|----------|------|
| lead | opus | 통합 판단 |
| security-reviewer | opus | 암호화/보안 분석 정확도 중요 |
| performance-reviewer | sonnet | 패턴 기반 분석 |
| data-reviewer | opus | Drift 트랜잭션/동시성 추론 |

---

## 참조

- [Agent Teams Guide](../../docs/agent-teams-guide.md)
- [Security Expert Agent](../../agents/quality/security-expert.md)
- [Performance Expert Agent](../../agents/quality/performance-expert.md)
- [Data Integrity Expert Agent](../../agents/quality/data-integrity-expert.md)
