---
title: "방법론 이식 아키텍처 — 프로젝트·에이전트 간 하네스 상속 (2026-07)"
date: 2026-07-20
status: 권고안 — 적대검증 미완(사용량 한도), 출처·로컬 실증 기반
---

# 방법론 이식 — 한 프로젝트의 하네스를 모든 프로젝트가 상속하게

> **정직 배너**
> - `/deep-research` 워크플로의 **수집·추출은 완료**(25개 주장, 각 출처 명시)했으나
>   **적대검증 레이어는 사용량 크레딧 소진으로 전부 실패**했다(75/104 에이전트 에러).
>   아래 외부 주장들은 "출처 있는 미검증" 상태다 — 반증된 게 아니라 검증이 안 돈 것.
> - 단, ★ 표시 항목은 **이 머신에서 직접 실증**했거나(로컬 파일 확인, 직접 fetch) 기존
>   메모리에 1차 기록이 있는 것 — 신뢰도가 다르다.
> - 재검증을 원하면 크레딧 리셋 후 동일 워크플로 resume 가능(runId `wf_8c2dfe6b-bf6`).

## 1. 결론 (권고 아키텍처)

**3층 구조 + 2채널 배포**:

```
L1 방법론 (스택 중립)      gangwoo-method 레포 (git 정본)
   vision-qa·test-sync·(향후 검증규율·세션인계…)
   ├─ 배포채널 A: Claude Code 플러그인 (마켓플레이스 레포)
   └─ 배포채널 B: npx skills (.agents/skills — Codex 등 비-Claude 에이전트)
L2 프로젝트 바인딩 (스택 특정)   각 리포 .claude/skills/<name>/SKILL.md
   같은 이름 → 프로젝트 스코프가 전역을 셰도잉 (key_box에서 구현·동작 확인 ★)
L3 기계 게이트                  각 리포 lefthook + 파라미터화 스크립트
   test-delta-guard: TDG_SRC_RE/TDG_TEST_RE로 스택 중립화 완료 ★
```

**지금 당장은 추가 도구 불요** — 전역 `~/.claude/skills/` + 리포 바인딩(이미 구축 ★)이
1인 개발 환경에선 사실상 플러그인과 동등하게 작동한다. 플러그인화(gangwoo-method)는
**방법론 스킬이 3~4개 이상 쌓이거나 두 번째 머신/에이전트가 생길 때** 착수하면 된다.

## 2. 근거 지형 (출처별)

### 2-1. 스킬 포맷은 이미 사실상 크로스-에이전트 표준 ★(부분)

- OpenAI Codex가 Anthropic Agent Skills와 동일 포맷(SKILL.md + YAML frontmatter
  name/description)을 채택, **agentskills.io** 개방 표준을 따른다고 문서화
  [developers.openai.com/codex/skills — 미검증].
- Codex의 스킬 디스커버리는 **계층형**: 리포 `.agents/skills` → 사용자 `$HOME/.agents/skills`
  → 관리자 → 내장 [같은 출처 — 미검증]. **★ 로컬 실증**: 이 머신에 정확히 그 구조가
  살아 있다 — `~/.agents/skills/`(gstack 스킬들), `key_box/.agents/skills/`(Flutter 스킬
  원본, `.claude/skills/`는 symlink — 기존 메모리 교훈과 일치).
- 함의: **우리의 2층(전역 방법론 + 리포 바인딩) 패턴은 Claude 전용 트릭이 아니라
  생태계 표준 방향과 일치**한다. 나중에 `.agents/skills`로 정본을 옮기면 Codex도 같은
  스킬을 읽는다.

### 2-2. 방법론 플러그인의 실전 선례

- **superpowers**(obra): TDD·디버깅·검증 등 스택 중립 방법론을 플러그인 하나로 패키징,
  마켓플레이스 배포 + 다수 비-Claude 에이전트 지원 주장 [github.com/obra/superpowers —
  미검증]. **★ 로컬**: 이 머신에 claude-plugins-official 마켓플레이스로 설치·상시 사용 중 —
  "방법론=플러그인" 모델의 살아있는 증거.
