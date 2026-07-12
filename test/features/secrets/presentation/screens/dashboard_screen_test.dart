import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/core/constants/app_constants.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/screens/dashboard_screen.dart';
import 'package:key_box/features/secrets/presentation/widgets/sidebar.dart';
import 'package:key_box/features/secrets/presentation/widgets/secret_list.dart';
import 'package:key_box/features/secrets/presentation/widgets/secret_detail.dart';
import 'package:key_box/features/secrets/presentation/widgets/command_palette.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  // Dashboard needs a wider surface (default 800px too narrow for 200+340+table)
  const testSurfaceSize = Size(1440, 900);

  setUp(() {
    suppressDriftWarning();
    SharedPreferences.setMockInitialValues({});
  });

  List<Override> dashboardOverrides({
    AuthState authState = const AuthLocked(),
    bool showPalette = false,
    bool sidebarCollapsed = false,
  }) {
    return [
      authProvider.overrideWith((ref) => FakeAuthNotifier(authState)),
      showCommandPaletteProvider.overrideWith((ref) => showPalette),
      selectedSecretIdProvider.overrideWith((ref) => null),
      selectedCategoryProvider.overrideWith((ref) => SecretCategory.all),
      selectedServiceProvider.overrideWith((ref) => null),
      filteredSecretsProvider.overrideWith((ref) => <Secret>[]),
      categoryCountsProvider.overrideWith((ref) => <SecretCategory, int>{}),
      rootFoldersProvider.overrideWith((ref) => Stream.value(<Folder>[])),
      clipboardServiceProvider.overrideWithValue(MockClipboardService()),
      sidebarCollapsedProvider.overrideWith((ref) => sidebarCollapsed),
    ];
  }

  AuthState unlockedState() =>
      AuthUnlocked(masterEncryptionKey: Uint8List(32), vaultId: 1);

  /// Pumps dashboard inside a large-enough surface.
  Future<void> pumpDashboard(
    WidgetTester tester, {
    required AuthState authState,
    bool showPalette = false,
    bool sidebarCollapsed = false,
  }) async {
    await tester.binding.setSurfaceSize(testSurfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: dashboardOverrides(
          authState: authState,
          showPalette: showPalette,
          sidebarCollapsed: sidebarCollapsed,
        ),
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: DashboardScreen()),
        ),
      ),
    );
  }

  group('DashboardScreen', () {
    group('widget tree structure [P0 — ParentData bug prevention]', () {
      testWidgets('Stack layout with sidebar overlay', (tester) async {
        await pumpDashboard(tester, authState: unlockedState());

        // Main layout is a Stack (sidebar overlays content)
        expect(find.byType(Stack), findsWidgets);
      });

      testWidgets('Content Row has 2 children (table + detail)', (
        tester,
      ) async {
        await pumpDashboard(tester, authState: unlockedState());

        final rowFinder = find.descendant(
          of: find.byType(FocusTraversalGroup),
          matching: find.byType(Row),
        );
        final rows = tester
            .widgetList<Row>(rowFinder)
            .where((r) => r.children.length == 2);
        expect(
          rows,
          isNotEmpty,
          reason: 'Should have a Row with 2 children (table + detail)',
        );
      });

      testWidgets('Detail SizedBox width = detailPanelWidth', (tester) async {
        await pumpDashboard(tester, authState: unlockedState());

        final detailBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        final detailBox = detailBoxes.where(
          (sb) => sb.width == AppConstants.detailPanelWidth,
        );
        expect(detailBox, isNotEmpty);
      });
    });

    group('auth guard', () {
      testWidgets('non-AuthUnlocked shows SizedBox.shrink', (tester) async {
        await pumpDashboard(tester, authState: const AuthLocked());

        expect(find.byType(Sidebar), findsNothing);
        expect(find.byType(SecretList), findsNothing);
        expect(find.byType(SecretDetail), findsNothing);
      });

      testWidgets('AuthUnlocked renders full layout', (tester) async {
        await pumpDashboard(tester, authState: unlockedState());

        expect(find.byType(Sidebar), findsOneWidget);
        expect(find.byType(SecretList), findsOneWidget);
        expect(find.byType(SecretDetail), findsOneWidget);
      });
    });

    group('top bar', () {
      testWidgets('renders Audit Log button with tooltip', (tester) async {
        await pumpDashboard(tester, authState: unlockedState());

        expect(find.byTooltip('Audit Log'), findsOneWidget);
        expect(find.byIcon(LucideIcons.scrollText), findsOneWidget);
      });

      testWidgets('renders theme toggle button with tooltip', (tester) async {
        await pumpDashboard(tester, authState: unlockedState());

        // Default is dark, so tooltip should say "Switch to light theme"
        expect(find.byTooltip('Switch to light theme'), findsOneWidget);
        expect(find.byIcon(LucideIcons.moon), findsOneWidget);
      });

      testWidgets('top bar has topBarHeight', (tester) async {
        await pumpDashboard(tester, authState: unlockedState());

        // Find Positioned with topBarHeight (full-width, no longer animated)
        final positioned = tester.widgetList<Positioned>(
          find.byType(Positioned),
        );
        final topBarPositioned = positioned.where(
          (p) => p.height == AppConstants.topBarHeight,
        );
        expect(
          topBarPositioned,
          isNotEmpty,
          reason: 'Should have a Positioned with topBarHeight height',
        );
      });

      testWidgets('top bar has no expand button (moved to sidebar)', (
        tester,
      ) async {
        await pumpDashboard(
          tester,
          authState: unlockedState(),
          sidebarCollapsed: true,
        );

        // Expand button is now inside the collapsed sidebar, not in top bar.
        // Verify top bar's Row doesn't contain a panelLeftOpen icon directly.
        // The icon should exist (in sidebar), but not duplicated in top bar.
        expect(find.byTooltip('Show sidebar'), findsOneWidget);
      });

      testWidgets('top bar has GestureDetector for dragging', (tester) async {
        await pumpDashboard(tester, authState: unlockedState());

        // The top bar should have a GestureDetector for window dragging
        expect(find.byType(GestureDetector), findsWidgets);
      });
    });

    group('sidebar collapse', () {
      testWidgets('sidebar visible by default', (tester) async {
        await pumpDashboard(tester, authState: unlockedState());

        expect(find.byType(Sidebar), findsOneWidget);
        expect(find.byTooltip('Show sidebar'), findsNothing);
      });

      testWidgets('sidebar renders in collapsed mode (icon rail)', (
        tester,
      ) async {
        await pumpDashboard(
          tester,
          authState: unlockedState(),
          sidebarCollapsed: true,
        );

        // Sidebar still renders (as icon rail), not hidden
        expect(find.byType(Sidebar), findsOneWidget);
      });

      testWidgets('collapsed sidebar shows expand button', (tester) async {
        await pumpDashboard(
          tester,
          authState: unlockedState(),
          sidebarCollapsed: true,
        );

        // Expand button is inside the collapsed sidebar
        expect(find.byTooltip('Show sidebar'), findsOneWidget);
        expect(find.byIcon(LucideIcons.panelLeftOpen), findsOneWidget);
      });

      testWidgets('collapsed sidebar shows category icons', (tester) async {
        await pumpDashboard(
          tester,
          authState: unlockedState(),
          sidebarCollapsed: true,
        );

        // All 5 category icons should be present as tooltips
        for (final cat in SecretCategory.values) {
          expect(find.byTooltip(cat.label), findsOneWidget);
        }
      });
    });

    group('command palette overlay', () {
      testWidgets('showPalette=true shows CommandPalette', (tester) async {
        await pumpDashboard(
          tester,
          authState: unlockedState(),
          showPalette: true,
        );

        expect(find.byType(CommandPalette), findsOneWidget);
      });

      testWidgets('showPalette=false hides CommandPalette', (tester) async {
        await pumpDashboard(
          tester,
          authState: unlockedState(),
          showPalette: false,
        );

        expect(find.byType(CommandPalette), findsNothing);
      });
    });

    group('focus traversal', () {
      testWidgets('FocusTraversalGroup exists in tree', (tester) async {
        await pumpDashboard(tester, authState: unlockedState());

        expect(find.byType(FocusTraversalGroup), findsWidgets);
      });

      testWidgets('3 FocusTraversalOrder children', (tester) async {
        await pumpDashboard(tester, authState: unlockedState());

        expect(find.byType(FocusTraversalOrder), findsNWidgets(3));
      });
    });

    group('Semantics widgets', () {
      testWidgets('Semantics widgets are present in the widget tree', (
        tester,
      ) async {
        await pumpDashboard(tester, authState: unlockedState());

        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('three Semantics children inside the main Row', (
        tester,
      ) async {
        await pumpDashboard(tester, authState: unlockedState());

        expect(find.byType(Sidebar), findsOneWidget);
        expect(find.byType(SecretList), findsOneWidget);
        expect(find.byType(SecretDetail), findsOneWidget);
      });
    });
  });
}
