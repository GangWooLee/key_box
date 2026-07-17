# Claude Code Memory Guide

> CLAUDE.md + Auto Memory + Agent Memory 가이드. Anthropic 공식 문서 기반. 최종 업데이트: 2026-02-26.

---

## Quick Reference

### 메모리 계층

| 유형 | 위치 | 로딩 |
|------|------|------|
| **CLAUDE.md** | `./CLAUDE.md` | 항상 자동 |
| **하위 CLAUDE.md** | `./src/CLAUDE.md` | 작업 시 자동 |
| **User CLAUDE.md** | `~/.claude/CLAUDE.md` | 항상 자동 |
| **Project Memory** | `~/.claude/projects/.../CLAUDE.md` | 항상 자동 |
| **Auto Memory** | `~/.claude/projects/.../memory/` | MEMORY.md 자동 |
| **Agent Memory** | `.claude/agent-memory/<name>/` | 에이전트 시작 시 |

### 명령어

| 명령어 | 용도 |
|--------|------|
| `/memory` | Auto Memory 편집 |
| `/init` | CLAUDE.md 자동 생성 |

---

## Patterns

### 1. CLAUDE.md 작성 구조

```markdown
# Project Name
## Project Overview
## Development Commands
## Architecture
## Rules
```

### 2. Auto Memory 관리

```
memory/
├── MEMORY.md       # 항상 로드 (200줄 제한!)
├── debugging.md    # 주제별 상세
└── patterns.md
```

**규칙**: 200줄 이후 잘림, 주제별 분리, 중복 방지

### 3. 저장 기준

| 저장 O | 저장 X |
|--------|--------|
| 안정적 패턴 | 임시 작업 상태 |
| 아키텍처 결정 | 미검증 추측 |
| 사용자 선호도 | CLAUDE.md 중복 |
| 반복 문제 해결책 | 일반 프로그래밍 지식 |

### 4. Agent Memory

```yaml
# 에이전트 frontmatter
memory: project  # .claude/agent-memory/<name>/ 에 저장
```

비즈니스 인사이트, 디자인 결정 등 세션 간 누적이 필요한 에이전트만 적용.

### 5. @import 구문

```markdown
@.claude/docs/agent-teams-guide.md
@.claude/skills/README.md
```

CLAUDE.md에서 외부 파일 인라인 로드. 핵심 2-3개만 추가 권장.

---

## Anti-patterns

| 안티패턴 | 올바른 방법 |
|---------|-----------|
| MEMORY.md 200줄 초과 | 주제별 파일 분리 |
| 모든 세션 내용 저장 | 안정적 패턴만 선별 |
| 모든 에이전트에 memory | 분석/비즈니스만 필요 |
| @import 과다 | 핵심 2-3개만 |

---

## Our Customizations (key_box)

### Agent Memory 배치

| 에이전트 | memory | 이유 |
|---------|--------|------|
| market-researcher | project | 시장 인사이트 누적 |
| data-analyst | project | 이벤트 트래킹 결정 |
| designer | project | 디자인 시스템 결정 |

### CLAUDE.md 구조 (390줄)

Rules 조건부 로딩, 의사결정 트리, 스킬 라우팅, 에이전트 역할, 워크플로우, Quality Gates, Best Practices, @import 포함.

---

## Related Notes

- [[Claude Code Best Practices]]
- [[Claude Code Subagents Guide]]
- [[Claude Code Agent Teams Guide]]
