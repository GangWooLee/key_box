import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/widgets/secret_list.dart';
import 'package:key_box/features/secrets/presentation/widgets/environment_badge.dart';

import '../../../../helpers/widget_test_helpers.dart';

// A minimal Secret stub for provider overrides.
Secret _makeSecret({
  required int id,
  required String name,
  String secretType = 'api_key',
  String? serviceName,
  String? environment,
  DateTime? lastAccessedAt,
}) {
  final now = DateTime.now();
  return Secret(
    id: id,
    vaultId: 1,
    folderId: 1,
    name: name,
    encryptedValue: Uint8List(0),
    encryptedValueIv: Uint8List(0),
    encryptedValueAuthTag: Uint8List(0),
    secretType: secretType,
    serviceName: serviceName,
    environment: environment,
    recordVersion: 1,
    accessCount: 0,
    lastAccessedAt: lastAccessedAt,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('SecretList', () {
    group('structure', () {
      testWidgets('renders mono uppercase header columns', (tester) async {
        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => <Secret>[]),
            selectedSecretIdProvider.overrideWith((ref) => null),
          ],
        );

        expect(find.text('NAME'), findsOneWidget);
        expect(find.text('SERVICE'), findsOneWidget);
        expect(find.text('ENV'), findsOneWidget);
        expect(find.text('LAST USED'), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('empty vault shows the bench-is-clear hero', (tester) async {
        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => <Secret>[]),
            selectedSecretIdProvider.overrideWith((ref) => null),
          ],
        );

        expect(find.text('THE BENCH IS CLEAR'), findsOneWidget);
        expect(find.text('your first secret goes here'), findsOneWidget);
        expect(find.text('+ New Secret'), findsOneWidget);
        // ⌘N hint: command icon + N (Plex Mono lacks the ⌘ glyph).
        expect(find.byIcon(LucideIcons.command), findsOneWidget);
        expect(find.text('N'), findsOneWidget);
      });

      testWidgets('empty folder shows quiet one-liner, not the hero', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => <Secret>[]),
            selectedSecretIdProvider.overrideWith((ref) => null),
            selectedFolderIdProvider.overrideWith((ref) => 7),
          ],
        );

        expect(find.text('this folder is empty'), findsOneWidget);
        expect(find.text('THE BENCH IS CLEAR'), findsNothing);
      });

      testWidgets('empty category filter shows quiet one-liner', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => <Secret>[]),
            selectedSecretIdProvider.overrideWith((ref) => null),
            selectedCategoryProvider.overrideWith(
              (ref) => SecretCategory.apiKey,
            ),
          ],
        );

        expect(find.text('no secrets in this view'), findsOneWidget);
        expect(find.text('THE BENCH IS CLEAR'), findsNothing);
      });
    });

    group('table rows', () {
      testWidgets('renders correct number of rows', (tester) async {
        final secrets = [
          _makeSecret(id: 1, name: 'Secret 1', serviceName: 'GitHub'),
          _makeSecret(id: 2, name: 'Secret 2', serviceName: 'AWS'),
          _makeSecret(id: 3, name: 'Secret 3'),
        ];

        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => secrets),
            selectedSecretIdProvider.overrideWith((ref) => null),
          ],
        );

        expect(find.text('Secret 1'), findsOneWidget);
        expect(find.text('Secret 2'), findsOneWidget);
        expect(find.text('Secret 3'), findsOneWidget);
      });

      testWidgets('row shows name, service, environment badge', (tester) async {
        final secrets = [
          _makeSecret(
            id: 1,
            name: 'My API Key',
            serviceName: 'Stripe',
            environment: 'production',
          ),
        ];

        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => secrets),
            selectedSecretIdProvider.overrideWith((ref) => null),
          ],
        );

        expect(find.text('My API Key'), findsOneWidget);
        expect(find.text('Stripe'), findsOneWidget);
        expect(find.byType(EnvironmentBadge), findsOneWidget);
        expect(find.text('PROD'), findsOneWidget);
      });

      testWidgets('row tap updates selectedSecretIdProvider', (tester) async {
        final secrets = [_makeSecret(id: 42, name: 'Test Secret')];

        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              filteredSecretsProvider.overrideWith((ref) => secrets),
              selectedSecretIdProvider.overrideWith((ref) => null),
            ],
            child: Builder(
              builder: (context) {
                return Consumer(
                  builder: (context, ref, _) {
                    container = ProviderScope.containerOf(context);
                    return MaterialApp(
                      theme: AppTheme.terminal(),
                      home: const Scaffold(body: SecretList()),
                    );
                  },
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Test Secret'));
        await tester.pump();

        expect(container.read(selectedSecretIdProvider), 42);
      });

      testWidgets('last accessed shows dash when null', (tester) async {
        final secrets = [
          _makeSecret(id: 1, name: 'No Access', lastAccessedAt: null),
        ];

        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => secrets),
            selectedSecretIdProvider.overrideWith((ref) => null),
          ],
        );

        expect(find.text('—'), findsOneWidget);
      });
    });

    group('bottom bar', () {
      testWidgets('renders "Add Secret" button with plus icon', (tester) async {
        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => <Secret>[]),
            selectedSecretIdProvider.overrideWith((ref) => null),
          ],
        );

        expect(find.text('Add Secret'), findsOneWidget);
        expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      });

      testWidgets('count label: "0 secrets" for empty', (tester) async {
        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => <Secret>[]),
            selectedSecretIdProvider.overrideWith((ref) => null),
          ],
        );

        expect(find.text('0 secrets'), findsOneWidget);
      });

      testWidgets('count label: "1 secret" singular', (tester) async {
        final secrets = [_makeSecret(id: 1, name: 'One')];

        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => secrets),
            selectedSecretIdProvider.overrideWith((ref) => null),
          ],
        );

        expect(find.text('1 secret'), findsOneWidget);
      });

      testWidgets('count label: "3 secrets" plural', (tester) async {
        final secrets = List.generate(
          3,
          (i) => _makeSecret(id: i + 1, name: 'S$i'),
        );

        await tester.pumpProviderWidget(
          const SecretList(),
          overrides: [
            filteredSecretsProvider.overrideWith((ref) => secrets),
            selectedSecretIdProvider.overrideWith((ref) => null),
          ],
        );

        expect(find.text('3 secrets'), findsOneWidget);
      });
    });
  });
}
