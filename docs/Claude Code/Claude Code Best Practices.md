# Claude Code Best Practices

> Anthropic 공식 문서 기반 핵심 요약. 최종 업데이트: 2026-02-26.

---

## Quick Reference

| 명령어 | 용도 |
|--------|------|
| `/clear` | 컨텍스트 리셋 (작업 전환 시) |
| `/compact <지시>` | 주제 집중 압축 |
| `/init` | 프로젝트에 CLAUDE.md 자동 생성 |
| `/memory` | 메모리 파일 편집 |
| `Shift+Tab` | 자동 수락 모드 토글 |
| `Esc` → `Esc` | 현재 작업 중단 |

---

## Patterns

### 1. CLAUDE.md 계층 구조

```
~/.claude/CLAUDE.md              # 글로벌 (모든 프로젝트 공통)
./CLAUDE.md                      # 프로젝트 루트
./src/CLAUDE.md                  # 하위 디렉토리별
~/.claude/projects/.../CLAUDE.md # 사용자 개인 (커밋 안 됨)
```

- 프로젝트 루트 CLAUDE.md는 **항상** 로드됨
- 하위 디렉토리 CLAUDE.md는 해당 디렉토리 작업 시만 로드
- `@path/to/file` 구문으로 외부 파일 import 가능

### 2. 효과적인 CLAUDE.md 작성법

```markdown
# 좋은 CLAUDE.md
- 짧고 명확한 지시 (bullet points)
- 빌드/테스트 명령어 명시
- 프로젝트 특수 규칙 명시
- 자주 실수하는 패턴 경고

# 피해야 할 것
- 장황한 설명
- 일반적인 프로그래밍 원칙
- 코드 예시 과다 (Standards로 분리)
```

### 3. 컨텍스트 관리 전략

| 상황 | 전략 |
|------|------|
| 새 작업 시작 | `/clear` |
| 긴 탐색 후 구현 | `/compact 구현에 집중` |
| 2회 수정 실패 | `/clear` + 더 구체적 프롬프트 |
| 대규모 코드 리딩 | subagent에 위임 |

### 4. 권한 모드

| 모드 | 설명 |
|------|------|
| `default` | 도구별 승인 필요 |
| `plan` | 읽기만 가능, 쓰기 불가 |
| `bypassPermissions` | 모든 도구 자동 승인 |
| `acceptEdits` | 파일 편집만 자동 승인 |

### 5. Headless 모드 (CI/CD)

```bash
# 비대화형 실행
claude -p "테스트 실행하고 결과 알려줘" --allowedTools Bash Read

# 파이프 입력
cat error.log | claude -p "이 에러 분석해줘"

# JSON 출력
claude -p "분석해줘" --output-format json
```

---

## Anti-patterns

| 안티패턴 | 올바른 방법 |
|---------|-----------|
| CLAUDE.md에 코드 예시 과다 | Standards 파일로 분리 |
| 모든 rules 무조건 로드 | `paths:` frontmatter로 조건부 로드 |
| 큰 파일 직접 읽기 | subagent에 탐색 위임 |
| 실패 시 같은 방법 반복 | `/clear` 후 접근 방식 변경 |
| 수동 컨텍스트 관리 | auto memory + `/compact` 활용 |

---

## Our Customizations (key_box)

- **Rules 이중 체계**: Rules (자동 로드, 원칙) + Standards (수동 참조, 상세 패턴)
- **Rules paths**: backend/frontend/testing rules에 조건부 로딩 적용
- **14개 에이전트**: quality(4) + domain(1) + workflow(1) + utility(1) + business(7)
- **19+ 커스텀 스킬**: 자동 감지 + `/command` 호출
- **5개 워크플로우**: 단독~10역할 팀까지 스케일링
- **SessionStart 훅**: git 상태 + 마이그레이션 수 자동 표시
- **PreToolUse 훅**: 위험 명령어 자동 차단

---

## Related Notes

- [[Claude Code Hooks Reference]]
- [[Claude Code Skills Guide]]
- [[Claude Code Subagents Guide]]
- [[Claude Code Agent Teams Guide]]
- [[Claude Code Memory Guide]]
