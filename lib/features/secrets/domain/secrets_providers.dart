import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/encryption/secret_encryption_service.dart';
import '../../../core/utils/result.dart';
import '../../../services/clipboard_service.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/domain/auth_state.dart';

// ─── Folder providers ───

final foldersProvider = StreamProvider<List<Folder>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) return const Stream.empty();
  final db = ref.read(databaseProvider);
  return db.folderDao.watchByVaultId(auth.vaultId);
});

/// Root folders (parentId == null) for the current vault.
final rootFoldersProvider = StreamProvider<List<Folder>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) return const Stream.empty();
  final db = ref.read(databaseProvider);
  return db.folderDao.watchRootFolders(auth.vaultId);
});

/// Children of a specific folder.
final folderChildrenProvider = StreamProvider.family<List<Folder>, int>((
  ref,
  parentId,
) {
  // Watch auth so the stream rebinds to the fresh keyed connection on
  // lock→unlock; without it this non-autoDispose family keeps serving the
  // previous closed connection's dead stream (and throws while locked).
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) return const Stream.empty();
  final db = ref.read(databaseProvider);
  return db.folderDao.watchChildren(parentId);
});

/// UI state: set of expanded folder IDs in the sidebar tree.
final expandedFolderIdsProvider = StateProvider<Set<int>>((ref) => {});

final selectedFolderIdProvider = StateProvider<int?>((ref) => null);

// ─── Secret list provider (original folder-based — retained for data layer) ───

final secretsProvider = StreamProvider<List<Secret>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) return const Stream.empty();
  final db = ref.read(databaseProvider);

  // Use vault-wide stream for category/service filtering
  return db.secretDao.watchByVaultId(auth.vaultId);
});

final selectedSecretIdProvider = StateProvider<int?>((ref) => null);

// ─── Category / Service filtering (V8 sidebar) ───

enum SecretCategory {
  all('All Keys'),
  apiKey('API Keys'),
  token('Tokens'),
  password('Passwords'),
  certificate('Certificates');

  const SecretCategory(this.label);
  final String label;

  /// Matches against the secret_type column values.
  bool matches(String secretType) {
    return switch (this) {
      SecretCategory.all => true,
      SecretCategory.apiKey => secretType == 'api_key',
      SecretCategory.token => secretType == 'token',
      SecretCategory.password => secretType == 'password',
      SecretCategory.certificate =>
        secretType == 'certificate' || secretType == 'ssh_key',
    };
  }
}

final selectedCategoryProvider = StateProvider<SecretCategory>(
  (ref) => SecretCategory.all,
);

/// Category counts derived from all vault secrets.
final categoryCountsProvider = Provider<Map<SecretCategory, int>>((ref) {
  final secretsAsync = ref.watch(secretsProvider);
  return secretsAsync.when(
    data: (secrets) {
      final counts = <SecretCategory, int>{};
      for (final cat in SecretCategory.values) {
        counts[cat] = secrets.where((s) => cat.matches(s.secretType)).length;
      }
      return counts;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Folder IDs linked to a secret (M:N via join table).
final folderIdsBySecretProvider = FutureProvider.autoDispose
    .family<List<int>, int>((ref, secretId) {
      final db = ref.read(databaseProvider);
      return db.folderSecretsDao.getFolderIdsBySecretId(secretId);
    });

/// Secrets for the currently selected folder (M:N via join table).
final folderSecretsProvider = StreamProvider.family<List<Secret>, int>((
  ref,
  folderId,
) {
  // Watch auth (see folderChildrenProvider) so the stream rebinds to the fresh
  // keyed connection on lock→unlock instead of serving the closed one.
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) return const Stream.empty();
  final db = ref.read(databaseProvider);
  return db.folderSecretsDao.watchSecretsByFolderId(folderId);
});

/// Live secret counts per folder, derived from the M:N join table — the single
/// source of truth (mirrors [categoryCountsProvider]). Replaces the drift-prone
/// `folders.secretsCount` cache, whose write paths diverged. Folders with no
/// links are absent from the map; the sidebar reads `counts[id] ?? 0`.
final folderSecretCountsProvider = StreamProvider<Map<int, int>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) return const Stream.empty();
  final db = ref.read(databaseProvider);
  return db.folderSecretsDao.watchCountsByFolder();
});

