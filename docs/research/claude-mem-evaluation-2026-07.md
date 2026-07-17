---
title: "claude-mem 도입 평가 & 권고 (key_box)"
date: 2026-07-17
status: 결정 대기 — 권고안(조건부 No-Go). 최종 결정은 사용자.
author: Claude (Opus 4.8) + 사용자 검토
tags: [research, memory, claude-code, tooling, security]
---

# claude-mem 도입 평가 & 권고 — key_box

> **정직 배너 (읽기의 출발점)**
> - 이 문서는 **문헌·레포·이슈 기반 데스크 평가**다. claude-mem을 **실제 설치·실행하지 않았다** —
>   운영/안정성 관련 서술은 공식 문서·CHANGELOG·GitHub 이슈의 사용자 보고에 근거한 2차 정보다.
> - 수치(star/fork/issue)는 **GitHub API 2026-07-17 시점값**. 시점에 따라 변한다.
> - 아키텍처 주장은 `/deep-research` 적대검증(3–0)으로 확정된 핵심 5건 + 레포 원문 이중 확인.
>   단 deep-research는 **세션 한도로 일부 검증이 중단**됐다(58/101 에이전트 에러) — "미검증(반증 아님)"
>   항목은 아래 §7에 명시했다.
> - **결론은 "claude-mem이 나쁘다"가 아니다.** 훌륭한 도구지만 **시크릿 매니저인 key_box의 위협모델**과
>   **이미 갖춘 큐레이션형 메모리 스택**이라는 두 특수조건 때문에 상시 도입이 부적합하다는 것이다.

---

## 1. TL;DR

| 항목 | 판정 |
|---|---|
| **key_box 상시 도입** | **조건부 No-Go (현 시점)** |
| 결정 축 | ① 시크릿 매니저 위협모델과 자동-캡처-평문-저장의 구조적 충돌 ② 기존 4계층 메모리와의 중복/드리프트 ③ 데몬 운영 부담 |
| 대안 | **패턴 이식**(도구 없이 progressive disclosure·redaction 규약·세션 요약 자동화) |
| 사용자 제약 | 프라이버시 = "로컬 전용 + 강한 완화 전제로만" → 이 바를 넘기려면 claude-mem이 제공 안 하는 자동 레드액션 게이트를 직접 만들어 뮤테이션 검증해야 함 |
| 재검토 트리거 | claude-mem이 (a) 자동 시크릿 레드액션 + (b) 암호화 at-rest 제공 시, 또는 네이티브 메모리 불충분 판명 시 |

---

## 2. claude-mem이란

Claude Code(및 Codex/Gemini/Copilot 등)용 **영속 메모리 시스템**. 세션 동안 에이전트의 도구 사용을
자동 관찰·캡처하고, AI로 요약·압축해, 다음 세션 시작 시 관련 컨텍스트를 semantic 검색으로 재주입한다.

- **성숙도/인기**: ~**87.5k** stars · **7,580** forks · **280** open issues · Apache-2.0 · **v13.11.0** · 거의 매일 push.
  → 실체가 분명하고 매우 활발한 프로젝트. (repo 생성 2025-08-31)
- **라이선스**: Apache-2.0 (프로덕션 임베딩 허용).
- **홈**: https://github.com/thedotmack/claude-mem · https://cmem.ai (구 claude-mem.ai)

---

## 3. 아키텍처 (확인된 사실)

**6개 lifecycle 훅** (Claude Code hook 시스템에 연결):

| 단계 | 훅/스크립트 | 하는 일 |
|---|---|---|
| Setup | `version-check.js` | 기동 시 버전 점검(외부 업그레이드 시 복구 유도) |
| **SessionStart** | — | **worker 데몬 기동 + semantic context 주입** (`/api/context/semantic`, Chroma 벡터검색) |
| **UserPromptSubmit** | `session-init` | 세션 등록 + SDK 에이전트 초기화 |
| **PostToolUse** | `observation` | **모든 도구 사용을 관찰로 캡처 → worker 큐 적재** |
| Summary | `summarize` | 세션 요약 요청(SDK 에이전트) → `session_summaries` |
| SessionEnd | `session-complete` | 세션 종료 + 대기 메시지 드레인 |

> ⚠️ deep-research에서 "PreToolUse 훅" 주장은 **1–2로 반증**됐다. 캡처는 **PostToolUse**가 맞다.

**저장 (전부 로컬)**:
- `~/.claude-mem/claude-mem.db` — **평문 SQLite** (bun:sqlite, **FTS5** 전문검색). 테이블: `sdk_sessions`,
  `observations`(SHA256 dedup), `pending_messages`, `session_summaries`.
