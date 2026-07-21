---
name: vision-qa
description: "key_box 바인딩 — 실앱 비전 QA. 방법론 정본은 전역 스킬(~/.claude/skills/vision-qa/), 이 파일은 Flutter/macOS 특정성(명령·헬퍼·함정·시나리오 팩)만 담는다."
---

# /vision-qa — key_box 프로젝트 바인딩

**방법론 정본은 전역 스킬이다**: `~/.claude/skills/vision-qa/SKILL.md`를 READ하고
그 절차(빌드 신선도 → 시나리오 주행 → 비전 판정 → 리포트)를 아래 바인딩으로 실행하라.
절차·판정 규율을 이 파일에 복제하지 않는다(드리프트 방지).

## 실행 명령

- 시나리오 실행(실 macOS 앱, 자체 빌드 포함):
  `flutter test integration_test/vision_qa/<시나리오>_test.dart -d macos`
- `.app` 직접 구동 보조검증 시: 바이너리 mtime > HEAD 커밋시각 확인(`scripts/dogfood.sh` 로직)

## 캡처 (macOS 특정)

- ⚠️ `binding.takeScreenshot()`은 **macOS 미지원**(SDK에 네이티브 핸들러 없음 — ios/·android/만).
  반드시 공용 헬퍼 사용: `integration_test/vision_qa/vision_capture.dart`
  - `visionCaptureRoot(child:)`로 앱을 감싸고 `captureVision(tester, scenario, name)` 호출
  - `pumpUntil()`/`pumpBounded()` 사용 — `pumpAndSettle()` 금지(무한 애니메이션·로딩 스피너 행)
- ⚠️ 앱은 샌드박스 — PNG는 앱 컨테이너에 저장되고
  `[VISION_QA] screenshot: <절대경로>` 마커가 출력된다. **테스트 출력에서 마커를 grep**해
  경로를 얻어 Read(비전)로 연다.
- 파이프라인 스모크: `integration_test/vision_qa/capture_spike_test.dart`

## 데이터 위생 (시크릿 매니저 — 필수)

모든 시나리오는 `VaultPaths.supportDir`를 임시 디렉토리로 리다이렉트(스파이크 참조).
실볼트 접근 금지 — 캡처물에 실시크릿이 찍힐 수 없게. 더미 값에는
`not-a-real-secret` 류의 명시 마커를 쓴다.

## key_box 특유 함정

1. **cipher는 flutter test를 안 탄다** — 호스트 VM은 Apple libsqlite3가 `PRAGMA key`를
   조용히 무시. 실앱 검증은 integration_test `-d macos`만 유효.
2. **스테일 빌드** — flutter test integration_test는 자체 빌드하므로 안전. `.app` 직접
   구동 경로만 mtime 게이트 필요.
3. **골든 배치런 플래키 + 리포터 이름 착시** — 실패 판정은 실제 실패 파일명으로.
4. `flutter test` 동시 실행 금지(SQLite BusyException) — 시나리오는 한 번에 하나.
5. 파인더: 문자열 Key 부재 — 텍스트/툴팁/타입/ValueKey(id) 파인더 사용. 짧은 카운트
   텍스트('0','1')는 반드시 `find.descendant`로 노드 범위 제한.
6. **잠금 트리거**: 대시보드에 잠금 버튼 위젯 없음 — `sendKeyDownEvent`로 Cmd+L
   시뮬레이션이 실앱 테스트에서 실동작 확인됨(S3). 실패 대비 `authProvider.notifier.lock()`
   직접 호출 폴백 패턴을 유지할 것. PlatformMenu는 파인더 불가.
7. **해제 후 테마 플립**: first-run hero(Bench 강제)가 첫 잠금에서 clear → 이후 사용자
   기본 모드(Terminal 다크)로 렌더. 잠금 전후 캡처의 색이 달라도 결함 아님(설계 동작).
   UnlockSweep(320ms) 오버레이 `ValueKey('unlock-sweep-cover')` 부재 확인 후 캡처.
8. unlock 화면에 kDebugMode 한정 'dev: reset vault' 버튼 존재 — 오탭 금지. 5회 실패 시 30초 lockout.

## 시나리오 팩

공용 여정 헬퍼: `integration_test/vision_qa/journey.dart`
(`driveToFreshDashboard`·`createFolder`·`selectFolder`·`addSecret`·`expectFolderCount`) — 새 시나리오는 이걸 재사용.

- **S1 폴더 내 시크릿 생성** (`s1_create_in_folder_test.dart`, 구현·뮤테이션 실증 완료):
  폴더 X 선택 → 새 시크릿 → 시크릿이 X 목록에 즉시 표시 / 사이드바 X 카운트 +1,
  General 불변. ※ 브레드크럼 위젯은 존재하지 않음 — "현재 폴더"는 사이드바 하이라이트로 판정.
- **S1-variant** (`s1_variant_no_folder_test.dart`, 구현·뮤테이션 실증 완료): 폴더 미선택
  (All Keys) 저장 → General 폴백 일관성·집계 정합. 판별 결과: 설계 동작 + 무음 파일링
  UX 갭(리포트 참조).
- **S3 잠금/해제 복원** (`s3_lock_unlock_restore_test.dart`, 구현·뮤테이션 실증 완료):
  lock → unlock → fed5da6 계약(트리·카운트 재로드 + 선택 폴더 보존) 검증.
- **S2 폴더 이동** (후속): home 이동 → 양쪽 카운트·목록 동기 갱신

## 리포트

`docs/qa/vision-qa-YYYYMMDD.md` (최초 리포트: `vision-qa-20260720.md` 참조 — 형식 템플릿).