/// Filtered secrets based on selected category OR folder. Folder selection
/// takes priority — when a folder is selected, the category filter is ignored.
final filteredSecretsProvider = Provider<List<Secret>>((ref) {
  final selectedFolder = ref.watch(selectedFolderIdProvider);

  // Folder mode: use M:N join table
  if (selectedFolder != null) {
    final folderSecrets = ref.watch(folderSecretsProvider(selectedFolder));
    return folderSecrets.when(
      data: (secrets) => secrets,
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Category mode
  final secretsAsync = ref.watch(secretsProvider);
  final category = ref.watch(selectedCategoryProvider);

  return secretsAsync.when(
    data: (secrets) =>
        secrets.where((s) => category.matches(s.secretType)).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Secret detail (single secret by ID, cached) ───

final secretDetailProvider = FutureProvider.autoDispose.family<Secret?, int>((
  ref,
  id,
) {
  final db = ref.read(databaseProvider);
  return db.secretDao.getById(id);
});

// ─── Sidebar collapse state ───

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

// ─── Command Palette visibility ───

final showCommandPaletteProvider = StateProvider<bool>((ref) => false);

// ─── Search ───

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Secret>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) return [];
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final db = ref.read(databaseProvider);
  return db.secretDao.search(auth.vaultId, query.trim());
});

// ─── Clipboard ───

/// Bumps every time a secret is copied, so the detail panel can (re)start the
/// quiet auto-clear countdown ring (보안 UX #3). The ring runs the same 30s as
/// the service's wipe timer, so no explicit "cleared" signal is needed.
final clipboardCopyEventProvider = StateProvider<int>((ref) => 0);

final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final service = ClipboardService(
    onCopy: () => ref.read(clipboardCopyEventProvider.notifier).state++,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

// ─── Secret operations ───

final secretEncryptionProvider = Provider((ref) => SecretEncryptionService());

class SecretOperations {
  SecretOperations(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(databaseProvider);
  AuthUnlocked get _auth => _ref.read(authProvider) as AuthUnlocked;
  SecretEncryptionService get _crypto => _ref.read(secretEncryptionProvider);

  Future<Result<Secret>> create({
    required String name,
    required String value,
    required int folderId,
    String secretType = 'api_key',
    String? serviceName,
    String? environment,
    String? notes,
    String? tags,
  }) async {
    try {
      // The AAD binds the ciphertext to the row id, which autoincrement only
      // reveals after insert — so: placeholder insert to reserve the id,
      // encrypt under that identity, then land the ciphertext. All inside a
      // transaction so a valueless placeholder can never escape.
      final secret = await _db.transaction(() async {
        final placeholder = await _db.secretDao.create(
          vaultId: _auth.vaultId,
          folderId: folderId,
          name: name,
          encryptedValue: Uint8List(0),
          encryptedValueIv: Uint8List(0),
          encryptedValueAuthTag: Uint8List(0),
          secretType: secretType,
          serviceName: serviceName,
          environment: environment,
          notes: notes,
          tags: tags,
        );

        final encrypted = _crypto.encrypt(
          value: value,
          key: _auth.masterEncryptionKey,
          aad: secretAad(
            secretId: placeholder.id,
            recordVersion: placeholder.recordVersion,
          ),
        );

        await _db.secretDao.updateSecret(
          placeholder.id,
          encryptedValue: encrypted.encryptedValue,
          encryptedValueIv: encrypted.iv,
          encryptedValueAuthTag: encrypted.authTag,
        );
        return (await _db.secretDao.getById(placeholder.id))!;
      });

      // M:N link is the source of truth for membership + count (derived via
      // folderSecretCountsProvider) — no cache column to keep in sync.
      await _db.folderSecretsDao.link(folderId, secret.id);
      await _logAudit('secret.create', secret.id, {'name': name});

      return Success(secret);
    } catch (e) {
      return Failure('Failed to create secret: $e');
    }
  }

  Future<String?> decrypt(Secret secret) {
    return Future.value(
      _crypto.decrypt(
        encryptedValue: Uint8List.fromList(secret.encryptedValue),
        iv: Uint8List.fromList(secret.encryptedValueIv),
        authTag: Uint8List.fromList(secret.encryptedValueAuthTag),
        key: _auth.masterEncryptionKey,
        aad: secretAad(
          secretId: secret.id,
          recordVersion: secret.recordVersion,
        ),
      ),
    );
  }

  Future<Result<void>> update(
    int secretId, {
    String? name,
    String? value,
    String? secretType,
    String? serviceName,
    String? environment,
    String? notes,
    String? tags,
    int? folderId,
  }) async {
    try {
      Uint8List? encryptedValue;
      Uint8List? iv;
      Uint8List? authTag;
      int? recordVersion;

      if (value != null) {
        final current = await _db.secretDao.getById(secretId);
        if (current == null) return const Failure('Secret not found');

        // Rotation bumps the record version and binds the fresh ciphertext
        // to it, so a restored older ciphertext fails GCM authentication
        // (rollback defense).
        recordVersion = current.recordVersion + 1;
        final encrypted = _crypto.encrypt(
          value: value,
          key: _auth.masterEncryptionKey,
          aad: secretAad(secretId: secretId, recordVersion: recordVersion),
        );
        encryptedValue = encrypted.encryptedValue;
        iv = encrypted.iv;
        authTag = encrypted.authTag;
      }

      await _db.secretDao.updateSecret(
        secretId,
        name: name,
        encryptedValue: encryptedValue,
        encryptedValueIv: iv,
        encryptedValueAuthTag: authTag,
        secretType: secretType,
        serviceName: serviceName,
        environment: environment,
        notes: notes,
        tags: tags,
        folderId: folderId,
        recordVersion: recordVersion,
      );

      await _logAudit('secret.update', secretId, {'name': name});
      return const Success(null);
    } catch (e) {
      return Failure('Failed to update: $e');
    }
  }

  Future<Result<void>> delete(Secret secret) async {
    try {
      // M:N: remove all folder links (count is derived, so no decrement).
      await _db.folderSecretsDao.unlinkAllForSecret(secret.id);
      await _db.secretDao.deleteSecret(secret.id);
      await _logAudit('secret.delete', null, {'name': secret.name});
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete: $e');
    }
  }

  /// Link a secret to an additional folder.
  Future<Result<void>> linkToFolder(int secretId, int folderId) async {
    try {
      await _db.folderSecretsDao.link(folderId, secretId);
      await _logAudit('secret.link', secretId, {'folderId': folderId});
      return const Success(null);
    } catch (e) {
      return Failure('Failed to link: $e');
    }
  }

  /// Remove a secret's link to a folder.
  Future<Result<void>> unlinkFromFolder(int secretId, int folderId) async {
    try {
      await _db.folderSecretsDao.unlink(folderId, secretId);
      await _logAudit('secret.unlink', secretId, {'folderId': folderId});
      return const Success(null);
    } catch (e) {
      return Failure('Failed to unlink: $e');
    }
  }

  Future<String?> reveal(Secret secret) async {
    await _db.secretDao.recordAccess(secret.id);
    await _logAudit('secret.read', secret.id, {'name': secret.name});
    return decrypt(secret);
  }

  Future<void> _logAudit(
    String action,
    int? secretId,
    Map<String, dynamic> meta,
  ) {
    return _db.auditEventDao.create(
      vaultId: _auth.vaultId,
      action: action,
      secretId: secretId,
      metadata: jsonEncode(meta),
    );
  }
}

final secretOpsProvider = Provider((ref) => SecretOperations(ref));