- **mattpocock/skills** ★(직접 fetch): 177.9k★(2026-07-17 GitHub API), MIT. 순수 방법론
  스킬 24종(tdd·code-review·diagnosing-bugs·to-spec·handoff…)을 **이중 채널**로 배포 —
  `npx skills@latest add mattpocock/skills`(리포에 편집 가능 복사) + Claude 플러그인
  (`claude plugin install mattpocock-skills@mattpocock`, 읽기전용·자동업데이트).
  프로젝트 특정성은 setup 커맨드가 `CONTEXT.md`로 분리 — **우리 바인딩 계약과 동형**.
- compound-engineering ★(로컬 설치 확인): 개인 마켓플레이스 레포 방식의 선례.

### 2-3. rules 동기화 도구 (ruler 등)

- **intellectronica/ruler**: `.ruler/`(AGENTS.md 정본) → 30+ 에이전트 네이티브 설정으로
  살포. 단 **스킬/서브에이전트 전파는 experimental** [github.com/intellectronica/ruler —
  미검증].
- 판단: 스킬이 이미 크로스-에이전트 표준(2-1)이라면 ruler의 주 가치는 **rules(CLAUDE.md ↔
  AGENTS.md) 동기화**로 좁혀진다. 지금은 Claude Code 단일 에이전트 체제이므로 **도입 불요**.
  둘째 에이전트(Codex 등)를 실사용하게 될 때 rules 계층에만 한정 도입 검토.

### 2-4. Claude Code 플러그인 표면

- 플러그인은 skills·commands·agents·hooks·MCP 서버·기본 settings까지 번들 가능하나
  **CLAUDE.md/rules 파일을 배포하는 메커니즘은 문서에 없음** [code.claude.com/docs/en/plugins
  — 미검증]. → rules·CLAUDE.md 골격은 플러그인이 아니라 **스타터 템플릿 레포**가 맡아야 한다.

## 3. key_box에서 이미 구축한 것 (2026-07-20 ★ 전부 실증)

| 층 | 구현 | 실증 |
|---|---|---|
| L1 방법론 | `~/.claude/skills/vision-qa/`·`test-sync/` — 스택 중립, 바인딩 계약 + 부트스트랩 모드 내장 | 스킬 리스팅에 전역·프로젝트 양층 등록 확인 |
| L2 바인딩 | `key_box/.claude/skills/…` — Flutter 명령·cipher 함정·시나리오 팩만, 절차 복제 금지 | S1 실주행 PASS + 뮤테이션 RED |
| L3 게이트 | `.lefthook/test-delta-guard` — TDG_SRC_RE/TDG_TEST_RE 파라미터 | 뮤테이션 3종(기본 RED/재정의 GREEN/src 레이아웃 RED) |

## 4. 로드맵 (각 단계 별도 승인)

1. **지금**: 현 구조 그대로 사용. 새 방법론이 생기면 같은 패턴(전역 방법론 + 리포 바인딩)으로 추가.
2. **gangwoo-method 레포 생성 트리거**: 방법론 스킬 ≥3~4개 또는 둘째 머신 필요 시.
   구조 = 마켓플레이스 플러그인 레포(skills/ + hooks 템플릿 + `.claude-plugin/marketplace.json`),
   mattpocock 모델대로 npx skills 채널 병행.
3. **스타터 템플릿 레포**: `.claude/` 골격(rules/common/ 5종·훅 스크립트·lefthook.yml·
   settings 스켈레톤) — 플러그인이 못 나르는 rules/CLAUDE.md 계층 담당. 새 프로젝트 =
   템플릿에서 시작 + `/init`으로 스택 특화.
4. **ruler**: Codex 등 둘째 에이전트 실사용 시작 시에만, rules 동기화 한정 재검토.

## 5. 미검증 항목 재검증 방법

크레딧 리셋(19:20 KST) 후: 워크플로 resume(runId `wf_8c2dfe6b-bf6` — 수집 단계는 캐시
재생, 검증만 재실행) 또는 결정 시점에 해당 출처 직접 확인. 특히 2-4(플러그인이 rules를
못 나른다)는 로드맵 3단계 착수 전 반드시 원문 재확인할 것.
