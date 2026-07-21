// VISION-QA S3 — 잠금 → 해제 → 상태 복원 (실앱 e2e).
//
// 목적: fed5da6(폴더 provider lock/unlock 반응성 — auth 가드)가 실앱에서 완결됐는지
// 검증. 코드가 정의하는 복원 계약:
//   ① 잠금 중 폴더/시크릿 스트림 = 빈 스트림(크래시 없음)
//   ② 해제 후 새 keyed 연결로 재바인딩 → 트리·목록·카운트 재로드
//   ③ selectedFolderIdProvider는 보존(autoDispose 아님) → 해제 후 선택 폴더 유지
//
// 잠금 트리거: 대시보드에 잠금 버튼 위젯 없음 — Cmd+L 키 시뮬레이션을 먼저 시도하고
// (KeyboardListener 포커스 의존이라 취약), 실패 시 authProvider.lock() 직접 호출로
// 폴백. 어느 경로가 통했는지 [VISION_QA] 라인으로 출력해 리포트에 기록.
//
// Run ONLY on a real macOS device:
//   flutter test integration_test/vision_qa/s3_lock_unlock_restore_test.dart -d macos
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/secrets/presentation/screens/dashboard_screen.dart';
import 'package:path_provider/path_provider.dart';

import 'journey.dart';
import 'vision_capture.dart';

const _folderName = 'Production';
const _secretName = 'S3 Persist Token';
const _sweepCoverKey = ValueKey('unlock-sweep-cover');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpVault;
  late Future<Directory> Function() previousSupportDir;

  setUp(() async {
    final base = await getApplicationSupportDirectory();
    tmpVault = Directory(
      '${base.path}/vision_qa_s3_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    previousSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tmpVault;
  });

  tearDown(() {
    VaultPaths.supportDir = previousSupportDir;
    if (tmpVault.existsSync()) tmpVault.deleteSync(recursive: true);
  });

  testWidgets('S3: lock→unlock 후 선택 폴더·목록·카운트 복원', (tester) async {
    // ── 사전 상태: S1 검증 상태 재현 (Production 선택 + 시크릿 1)
    await driveToFreshDashboard(tester);
    await createFolder(tester, _folderName);
    await selectFolder(tester, _folderName);
    await addSecret(tester, _secretName, 's3-dummy-value-not-a-real-secret');
    expectFolderCount(tester, _folderName, 1);
    await captureVision(tester, 's3', '01_before_lock');

    // ── 잠금: Cmd+L 시도 → 실패 시 provider 직접 호출 폴백
    final unlockScreen = find.widgetWithText(ElevatedButton, 'Unlock');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await pumpBounded(tester, frames: 4);

    var lockPath = 'cmd+L';
    if (unlockScreen.evaluate().isEmpty) {
      lockPath = 'provider-fallback';
      final ctx = tester.element(find.byType(DashboardScreen));
      ProviderScope.containerOf(ctx).read(authProvider.notifier).lock();
      await pumpBounded(tester, frames: 4);
    }
    // ignore: avoid_print
    print('[VISION_QA] lock path used: $lockPath');
    await pumpUntil(tester, unlockScreen);
    expect(find.text('KEY_BOX'), findsWidgets, reason: '잠금 화면 미도착');
    await captureVision(tester, 's3', '02_locked');

    // ── 해제: 패스워드 입력 → Unlock (로딩 스피너 → pumpAndSettle 금지)
    await tester.enterText(find.byType(TextField), kMasterPw);
    await tester.tap(unlockScreen);
    await pumpUntil(tester, find.text('FOLDERS'));

    // UnlockSweep(320ms 유한) 오버레이·테마 전환이 끝난 뒤 캡처
    await pumpBounded(tester, frames: 8);
    expect(
      find.byKey(_sweepCoverKey),
      findsNothing,
      reason: 'UnlockSweep 오버레이가 아직 화면을 덮고 있음',
    );
    await captureVision(tester, 's3', '03_after_unlock');

    // ── 복원 계약 검증 (fed5da6)
    // ② 트리·카운트 재로드: General·Production 표시 + Production 카운트=1
    expect(
      folderInTree('General'),
      findsOneWidget,
      reason: '해제 후 폴더 트리에 General 없음 — 스트림 재바인딩 실패',
    );
    expect(
      folderInTree(_folderName),
      findsOneWidget,
      reason: '해제 후 폴더 트리에 Production 없음 — 스트림 재바인딩 실패',
    );
    expectFolderCount(
      tester,
      _folderName,
      1,
      reason: '해제 후 Production 카운트 소실 — 카운트 provider 재로드 실패(fed5da6 회귀)',
    );
    // ③ 선택 폴더 보존: Production이 선택 상태 → 그 목록에 시크릿이 다시 보임
    expect(
      find.text(_secretName),
      findsWidgets,
      reason: '해제 후 선택 폴더 목록이 비어 있음 — 선택 보존/목록 재바인딩 실패',
    );
  });
}
