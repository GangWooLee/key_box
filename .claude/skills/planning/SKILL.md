---
name: planning-with-files
version: "2.11.0"
description: Implements Manus-style file-based planning for complex tasks. Creates task_plan.md, findings.md, and progress.md. Use when starting complex multi-step tasks, research projects, or any task requiring >5 tool calls. Now with automatic session recovery after /clear.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - WebSearch
hooks:
  PreToolUse:
    - matcher: "Write|Edit|Bash|Read|Glob|Grep"
      hooks:
        - type: command
          command: "cat task_plan.md 2>/dev/null | head -30 || true"
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "echo '[planning-with-files] File updated. If this completes a phase, update task_plan.md status.'"
  Stop:
    - hooks:
        - type: command
          command: |
            sh .claude/skills/planning/scripts/check-complete.sh
---

# Planning with Files

Work like Manus: Use persistent markdown files as your "working memory on disk."

## FIRST: Check for Previous Session (v2.2.0)

**Before starting work**, check for unsynced context from a previous session:

```bash
$(command -v python3 || command -v python) .claude/skills/planning/scripts/session-catchup.py "$(pwd)"
```

If catchup report shows unsynced context:
1. Run `git diff --stat` to see actual code changes
2. Read current planning files
3. Update planning files based on catchup + git diff
4. Then proceed with task

## Important: Where Files Go

- **Templates** are in `.claude/skills/planning/templates/`
- **Your planning files** go in **your project directory**

| Location | What Goes There |
|----------|-----------------|
| Skill directory (`.claude/skills/planning/`) | Templates, scripts, reference docs |
| Your project directory | `task_plan.md`, `findings.md`, `progress.md` |

## Phase 0: 브레인스토밍 (코드 작성 전 필수)

코드를 작성하기 전에 반드시 설계 합의를 완료합니다.

### 0-1. 요구사항 명확화
- 한 번에 하나씩 질문 (AskUserQuestion 사용, 객관식 우선)
- 파악 대상: 목적, 제약, 성공 기준, 영향 범위

### 0-2. 접근법 탐색
- 2-3개 방안을 트레이드오프와 함께 제시
- 권장안을 첫 번째에 배치
- 사용자 선택 대기 (선택 전 진행 금지)

### 0-3. 설계 합의
- 200-300자 단위 섹션으로 설계 발표:
  - 아키텍처 결정
  - 데이터 모델 변경
  - API/라우팅 변경
  - 에러 처리 전략
  - 테스트 전략
- 각 섹션 승인 후 다음 진행
- 설계 문서를 `docs/plans/`에 저장 (기존 plan template 활용)

### Phase 0 스킵 조건 (이것만)
- 사용자가 이미 상세 설계를 제공한 경우
- 5줄 이하의 단순 변경

**Phase 0과 Phase 1의 관계**: Phase 0은 "무엇을 만들지" 합의, Phase 1은 "어떻게 만들지" 분석. Phase 0의 설계 합의가 Phase 1의 입력이 됨.

### Phase 0 Hard Gate (위반 시 전체 플래닝 세션 무효)

**금지사항**: 아래 조건이 모두 충족될 때까지 구현 스킬(`implement`, `rails-dev`, `tdd-workflow`), 프로덕션 코드 작성, 마이그레이션 생성, 리소스 스캐폴딩을 수행하지 않습니다:
1. 설계가 200-300자 섹션 단위로 발표됨
2. 사용자가 각 섹션을 명시적으로 승인함
3. 설계 문서가 `docs/plans/`에 저장됨

---

## Quick Start

Before ANY complex task:

0. **Phase 0: 브레인스토밍** — 요구사항 명확화 → 접근법 탐색 → 설계 합의
1. **Create `task_plan.md`** — Use [templates/task_plan.md](templates/task_plan.md) as reference
2. **Create `findings.md`** — Use [templates/findings.md](templates/findings.md) as reference
3. **Create `progress.md`** — Use [templates/progress.md](templates/progress.md) as reference
4. **Re-read plan before decisions** — Refreshes goals in attention window
5. **Update after each phase** — Mark complete, log errors

