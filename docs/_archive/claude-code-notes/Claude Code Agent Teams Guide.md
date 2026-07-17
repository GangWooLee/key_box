# Claude Code Agent Teams Guide

> 팀 운영 패턴. Anthropic 공식 문서 기반. 최종 업데이트: 2026-02-26.

---

## Quick Reference

### 팀 생성 흐름

```
1. TeamCreate        → 팀 + 태스크 리스트 생성
2. TaskCreate        → 태스크 정의
3. Task(team_name)   → 팀원 스폰
4. TaskUpdate(owner) → 태스크 할당
5. SendMessage       → 팀원 간 통신
6. shutdown_request  → 팀원 종료
7. TeamDelete        → 팀 정리
```

---

## Patterns

### 1. Review Team (병렬 리뷰)

```
Lead
├── code-review-expert (plan)
├── security-expert (plan)
├── performance-expert (plan)
└── data-integrity-expert (plan)
```

### 2. Feature Dev Team

```
Lead (planner)
├── Phase 1: 설계 → planner
├── Phase 2: 구현 → backend-dev + frontend-dev
└── Phase 3: 검증 → qa-engineer
```

### 3. Debugging Team (경쟁 가설)

```
Lead
├── hypothesis-1 → "DB 쿼리 문제"
├── hypothesis-2 → "캐시 무효화 문제"
└── hypothesis-3 → "동시성 문제"
```

### 4. Full Lifecycle Team (10역할 5 Wave)

```
Wave 1: 조사  → market-researcher + data-analyst
Wave 2: 기획  → product-manager + designer
Wave 3: 구현  → backend-ops + 개발자들
Wave 4: 품질  → qa-engineer + 리뷰어들
Wave 5: 런칭  → marketer
```

---

## 팀 통신 규칙

| 유형 | 용도 | 빈도 |
|------|------|------|
| `message` | 1:1 DM | 기본 (90%) |
| `broadcast` | 전체 공지 | 긴급 시만 |
| `shutdown_request` | 팀원 종료 | 완료 시 |

**핵심**: SendMessage 필수 (텍스트 출력은 팀원에게 안 보임), broadcast 절제, idle = 정상

---

## Anti-patterns

| 안티패턴 | 올바른 방법 |
|---------|-----------|
| 모든 통신에 broadcast | message로 1:1 |
| idle 팀원 걱정 | idle = 입력 대기, 정상 |
| 종료 없이 TeamDelete | shutdown_request 먼저 |
| JSON으로 상태 보고 | 평문 메시지 사용 |

---

## Our Customizations (key_box)

### 워크플로우 선택 기준

| 규모 | 워크플로우 |
|------|----------|
| Small (1-2 파일) | 단독 개발 |
| Medium (3-5 파일) | feature-development |
| Large (6+ 파일) | feature-dev-team |
| X-Large (새 제품) | full-lifecycle-team |

### 훅 통합

- `TeammateIdle` → 테스트 자동 실행
- `TaskCompleted` → rubocop + 테스트

---

## Related Notes

- [[Claude Code Best Practices]]
- [[Claude Code Subagents Guide]]
- [[Claude Code Memory Guide]]
