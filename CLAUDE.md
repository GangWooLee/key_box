# key_box

## Project Overview
- **Project**: key_box
- **Framework**: Ruby on Rails
- **Language**: Ruby, JavaScript (Stimulus), HTML (ERB), CSS (Tailwind)

## Development Environment

### Available Tools
- **Agents** (7): code-review-expert, security-expert, data-integrity-expert, performance-expert, planner, ui-ux-expert, doc-updater
- **Commands** (10): /plan, /tdd, /verify, /checkpoint, /update-docs, /wrap-up, /skills-manage, /bridge, /verify-rules, /manage-rules
- **Skills** (60+): See `.claude/skills/README.md` for full list
- **Rules** (20): Backend (6), Frontend (5), Common (7), Testing (2)
- **Standards** (3): rails-backend, tailwind-frontend, testing
- **Workflows** (1): feature-development

### Commands Quick Reference
```
/plan          — 기능 계획 수립
/tdd           — TDD 워크플로우
/verify        — 6단계 검증
/checkpoint    — 진행 상태 저장
/update-docs   — 문서 동기화
/wrap-up       — 작업 마무리
/bridge        — UI 주석 처리
/verify-rules  — 프로젝트 규칙 준수 검증
/manage-rules  — 검증 스킬 생성/업데이트
```

## Feature Development Principles

### Phase-Based TDD
- 각 Phase는 독립적 RED/GREEN/REFACTOR 사이클
- Phase 간 전환 시 Quality Gate 필수 통과
- Quality Gate 실패 상태에서 다음 Phase 진행 금지

### Quality Gate (Phase 간 체크포인트)
1. `bin/rails runner "puts 'OK'"` — 빌드 통과
2. `bin/rails test` — 전체 테스트 통과
3. `bundle exec rubocop` — 린트 통과
4. TDD 준수 — 테스트가 구현보다 먼저 작성됨
5. 수동 테스트 — Phase 기능 동작 확인

### Test Coverage Targets (standards/testing.md 기준)
| 영역 | 최소 커버리지 |
|------|-------------|
| 모델 (Validations/Associations) | 100% |
| 인증/결제 | 100% |
| 서비스 객체 | 80% |
| 컨트롤러 | 80% |
| 시스템 테스트 | 60% |

### Risk-First Planning
- 새 기능 계획 시 Risk Assessment 포함
- Probability x Impact 매트릭스
- Phase별 Rollback 전략 문서화

## Project-Specific Notes
- bkit 플러그인 비활성화 (2026-02-23): 프로젝트 자체 프레임워크(agents/commands/skills/rules)와 충돌. `.claude/settings.json`에서 `false` 처리.
- ui-ux-pro-max 도입 (2026-02-23): frontend-design 스킬 교체. BM25 검색 엔진 + 24 CSV 데이터셋 + 3 Python 스크립트. 소스: nextlevelbuilder/ui-ux-pro-max-skill.
- Superpowers 참조 (2026-02-23): 신규 프로젝트에서 커스텀 프레임워크 구축 전 obra/superpowers 플러그인 권장. 설치: `/plugin marketplace add obra/superpowers-marketplace` → `/plugin install superpowers@superpowers-marketplace`.