- `~/.claude-mem/chroma.sqlite3` — Chroma 벡터 DB(관찰당 narrative + fact_0..N 임베딩), MCP stdio 접근.
- Bun HTTP **worker 데몬** 상주. 설정 `~/.claude-mem/settings.json`, 비밀 `~/.claude-mem/.env`.

**검색 = 3-layer progressive disclosure** (MCP 도구): `search`(ID 인덱스 ~50–100 tok/건) → `timeline`(시간축 맥락)
→ `get_observations`(선별 ID만 풀 상세 ~500–1,000 tok/건). **"~10x 토큰 절감"** 을 표방. `mem-search` 스킬로 자연어 질의.

**요구사항**: Node ≥20.12, Bun(자동설치), uv(자동설치).

**설치**: `npx claude-mem install` 또는 `/plugin marketplace add thedotmack/claude-mem`.
(주의: 단순 `npm install -g`는 훅 미등록/worker 미기동으로 실패 — 문서화된 함정.)

---

## 4. 프라이버시/보안 모델 (레포 `docs/security.md` · 루트 `SECURITY.md`)

- ✅ **로컬 우선**: "All claude-mem state files are written to the local user directory and are **not uploaded by
  claude-mem itself**." **텔레메트리 없음.**
- ⚠️ **요약 경로**: SDK 에이전트가 프롬프트·트랜스크립트를 Anthropic API로 전송(대체 provider 시 Gemini/OpenRouter).
  → Claude Code가 **이미 하는 것과 동일 경로**이므로 *새로운* 유출은 아님. 단 트랜스크립트를 처리하는 **경로가 하나 더** 생김.
- ⚠️ **클라우드 싱크(cmem.ai)**: **opt-in·기본 오프**(웨이트리스트, 무료 베타, "worker syncs on write").
  "End-to-end private — your link, your keys" 표방. **본 평가의 전제는 이 기능 하드-오프.**
- 🔴 **`<private>...</private>` 태그는 수동**. 문서상 "keep specific content out of the local store." 그러나
  **자동 자격증명 탐지·레드액션은 없다.**

---

## 5. key_box 적합성 평가 — 3축

### 축 A — 보안/프라이버시 (결정적)

key_box는 **시크릿 매니저**다. 방침: SQLCipher(AES-256)로 전부 암호화, **복호화 값·마스터키 로깅/저장 절대 금지**,
`.gitignore`로 `*.db`·`*.keychain`·`*.pem` 차단.

claude-mem의 핵심 루프 = **"PostToolUse에서 모든 도구 사용을 자동 캡처 → AI 요약 → 평문·임베딩·검색가능 저장"**.
이는 위 방침과 **구조적으로 상충**한다:

- 캡처 대상에 암호화 구현 코드, 테스트 픽스처의 키 재료, DB 스키마, bash 출력, 복호화 흐름이 포함될 수 있다.
- **실사례(최다 코멘트 open issue, §7 인용)**: "User API keys and secrets appear in observations **without
  auto-detection**; tool output echoing credentials **not caught by the existing `<private>` mechanism**."
- `<private>`는 **수동**이라 시크릿 매니저의 충분한 통제가 못 된다 — 한 번 빠뜨리면 **평문·검색가능** 저장 후
  **차기 세션 컨텍스트로 재주입**된다(유출면 확대).
- 저장소는 **암호화 at-rest 아님**(bun:sqlite 평문). key_box가 자기 데이터엔 SQLCipher를 강제하는 것과 대비.

**사용자 제약("로컬 전용 + 강한 완화")을 충족하려면**: 클라우드 하드-오프 **+ claude-mem이 제공하지 않는
자동 레드액션 게이트**를 직접 구축해 **뮤테이션으로 실증**해야 한다(시크릿 주입 시 저장이 차단되는지). 이는
실질적 개발·검증 부담이며, 통과해도 시크릿 매니저에서의 **잔여 리스크가 높다**.

### 축 B — 중복/드리프트 (기존 4계층)

key_box는 이미 **의도적으로 큐레이션형** 메모리 스택을 운영한다:

| 계층 | 위치 | 성격 |
|---|---|---|
| 하네스 네이티브 메모리 | `~/.claude/projects/.../memory/` | 타입드(project/reference)·세션기원·**자동 주입** |
| compound-engineering | `docs/solutions/` | 리포 커밋 엔지니어링 교훈(현재 비어있음) |
| 세션 핸드오프 | `docs/plans/` | 계획·인계 문서 |
| 지식 vault | Obsidian `docs/` | 광역 지식, MCP 접근 |
| 압축 대비 | PreCompact-save 훅 → `.claude/plans/.pre-compact-state.md` · SessionStart `compact` echo · AUTOCOMPACT 80% | 컨텍스트 연속성 |

