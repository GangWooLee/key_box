import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/constants/app_constants.dart';
import 'package:key_box/core/database/database.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/widgets/sidebar.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Overrides that make Sidebar renderable without a real DB.
  List<Override> sidebarOverrides({
    SecretCategory selectedCategory = SecretCategory.all,
    String? selectedService,
    Map<SecretCategory, int>? counts,
    List<Folder>? rootFolders,
    bool sidebarCollapsed = false,
  }) {
    return [
      selectedCategoryProvider.overrideWith((ref) => selectedCategory),
      selectedServiceProvider.overrideWith((ref) => selectedService),
      categoryCountsProvider.overrideWith((ref) {
        return counts ??
            {
              SecretCategory.all: 10,
              SecretCategory.apiKey: 4,
              SecretCategory.token: 3,
              SecretCategory.password: 2,
              SecretCategory.certificate: 1,
            };
      }),
      rootFoldersProvider.overrideWith((ref) {
        return Stream.value(rootFolders ?? []);
      }),
      showCommandPaletteProvider.overrideWith((ref) => false),
      sidebarCollapsedProvider.overrideWith((ref) => sidebarCollapsed),
    ];
  }

  group('Sidebar', () {
    group('header', () {
      testWidgets('renders sidebar header with traffic light inset height',
          (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(),
        );

        // The header SizedBox should have trafficLightInset height
        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        final headerBox = sizedBoxes.where(
          (sb) => sb.height == AppConstants.trafficLightInset,
        );
        expect(headerBox, isNotEmpty,
            reason: 'Should have a SizedBox with trafficLightInset height');
      });

      testWidgets('renders collapse button with tooltip', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(),
        );

        expect(
          find.byTooltip('Hide sidebar'),
          findsOneWidget,
        );
      });

      testWidgets('collapse button sets sidebarCollapsedProvider to true',
          (tester) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: sidebarOverrides(),
            child: Builder(builder: (context) {
              return Consumer(builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return MaterialApp(
                  theme: ThemeData.dark(),
                  home: const Scaffold(body: Sidebar()),
                );
              });
            }),
          ),
        );

        await tester.tap(find.byTooltip('Hide sidebar'));
        await tester.pump();

        expect(container.read(sidebarCollapsedProvider), isTrue);
      });

      testWidgets('renders panelLeftClose icon', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(),
        );

        expect(find.byIcon(LucideIcons.panelLeftClose), findsOneWidget);
      });
    });

    group('structure', () {
      testWidgets('renders search bar placeholder', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(),
        );

        expect(find.text('Search secrets...'), findsOneWidget);
      });

      testWidgets('renders ⌘K badge', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(),
        );

        expect(find.text('\u2318K'), findsOneWidget);
      });
    });

    group('category section', () {
      testWidgets('renders all 5 categories', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(),
        );

        for (final cat in SecretCategory.values) {
          expect(find.text(cat.label), findsOneWidget);
        }
      });

      testWidgets('selected category is highlighted', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(selectedCategory: SecretCategory.apiKey),
        );

        // 'API Keys' row should have active styling (w600 weight)
        final apiKeysText = tester.widget<Text>(find.text('API Keys'));
        expect(apiKeysText.style?.fontWeight, FontWeight.w600);
      });

      testWidgets('correct count per category', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(),
        );

        expect(find.text('10'), findsOneWidget); // all
        expect(find.text('4'), findsOneWidget); // apiKey
        expect(find.text('3'), findsOneWidget); // token
        expect(find.text('2'), findsOneWidget); // password
        expect(find.text('1'), findsOneWidget); // certificate
      });

      testWidgets('category tap updates selectedCategoryProvider',
          (tester) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: sidebarOverrides(),
            child: Builder(builder: (context) {
              return Consumer(builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return MaterialApp(
                  theme: ThemeData.dark(),
                  home: const Scaffold(body: Sidebar()),
                );
              });
            }),
          ),
        );

        // Tap 'Tokens'
        await tester.tap(find.text('Tokens'));
        await tester.pump();

        expect(
            container.read(selectedCategoryProvider), SecretCategory.token);
      });
    });

    group('folder tree section', () {
      testWidgets('renders FOLDERS header', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(),
        );

        expect(find.text('FOLDERS'), findsOneWidget);
      });

      testWidgets('empty folders shows hint text', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(rootFolders: []),
        );
        await tester.pump(); // process stream

        expect(find.text('FOLDERS'), findsOneWidget);
        expect(find.text('No folders yet'), findsOneWidget);
      });
    });

    group('interactions', () {
      testWidgets('search bar tap sets showCommandPaletteProvider to true',
          (tester) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: sidebarOverrides(),
            child: Builder(builder: (context) {
              return Consumer(builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return MaterialApp(
                  theme: ThemeData.dark(),
                  home: const Scaffold(body: Sidebar()),
                );
              });
            }),
          ),
        );

        await tester.tap(find.text('Search secrets...'));
        await tester.pump();

        expect(container.read(showCommandPaletteProvider), isTrue);
      });
    });
  });
}
