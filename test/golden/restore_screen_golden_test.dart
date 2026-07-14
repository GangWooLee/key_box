@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/domain/backup_file_picker.dart';
import 'package:key_box/features/auth/presentation/screens/restore_screen.dart';

import '../helpers/widget_test_helpers.dart';
import 'golden_helpers.dart';

/// The restore-from-backup screen on the sealed Slab (DESIGN.md §restore).
void main() {
  final overrides = [
    authProvider.overrideWith(
      (ref) => FakeAuthNotifier(
        const AuthVaultError(reason: VaultErrorReason.configMissing),
      ),
    ),
    backupFilePickerProvider.overrideWithValue(
      () async => const PickedBackup(
        name: 'key_box.backup-1720000000.kbx',
        contents: '{}',
      ),
    ),
  ];

  testWidgets('restore_screen — step 1 (pick a file)', (tester) async {
    await pumpGolden(
      tester,
      child: const RestoreScreen(),
      size: GoldenSizes.authCard,
      surface: GoldenSurface.sealed,
      overrides: overrides,
    );
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/restore_screen_pick.png'),
    );
  });

  testWidgets('restore_screen — step 2 (master password)', (tester) async {
    await pumpGolden(
      tester,
      child: const RestoreScreen(),
      size: GoldenSizes.authCard,
      surface: GoldenSurface.sealed,
      overrides: overrides,
    );
    await tester.tap(find.text('Choose file…'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/restore_screen_password.png'),
    );
  });
}
