# Claude Code Hooks Reference

> 훅 이벤트 레퍼런스. Anthropic 공식 문서 기반. 최종 업데이트: 2026-02-26.

---

## Quick Reference

### 훅 이벤트 목록

| 이벤트 | 타이밍 | 주요 용도 |
|--------|--------|----------|
| `SessionStart` | 세션 시작 시 | 프로젝트 상태 표시, 환경 검증 |
| `PreToolUse` | 도구 실행 전 | 위험 명령어 차단, 입력 검증 |
| `PostToolUse` | 도구 실행 후 | 자동 포맷팅, 린트 |
| `Notification` | 알림 발생 시 | 외부 알림 전송 |
| `Stop` | 에이전트 턴 종료 시 | 자동 검증, 로깅 |
| `SubagentStop` | subagent 턴 종료 시 | subagent 출력 검증 |
| `TeammateIdle` | 팀원 유휴 시 | 테스트 자동 실행 |
| `TaskCompleted` | 태스크 완료 시 | 린트 + 테스트 자동 실행 |

### 훅 응답 코드

| Exit Code | 의미 |
|-----------|------|
| `0` | 허용 (성공) |
| `1` | 에러 (stderr 표시) |
| `2` | 차단 (PreToolUse에서 도구 실행 방지) |

---

## Patterns

### 1. PreToolUse — 위험 명령어 차단

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-commands.sh",
          "timeout": 5
        }
      ]
    }
  ]
}
```

```bash
#!/bin/bash
COMMAND=$(jq -r '.tool_input.command // empty')
if echo "$COMMAND" | grep -iE '(rm -rf /|git push --force.*main|git reset --hard)'; then
  echo "Blocked: $COMMAND" >&2
  exit 2
fi
exit 0
```

### 2. PostToolUse — 자동 포맷팅

```json
{
  "PostToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [
        {
          "type": "command",
          "command": "bundle exec rubocop --autocorrect-all \"$CLAUDE_FILE_PATH\"",
          "timeout": 30
        }
      ]
    }
  ]
}
```

### 3. SessionStart — 프로젝트 상태 표시

```json
{
  "SessionStart": [
    {
      "matcher": "startup",
      "hooks": [
        {
          "type": "command",
          "command": "echo \"Branch: $(git branch --show-current) | Last: $(git log --oneline -1)\"",
          "timeout": 15
        }
      ]
    }
  ]
}
```

### 4. Stop — 턴 종료 시 자동 검증

```json
{
  "Stop": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "bin/rails test 2>&1 | tail -5",
          "timeout": 120
        }
      ]
    }
  ]
}
```

---

## 환경 변수

| 변수 | 설명 |
|------|------|
| `$CLAUDE_PROJECT_DIR` | 프로젝트 루트 경로 |
| `$CLAUDE_FILE_PATH` | 현재 파일 경로 (PostToolUse) |

훅의 stdin으로 JSON 데이터 전달:
```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "..." },
  "tool_output": "..."
}
```

---

## Matcher 패턴

| 패턴 | 매칭 대상 |
|------|----------|
| `"Bash"` | Bash 도구만 |
| `"Edit\|Write"` | Edit 또는 Write 도구 |
| `"startup"` | SessionStart 이벤트 |
| `""` (빈 문자열) | 모든 이벤트 |

---

## Anti-patterns

| 안티패턴 | 올바른 방법 |
|---------|-----------|
| 훅에서 긴 작업 실행 (60s+) | timeout 설정 + 비동기 처리 |
| stdout에 대량 출력 | stderr 사용 또는 요약만 출력 |
| 훅에서 git commit | 부작용 최소화, 검증만 수행 |
| 훅 실패 무시 | exit code 적절히 반환 |

---

## Our Customizations (key_box)

```
SessionStart      → git 상태 + 마이그레이션 수 표시
PreToolUse(Bash)  → 위험 명령어 차단 (block-dangerous-commands.sh)
PostToolUse(Edit) → RuboCop 자동 수정
TeammateIdle      → 테스트 자동 실행
TaskCompleted     → RuboCop + 테스트 실행
```

---

## Related Notes

- [[Claude Code Best Practices]]
- [[Claude Code Skills Guide]]
