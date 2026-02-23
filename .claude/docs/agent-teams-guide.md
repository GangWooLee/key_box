# Agent Teams Guide — key_box

Claude Code의 Agent Teams 기능을 key_box 프로젝트에서 활용하기 위한 중앙 참조 문서.

---

## Quick Start

### 팀 생성 요청 예시

```
"User 모델 기능을 팀으로 개발해줘"
"현재 브랜치를 리뷰 팀으로 검수해줘"
"이 버그를 디버깅 팀으로 조사해줘"
```

### 기본 흐름

```
1. TeamCreate → 팀 생성
2. TaskCreate → 태스크 분해
3. Task (subagent) → 팀원 spawn
4. TaskUpdate → 태스크 할당 (owner)
5. 팀원 작업 → SendMessage 보고
6. Quality Gate → 통과 확인
7. shutdown_request → 팀 종료
8. TeamDelete → 정리
```

---

## 워크플로우 템플릿

| 템플릿 | 파일 | 팀 규모 | 용도 |
|--------|------|---------|------|
| 기능 개발 팀 | [feature-dev-team.md](../workflows/teams/feature-dev-team.md) | 3-4명 | 새 기능 구현 |
| 리뷰 팀 | [review-team.md](../workflows/teams/review-team.md) | 4명 | PR 전 전문가 병렬 리뷰 |
| 디버깅 팀 | [debugging-team.md](../workflows/teams/debugging-team.md) | 2-3명 | 경쟁 가설 병렬 조사 |

---

## 에이전트 → 팀 역할 매핑

| 에이전트 | teamRole | 기능 팀 | 리뷰 팀 | 디버깅 팀 |
|---------|----------|---------|---------|----------|
| code-review-expert | quality-guard | quality-guard | - | - |
| security-expert | security-reviewer | - | security-reviewer | - |
| data-integrity-expert | data-reviewer | - | data-reviewer | - |
| performance-expert | performance-reviewer | - | performance-reviewer | - |
| ui-ux-expert | frontend-dev | frontend-dev | - | tracer-frontend |
| planner | - | lead 보조 | - | - |
| doc-updater | - | Phase 3 문서화 | - | - |

---

## 팀 조율 규칙

### 1. 태스크 기반 조율

- ad-hoc 메시징이 아닌 TaskCreate/TaskUpdate로 작업 추적
- 모든 작업은 태스크로 존재해야 함
- 팀원은 TaskList를 주기적으로 확인

### 2. 파일 소유권 경계

**동일 파일 동시 수정 금지**. 충돌 방지를 위한 파일 소유권:

| 소유자 | 파일 범위 |
|--------|----------|
| backend-dev | `app/models/`, `app/controllers/`, `app/services/`, `db/migrate/` |
| frontend-dev | `app/views/`, `app/javascript/controllers/`, `app/assets/` |
| quality-guard | `test/` |
| lead | `docs/`, `config/`, task list |

### 3. Phase 간 Quality Gate 강제

Phase 전환 전 반드시 통과:
1. `bin/rails runner "puts 'OK'"` — 빌드
2. `bin/rails test` — 테스트
3. `bundle exec rubocop` — 린트

### 4. 최대 3-4명

- 비용/효과 최적점은 3-4명
- 5명 이상은 조율 오버헤드가 생산성을 초과

### 5. Lead가 /verify 실행 후에만 완료 선언

팀원의 보고를 신뢰하되, lead가 독립적으로 검증 실행.

---

## 훅 동작

프로젝트에 설정된 훅과 팀 작업의 상호작용:

| 훅 | 트리거 | 동작 | 팀 영향 |
|----|--------|------|---------|
| TeammateIdle | 팀원 유휴 시 | `bin/rails test` 자동 실행 | 유휴 팀원이 빌드 깨뜨렸는지 자동 확인 |
| TaskCompleted | 태스크 완료 시 | `rubocop` + `bin/rails test` | 태스크 완료 품질 자동 검증 |
| PostToolUse (Edit\|Write) | 파일 수정 시 | `rubocop --autocorrect` | 스타일 자동 교정 |

---

## 관련 스킬

| 스킬 | 용도 | 팀 시나리오 |
|------|------|-----------|
| dispatching-parallel-agents | 병렬 에이전트 오케스트레이션 기반 | 모든 팀 |
| parallel-feature-development | 기능 Phase별 팀 분배 | 기능 개발 팀 |
| parallel-debugging | 경쟁 가설 병렬 조사 | 디버깅 팀 |
| team-communication-protocols | 팀원 간 구조화된 통신 | 모든 팀 |

---

## 비용 관리

### 모델 선택 가이드

| 작업 유형 | 권장 모델 | 근거 |
|----------|----------|------|
| 계획 수립, 복잡한 판단 | opus | 추론 품질 |
| 패턴 기반 코드 생성 | sonnet | 비용 효율 |
| 코드 리뷰, 보안 분석 | opus | 정확도 |
| 템플릿 기반 UI 작성 | sonnet | 비용 효율 |

### 비용 절감 전략

1. **팀원 수 제한**: 3-4명 (최대)
2. **즉시 shutdown**: 작업 완료 후 바로 종료
3. **sonnet 활용**: mechanical 작업에 sonnet 모델 지정
4. **태스크 최소화**: 불필요한 세분화 방지

---

## 안티패턴

| 안티패턴 | 문제 | 올바른 접근 |
|---------|------|-----------|
| 동일 파일 동시 수정 | Git 충돌, 작업 손실 | 파일 소유권 경계 준수 |
| Quality Gate 스킵 | 깨진 빌드 위에 작업 | Phase 전환 전 반드시 통과 |
| 5명+ 동시 실행 | 조율 오버헤드 > 생산성 | 3-4명 제한 |
| broadcast 남용 | 불필요한 API 비용 | SendMessage (DM) 사용 |
| 팀원 보고 무검증 신뢰 | 오류 전파 | lead가 독립 검증 |
| 작업 완료 후 팀 미종료 | 불필요한 리소스 소비 | 즉시 shutdown_request |

---

**Last Updated**: 2026-02-24
