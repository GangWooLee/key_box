import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/backup/vault_recovery_service.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/encryption/key_hierarchy_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/encryption/secret_encryption_service.dart';

/// Pure round-trip coverage for the recovery net's crown-jewel claim: a backup
/// preserves every secret across the AAD asymmetry (stored = AAD-bound, archive
/// = empty-AAD). No DB, no file, no SQLCipher — all crypto (flutter test does
/// not exercise cipher; the DB/file wiring is integration_test territory).
void main() {
  final enc = SecretEncryptionService();
  final kdf = KeyDerivationService();
  final kh = KeyHierarchyService();
  final mks = MasterKeyService();
  final service = VaultRecoveryService();

  ({Uint8List salt, Uint8List wrappedMek, Uint8List mek}) makeVault(
    String password,
  ) {
    final salt = kdf.generateSalt();
    final pdk = kdf.deriveKey(password: password, salt: salt);
    final kek = kh.deriveKek(pdk);
    final mek = mks.generateMasterKey();
    final wrappedMek = mks.wrap(masterKey: mek, wrappingKey: kek);
    return (salt: salt, wrappedMek: wrappedMek, mek: mek);
  }

  Secret storedSecret({
    required int id,
    required String name,
    required String value,
    required Uint8List mek,
    bool aadBound = true,
    String secretType = 'api_key',
    String? serviceName,
    String? environment,
    String? notes,
    String? tags,
  }) {
    final e = enc.encrypt(
      value: value,
      key: mek,
      aad: aadBound ? secretAad(secretId: id, recordVersion: 1) : null,
    );
    final now = DateTime.utc(2026, 1, 1);
    return Secret(
      id: id,
      vaultId: 1,
      folderId: 1,
      name: name,
      encryptedValue: e.encryptedValue,
      encryptedValueIv: e.iv,
      encryptedValueAuthTag: e.authTag,
      secretType: secretType,
      serviceName: serviceName,
      environment: environment,
      notes: notes,
      tags: tags,
      recordVersion: 1,
      accessCount: 0,
      lastAccessedAt: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('export → restore preserves every value + metadata (round-trip)', () {
    const password = 'correct-horse-battery-staple';
    final v = makeVault(password);
    final secrets = [
      storedSecret(
        id: 1,
        name: 'GitHub PAT',
        value: 'ghp_abc123DEF456',
        mek: v.mek,
        serviceName: 'GitHub',
        environment: 'production',
      ),
      storedSecret(
        id: 2,
        name: 'AWS Root',
        value: '{"key":"AKIA...","secret":"a+long/value=with==padding"}',
        mek: v.mek,
        secretType: 'token',
        notes: 'do not rotate without warning',
        tags: 'infra,critical',
      ),
    ];

    final archive = service.buildArchive(
      salt: v.salt,
      wrappedMek: v.wrappedMek,
      secrets: secrets,
      mek: v.mek,
    );
    expect(archive, isNotNull);

    // Restore into a brand-new vault keyed with a different password/MEK.
    final dest = makeVault('a-totally-different-new-password');
    final restored = service.restore(
      archive: archive!,
      password: password,
      destinationMek: dest.mek,
    );

    expect(restored, isNotNull);
    expect(restored!.length, 2);
    expect(restored[0].name, 'GitHub PAT');
    expect(restored[0].value, 'ghp_abc123DEF456');
    expect(restored[0].serviceName, 'GitHub');
    expect(restored[0].environment, 'production');
    expect(restored[0].secretType, 'api_key');
    expect(restored[1].name, 'AWS Root');
    expect(
      restored[1].value,
      '{"key":"AKIA...","secret":"a+long/value=with==padding"}',
    );
    expect(restored[1].secretType, 'token');
    expect(restored[1].notes, 'do not rotate without warning');
    expect(restored[1].tags, 'infra,critical');
  });

  test('legacy empty-AAD stored secrets still export + restore', () {
    const password = 'legacy-vault-password';
    final v = makeVault(password);
    final secrets = [
      storedSecret(
        id: 7,
        name: 'Old Key',
        value: 'pre-B2-value',
        mek: v.mek,
        aadBound: false, // legacy write, no AAD binding
      ),
    ];

    final archive = service.buildArchive(
      salt: v.salt,
      wrappedMek: v.wrappedMek,
      secrets: secrets,
      mek: v.mek,
    );
    expect(archive, isNotNull);

    final dest = makeVault('new-pass');
    final restored = service.restore(
      archive: archive!,
      password: password,
      destinationMek: dest.mek,
    );
    expect(restored, isNotNull);
    expect(restored!.single.value, 'pre-B2-value');
  });

  test('empty vault exports and restores to nothing', () {
    final v = makeVault('empty-vault-pw');
    final archive = service.buildArchive(
      salt: v.salt,
      wrappedMek: v.wrappedMek,
      secrets: const [],
      mek: v.mek,
    );
    expect(archive, isNotNull);

    final dest = makeVault('new');
    final restored = service.restore(
      archive: archive!,
      password: 'empty-vault-pw',
      destinationMek: dest.mek,
    );
    expect(restored, isNotNull);
    expect(restored, isEmpty);
  });

  test(
    'buildArchive returns null when a secret is unreadable under the MEK',
    () {
      final v = makeVault('pw');
      final wrongMekVault = makeVault('other');
      // Secret was sealed under a DIFFERENT mek — cannot be read under v.mek.
      final secrets = [
        storedSecret(id: 1, name: 'x', value: 'v', mek: wrongMekVault.mek),
      ];

      final archive = service.buildArchive(
        salt: v.salt,
        wrappedMek: v.wrappedMek,
        secrets: secrets,
        mek: v.mek,
      );
      expect(archive, isNull);
    },
  );

  test('wrong password fails the restore', () {
    const password = 'the-real-password';
    final v = makeVault(password);
    final archive = service.buildArchive(
      salt: v.salt,
      wrappedMek: v.wrappedMek,
      secrets: [storedSecret(id: 1, name: 'x', value: 'v', mek: v.mek)],
      mek: v.mek,
    )!;

    final dest = makeVault('new');
    final restored = service.restore(
      archive: archive,
      password: 'WRONG-password',
      destinationMek: dest.mek,
    );
    expect(restored, isNull);
  });

  test('a malformed archive fails the restore', () {
    final dest = makeVault('new');
    final restored = service.restore(
      archive: '{"format":"not-a-keybox-archive"}',
      password: 'whatever',
      destinationMek: dest.mek,
    );
    expect(restored, isNull);
  });

  test('round-trips tricky payloads: unicode, empty, and long values', () {
    const password = 'edge-case-vault';
    final v = makeVault(password);
    const emoji = '🔐 パスワード «naïve» \n\ttab+newline';
    final longValue = 'x' * 4000; // JWT/cert-sized
    final secrets = [
      storedSecret(id: 1, name: 'unicode', value: emoji, mek: v.mek),
      storedSecret(id: 2, name: 'empty', value: '', mek: v.mek),
      storedSecret(id: 3, name: 'long', value: longValue, mek: v.mek),
    ];

    final archive = service.buildArchive(
      salt: v.salt,
      wrappedMek: v.wrappedMek,
      secrets: secrets,
      mek: v.mek,
    )!;
    final dest = makeVault('dest');
    final restored = service.restore(
      archive: archive,
      password: password,
      destinationMek: dest.mek,
    )!;

    expect(restored[0].value, emoji);
    expect(restored[1].value, '');
    expect(restored[2].value, longValue);
  });

  test('preserves count + order across many records', () {
    const password = 'bulk-vault';
    final v = makeVault(password);
    final secrets = [
      for (var i = 1; i <= 50; i++)
        storedSecret(id: i, name: 'secret-$i', value: 'value-$i', mek: v.mek),
    ];

    final archive = service.buildArchive(
      salt: v.salt,
      wrappedMek: v.wrappedMek,
      secrets: secrets,
      mek: v.mek,
    )!;
    final dest = makeVault('dest');
    final restored = service.restore(
      archive: archive,
      password: password,
      destinationMek: dest.mek,
    )!;

    expect(restored.length, 50);
    for (var i = 0; i < 50; i++) {
      expect(restored[i].name, 'secret-${i + 1}');
      expect(restored[i].value, 'value-${i + 1}');
    }
  });
}
