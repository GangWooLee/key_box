---
title: First-run hero flag masks explicit theme selection until next lock
date: 2026-07-19
category: ui-bugs
module: core/theme
problem_type: ui_bug
component: frontend
symptoms:
  - "Settings > Appearance shows Dark checked, but the app renders the light Bench for the whole post-setup session"
  - "In-app theme toggle changes its icon, and re-selecting Light→Dark changes nothing — render never flips"
  - "App restart restores normal theme behavior (the bug lives only in the first unlocked session)"
root_cause: logic_error
resolution_type: code_fix
severity: medium
tags: [riverpod, theme-provider, first-run-hero, state-masking, override-flag, flutter]
---

# First-run hero flag masks explicit theme selection until next lock

## Problem

실앱 비전 QA에서 발견: 신규 볼트 셋업 직후 세션에서 테마 선택(Settings 라디오·툴바 토글·메뉴바)이 체크 상태만 바꾸고 실제 렌더는 벤치(라이트)에 고정. `flutter test` 전건 green 상태에서 실앱만 재현되는 유형.

## Symptoms

- Settings의 "Dark — the Terminal"이 체크돼 있는데 렌더는 Bench(light) 유지, 재선택해도 불변.
- 우상단 토글은 아이콘만 바뀌고 표면 불변 (`themeModeProvider`는 갱신되는데 렌더가 안 따라감).
- 재시작 후엔 정상 — 세션 한정 증상.

## Root Cause (원인)

`surfaceThemeProvider`가 `firstRunHeroProvider`(셋업 후 첫 스윕을 벤치로 강제하는 히어로 플래그)를 먼저 보고 **조기 반환** — 플래그가 true인 동안 `themeModeProvider`는 아예 watch되지 않는다. 플래그는 `AuthFirstRun→AuthUnlocked` 전이에서 arm되고 **다음 잠금에서만** disarm되므로, 셋업 직후 세션 전체에서 명시적 테마 선택이 침묵 무시됐다.

```dart
// lib/core/theme/theme_provider.dart — 버그 당시
if (ref.watch(firstRunHeroProvider)) {
  return AppTheme.bench();          // themeModeProvider가 가려짐
}
final mode = ref.watch(themeModeProvider); // 히어로 동안 도달 불가
```

UI 위젯들은 `themeModeProvider`를 직접 watch하므로 체크마크·아이콘은 갱신 — "상태는 바뀌는데 렌더만 안 바뀌는" 착시가 생겼다.

## What Didn't Work (기각한 설계)

- **`ref.listen(themeModeProvider, …)`으로 상태 변화 시 히어로 해제**: 기각. `ThemeModeNotifier._load()`(비동기 prefs 복원)도 `state`를 변경하므로 프로그램적 변화와 사용자 의사를 구분 못 함 — 복원 플로우에서 히어로가 첫 렌더 전에 죽는 오동작 가능.

## Solution (해법)

명시적 선택 경로(`setThemeMode()`, `toggle()`이 위임)에만 히어로 해제 시임을 심음 — 생성자 콜백으로 주입해 `_load()`는 건드리지 않는다.

```dart
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(
    onExplicitChange: () =>
        ref.read(firstRunHeroProvider.notifier).state = false,
  );
});

Future<void> setThemeMode(ThemeMode mode) async {
  _onExplicitChange?.call();   // 히어로는 기본값을 이기지만 명시적 의사는 못 이긴다
  state = mode;
  ...
}
```

같은 값 재선택(이미 dark인데 Dark 클릭)도 동작하는 이유: `themeModeProvider`는 무변화라 통지가 없지만 히어로 플래그 flip이 `surfaceThemeProvider`를 재계산시켜 mode 분기에 도달한다. DESIGN.md §Motion 히어로 규칙에 예외 조항 동시 반영(디자인 정본 먼저, 코드가 따라감).

## Why This Works

히어로는 "첫 노출의 기본값" 규칙이지 사용자 선택 차단 장치가 아니다. 해제 조건을 명시적 사용자 행위에만 결선하면 첫인상 연출(벤치 강제)과 사용자 주권이 동시에 성립한다.

## Prevention (재발방지)

- **오버라이드/히어로 플래그는 도입 시점에 "무엇에게 지는가"를 정의하라.** 기본값을 이기는 플래그가 명시적 사용자 의사까지 이기고 있으면 설계 결함이다.
- **프로그램적 상태 변화와 사용자 발화 변화는 다른 seam으로 분리하라** (상태 listener가 아니라 명시 메서드에 훅). 그래야 각각 독립 테스트가 가능하다.
- 회귀 테스트 3종이 이 계약을 고정한다 (`test/core/theme/theme_provider_test.dart`):
  1. 히어로 세션 중 `setThemeMode(dark)` → 즉시 terminal 렌더 (같은 값 재선택 케이스 포함)
  2. `toggle()` → 히어로 해제 + 선택 모드 추종
  3. **prefs `_load()`는 히어로를 해제하지 않는다** (프로그램적 ≠ 명시적)
- 단위테스트 전건 green이어도 "상태 provider 갱신 ≠ 렌더 provider 반영"은 실앱 QA에서만 드러날 수 있다 — 마스킹 분기가 있는 provider는 마스킹 활성 중의 하위 입력 변화를 테스트하라.

## Related Issues

- DESIGN.md §Motion 첫 실행 히어로 규칙 (2026-07-19 예외 조항 추가)
- 세션 메모리 `stale-build-dogfood-gap` — 실앱 검증 전 `scripts/dogfood.sh` 재빌드 필수
