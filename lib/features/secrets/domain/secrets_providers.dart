import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/encryption/secret_encryption_service.dart';
import '../../../core/utils/result.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/domain/auth_state.dart';

// ─── Folder providers ───

final foldersProvider = StreamProvider<List<Folder>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) return const Stream.empty();
  final db = ref.read(databaseProvider);
  return db.folderDao.watchByVaultId(auth.vaultId);
});

final selectedFolderIdProvider = StateProvider<int?>((ref) => null);

// ─── Secret list provider ───

final secretsProvider = StreamProvider<List<Secret>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) return const Stream.empty();
  final db = ref.read(databaseProvider);
  final folderId = ref.watch(selectedFolderIdProvider);

  if (folderId == null) {
    return db.secretDao.watchByFolderId(-1); // empty
  }
  return db.secretDao.watchByFolderId(folderId);
});

final selectedSecretIdProvider = StateProvider<int?>((ref) => null);

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
      final encrypted = _crypto.encrypt(value: value, key: _auth.masterEncryptionKey);

      final secret = await _db.secretDao.create(
        vaultId: _auth.vaultId,
        folderId: folderId,
        name: name,
        encryptedValue: encrypted.encryptedValue,
        encryptedValueIv: encrypted.iv,
        encryptedValueAuthTag: encrypted.authTag,
        secretType: secretType,
        serviceName: serviceName,
        environment: environment,
        notes: notes,
        tags: tags,
      );

      await _db.folderDao.incrementSecretsCount(folderId);
      await _logAudit('secret.create', secret.id, {'name': name});

      return Success(secret);
    } catch (e) {
      return Failure('Failed to create secret: $e');
    }
  }

  Future<String?> decrypt(Secret secret) {
    return Future.value(_crypto.decrypt(
      encryptedValue: Uint8List.fromList(secret.encryptedValue),
      iv: Uint8List.fromList(secret.encryptedValueIv),
      authTag: Uint8List.fromList(secret.encryptedValueAuthTag),
      key: _auth.masterEncryptionKey,
    ));
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

      if (value != null) {
        final encrypted = _crypto.encrypt(value: value, key: _auth.masterEncryptionKey);
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
      );

      await _logAudit('secret.update', secretId, {'name': name});
      return const Success(null);
    } catch (e) {
      return Failure('Failed to update: $e');
    }
  }

  Future<Result<void>> delete(Secret secret) async {
    try {
      await _db.secretDao.deleteSecret(secret.id);
      await _db.folderDao.decrementSecretsCount(secret.folderId);
      await _logAudit('secret.delete', null, {'name': secret.name});
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete: $e');
    }
  }

  Future<String?> reveal(Secret secret) async {
    await _db.secretDao.recordAccess(secret.id);
    await _logAudit('secret.read', secret.id, {'name': secret.name});
    return decrypt(secret);
  }

  Future<void> _logAudit(String action, int? secretId, Map<String, dynamic> meta) {
    return _db.auditEventDao.create(
      vaultId: _auth.vaultId,
      action: action,
      secretId: secretId,
      metadata: jsonEncode(meta),
    );
  }
}

final secretOpsProvider = Provider((ref) => SecretOperations(ref));
