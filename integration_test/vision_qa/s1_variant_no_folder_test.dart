// VISION-QA S1-variant — 폴더 미선택 상태에서 시크릿 저장 (실앱 e2e).
//
// 목적: "새 시크릿이 현재 폴더에 안 생기고 General로 들어간다"는 사용자 보고가
// 설계 동작(폴더 미선택 시 `folders.first`=General 폴백 — sheet_modal.dart `_save`)인지
// 실제 결함인지 판별한다. 이 시나리오의 PASS = "General 폴백이 일관 동작 + 집계 정합"
// (= 설계 동작 확인). 근본 원인이 저장 모달의 대상 폴더 표시/선택 UI 부재라면
// 리포트에 개선 제안으로 기록한다(수정은 별도 승인).
//
// Run ONLY on a real macOS device:
//   flutter test integration_test/vision_qa/s1_variant_no_folder_test.dart -d macos
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:path_provider/path_provider.dart';

import 'journey.dart';
import 'vision_capture.dart';

const _folderName = 'Production'; // 대조군 — 생성만 하고 선택하지 않음
const _secretName = 'S1V Orphan Token';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpVault;
  late Future<Directory> Function() previousSupportDir;

  setUp(() async {
    final base = await getApplicationSupportDirectory();
    tmpVault = Directory(
      '${base.path}/vision_qa_s1v_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    previousSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tmpVault;
  });

  tearDown(() {
    VaultPaths.supportDir = previousSupportDir;
    if (tmpVault.existsSync()) tmpVault.deleteSync(recursive: true);
  });

  testWidgets('S1V: 폴더 미선택 저장 → General 폴백 일관성·집계 정합', (tester) async {
    await driveToFreshDashboard(tester);

    // 대조군 폴더 생성 — 선택하지 않음(All Keys 뷰 유지)
    await createFolder(tester, _folderName);
    await captureVision(tester, 's1_variant', '01_all_keys_view');

    // 폴더 미선택 상태에서 저장
    await addSecret(tester, _secretName, 's1v-dummy-value-not-a-real-secret');
    await captureVision(tester, 's1_variant', '02_after_save_no_folder');

    // 폴백 실증: General로 배정(+1), 대조군 Production은 0 유지
    expect(
      find.text(_secretName),
      findsWidgets,
      reason: 'All Keys 뷰에 방금 저장한 시크릿이 안 보임',
    );
    expectFolderCount(
      tester,
      'General',
      1,
      reason: 'General 폴백이 동작하지 않음 — folderId 결정 로직 회귀',
    );
    expectFolderCount(
      tester,
      _folderName,
      0,
      reason: '미선택인 Production에 시크릿이 들어감 — 폴백 로직 결함',
    );

    // General을 열어 실제로 그 안에 있는지 확인
    await selectFolder(tester, 'General');
    expect(
      find.text(_secretName),
      findsWidgets,
      reason: 'General 목록에 시크릿이 없음 — 집계와 실목록 불일치',
    );
    await captureVision(tester, 's1_variant', '03_general_contains');
  });
}
