# Claude Code Subagents Guide

> 서브에이전트 설계 패턴. Anthropic 공식 문서 기반. 최종 업데이트: 2026-02-26.

---

## Quick Reference

### 에이전트 정의 파일

```
.claude/agents/
├── quality/     # 리뷰 전용 (plan mode)
├── domain/      # UI/UX 전문가
├── workflow/    # 설계/계획
├── utility/     # 문서 관리
└── business/    # 비즈니스 에이전트
```

### Frontmatter 필드

```yaml
---
name: code-review-expert
description: "코드 리뷰 전문가"
permissionMode: plan          # plan = 읽기 전용
memory: project               # project = 프로젝트별 메모리
triggers:
  - 코드 리뷰
related_skills:
  - code-review
teamRole: quality-guard
---
```

---

## Patterns

### 1. Permission Mode 설계

| 모드 | 용도 | 에이전트 예시 |
|------|------|-------------|
| `plan` | 읽기/분석 전용 | code-review-expert, security-expert |
| `default` | 읽기 + 쓰기 | planner, designer |

**원칙**: 리뷰/분석 에이전트는 `plan` 모드로 실수 방지.

### 2. Memory 스코프

| 스코프 | 저장 위치 | 공유 범위 |
|--------|----------|----------|
| `user` | `~/.claude/agent-memory/` | 사용자 로컬 |
| `project` | `.claude/agent-memory/` | 팀 (커밋 가능) |

**원칙**: 비즈니스 인사이트는 `project`, 기술 에이전트는 메모리 불필요.

### 3. 병렬 리뷰 패턴

```
Task(code-review-expert)       ──┐
Task(security-expert)          ──┤
Task(performance-expert)       ──┼── 결과 종합
Task(data-integrity-expert)    ──┘
```

### 4. 에이전트 역할 분리

| 카테고리 | 역할 | 권한 |
|---------|------|------|
| Quality | 코드 품질, 보안, 성능, 데이터 | 읽기 전용 (plan) |
| Domain | UI/UX | 읽기+쓰기 |
| Business | 시장조사, 기획, 디자인 | 혼합 |

---

## Anti-patterns

| 안티패턴 | 올바른 방법 |
|---------|-----------|
| 모든 에이전트에 쓰기 권한 | 리뷰 에이전트는 plan 모드 |
| 에이전트에 과도한 프롬프트 | 참조 문서로 분리 |
| 순차적 리뷰 호출 | 병렬 호출로 시간 절약 |
| 모든 에이전트에 memory | 분석 에이전트만 필요 |

---

## Our Customizations (key_box)

### Permission Mode 배치

| permissionMode | 에이전트 |
|---------------|---------|
| `plan` | code-review-expert, security-expert, performance-expert, data-integrity-expert, market-researcher, data-analyst |
| default | planner, ui-ux-expert, doc-updater, designer, product-manager, backend-ops, qa-engineer, marketer |

### Memory 배치

| memory | 에이전트 |
|--------|---------|
| `project` | market-researcher, data-analyst, designer |

---

## Related Notes

- [[Claude Code Best Practices]]
- [[Claude Code Agent Teams Guide]]
- [[Claude Code Memory Guide]]