- CLAUDE.md **L33**(세션메모리 ↔ `docs/solutions` 분리)·**L101**("내용 복제 금지 — 이중화가 드리프트를 낳는다")·
  **L20**("중복 loop 스킬 미사용 — 컨텍스트 비대 방지")는 **자동 캡처가 아니라 큐레이션을 택한 설계 의도**를 명시한다.
- claude-mem의 **SessionStart 자동 주입**은 여기에 **5번째·자동·중첩** 컨텍스트원을 더한다 →
  **컨텍스트 비대** + "지난 세션 진실원천" **이중화**(하네스 메모리 vs claude-mem).

### 축 C — 운영 비용/안정성

- **의존성 추가**: Bun + uv + **상주 worker 데몬** (솔로 개발자 머신에 움직이는 부품 증가).
- **문서화된 실패 사례(§7)**: 프로세스 릭(227개 → ~71GB → OOM), SQLite bloat(리텐션 정책 없음),
  마켓플레이스 설치가 빈 node_modules 배포("Cannot find module 'zod/v3'"), server-beta 검색 0건 회귀.
- **플랫폼**: 최악은 Windows(좀비 worker). **macOS는 상대적으로 양호**하나 데몬/프로세스 관리 부담은 상존.
- **CHANGELOG**: 버그픽스 위주·잦은 핫픽스(성숙 중이나 churn 존재). v13.11에 worker-native 클라우드 싱크 **신규 표면** 추가.

---

## 6. 의사결정 표

점수: 🟢 유리 / 🟡 중립·조건부 / 🔴 불리 (key_box 맥락 기준)

| 축 | 판정 | 근거 요약 |
|---|---|---|
| A. 보안/프라이버시 | 🔴 | 자동-캡처-평문-저장이 시크릿 매니저 위협모델과 구조적 충돌. 시크릿 유출 실사례. `<private>` 수동. at-rest 미암호화. |
| B. 중복/드리프트 | 🔴 | 이미 4계층 + 압축대비 훅. CLAUDE.md가 명시적으로 복제/비대 회피. 자동주입이 5번째 진실원천 이중화. |
| C. 운영/안정성 | 🟡 | macOS는 양호하나 Bun+uv+데몬 부담, 프로세스 릭·bloat 보고, churn. |
| 순기능(패턴) | 🟢 | progressive disclosure(~10x), 구조적 관찰 스키마, `<private>` 규약, SessionEnd 요약 — **아이디어는 우수**. |
| 인기/성숙 | 🟢 | 87.5k★, 활발, Apache-2.0. 도구 자체 신뢰도는 높음. |

**종합**: 도구 품질은 높으나(🟢), **key_box 두 특수조건(A·B)이 🔴**이라 상시 도입 부적합. 가치는 순기능 패턴(🟢)에 있다.

---

## 7. 근거 인용 — GitHub 이슈/문서 (실사용 신호)

최다 코멘트 open issue에서 반복되는 통점(발췌):
- **프라이버시 누출**: "User API keys and secrets appear in observations without auto-detection; tool output
  echoing credentials not caught by existing `<private>` mechanism." → **본 평가 축 A의 핵심 근거**.
- **프로세스 릭**: "227 leaked processes consuming ~71 GB → OOM kills"; Chroma-MCP가 PID 1로 reparent 후 미종료.
- **스토리지 bloat**: 완료 세션 프롬프트 중복 누적, 스테일 관찰 **자동 리텐션 정책 없음**.
- **설치 실패**: 마켓플레이스가 빈 node_modules 배포 → 첫 훅에서 "Cannot find module 'zod/v3'".
- **검색 회귀(server-beta)**: Postgres 데이터 있음에도 `search`가 0건 반환, `query` 파라미터 무시 사례.
- **Windows 불안정**(참고): 좀비 worker, 콘솔창 플래시 — macOS엔 해당 약함.

**미검증(반증 아님) — deep-research 세션한도로 검증 중단된 항목**:
- `<private>` 필터가 **훅 레이어(저장 이전)** 에서 동작한다는 문서 주장(docs.claude-mem.ai) — 사실이면 축 A 리스크를
  일부 낮추나, **자동 자격증명 탐지가 아니라 수동 태그 스트리핑**이라는 한계는 그대로. 실측 필요(트랙 2).
- 훅 타임아웃(SessionStart 60s / PostToolUse 120s 등) 초과 시 IDE 프로세스 종료 주장 — 실측 필요.

---

## 8. 권고 — 3트랙

