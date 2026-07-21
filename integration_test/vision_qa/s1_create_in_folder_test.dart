// VISION-QA S1 — 폴더 내 시크릿 생성 (실앱 e2e).
//
// 시나리오: 신규 볼트 → 대시보드 → 'Production' 폴더 생성 → 선택 → 새 시크릿 저장.
// 검증: 시크릿이 선택 폴더 목록에 즉시 표시 / Production 카운트 +1 / General 불변.
// "현재 폴더" 판정은 사이드바 하이라이트(전용 브레드크럼 위젯 없음 — 파인더 맵 ⑥b).
//
// 공용 여정·캡처는 journey.dart / vision_capture.dart. pumpAndSettle 금지.
//
// Run ONLY on a real macOS device:
//   flutter test integration_test/vision_qa/s1_create_in_folder_test.dart -d macos
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:path_provider/path_provider.dart';

import 'journey.dart';
import 'vision_capture.dart';

const _folderName = 'Production';
const _secretName = 'S1 GitHub Token';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpVault;
  late Future<Directory> Function() previousSupportDir;

  setUp(() async {
    // 볼트 위생: 실볼트 절대 접근 금지 — 캡처물에 실시크릿이 찍힐 수 없게.
    final base = await getApplicationSupportDirectory();
    tmpVault = Directory(
      '${base.path}/vision_qa_s1_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    previousSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tmpVault;
  });

  tearDown(() {
    VaultPaths.supportDir = previousSupportDir;
    if (tmpVault.existsSync()) tmpVault.deleteSync(recursive: true);
  });

  testWidgets('S1: 선택 폴더에 시크릿 생성 — 목록·카운트 즉시 반영', (tester) async {
    await driveToFreshDashboard(tester);
    await captureVision(tester, 's1', '01_dashboard_initial');

    await createFolder(tester, _folderName);
    await captureVision(tester, 's1', '02_folder_created');

    await selectFolder(tester, _folderName);
    await captureVision(tester, 's1', '03_folder_selected');

    await addSecret(tester, _secretName, 's1-dummy-value-not-a-real-secret');
    await captureVision(tester, 's1', '04_after_save');

    // 코드 레벨 assert (벨트) — 비전 판정이 서스펜더
    expect(find.text(_secretName), findsWidgets);
    expectFolderCount(
      tester,
      _folderName,
      1,
      reason: '사이드바 Production 카운트가 1이 아님 — 집계 버그',
    );
    expectFolderCount(
      tester,
      'General',
      0,
      reason: '사이드바 General 카운트가 0이 아님 — 잘못된 폴더 배정/집계 버그',
    );
  });
}
