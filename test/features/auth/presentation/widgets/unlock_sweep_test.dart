import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/core/theme/motion.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/presentation/widgets/unlock_sweep.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  setUp(suppressDriftWarning);

  AuthUnlocked unlocked() =>
      AuthUnlocked(masterEncryptionKey: Uint8List(32), vaultId: 1);

  /// Pumps the sweep wrapper around plain content, starting locked.
  Future<FakeAuthNotifier> pumpSweep(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    final fake = FakeAuthNotifier(const AuthLocked());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((ref) => fake)],
        child: MaterialApp(
          theme: AppTheme.sealed(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: const UnlockSweep(child: Scaffold(body: Text('content'))),
          ),
        ),
      ),
    );
    return fake;
  }

  group('UnlockSweep', () {
    testWidgets('idle: no cover overlay in the tree', (tester) async {
      await pumpSweep(tester);

      // No hit-test/semantics pollution while idle — the overlay widget
      // itself must be absent, not merely invisible.
      expect(find.byKey(UnlockSweep.coverKey), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('locked→unlocked: cover appears, then clears after the sweep', (
      tester,
    ) async {
      final fake = await pumpSweep(tester);

      fake.setAuthState(unlocked());
      await tester.pump(); // mount cover + arm the ticker
      expect(find.byKey(UnlockSweep.coverKey), findsOneWidget);

      // First tick sets the ticker epoch; the cover is still mid-sweep.
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(UnlockSweep.coverKey), findsOneWidget);

      // Advance past the signature duration → completes → overlay drops.
      await tester.pump(AppMotion.signature);
      await tester.pump(); // completion setState leaves the overlay out
      expect(find.byKey(UnlockSweep.coverKey), findsNothing);
    });

    testWidgets(
      'reduce motion: crossfade cover clears within the snap window',
      (tester) async {
        final fake = await pumpSweep(tester, reduceMotion: true);

        fake.setAuthState(unlocked());
        await tester.pump(); // mount cover + arm the ticker
        expect(find.byKey(UnlockSweep.coverKey), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 16)); // ticker epoch
        await tester.pump(AppMotion.snap); // past the 120ms crossfade end
        await tester.pump();
        expect(find.byKey(UnlockSweep.coverKey), findsNothing);
      },
    );

    testWidgets('unlocked→locked (lock) does not trigger a sweep', (
      tester,
    ) async {
      final fake = await pumpSweep(tester);

      // Open, and let the unlock sweep fully finish first.
      fake.setAuthState(unlocked());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(AppMotion.signature);
      await tester.pump();
      expect(find.byKey(UnlockSweep.coverKey), findsNothing);

      // Relock is immediate — the sweep only fires toward open, never back.
      fake.setAuthState(const AuthLocked());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(UnlockSweep.coverKey), findsNothing);
    });
  });
}
