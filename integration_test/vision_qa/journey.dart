// VISION-QA 공용 여정 헬퍼 — 시나리오들이 재사용하는 사용자 여정 조각.
// 파인더는 전부 소스 실증 기반(파인더 맵). pumpAndSettle 금지 원칙 준수.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/app.dart';
import 'package:key_box/features/secrets/presentation/widgets/folder_tree.dart';

import 'vision_capture.dart';

/// ≥12자 (CryptoConstants.minPasswordLength)
const kMasterPw = 'vision-qa-master-pw1';

/// 신규 볼트: setup(마스터 패스워드) → 온보딩 통과 → 대시보드 도착.
/// 호출 전 VaultPaths가 임시 디렉토리로 리다이렉트되어 있어야 한다(볼트 위생).
Future<void> driveToFreshDashboard(WidgetTester tester) async {
  await tester.pumpWidget(
    visionCaptureRoot(child: const ProviderScope(child: KeyBoxApp())),
  );
  await pumpBounded(tester);

  // Setup: 필드 2개(password→confirm), 로딩 스피너 → pumpAndSettle 금지
  final pwFields = find.byType(TextFormField);
  expect(pwFields, findsNWidgets(2), reason: 'setup 화면이 아님');
  await tester.enterText(pwFields.at(0), kMasterPw);
  await tester.enterText(pwFields.at(1), kMasterPw);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Create Vault'));
  // PBKDF2 600k ≈ 수 초
  await pumpUntil(tester, find.widgetWithText(ElevatedButton, 'Continue'));

  // Onboarding: Continue → Skip → Go to Dashboard
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await pumpUntil(tester, find.widgetWithText(TextButton, 'Skip'));
  await tester.tap(find.widgetWithText(TextButton, 'Skip'));
  await pumpUntil(
    tester,
    find.widgetWithText(ElevatedButton, 'Go to Dashboard'),
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Go to Dashboard'));

  // 대시보드 도착 = FOLDERS 헤더 + 시딩된 General
  await pumpUntil(tester, find.text('FOLDERS'));
  await pumpUntil(tester, find.text('General'));
}

/// 사이드바 + 버튼(툴팁)으로 새 폴더 생성. 생성 후 트리에 등장할 때까지 대기.
Future<void> createFolder(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('New folder'));
  await pumpUntil(tester, find.widgetWithText(TextField, 'Folder name'));
  await tester.enterText(find.widgetWithText(TextField, 'Folder name'), name);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
  await pumpUntil(tester, folderInTree(name));
}

/// 폴더 트리 범위로 좁힌 폴더명 파인더.
Finder folderInTree(String name) =>
    find.descendant(of: find.byType(FolderTree), matching: find.text(name));

/// 사이드바에서 폴더를 탭해 선택(selectedFolderIdProvider 세팅).
Future<void> selectFolder(WidgetTester tester, String name) async {
  await tester.tap(folderInTree(name));
  await pumpBounded(tester, frames: 3);
}

/// Add Secret 모달로 시크릿 생성(제목·값). 저장 후 테이블에 행 등장까지 대기.
Future<void> addSecret(WidgetTester tester, String name, String value) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Add Secret'));
  await pumpUntil(
    tester,
    find.widgetWithText(TextField, 'e.g. GitHub API Key'),
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'e.g. GitHub API Key'),
    name,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Paste your secret here...'),
    value,
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
  // 저장 = 암호화+DB 트랜잭션, Save가 스피너로 변함 → pumpAndSettle 금지
  await pumpUntil(tester, find.text(name));
  await pumpBounded(tester, frames: 5); // 카운트 provider 갱신 여유
}

/// 사이드바 폴더 노드 내부 카운트가 기대값인지 assert.
/// 짧은 카운트 텍스트('0','1')는 전역 충돌 위험 → 노드 범위로 제한.
void expectFolderCount(
  WidgetTester tester,
  String folderName,
  int count, {
  String? reason,
}) {
  final node = find
      .ancestor(of: folderInTree(folderName), matching: find.byType(InkWell))
      .first;
  expect(
    find.descendant(of: node, matching: find.text('$count')),
    findsOneWidget,
    reason: reason ?? '사이드바 $folderName 카운트가 $count가 아님',
  );
}
