import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/constants/app_constants.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/widgets/clipboard_countdown.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('ClipboardCountdown', () {
    testWidgets('idle: renders nothing (takes no space)', (tester) async {
      await tester.pumpProviderWidget(const ClipboardCountdown());

      expect(find.textContaining('clipboard clears'), findsNothing);
      expect(find.byKey(ClipboardCountdown.ringKey), findsNothing);
    });

    testWidgets('a copy event starts the ring + countdown line', (
      tester,
    ) async {
      late ProviderContainer container;
      await tester.pumpProviderWidget(
        Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const ClipboardCountdown();
          },
        ),
      );

      // Simulate a copy (what ClipboardService.onCopy does).
      container.read(clipboardCopyEventProvider.notifier).state++;
      await tester.pump();

      expect(
        find.text('clipboard clears in ${AppConstants.clipboardClearSeconds}s'),
        findsOneWidget,
      );
      expect(find.byKey(ClipboardCountdown.ringKey), findsOneWidget);
    });

    testWidgets('the count decrements each second', (tester) async {
      late ProviderContainer container;
      await tester.pumpProviderWidget(
        Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const ClipboardCountdown();
          },
        ),
      );

      container.read(clipboardCopyEventProvider.notifier).state++;
      await tester.pump();
      expect(find.text('clipboard clears in 30s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('clipboard clears in 29s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('clipboard clears in 28s'), findsOneWidget);
    });

    testWidgets('vanishes once the wipe window elapses', (tester) async {
      late ProviderContainer container;
      await tester.pumpProviderWidget(
        Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const ClipboardCountdown();
          },
        ),
      );

      container.read(clipboardCopyEventProvider.notifier).state++;
      await tester.pump();
      expect(find.byKey(ClipboardCountdown.ringKey), findsOneWidget);

      // Tick all the way to the wipe.
      await tester.pump(
        const Duration(seconds: AppConstants.clipboardClearSeconds),
      );
      expect(find.textContaining('clipboard clears'), findsNothing);
      expect(find.byKey(ClipboardCountdown.ringKey), findsNothing);
    });

    testWidgets('a second copy re-arms the full window', (tester) async {
      late ProviderContainer container;
      await tester.pumpProviderWidget(
        Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const ClipboardCountdown();
          },
        ),
      );

      container.read(clipboardCopyEventProvider.notifier).state++;
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('clipboard clears in 25s'), findsOneWidget);

      // Copy again → back to a full 30s.
      container.read(clipboardCopyEventProvider.notifier).state++;
      await tester.pump();
      expect(find.text('clipboard clears in 30s'), findsOneWidget);
    });
  });
}
