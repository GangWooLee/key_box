import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/encryption/key_derivation_service.dart';
import '../../../core/encryption/master_key_service.dart';
import '../../../core/constants/crypto_constants.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(databaseProvider));
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._db) : super(const AuthInitial());

  final AppDatabase _db;
  final _kds = KeyDerivationService();
  final _mks = MasterKeyService();

  /// Check if vault is set up and transition to the right state.
  Future<void> initialize() async {
    final hasConfig = await _db.vaultConfigDao.exists();
    if (hasConfig) {
      state = const AuthLocked();
    } else {
      state = const AuthFirstRun();
    }
  }

  /// First-time setup: create vault, derive keys, wrap MEK.
  Future<String?> setup({
    required String password,
    required String confirmation,
  }) async {
    // Validate
    if (password != confirmation) return 'Passwords do not match';
    if (password.length < CryptoConstants.minPasswordLength) {
      return 'Password must be at least ${CryptoConstants.minPasswordLength} characters';
    }

    // Generate cryptographic materials
    final salt = _kds.generateSalt();
    final pdk = _kds.deriveKey(password: password, salt: salt);
    final mek = _mks.generateMasterKey();
    final wrappedMek = _mks.wrap(masterKey: mek, wrappingKey: pdk);

    if (kDebugMode) debugPrint('[Auth:setup] salt(${salt.length}B) wrappedMek(${wrappedMek.length}B)');

    // Create vault + config + default folder atomically
    late int vaultId;
    await _db.transaction(() async {
      final vault = await _db.vaultDao.create(name: 'Personal');
      vaultId = vault.id;
      await _db.vaultConfigDao.create(
        vaultId: vault.id,
        masterKeySalt: salt,
        encryptedMasterKey: wrappedMek,
        masterPasswordDigest: '', // No BCrypt in Flutter — we verify via unwrap
      );
      await _db.folderDao.create(
        vaultId: vault.id,
        name: 'General',
        icon: 'folder',
        position: 0,
      );
      await _db.auditEventDao.create(
        vaultId: vault.id,
        action: 'vault.setup',
      );
    });

    if (kDebugMode) debugPrint('[Auth:setup] vault $vaultId created');

    // Transition to unlocked (first setup → onboarding)
    state = AuthUnlocked(
      masterEncryptionKey: mek,
      vaultId: vaultId,
      isFirstSetup: true,
    );
    return null; // success
  }

  /// Unlock vault with password.
  Future<String?> unlock({required String password}) async {
    final vault = await _db.vaultDao.getFirst();
    if (vault == null) return 'No vault found';

    final config = await _db.vaultConfigDao.getByVaultId(vault.id);
    if (config == null) return 'No vault configuration found';

    final storedSalt = Uint8List.fromList(config.masterKeySalt);
    final storedEmk = Uint8List.fromList(config.encryptedMasterKey);

    // Derive PDK from password + stored salt
    final pdk = _kds.deriveKey(password: password, salt: storedSalt);

    // Try to unwrap MEK — if it fails, password was wrong
    final mek = _mks.unwrap(wrappedKey: storedEmk, wrappingKey: pdk);

    if (mek == null) {
      if (kDebugMode) debugPrint('[Auth:unlock] unwrap failed');
      return 'Incorrect password';
    }
    state = AuthUnlocked(masterEncryptionKey: mek, vaultId: vault.id);
    return null; // success
  }

  /// Finish onboarding — transition from first-setup to normal unlocked.
  void completeOnboarding() {
    final current = state;
    if (current is AuthUnlocked && current.isFirstSetup) {
      state = AuthUnlocked(
        masterEncryptionKey: current.masterEncryptionKey,
        vaultId: current.vaultId,
      );
    }
  }

  /// Lock the vault — clear MEK from memory.
  void lock() {
    state = const AuthLocked();
  }

  /// DEV ONLY: Wipe all vault data and return to first-run state.
  Future<void> resetAndReinitialize() async {
    await _db.resetVault();
    state = const AuthFirstRun();
  }
}
