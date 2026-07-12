# Feature Development Team Workflow

기능 개발을 위한 3-4명 팀 구성 및 실행 흐름.

---

## 팀 구성

| 역할 | 에이전트 타입 | 담당 | 파일 소유권 |
|------|-------------|------|-----------|
| lead (사용자) | Default | 계획 수립, 태스크 조율, 통합 | `docs/plans/`, task list |
| backend-dev | general-purpose | DB, DAO, Provider, 암호화, 라우터 | `lib/core/`, `lib/features/*/domain/` |
| frontend-dev | general-purpose | 화면, 위젯, 테마 | `lib/features/*/presentation/` |
| quality-guard | general-purpose (plan mode) | 테스트, 리뷰, 보안 감사 | `test/` |

### 에이전트 생성 예시

```
"backend-dev, frontend-dev, quality-guard 3명으로 기능 개발 팀을 구성해줘"
```

---

## 실행 흐름

### Phase 0: Planning (lead만, 순차)

1. `/plan`으로 PLAN 문서 생성
2. micro-task 분해 (TaskCreate)
3. 태스크 의존성 설정 (blockedBy)
4. 팀원에게 태스크 할당 (TaskUpdate → owner)

### Phase 1: Foundation (backend-dev, 순차)

1. Drift 테이블 정의 + 코드 생성 (`dart run build_runner build --delete-conflicting-outputs`)
2. DAO 작성 (TDD: 테스트 → 구현)
3. sealed class 상태 정의
4. **Quality Gate 통과 필수**:
   - `flutter build macos --debug`
   - `flutter test`
   - `dart analyze`

### Phase 2: Parallel Build (전원 병렬)

| 팀원 | 작업 | 전제 조건 |
|------|------|----------|
| backend-dev | Provider + StateNotifier 구현 | Phase 1 완료 |
| frontend-dev | Screen + Widget 작성 (Material 3) | 스키마 존재 (Phase 1) |
| quality-guard | Provider + Widget 테스트 병렬 작성 | 스키마 존재 (Phase 1) |

**병렬 작업 규칙**:
- 동일 파일 동시 수정 금지 (파일 소유권 참조)
- SendMessage로 인터페이스 변경 사항 공유
- 각자 작업 완료 후 TaskUpdate로 완료 보고

**Phase 2 Quality Gate**:
- `flutter test` (전체 테스트 통과)

### Phase 3: Integration + Review (전체)

1. quality-guard: `/verify` 실행 (6단계 검증)
2. lead: 병합 + 충돌 해결
3. lead: `/wrap-up`

---

## 태스크 분해 가이드

### Good: 병렬화 가능한 분해

```
Task 1: [backend-dev] Xxx Drift 테이블 + DAO (blockedBy: 없음)
Task 2: [backend-dev] XxxNotifier + Provider (blockedBy: Task 1)
Task 3: [frontend-dev] Xxx Screen + Widget (blockedBy: Task 1)
Task 4: [quality-guard] Xxx Provider 테스트 (blockedBy: Task 1)
Task 5: [quality-guard] Xxx Widget + 통합 테스트 (blockedBy: Task 2, Task 3)
```

### Bad: 순차적 병목

```
Task 1: Xxx 테이블 생성
Task 2: Xxx Provider 구현 (blockedBy: Task 1)
Task 3: Xxx Widget 작성 (blockedBy: Task 2)  ← 불필요한 의존성
Task 4: Xxx 테스트 (blockedBy: Task 3)       ← 불필요한 의존성
```

---

## 비용 최적화

| 역할 | 권장 모델 | 근거 |
|------|----------|------|
| lead | opus | 계획 수립, 복잡한 판단 |
| backend-dev | sonnet | 패턴 기반 코드 생성 |
| frontend-dev | sonnet | Material 3 위젯 작성 |
| quality-guard | opus | 리뷰 품질 중요 |

---

## 참조

- [Agent Teams Guide](../../docs/agent-teams-guide.md)
- [Feature Development Workflow](../feature-development.md)
- [Quality Gate Rules](../../rules/common/verification-discipline.md)
