---
name: test-sync
description: "key_box 바인딩 — 변경-테스트 정합 감사. 방법론 정본은 전역 스킬(~/.claude/skills/test-sync/), 이 파일은 Flutter/Drift/cipher 특정성만 담는다."
---

# /test-sync — key_box 프로젝트 바인딩

**방법론 정본은 전역 스킬이다**: `~/.claude/skills/test-sync/SKILL.md`를 READ하고
그 절차(변경 추출 → 행동 목록화 → 실매핑 → RED-first 봉합 → 승인 요청)를 아래 바인딩으로
실행하라. 절차를 이 파일에 복제하지 않는다.

## 디렉토리·명령

- 소스: `lib/` · 테스트: `test/`, `integration_test/`
- 변경 추출: `git diff --stat origin/main...HEAD -- lib/` (upstream 있으면 `@{upstream}...HEAD`)
- 러너: `flutter test` (단위/위젯) · `flutter test integration_test/... -d macos` (실앱)
- **동시 실행 금지**(SQLite BusyException — 한 번에 하나)
- Drift 스키마 변경 동반 시: `dart run build_runner build --delete-conflicting-outputs` 선행

## 테스트 계층 배치 규칙 (공허 통과 함정)

- **cipher 의존 행동**(암호화·keyed-open·무결성·레코드치환): `flutter test`는 Apple
  libsqlite3가 `PRAGMA key`를 조용히 무시해 **공허 통과** — 반드시 `integration_test`
  (`-d macos`)에 배치.
- **실앱 UI 반응 행동**(라우팅·provider 반응성·창 관리): 위젯 테스트가 못 보는 경우
  `/vision-qa` 시나리오로 배치.
- 순수 로직(HKDF·export/import·AAD 바인딩)은 `flutter test` 유지.

## 기계 게이트

- `.lefthook/test-delta-guard` (pre-push): lib/ 변경 + 테스트 변경 0건 → push 차단.
  우회 = `TESTLESS_PUSH=1 TESTLESS_REASON='사유' git push` → `log/testless-pushes.log` 감사 기록.
- 게이트가 RED를 낸 push 앞에서는 이 스킬로 매핑표를 만들어 봉합하는 것이 정도다.