> **Note:** Planning files go in your project root, not the skill installation folder.

## The Core Pattern

```
Context Window = RAM (volatile, limited)
Filesystem = Disk (persistent, unlimited)

→ Anything important gets written to disk.
```

## File Purposes

| File | Purpose | When to Update |
|------|---------|----------------|
| `task_plan.md` | Phases, progress, decisions | After each phase |
| `findings.md` | Research, discoveries | After ANY discovery |
| `progress.md` | Session log, test results | Throughout session |

## Critical Rules

### 1. Create Plan First
Never start a complex task without `task_plan.md`. Non-negotiable.

### 2. The 2-Action Rule
> "After every 2 view/browser/search operations, IMMEDIATELY save key findings to text files."

This prevents visual/multimodal information from being lost.

### 3. Read Before Decide
Before major decisions, read the plan file. This keeps goals in your attention window.

### 4. Update After Act
After completing any phase:
- Mark phase status: `in_progress` → `complete`
- Log any errors encountered
- Note files created/modified

### 5. Log ALL Errors
Every error goes in the plan file. This builds knowledge and prevents repetition.

```markdown
## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| FileNotFoundError | 1 | Created default config |
| API timeout | 2 | Added retry logic |
```

### 6. Never Repeat Failures
```
if action_failed:
    next_action != same_action
```
Track what you tried. Mutate the approach.

## The 3-Strike Error Protocol

```
ATTEMPT 1: Diagnose & Fix
  → Read error carefully
  → Identify root cause
  → Apply targeted fix

ATTEMPT 2: Alternative Approach
  → Same error? Try different method
  → Different tool? Different library?
  → NEVER repeat exact same failing action

ATTEMPT 3: Broader Rethink
  → Question assumptions
  → Search for solutions
  → Consider updating the plan

AFTER 3 FAILURES: Escalate to User
  → Explain what you tried
  → Share the specific error
  → Ask for guidance
```

## Read vs Write Decision Matrix

| Situation | Action | Reason |
|-----------|--------|--------|
| Just wrote a file | DON'T read | Content still in context |
| Viewed image/PDF | Write findings NOW | Multimodal → text before lost |
| Browser returned data | Write to file | Screenshots don't persist |
| Starting new phase | Read plan/findings | Re-orient if context stale |
| Error occurred | Read relevant file | Need current state to fix |
| Resuming after gap | Read all planning files | Recover state |

## The 5-Question Reboot Test

If you can answer these, your context management is solid:

| Question | Answer Source |
|----------|---------------|
| Where am I? | Current phase in task_plan.md |
| Where am I going? | Remaining phases |
| What's the goal? | Goal statement in plan |
| What have I learned? | findings.md |
| What have I done? | progress.md |

## When to Use This Pattern

**Use for:**
- Multi-step tasks (3+ steps)
- Research tasks
- Building/creating projects
- Tasks spanning many tool calls
- Anything requiring organization

**Skip for:**
- Simple questions
- Single-file edits
- Quick lookups

## Templates

Copy these templates to start:

- [templates/task_plan.md](templates/task_plan.md) — Phase tracking
- [templates/findings.md](templates/findings.md) — Research storage
- [templates/progress.md](templates/progress.md) — Session logging

## Scripts

Helper scripts for automation:

- `scripts/init-session.sh` — Initialize all planning files
- `scripts/check-complete.sh` — Verify all phases complete
- `scripts/session-catchup.py` — Recover context from previous session (v2.2.0)

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Use TodoWrite for persistence | Create task_plan.md file |
| State goals once and forget | Re-read plan before decisions |
| Hide errors and retry silently | Log errors to plan file |
| Stuff everything in context | Store large content in files |
| Start executing immediately | Create plan file FIRST |
| Repeat failed actions | Track attempts, mutate approach |
| Create files in skill directory | Create files in your project |
