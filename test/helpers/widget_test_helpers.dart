import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/core/utils/result.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/services/clipboard_service.dart';

/// Suppress Drift "multiple databases" warning in tests.
void suppressDriftWarning() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
}

// ─── FakeAuthNotifier ───
// Shared fake that returns a fixed AuthState without touching the real DB.
// Extracted from secret_operations_test.dart for reuse across all widget tests.

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._fixedState) : super(_createDummyDb());

  AuthState _fixedState;

  static AppDatabase _createDummyDb() =>
      AppDatabase.forTesting(NativeDatabase.memory());

  @override
  AuthState get state => _fixedState;

  /// Test-only: drive an auth-state transition (e.g. Locked → Unlocked) so
  /// provider listeners (unlock sweep, surface theme) fire like production.
  /// The frozen-getter behavior for real AuthNotifier methods is unchanged —
  /// only this setter moves the reported state.
  void setAuthState(AuthState next) {
    _fixedState = next;
    state = next; // notifies StateNotifier listeners → ref.listen fires
  }
}

// ─── MockSecretOperations ───

class MockSecretOperations extends Mock implements SecretOperations {}

// ─── MockClipboardService ───

class MockClipboardService extends Mock implements ClipboardService {}

// ─── Fallback values for mocktail ───

class FakeSecret extends Fake implements Secret {}

void registerFallbackValues() {
  registerFallbackValue(FakeSecret());
}

// ─── TestVaultData ───
// Helper to create a seeded vault with secrets for widget testing.

class TestVaultData {
  TestVaultData({
    required this.db,
    required this.vaultId,
    required this.masterKey,
    required this.folderId,
    required this.secrets,
  });

  final AppDatabase db;
  final int vaultId;
  final Uint8List masterKey;
  final int folderId;
  final List<Secret> secrets;
}

/// Creates a real in-memory DB with a vault, folder, and optionally seeded secrets.
///
/// KDF cost is cut to 2 iterations: no consumer ever re-derives from the
/// password (they use the returned [TestVaultData.masterKey] directly), and
/// the production 600k-iteration PBKDF2 costs ~3s of blocked event loop PER
/// setUp — the main reason widget suites finished last in batch runs and got
/// blamed by the compact reporter for other suites' failures (2026-07-20).
Future<TestVaultData> createSeededVault({int secretCount = 3}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final notifier = AuthNotifier(
    db,
    keyDerivationService: KeyDerivationService(iterations: 2),
  );
  await notifier.setup(
    password: 'testpassword123',
    confirmation: 'testpassword123',
  );
  final authState = notifier.state as AuthUnlocked;
  final vaultId = authState.vaultId;
  final masterKey = authState.masterEncryptionKey;

  // Get default folder
  final folders = await db.folderDao.getByVaultId(vaultId);
  final folderId = folders.first.id;

  // Create secrets via SecretOperations for proper encryption
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      authProvider.overrideWith(
        (ref) => FakeAuthNotifier(
          AuthUnlocked(masterEncryptionKey: masterKey, vaultId: vaultId),
        ),
      ),
    ],
  );

  final ops = container.read(secretOpsProvider);
  final secrets = <Secret>[];

  final types = [
    'api_key',
    'token',
    'password',
    'certificate',
    'ssh_key',
    'credential',
    'other',
  ];
  final envs = ['production', 'development', 'staging', null];
  final services = ['GitHub', 'AWS', 'Stripe', null];

  for (var i = 0; i < secretCount; i++) {
    final result = await ops.create(
      name: 'Secret ${i + 1}',
      value: 'value-${i + 1}',
      folderId: folderId,
      secretType: types[i % types.length],
      serviceName: services[i % services.length],
      environment: envs[i % envs.length],
    );
    if (result is Success<Secret>) {
      secrets.add(result.data);
    }
  }

  container.dispose();

  return TestVaultData(
    db: db,
    vaultId: vaultId,
    masterKey: masterKey,
    folderId: folderId,
    secrets: secrets,
  );
}

// ─── Test Secret Factory ───
// Convenience constructor for Secret objects used in widget/screen tests.

Secret makeTestSecret({
  int id = 1,
  int vaultId = 1,
  int folderId = 1,
  String name = 'Test Secret',
  String secretType = 'api_key',
  String? serviceName,
  String? environment,
  String? notes,
  String? tags,
  int accessCount = 0,
  DateTime? lastAccessedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return Secret(
    id: id,
    vaultId: vaultId,
    folderId: folderId,
    name: name,
    encryptedValue: Uint8List(16),
    encryptedValueIv: Uint8List(12),
    encryptedValueAuthTag: Uint8List(16),
    secretType: secretType,
    serviceName: serviceName,
    environment: environment,
    notes: notes,
    tags: tags,
    recordVersion: 1,
    accessCount: accessCount,
    lastAccessedAt: lastAccessedAt,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

/// Unmounts the tree and elapses the fake clock so drift's zero-duration
/// stream-cleanup timers fire inside the test's FakeAsync zone. Call at the
/// end of any test whose tree watched a real drift stream (StreamProvider on
/// the test DB) — otherwise the binding's `!timersPending` invariant fails
/// ("A Timer is still pending…") and the tearDown `db.close()` hangs waiting
/// on cleanup that can no longer run.
Future<void> drainDriftTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

// ─── Widget Test Helper ───
// Extended pumpApp that pre-configures all providers needed for dashboard-level tests.

extension PumpWidget on WidgetTester {
  /// Pump a widget with ProviderScope + MaterialApp, with arbitrary overrides.
  Future<void> pumpProviderWidget(
    Widget widget, {
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: Scaffold(body: widget),
        ),
      ),
    );
  }
}
