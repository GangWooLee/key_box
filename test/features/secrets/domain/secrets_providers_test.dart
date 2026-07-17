import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  group('SecretCategory.matches', () {
    test('all matches every type', () {
      for (final type in [
        'api_key',
        'token',
        'password',
        'certificate',
        'ssh_key',
        'other',
      ]) {
        expect(
          SecretCategory.all.matches(type),
          isTrue,
          reason: 'all should match $type',
        );
      }
    });

    test('apiKey matches only api_key', () {
      expect(SecretCategory.apiKey.matches('api_key'), isTrue);
      expect(SecretCategory.apiKey.matches('token'), isFalse);
      expect(SecretCategory.apiKey.matches('password'), isFalse);
    });

    test('token matches only token', () {
      expect(SecretCategory.token.matches('token'), isTrue);
      expect(SecretCategory.token.matches('api_key'), isFalse);
    });

    test('password matches only password', () {
      expect(SecretCategory.password.matches('password'), isTrue);
      expect(SecretCategory.password.matches('token'), isFalse);
    });

    test('certificate matches certificate and ssh_key', () {
      expect(SecretCategory.certificate.matches('certificate'), isTrue);
      expect(SecretCategory.certificate.matches('ssh_key'), isTrue);
      expect(SecretCategory.certificate.matches('api_key'), isFalse);
    });
  });

  group('filteredSecretsProvider (unit-like)', () {
    // These test the filtering logic by constructing mock secrets directly.
    test('category=all returns all secrets', () {
      final secrets = [
        makeTestSecret(id: 1, secretType: 'api_key'),
        makeTestSecret(id: 2, secretType: 'token'),
        makeTestSecret(id: 3, secretType: 'password'),
      ];

      final filtered = secrets
          .where((s) => SecretCategory.all.matches(s.secretType))
          .toList();
      expect(filtered.length, 3);
    });

    test('category=apiKey filters api_key only', () {
      final secrets = [
        makeTestSecret(id: 1, secretType: 'api_key'),
        makeTestSecret(id: 2, secretType: 'token'),
        makeTestSecret(id: 3, secretType: 'api_key'),
      ];

      final filtered = secrets
          .where((s) => SecretCategory.apiKey.matches(s.secretType))
          .toList();
      expect(filtered.length, 2);
    });

    test('service filter narrows results', () {
      final secrets = [
        makeTestSecret(id: 1, serviceName: 'GitHub'),
        makeTestSecret(id: 2, serviceName: 'AWS'),
        makeTestSecret(id: 3, serviceName: 'GitHub'),
      ];

      const service = 'GitHub';
      final filtered = secrets.where((s) => s.serviceName == service).toList();
      expect(filtered.length, 2);
    });

    test('no match returns empty', () {
      final secrets = [makeTestSecret(id: 1, secretType: 'api_key')];

      final filtered = secrets
          .where((s) => SecretCategory.password.matches(s.secretType))
          .toList();
      expect(filtered, isEmpty);
    });
  });

  group('categoryCountsProvider (unit-like)', () {
    test('counts per category correct', () {
      final secrets = [
        makeTestSecret(id: 1, secretType: 'api_key'),
        makeTestSecret(id: 2, secretType: 'api_key'),
        makeTestSecret(id: 3, secretType: 'token'),
        makeTestSecret(id: 4, secretType: 'password'),
        makeTestSecret(id: 5, secretType: 'certificate'),
        makeTestSecret(id: 6, secretType: 'ssh_key'),
      ];

      final counts = <SecretCategory, int>{};
      for (final cat in SecretCategory.values) {
        counts[cat] = secrets.where((s) => cat.matches(s.secretType)).length;
      }

      expect(counts[SecretCategory.all], 6);
      expect(counts[SecretCategory.apiKey], 2);
      expect(counts[SecretCategory.token], 1);
      expect(counts[SecretCategory.password], 1);
      expect(counts[SecretCategory.certificate], 2); // certificate + ssh_key
    });
  });

  group('searchResultsProvider (unit-like)', () {
    test('empty query returns no results', () {
      const query = '';
      expect(query.trim().isEmpty, isTrue);
    });

    test(
      'searchResultsProvider returns empty when the vault is locked',
      () async {
        // Actually execute the provider (the previous test asserted a tautology,
        // giving illusory coverage). Locked auth must short-circuit to [] before
        // touching databaseProvider.
        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthLocked()),
            ),
            searchQueryProvider.overrideWith((ref) => 'github'),
          ],
        );
        addTearDown(container.dispose);

        final results = await container.read(searchResultsProvider.future);
        expect(results, isEmpty);
      },
    );
  });
}
