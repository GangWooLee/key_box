import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/theme/colors.dart';
import 'package:key_box/features/secrets/presentation/widgets/environment_badge.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('EnvironmentBadge', () {
    testWidgets('Production badge renders with red colors', (tester) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'production'),
      );

      expect(find.text('Production'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.envProdBg);
      final border = decoration.border as Border;
      expect(border.top.color, AppColors.envProdStroke);
    });

    testWidgets('Development badge renders with green colors', (tester) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'development'),
      );

      expect(find.text('Development'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.envDevBg);
    });

    testWidgets('Staging badge renders with amber colors', (tester) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'staging'),
      );

      expect(find.text('Staging'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.envStagingBg);
    });

    testWidgets('null environment returns SizedBox.shrink', (tester) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: null),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('empty string returns SizedBox.shrink', (tester) async {
      await tester.pumpProviderWidget(const EnvironmentBadge(environment: ''));

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('case-insensitive: PRODUCTION matches production', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'PRODUCTION'),
      );

      expect(find.text('Production'), findsOneWidget);
    });

    testWidgets('pill shape border radius', (tester) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'production'),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(10));
    });

    testWidgets('unknown environment uses raw text as label', (tester) async {
      await tester.pumpProviderWidget(
        const EnvironmentBadge(environment: 'custom-env'),
      );

      expect(find.text('custom-env'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.darkTableHeaderBg);
    });
  });
}
