# Parallel Review Team Workflow

PR 전 전문가 병렬 리뷰를 위한 4명 팀 구성 및 실행 흐름.

---

## 팀 구성

| 역할 | 에이전트 타입 | 포커스 |
|------|-------------|--------|
| lead | Default | 조율, 최종 요약 |
| security-reviewer | general-purpose (plan mode) | OWASP Top 10, IDOR, mass assignment |
| performance-reviewer | general-purpose (plan mode) | N+1, 인덱스, 캐싱 |
| data-reviewer | general-purpose (plan mode) | Race condition, 트랜잭션, 마이그레이션 |

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
| Security Review | security-reviewer | SQL Injection, XSS, CSRF, 인가 |
| Performance Review | performance-reviewer | N+1, 쿼리 최적화, 인덱스 |
| Data Integrity Review | data-reviewer | Race condition, 트랜잭션, 정합성 |

### Step 3: 병렬 리뷰 (전원 동시)

각 리뷰어는 독립적으로:
1. 할당된 파일 범위 읽기
2. 전문 영역 관점에서 분석
3. 발견사항을 SendMessage로 lead에게 보고
4. TaskUpdate로 완료 표시

### Step 4: 통합 요약 (lead)

1. 3명의 발견사항 수집
2. 심각도별 분류:
   - **Critical**: 즉시 수정 필수 (보안 취약점, 데이터 손실 가능)
   - **Warning**: 권장 수정 (성능 저하, 잠재적 문제)
   - **Info**: 참고 사항 (코드 스타일, 개선 제안)
3. 통합 리뷰 요약 생성

---

## 리뷰어별 체크리스트

### Security Reviewer

- [ ] SQL Injection (raw SQL, `.where("...")` 패턴)
- [ ] XSS (raw output, `html_safe` 사용)
- [ ] CSRF (token 검증)
- [ ] IDOR (인가 없는 리소스 접근)
- [ ] Mass Assignment (Strong Parameters)
- [ ] Secret 노출 (하드코딩된 키/비밀번호)

### Performance Reviewer

- [ ] N+1 쿼리 (includes/preload 누락)
- [ ] 누락된 인덱스 (외래 키, 검색 컬럼)
- [ ] 불필요한 쿼리 (counter cache 활용 가능)
- [ ] 대량 데이터 처리 (find_each 사용)
- [ ] 캐싱 기회 (fragment cache, Russian Doll)

### Data Integrity Reviewer

- [ ] Race condition (동시 요청 시 데이터 충돌)
- [ ] 트랜잭션 범위 (다중 모델 저장 시 원자성)
- [ ] 마이그레이션 안전성 (reversible, 무중단)
- [ ] 유니크 제약 (DB 레벨 + 모델 레벨)
- [ ] 외래 키 정합성 (orphaned records 방지)

---

## 비용 최적화

| 역할 | 권장 모델 | 근거 |
|------|----------|------|
| lead | opus | 통합 판단 |
| security-reviewer | opus | 보안 분석 정확도 중요 |
| performance-reviewer | sonnet | 패턴 기반 분석 |
| data-reviewer | opus | 동시성 문제 추론 |

---

## 참조

- [Agent Teams Guide](../../docs/agent-teams-guide.md)
- [Security Expert Agent](../../agents/quality/security-expert.md)
- [Performance Expert Agent](../../agents/quality/performance-expert.md)
- [Data Integrity Expert Agent](../../agents/quality/data-integrity-expert.md)
