@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/database/database.dart';
import 'package:key_box/features/audit/domain/audit_providers.dart';
import 'package:key_box/features/audit/presentation/screens/audit_log_screen.dart';

import 'golden_helpers.dart';

/// Deterministic ledger fixture. Timestamps are built relative to now so the
/// `timeAgo` labels ('5m ago', '2h ago', …) stay stable no matter when the
/// golden is regenerated.
List<AuditEvent> _testEvents() {
  final now = DateTime.now();
  AuditEvent event(int id, String action, String? name, Duration ago) =>
      AuditEvent(
        id: id,
        vaultId: 1,
        secretId: name == null ? null : id,
        action: action,
        metadata: name == null ? null : '{"name": "$name"}',
        createdAt: now.subtract(ago),
      );

  return [
    event(1, 'secret.read', 'AWS Access Key', const Duration(minutes: 5)),
    event(2, 'secret.create', 'Stripe Live Key', const Duration(hours: 2)),
    event(3, 'secret.update', 'GitHub PAT', const Duration(hours: 6)),
    event(4, 'vault.unlock', null, const Duration(hours: 9)),
    event(5, 'secret.delete', 'Old Deploy Token', const Duration(days: 3)),
    event(6, 'vault.setup', null, const Duration(days: 12)),
  ];
}

void main() {
  // The mono ledger on the terminal surface (working screen, dark mode).
  testWidgets('audit_log_screen — ledger, V9 Terminal', (tester) async {
    await pumpGolden(
      tester,
      child: const AuditLogScreen(),
      size: const Size(900, 700),
      surface: GoldenSurface.terminal,
      overrides: [
        auditEventsProvider.overrideWith((ref) => Future.value(_testEvents())),
      ],
    );
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/audit_log_screen.png'),
    );
  });
}
