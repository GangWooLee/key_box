---
title: Batch-run "(tearDownAll)" flake was a golden-test row-order flip, not a teardown bug
date: 2026-07-20
category: test-failures
module: test/golden + test/helpers
problem_type: test_failure
component: testing_framework
symptoms:
  - "Full flutter test batch intermittently ends with '+508 -1: .../secret_detail_test.dart: (tearDownAll)' — looks like a teardown failure in that file"
  - "secret_detail_test.dart alone is always 12/12 green, even under CPU load"
  - "Actual [E] in the log: Golden hero-dark.png 'Pixel test failed, 5.61%, 72714px diff'"
root_cause: async_timing
resolution_type: test_fix
severity: medium
tags: [flaky-test, golden-test, compact-reporter, drift-ordering, pbkdf2, teardownall]
---

# Batch-run "(tearDownAll)" flake was a golden-test row-order flip, not a teardown bug

## Problem

`flutter test` 전체 배치가 간헐적으로 `+508 -1: ...secret_detail_test.dart: (tearDownAll)`로 끝나 secret_detail의 teardown 결함처럼 보였지만, 그 파일은 무결했다. 실제 실패는 `test/golden/readme_assets_test.dart`의 hero 골든이었다.

## Symptoms

- 배치런 마지막 줄: `secret_detail_test.dart: (tearDownAll)` + "Some tests failed"
- 해당 파일 단독 실행은 항상 green (부하를 걸어도 10/10 green)
- 로그 전체를 뒤지면 진짜 `[E]`는 골든: `Pixel test failed, 5.61%, 72714px diff`

## What Didn't Work

- **secret_detail_test 안에서 범인 찾기**: tearDown TOCTOU, drift 스트림 타이머, `RevealByDefaultNotifier._load()` dispose 레이스 등 실존(real-zone) 비동기 탈출 후보를 전수 감사했으나 전부 무혐의. 접힌 섹션은 빌드되지 않아 drift 스트림 자체가 안 물린다.
- **솔로 + CPU 부하 재현**: 10회 전부 green — 이 스위트 단독으로는 재현 불가. 전체 배치의 동시성이 조건이었다.

## Solution

두 겹의 원인, 두 개의 수정:

**1. 리포터 착시 해부** — `(tearDownAll)` 엔티티는 package:test가 `setUpAll`이 있는 스위트에만 합성한다(당시 setUpAll을 가진 유일한 위젯 스위트 = secret_detail_test). 그 스위트가 프로덕션 원가 PBKDF2(600k회, ~2.8s/derive)를 매 setUp마다 지불해 배치 최후미에 끝났고, compact 리포터의 마지막 줄은 "마지막에 실행 중이던 엔티티" 이름이라 다른 스위트의 실패까지 이 파일이 뒤집어썼다.

**2. 골든 플립 수정** — 골든은 실 DB 정렬(`orderBy(updatedAt DESC)`, 타이브레이커 없음, drift 초 정밀 저장)을 탄다. 무부하에선 시드 6건이 같은 1초에 들어가 전부 동률(rowid 순 = 커밋된 골든 순서)이지만, 부하 시 시딩이 초 경계를 걸치면 뒤 3건이 "더 새로움"이 되어 행 순서가 플립된다. `pinSeedTimestamps()`로 시딩 직후 타임스탬프를 결정적 사다리(id 순, 1초 간격, 삽입 순=최신 순)로 고정:

```dart
Future<void> pinSeedTimestamps() async {
  final rows = await db.secretDao.getByVaultId(vaultId);
  final base = DateTime.now();
  for (final row in rows) {
    final t = base.subtract(Duration(seconds: row.id));
    await (db.update(db.secrets)..where((s) => s.id.equals(row.id))).write(
      SecretsCompanion(createdAt: Value(t), updatedAt: Value(t)),
    );
  }
}
```

오프셋이 60초 "just now" 임계 아래라 렌더 텍스트 불변 → 커밋된 골든 PNG 그대로 유효.

**3. 부하 자체 절감** — `createSeededVault`에 `KeyDerivationService(iterations: 2)` 주입(소비자 전원이 반환된 masterKey만 쓰고 재파생하지 않음을 확인 후). secret_detail 스위트 31s → 1s.

**뮤테이션 실증**: `updatedAt +2s` 주입으로 배치 실패와 픽셀 단위 동일(5.61%/72714px)한 RED를 결정적으로 재현 → pin 적용 후 주입 상태에서도 GREEN → 주입 제거. 수정 후 부하 배치 4회 연속 전건 green.

## Why This Works

정렬 키(updatedAt, 초 정밀)가 비결정적이었던 것이 근본 원인이다. 타임스탬프를 명시 고정하면 벽시계와 CPU 부하가 정렬에 개입할 통로가 사라진다. AAD는 (secretId, recordVersion)에만 바인딩되므로 타임스탬프 갱신은 복호화에 영향이 없다.

## Prevention

- **배치 실패의 마지막 줄 이름을 믿지 마라.** compact 리포터의 최종 줄은 "마지막 엔티티"지 "실패 테스트"가 아니다. 판정은 반드시 로그 전체에서 `[E]` 마커/예외 본문으로.
- **골든이 실 DB 정렬을 타면 시드 타임스탬프를 고정하라.** 초 정밀 + DESC 정렬 + 벽시계 시딩 = 초 경계 러시안룰렛.
- **테스트 헬퍼에서 프로덕션 KDF 원가를 지불하지 마라.** 파생 키를 재검증하지 않는 시딩 경로는 반복수를 주입해 절감한다.
- 재현 루프를 짤 때: zsh burner는 `$!`로 수집 + `trap ... EXIT INT TERM`, waiter의 `pgrep -f <이름>`은 자기 명령줄과 자기매치되어 영구 대기할 수 있다.

## Related Issues

- 세션 메모리: `teardownall-flake-golden-order.md`, `pbkdf2-test-cost-flake.md`, `macos-release-golden-gotchas.md`(리포터 이름 착시 선례), `stale-build-dogfood-gap.md`(drift 타이머 드레인 패턴)
