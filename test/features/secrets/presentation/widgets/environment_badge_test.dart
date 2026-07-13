import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/features/secrets/presentation/widgets/environment_badge.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('EnvironmentBadge (V9 — weight-coded, no fill)', () {
    Text badgeText(WidgetTester tester, String label) =>
        tester.widget<Text>(find.text(label));

    testWidgets('Production renders PROD with SemiBold weight', (tester) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'production'),
      );

      expect(find.text('PROD'), findsOneWidget);
      expect(badgeText(tester, 'PROD').style?.fontWeight, FontWeight.w600);
      // Weight, not color chips: no decorated pill container.
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('Development renders DEV with regular weight', (tester) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'development'),
      );

      expect(find.text('DEV'), findsOneWidget);
      expect(badgeText(tester, 'DEV').style?.fontWeight, FontWeight.w400);
    });

    testWidgets('Staging renders STG with regular weight', (tester) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'staging'),
      );

      expect(find.text('STG'), findsOneWidget);
      expect(badgeText(tester, 'STG').style?.fontWeight, FontWeight.w400);
    });

    testWidgets('PROD is visually heavier than DEV (weight distinction)', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        const Row(
          children: [
            EnvironmentBadge(environment: 'production'),
            EnvironmentBadge(environment: 'development'),
          ],
        ),
      );

      final prod = badgeText(tester, 'PROD').style!;
      final dev = badgeText(tester, 'DEV').style!;
      expect(prod.fontWeight!.value, greaterThan(dev.fontWeight!.value));
      expect(prod.color, isNot(dev.color));
    });

    testWidgets('null environment returns SizedBox.shrink', (tester) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: null),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('empty string returns SizedBox.shrink', (tester) async {
      await tester.pumpProviderWidget(const EnvironmentBadge(environment: ''));

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('case-insensitive: PRODUCTION matches production', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'PRODUCTION'),
      );

      expect(find.text('PROD'), findsOneWidget);
    });

    testWidgets('unknown environment uppercases the raw label, muted weight', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'custom-env'),
      );

      expect(find.text('CUSTOM-ENV'), findsOneWidget);
      expect(
        badgeText(tester, 'CUSTOM-ENV').style?.fontWeight,
        FontWeight.w400,
      );
    });
  });
}
