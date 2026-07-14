@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/widgets/clipboard_countdown.dart';

import 'golden_helpers.dart';

/// The quiet clipboard auto-clear countdown mid-drain (보안 UX #3). Rendered
/// on the Terminal lamp surface (the detail panel it inhabits), a few seconds
/// in so the conic ring is partly drained.
void main() {
  testWidgets('clipboard_countdown — mid-drain on the lamp', (tester) async {
    await loadTestFonts();
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(280, 80));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.terminal(),
          home: Scaffold(
            // The detail panel is the lamp surface this lives on.
            backgroundColor: AppTheme.terminal().extension<KbSurface>()!.lamp,
            body: Center(
              child: Consumer(
                builder: (context, ref, _) {
                  container = ProviderScope.containerOf(context);
                  return const ClipboardCountdown();
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Copy, then drain a few seconds so the ring shows a partial arc.
    container.read(clipboardCopyEventProvider.notifier).state++;
    await tester.pump();
    await tester.pump(const Duration(seconds: 8)); // 30 → 22

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/clipboard_countdown.png'),
    );
  });
}
