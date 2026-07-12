import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';

/// Creates a fresh in-memory test database.
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

/// Creates a ProviderContainer with the given database override.
ProviderContainer createTestContainer({AppDatabase? db}) {
  final testDb = db ?? createTestDatabase();
  return ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(testDb)],
  );
}

/// Helper to set up a fully unlocked vault in the test database.
/// Returns the vault ID and master encryption key.
Future<({int vaultId, Uint8List masterKey})> setupTestVault(
  AppDatabase db,
) async {
  final notifier = AuthNotifier(db);
  await notifier.setup(
    password: 'testpassword123',
    confirmation: 'testpassword123',
  );
  final state = notifier.state as AuthUnlocked;
  return (vaultId: state.vaultId, masterKey: state.masterEncryptionKey);
}

/// Extension on WidgetTester to pump a widget wrapped with providers.
extension PumpApp on WidgetTester {
  /// Pump a widget wrapped in ProviderScope + MaterialApp.
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: Scaffold(body: widget),
        ),
      ),
    );
  }
}
