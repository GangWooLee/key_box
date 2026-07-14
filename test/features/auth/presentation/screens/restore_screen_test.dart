import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/backup/vault_recovery_service.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/domain/backup_file_picker.dart';
import 'package:key_box/features/auth/presentation/screens/restore_screen.dart';

import '../../../../helpers/widget_test_helpers.dart';

/// Drives [AuthNotifier.restoreFromBackup] to a preset outcome so the screen's
/// step machine can be exercised without a real vault/DB.
class _RestoreFake extends FakeAuthNotifier {
  _RestoreFake(super.initial, this._outcome);
  final RestoreOutcome _outcome;

  @override
  Future<RestoreOutcome> restoreFromBackup({
    required String archive,
    required String password,
  }) async {
    if (_outcome is RestoreSuccess) {
      setAuthState(
        AuthUnlocked(masterEncryptionKey: Uint8List(32), vaultId: 1),
      );
    }
    return _outcome;
  }
}

void main() {
  BackupFilePicker fakePicker() =>
      () async => const PickedBackup(
        name: 'key_box.backup-123.kbx',
        contents: '<archive>',
      );

  Future<_RestoreFake> pumpRestore(
    WidgetTester tester, {
    required RestoreOutcome outcome,
  }) async {
    final fake = _RestoreFake(
      const AuthVaultError(reason: VaultErrorReason.configMissing),
      outcome,
    );
    await tester.pumpProviderWidget(
      const RestoreScreen(),
      overrides: [
        authProvider.overrideWith((ref) => fake),
        backupFilePickerProvider.overrideWithValue(fakePicker()),
      ],
    );
    return fake;
  }

  group('RestoreScreen', () {
    testWidgets('step 1 offers a file picker', (tester) async {
      await pumpRestore(tester, outcome: const RestoreCorrupt());

      expect(find.text('RESTORE FROM BACKUP'), findsOneWidget);
      expect(find.text('Choose file…'), findsOneWidget);
      expect(find.text('Restore'), findsNothing);
    });

    testWidgets('picking a file advances to the password step', (tester) async {
      await pumpRestore(tester, outcome: const RestoreCorrupt());

      await tester.tap(find.text('Choose file…'));
      await tester.pumpAndSettle();

      expect(find.text('key_box.backup-123.kbx'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('wrong password shows the 오답 reason and stays on password', (
      tester,
    ) async {
      await pumpRestore(tester, outcome: const RestoreWrongPassword());

      await tester.tap(find.text('Choose file…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'guess');
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(
        find.text("the password doesn't match this backup"),
        findsOneWidget,
      );
      // Still on the password step (the field + Restore remain).
      expect(find.text('Restore'), findsOneWidget);
    });

    testWidgets('a damaged backup shows the 손상 reason and returns to pick', (
      tester,
    ) async {
      await pumpRestore(tester, outcome: const RestoreCorrupt());

      await tester.tap(find.text('Choose file…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'anything');
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(find.text('this backup is damaged'), findsOneWidget);
      // Back on the pick step.
      expect(find.text('Choose file…'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a valid restore flips auth to unlocked', (tester) async {
      final fake = await pumpRestore(tester, outcome: const RestoreSuccess([]));

      await tester.tap(find.text('Choose file…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'correct-password');
      await tester.tap(find.text('Restore'));
      // Success stays on the checking step (infinite spinner) in-screen — the
      // router redirect away is what the real app does — so pump fixed frames
      // rather than settling.
      await tester.pump(); // setState → checking
      await tester.pump(); // restoreFromBackup resolves → state flips

      // The router carries an unlocked user away; here we assert the state
      // transition the redirect keys on.
      expect(fake.state, isA<AuthUnlocked>());
    });
  });
}
