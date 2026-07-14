import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/widgets/sidebar.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Overrides that make Sidebar renderable without a real DB.
  List<Override> sidebarOverrides({
    SecretCategory selectedCategory = SecretCategory.all,
    Map<SecretCategory, int>? counts,
    List<Folder>? rootFolders,
    bool sidebarCollapsed = false,
  }) {
    return [
      selectedCategoryProvider.overrideWith((ref) => selectedCategory),
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
    group('structure', () {
      testWidgets('renders mono ⌘K search placeholder', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(),
        );

        // ⌘ renders as the Lucide command icon (Plex Mono lacks the glyph).
        expect(find.byIcon(LucideIcons.command), findsOneWidget);
        expect(find.text('K — search…'), findsOneWidget);
      });

      testWidgets('renders collapse button with Hide sidebar tooltip', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          const Sidebar(),
          overrides: sidebarOverrides(),
        );

        expect(find.byTooltip('Hide sidebar'), findsOneWidget);
        expect(find.byIcon(LucideIcons.panelLeftClose), findsOneWidget);
      });

      testWidgets('collapse button sets sidebarCollapsedProvider to true', (
        tester,
      ) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: sidebarOverrides(),
            child: Builder(
              builder: (context) {
                return Consumer(
                  builder: (context, ref, _) {
                    container = ProviderScope.containerOf(context);
                    return MaterialApp(
                      theme: AppTheme.terminal(),
                      home: const Scaffold(body: Sidebar()),
                    );
                  },
                );
              },
            ),
          ),
        );

        await tester.tap(find.byTooltip('Hide sidebar'));
        await tester.pump();

        expect(container.read(sidebarCollapsedProvider), isTrue);
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

      testWidgets('category tap updates selectedCategoryProvider', (
        tester,
      ) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: sidebarOverrides(),
            child: Builder(
              builder: (context) {
                return Consumer(
                  builder: (context, ref, _) {
                    container = ProviderScope.containerOf(context);
                    return MaterialApp(
                      theme: AppTheme.terminal(),
                      home: const Scaffold(body: Sidebar()),
                    );
                  },
                );
              },
            ),
          ),
        );

        // Tap 'Tokens'
        await tester.tap(find.text('Tokens'));
        await tester.pump();

        expect(container.read(selectedCategoryProvider), SecretCategory.token);
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

    group('collapsed mode (icon rail)', () {
      testWidgets('renders expand button with Show sidebar tooltip', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          const Sidebar(collapsed: true),
          overrides: sidebarOverrides(sidebarCollapsed: true),
        );

        expect(find.byTooltip('Show sidebar'), findsOneWidget);
        expect(find.byIcon(LucideIcons.panelLeftOpen), findsOneWidget);
      });

      testWidgets('renders 5 category rail items with tooltips', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          const Sidebar(collapsed: true),
          overrides: sidebarOverrides(sidebarCollapsed: true),
        );

        for (final cat in SecretCategory.values) {
          expect(find.byTooltip(cat.label), findsOneWidget);
        }
      });

      testWidgets('rail items show mono initials, not icons', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(collapsed: true),
          overrides: sidebarOverrides(sidebarCollapsed: true),
        );

        // First two letters of each category label, uppercase.
        for (final initials in ['AL', 'AP', 'TO', 'PA', 'CE']) {
          expect(find.text(initials), findsOneWidget);
        }
        // The silence principle: no category icons on the rail.
        expect(find.byIcon(LucideIcons.key), findsNothing);
        expect(find.byIcon(LucideIcons.zap), findsNothing);
      });

      testWidgets('does not render category labels', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(collapsed: true),
          overrides: sidebarOverrides(sidebarCollapsed: true),
        );

        // Text labels should not appear in collapsed mode
        for (final cat in SecretCategory.values) {
          expect(find.text(cat.label), findsNothing);
        }
      });

      testWidgets('active category icon has active background', (tester) async {
        await tester.pumpProviderWidget(
          const Sidebar(collapsed: true),
          overrides: sidebarOverrides(
            sidebarCollapsed: true,
            selectedCategory: SecretCategory.apiKey,
          ),
        );

        // The API Keys tooltip should be present
        expect(find.byTooltip('API Keys'), findsOneWidget);
      });

      testWidgets('icon tap updates selectedCategoryProvider', (tester) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: sidebarOverrides(sidebarCollapsed: true),
            child: Builder(
              builder: (context) {
                return Consumer(
                  builder: (context, ref, _) {
                    container = ProviderScope.containerOf(context);
                    return MaterialApp(
                      theme: AppTheme.terminal(),
                      home: const Scaffold(body: Sidebar(collapsed: true)),
                    );
                  },
                );
              },
            ),
          ),
        );

        // Tap the Tokens category icon (via tooltip)
        await tester.tap(find.byTooltip('Tokens'));
        await tester.pump();

        expect(container.read(selectedCategoryProvider), SecretCategory.token);
      });

      testWidgets('expand button sets sidebarCollapsed to false', (
        tester,
      ) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: sidebarOverrides(sidebarCollapsed: true),
            child: Builder(
              builder: (context) {
                return Consumer(
                  builder: (context, ref, _) {
                    container = ProviderScope.containerOf(context);
                    return MaterialApp(
                      theme: AppTheme.terminal(),
                      home: const Scaffold(body: Sidebar(collapsed: true)),
                    );
                  },
                );
              },
            ),
          ),
        );

        await tester.tap(find.byTooltip('Show sidebar'));
        await tester.pump();

        expect(container.read(sidebarCollapsedProvider), isFalse);
      });
    });

    group('interactions', () {
      testWidgets('search bar tap sets showCommandPaletteProvider to true', (
        tester,
      ) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: sidebarOverrides(),
            child: Builder(
              builder: (context) {
                return Consumer(
                  builder: (context, ref, _) {
                    container = ProviderScope.containerOf(context);
                    return MaterialApp(
                      theme: AppTheme.terminal(),
                      home: const Scaffold(body: Sidebar()),
                    );
                  },
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('K — search…'));
        await tester.pump();

        expect(container.read(showCommandPaletteProvider), isTrue);
      });
    });
  });
}
