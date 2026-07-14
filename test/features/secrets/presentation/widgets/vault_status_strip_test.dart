import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/features/secrets/presentation/widgets/vault_status_strip.dart';
import 'package:key_box/services/auto_lock_service.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('VaultStatusStrip', () {
    testWidgets('shows "never backed up" when the vault has no backup', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpProviderWidget(const VaultStatusStrip());
      await tester.pumpAndSettle();

      expect(find.text('never backed up'), findsOneWidget);
    });

    testWidgets('shows the last-backup age when a backup exists', (
      tester,
    ) async {
      final at = DateTime.now().subtract(const Duration(hours: 2));
      SharedPreferences.setMockInitialValues({
        'last_backup_at': at.millisecondsSinceEpoch,
      });
      await tester.pumpProviderWidget(const VaultStatusStrip());
      await tester.pumpAndSettle();

      expect(find.textContaining('backed up'), findsOneWidget);
      expect(find.text('never backed up'), findsNothing);
    });

    testWidgets('hides the auto-lock line when tracking is off (no deadline)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpProviderWidget(const VaultStatusStrip());
      await tester.pumpAndSettle();

      expect(find.textContaining('auto-lock'), findsNothing);
    });

    testWidgets(
      'shows the remaining minutes when an auto-lock deadline is set',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpProviderWidget(
          const VaultStatusStrip(),
          overrides: [
            autoLockDeadlineProvider.overrideWith(
              (ref) => DateTime.now().add(const Duration(minutes: 15)),
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('auto-lock in'), findsOneWidget);
      },
    );
  });
}
