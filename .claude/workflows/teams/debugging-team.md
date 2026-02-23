# Parallel Debugging Team Workflow

경쟁 가설 기반 병렬 디버깅을 위한 2-3명 팀 구성 및 실행 흐름.

---

## 팀 구성

| 역할 | 에이전트 타입 | 조사 경로 |
|------|-------------|----------|
| lead | Default | 조율, 발견사항 종합, fix 적용 |
| tracer-backend | general-purpose | Controller → Service → Model 경로 |
| tracer-frontend | general-purpose | View → Stimulus → Turbo 경로 |

### 에이전트 생성 예시

```
"backend, frontend 2명으로 디버깅 팀 구성해서 이 버그 조사해줘"
```

---

## 실행 흐름

### Step 1: 버그 정의 (lead)

1. 재현 단계 기록
2. 예상 동작 vs 실제 동작 정리
3. 가설 2-3개 수립
4. 각 tracer에게 독립 가설 할당

### Step 2: 경쟁 가설 조사 (병렬)

| tracer | 조사 범위 | 방법 |
|--------|----------|------|
| tracer-backend | Controller, Service, Model, DB | 로그 분석, 쿼리 추적, 데이터 검증 |
| tracer-frontend | View, Stimulus, Turbo Stream, JS | DOM 검사, 이벤트 흐름, 네트워크 분석 |

각 tracer는 독립적으로:
1. 할당된 가설 조사
2. 근거 수집 (코드 경로, 로그, 재현 결과)
3. 가설의 확신도 평가 (High / Medium / Low)
4. SendMessage로 lead에게 보고

### Step 3: 가설 평가 (lead)

1. 각 tracer의 보고 수집
2. 가설 강도 비교:
   - **확인됨**: 근본 원인 특정 → Step 4로
   - **유력**: 추가 조사 필요 → 해당 tracer에게 깊이 조사 지시
   - **기각**: 다른 가설로 전환
3. 필요시 새로운 가설 생성

### Step 4: Fix 적용 (lead 또는 지정 tracer)

1. 근본 원인 기반 최소 범위 수정
2. 재현 시나리오로 수정 검증
3. 회귀 테스트 추가
4. `bin/rails test` 전체 통과 확인

---

## 경쟁 가설 패턴

### 예시: "폼 제출 시 데이터가 저장되지 않음"

```
가설 A (tracer-backend): Controller strong params에서 필드 누락
가설 B (tracer-frontend): Stimulus 컨트롤러가 폼 submit 이벤트를 가로챔
가설 C (lead 예비): Turbo Frame이 잘못된 대상에 렌더링
```

### 보고 형식

```
## 가설: [가설 내용]
### 확신도: High / Medium / Low
### 근거:
1. [코드 경로 또는 증거]
2. [재현 결과]
### 결론: 확인됨 / 유력 / 기각
### 제안 수정: (확인된 경우)
```

---

## 사용 시점

| 상황 | 팀 구성 |
|------|---------|
| 단일 레이어 버그 (모델 로직) | 팀 불필요, 단독 `/bugfix` |
| 프론트-백 연동 버그 | tracer-backend + tracer-frontend |
| 3회 이상 디버깅 실패 | 팀 전환 (새 관점 필요) |
| 간헐적 재현 버그 (Race condition) | tracer-backend + data-integrity 관점 |

---

## 비용 최적화

| 역할 | 권장 모델 | 근거 |
|------|----------|------|
| lead | opus | 가설 종합 판단 |
| tracer-backend | opus | 복잡한 추론 |
| tracer-frontend | sonnet | DOM/이벤트 추적 |

---

## 참조

- [Agent Teams Guide](../../docs/agent-teams-guide.md)
- [Bugfix Skill](.claude/skills/bugfix/)
- [Error Handling Rules](../../rules/backend/error-handling.md)
