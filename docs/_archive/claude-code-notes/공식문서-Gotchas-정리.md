# Claude Code 공식문서 Gotchas 정리

> 적용일: 2026-02-26
> 대상: key_box + claude-rails-template (동일 적용)
> 참조: Anthropic 공식 문서 (hooks, permissions, agents, context)

---

## 1. Hook 라이프사이클 (8개 이벤트)

| 이벤트 | 시점 | exit 2 차단 가능 | stdin JSON |
|--------|------|:---:|:---:|
| **PreToolUse** | 도구 실행 전 | ✅ | tool_input |
| **PostToolUse** | 도구 성공 후 | ❌ | tool_input, tool_result |
| **PostToolUseFailure** | 도구 실패 후 | ❌ | tool_name, error |
| **PreCompact** | 컨텍스트 압축 전 | ❌ | - |
| **SessionStart** | 세션 시작 시 | ❌ | - |
| **Stop** | 세션 종료 시 | ❌ | - |
| **Notification** | 알림 발생 시 | ❌ | message |
| **TeammateIdle** | 팀원 유휴 시 | ❌ | - |
| **TaskCompleted** | 태스크 완료 시 | ❌ | - |

### Hook Exit Code 규칙
- `0` = 성공 (허용)
- `1` = 비차단 에러 (경고만 표시, 계속 진행)
- `2` = 차단 (**PreToolUse에서만 유효**, 도구 실행 차단)

### Hook stdin 파싱
```bash
# ❌ 잘못된 방법
TOOL_NAME=$1

# ✅ 올바른 방법
TOOL_NAME=$(jq -r '.tool_name // "unknown"')

# ⚠️ stdin 두 번 읽기 불가 — 변수에 먼저 저장
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
ERROR=$(echo "$INPUT" | jq -r '.error')
```

### SessionStart Matcher 4종
| Matcher | 시점 |
|---------|------|
| `startup` | 새 세션 시작 |
| `resume` | 기존 세션 재개 |
| `clear` | `/clear` 후 |
| `compact` | 자동/수동 압축 후 |

---

## 2. Permission 우선순위

```
deny > ask > allow
```

- 같은 패턴이 `allow`와 `deny`에 동시 존재 → **deny 승리**
- `settings.local.json`은 `settings.json`보다 **높은 우선순위**
- 파일 경로는 프로젝트 루트 기준 **상대 경로** (예: `Read(.env)`)

### 적용한 deny 규칙
```json
"deny": [
  "Bash(git reset --hard*)",
  "Bash(rm -rf*)",
  "Bash(rails db:drop*)",
  "Bash(rails db:reset*)",
  "Read(.env)",
  "Read(.env.*)",
  "Read(config/master.key)",
  "Read(config/credentials.yml.enc)"
]
```

---

## 3. Agent Frontmatter 완전 레퍼런스

| 속성               | 값                           | 설명             |
| ---------------- | --------------------------- | -------------- |
| `name`           | 문자열                         | 에이전트 식별자       |
| `description`    | 문자열                         | 역할 설명          |
| `permissionMode` | `plan`\|`bypassPermissions` | plan=read-only |
| `model`          | `opus`\|`sonnet`\|`haiku`   | 미지정 시 부모 상속    |
| `memory`         | `project`                   | 프로젝트별 영속 메모리   |
| `triggers`       | 배열                          | 자동 감지 키워드      |
| `related_skills` | 배열                          | 연관 스킬          |
| `teamRole`       | 문자열                         | 팀 내 역할         |

### 적용한 모델 배치

| 에이전트 | Model | 이유 |
|---------|-------|------|
| code-review-expert | opus | 미묘한 코드 패턴 판단 |
| security-expert | opus | 보안 취약점 놓치면 안됨 |
| data-integrity-expert | opus | 동시성/레이스 조건 추론 |
| market-researcher | opus | 시장 분석 추론 |
| planner | opus | 설계 판단 (기존) |
| performance-expert | sonnet | 패턴 매칭 기반 |
| ui-ux-expert | sonnet | UI 패턴 적용 |
| product-manager | sonnet | 문서 생성 중심 |
| designer | sonnet | 디자인 도구 호출 |
| backend-ops | sonnet | 인프라 설정 패턴 |
| qa-engineer | sonnet | 테스트 생성 패턴 |
| marketer | sonnet | 콘텐츠 생성 |
| data-analyst | sonnet | 데이터 구조화 |
| doc-updater | sonnet | 문서 생성 (기존) |

### memory: project 적용 에이전트 (7개)
- quality 4개: code-review, security, performance, data-integrity
- business 3개: designer, market-researcher, data-analyst

---

## 4. Context 관리

### AUTOCOMPACT_PCT_OVERRIDE
- **기본값**: 95% (컨텍스트 95% 차면 압축 시작)
- **권장값**: 80% (더 여유 있을 때 압축 → 요약 품질 향상)

```json
"env": {
  "CLAUDE_CODE_AUTOCOMPACT_PCT_OVERRIDE": "80"
}
```

### /compact 사용법
```
/compact API 변경에 집중    ← 지시 포함 (권장)
/compact                    ← 지시 없음 (컨텍스트 유실 위험)
```

---

## 5. 적용 Hook 인벤토리

### 기존 (8개 — 이전 세션)
1. SessionStart(startup) — git 상태 출력
2. PreToolUse(Bash) — 위험 명령어 차단
3. PostToolUse(Edit|Write) — rubocop 자동 교정
4. TeammateIdle — 테스트 자동 실행
5. TaskCompleted — rubocop + 테스트

### 신규 (5개 — 이번 세션)
6. SessionStart(compact) — 압축 후 git 상태 재주입
7. PreCompact — 압축 전 작업 상태 스냅샷 저장
8. Stop — 세션 종료 시 미커밋 변경 경고
9. Notification — macOS 데스크탑 알림
10. PostToolUseFailure — 도구 실패 로깅

---

## 6. 새로 추가된 파일

| 파일 | 용도 |
|------|------|
| `.claude/hooks/pre-compact-save.sh` | 압축 전 git 상태 저장 |
| `.claude/hooks/stop-guard.sh` | 세션 종료 시 미커밋 경고 |
| `.claude/hooks/desktop-notify.sh` | macOS 데스크탑 알림 |
| `.claude/hooks/log-tool-failure.sh` | 도구 실패 로깅 |
| `.claude/settings.local.json.example` | 개인 설정 오버라이드 템플릿 |

---

## 7. Gotchas 요약 (빠른 참조)

### ⚠️ 반드시 기억
1. **stdin은 한 번만 읽힌다** — `jq` 두 번 호출 시 `INPUT=$(cat)` 먼저
2. **PreCompact exit 2는 무효** — 압축을 막을 수 없음, 저장만 가능
3. **Stop hook에서 도구 호출 금지** — 무한루프 (가드 변수 필수)
4. **deny가 항상 이긴다** — allow에 있어도 deny에 있으면 차단
5. **model 미지정 = 부모 상속** — 비용 폭발 가능 (sonnet 써야 할 곳에 opus)
6. **/compact에 지시 포함** — 빈 compact는 중요 컨텍스트 유실

---

*Last Updated: 2026-02-26*
*Tags: #claude-code #hooks #permissions #agents #gotchas*
