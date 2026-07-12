# Claude Code Skills Guide

> 스킬 설계 패턴 및 활용 가이드. Anthropic 공식 문서 기반. 최종 업데이트: 2026-02-26.

---

## Quick Reference

### 스킬 파일 구조

```
.claude/skills/
└── my-skill/
    └── SKILL.md       # 스킬 정의 파일
```

### SKILL.md Frontmatter

```yaml
---
name: my-skill
description: "스킬 설명 (자동 감지에 사용)"
disable-model-invocation: true  # 자동 호출 방지 (선택)
---
```

### 스킬 호출 방법

| 방법 | 예시 |
|------|------|
| 사용자 명령어 | `/my-skill` |
| 키워드 감지 | description 매칭 시 자동 호출 |
| 수동 요청 | "my-skill 스킬 사용해줘" |

---

## Patterns

### 1. 기본 스킬 구조

```markdown
---
name: code-review
description: "코드 리뷰 및 품질 검수"
---

# Code Review Skill

## 실행 단계
1. 변경된 파일 식별
2. 패턴 검증
3. 리포트 생성

## 체크리스트
- [ ] 복잡도 제한 준수
- [ ] 테스트 커버리지
```

### 2. 자동 호출 방지 (부작용 있는 스킬)

```yaml
---
name: wrap-up
description: "작업 마무리 — 커밋 생성"
disable-model-invocation: true
---
```

적용 대상:
- 커밋 생성 (`wrap-up`)
- 전체 테스트 실행 (`verification-loop`)
- 컨텍스트 압축 (`strategic-compact`)

### 3. 스킬 조합 패턴

```
새 기능:     rails-resource → test-gen → stimulus-controller → ui-component
코드 품질:   code-review + security-audit + performance-check
UI 개선:     bridge → ui-ux-pro-max → ui-component
```

### 4. 도메인 자동 라우팅

| 도메인 | 감지 키워드 | 스킬 |
|--------|-----------|------|
| Frontend | UI, Stimulus | ui-ux-pro-max, ui-component |
| Backend | 모델, 서비스 | rails-resource, service-object |
| Testing | 테스트, TDD | test-gen, tdd-workflow |
| Security | 보안, 취약점 | security-audit |

---

## Anti-patterns

| 안티패턴 | 올바른 방법 |
|---------|-----------|
| 모든 스킬 자동 호출 허용 | 부작용 스킬은 `disable-model-invocation` |
| 너무 긴 스킬 (200줄+) | 핵심만, 상세는 Standards 참조 |
| 스킬 간 암묵적 의존성 | 명시적 워크플로우로 조합 |

---

## Our Customizations (key_box)

| 카테고리 | 스킬 수 | 예시 |
|---------|--------|------|
| Rails 개발 | 6 | rails-resource, service-object |
| 테스팅 | 3 | test-gen, tdd-workflow |
| UI/UX | 4 | ui-ux-pro-max, ui-component |
| 품질 | 4 | code-review, security-audit |
| 워크플로우 | 4 | planning, bugfix, wrap-up |
| 마케팅 | 15+ | copywriting, seo-audit |

**스킬 강제 호출 규칙**: 적용 가능한 스킬이 있으면 반드시 호출.

---

## Related Notes

- [[Claude Code Best Practices]]
- [[Claude Code Hooks Reference]]
- [[Claude Code Subagents Guide]]