### 트랙 1 (주력) — 도구가 아니라 **패턴을 이식**

외부 의존·데몬·평문 시크릿 저장 **없이** claude-mem의 좋은 아이디어만 취한다:

1. **`MEMORY.md`를 진짜 2-layer progressive disclosure로 정리.** 현재 인덱스+지식이 혼재 → 인라인 지식 섹션을
   타입드 파일(`type: project|reference|feedback`)로 분리하고 MEMORY.md는 **얇은 인덱스**로. (claude-mem의 search→get 계층을 파일 구조로 모방)
2. **"절대 저장 금지" 규약 + 레드액션 규칙**을 `.claude/rules/common/`에 명문화. 유지하는 모든 메모리·요약·핸드오프에
   대해 복호화 값·키·토큰·시크릿을 기록 금지(시크릿 도메인 필수). claude-mem `<private>` 사상을 **정책**으로 내재화.
3. **경량 세션 요약 자동화 — 기존 훅 재사용.** 이미 있는 Stop/SessionEnd 훅(또는 PreCompact-save)에 구조적 요약
   (request / learned / next-steps)을 `docs/plans/`에 append. claude-mem "SessionEnd 요약" 이점을 **외부 도구·평문
   시크릿 저장 없이** 취함. (레드액션 규칙 준수)
4. **관찰 스키마 표준화.** `docs/solutions/`(현재 README만) 항목을 narrative + facts, 문제→원인→해법→재발방지로
   통일. compound-engineering `/ce-compound`와 정합.

> 트랙 1은 **각각 독립적**이라 원하는 것만 골라 후속 승인 가능. 코드/규칙/훅 변경이 수반되므로 본 문서와 별개 작업.

### 트랙 2 (선택) — 도구를 **정말** 시험하려면 key_box 밖에서

1. **시크릿 없는 throwaway 레포**에서 `npx claude-mem install`, **클라우드 하드-오프**.
2. 정상 작업 몇 세션 후 `~/.claude-mem/claude-mem.db`를 열어 **무엇이 저장됐는지 실측** (SQLite `.dump` / FTS 조회).
3. **레드액션 게이트를 뮤테이션으로 실증**: 일부러 가짜 시크릿/키를 도구 출력에 흘려보고, 그것이 관찰 저장에서
   **차단되는지** 확인. 차단 안 되면 → key_box엔 부적합 확정.
4. **key_box 승격은 "복호화 값/키 절대 미저장"이 뮤테이션 검증될 때만.** 타임박스(예: 반나절) 후 유지/폐기 결정.

### 트랙 3 — 재검토 트리거

- claude-mem이 **(a) 자동 시크릿 레드액션 + (b) 암호화 at-rest**를 공식 제공.
- 하네스 **네이티브 메모리가 불충분**함이 실제로 드러남(예: 세션 간 컨텍스트 손실이 반복 비용을 유발).
- 위 중 하나라도 성립하면 이 문서를 갱신해 재평가.

---

## 9. 검증 (이 평가의 재현/반증법)

- **사실 재확인**: 본 문서 주장은 아래 출처로 교차검증. star/issue 수치는 시점값(2026-07-17).
- **자기반증 포인트**: 축 A를 무력화하려면 트랙 2의 실측에서 "시크릿이 절대 저장 안 됨 + at-rest 암호화"가
  증명돼야 함. 그 전까지 축 A는 유효.
- **정합성**: 권고는 사용자 선택(평가+권고 / 로컬전용+강한완화) 및 CLAUDE.md 보안·메모리 방침(L20·L33·L101)과 정합.

---

## 10. 출처

- 레포: https://github.com/thedotmack/claude-mem (README, `package.json` v13.11.0, `CHANGELOG.md`, `docs/security.md`, 루트 `SECURITY.md`, `docs/architecture-overview.md`, open issues)
- GitHub API 메타데이터 (2026-07-17): stars 87,483 / forks 7,580 / open issues 280 / subscribers 278
- 제품/문서: https://cmem.ai · https://docs.claude-mem.ai (architecture/overview, installation, usage/private-tags)
- `/deep-research` 워크플로 산출(적대검증 3–0 확정 5건; 세션한도로 synthesis 및 일부 검증 중단)
- key_box 내부: CLAUDE.md(L20·L33·L101·컨텍스트/압축 절), `.claude/rules/common/context-management.md`,
  `.claude/settings.json`(훅), `docs/solutions/README.md`, `~/.claude/projects/.../memory/` 구조

---

*본 문서는 결정 지원용이다. 도구는 설치되지 않았고, key_box엔 어떤 변경도 가해지지 않았다.*
