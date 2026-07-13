import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../widgets/sidebar.dart';
import '../widgets/secret_list.dart';
import '../widgets/secret_detail.dart';
import '../widgets/sheet_modal.dart';
import '../../domain/secrets_providers.dart';
import '../widgets/command_palette.dart';

/// The 3-column workbench (DESIGN.md §dashboard): tray sidebar (sunken) →
/// canvas table → lamp detail. Light comes from the right — the thing you
/// hold sits under the lamp. Surfaces are solid tonal steps; no glass.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth is! AuthUnlocked) return const SizedBox.shrink();
    final showPalette = ref.watch(showCommandPaletteProvider);

    return PlatformMenuBar(
      menus: _buildMenus(context, ref),
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            _buildLayout(context),
            if (showPalette) _buildCommandPaletteOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final sidebarWidth = collapsed
        ? AppConstants.sidebarCollapsedWidth
        : AppConstants.sidebarWidth;

    return Scaffold(
      backgroundColor: s.canvas,
      body: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Stack(
          children: [
            // ─── Main content (padded for sidebar + top bar) ───
            AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: sidebarWidth,
                top: AppConstants.topBarHeight,
              ),
              child: Row(
                children: [
                  // Table View — fluid middle column, rides the canvas.
                  Expanded(
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(2),
                      child: Semantics(
                        label: 'Secret table',
                        child: const SecretList(),
                      ),
                    ),
                  ),

                  // Detail Panel — 340px fixed, under the lamp.
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: Semantics(
                      label: 'Secret details',
                      child: SizedBox(
                        width: AppConstants.detailPanelWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: s.lamp,
                            border: Border(left: BorderSide(color: s.hairline)),
                          ),
                          child: const SecretDetail(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Sidebar — the sunken tray (solid, no glass) ───
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: 0,
              top: AppConstants.topBarHeight,
              bottom: 0,
              width: sidebarWidth,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: Semantics(
                  label: 'Navigation sidebar',
                  child: Container(
                    decoration: BoxDecoration(
                      color: s.tray,
                      border: Border(right: BorderSide(color: s.hairline)),
                    ),
                    child: Sidebar(collapsed: collapsed),
                  ),
                ),
              ),
            ),

            // ─── Top bar (draggable, full-width, z-order topmost) ───
            const Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: AppConstants.topBarHeight,
              child: _TopBar(),
            ),
          ],
        ),
      ),
    );
  }

  void _closePalette() {
    ref.read(showCommandPaletteProvider.notifier).state = false;
  }

  Widget _buildCommandPaletteOverlay() {
    final s = Theme.of(context).extension<KbSurface>()!;
    return GestureDetector(
      onTap: _closePalette,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          color: s.scrim,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: 1.0),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: CommandPalette(onClose: _closePalette),
            ),
          ),
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Cmd+K → command palette
      if (event.logicalKey == LogicalKeyboardKey.keyK &&
          HardwareKeyboard.instance.isMetaPressed) {
        final notifier = ref.read(showCommandPaletteProvider.notifier);
        notifier.state = !notifier.state;
      }
      // Cmd+N → new secret (the empty-state hero advertises this)
      if (event.logicalKey == LogicalKeyboardKey.keyN &&
          HardwareKeyboard.instance.isMetaPressed) {
        showSecretSheetModal(context: context, ref: ref);
      }
      // Cmd+L → lock (fire-and-forget: state flips synchronously, only the
      // encrypted-connection close is awaited internally)
      if (event.logicalKey == LogicalKeyboardKey.keyL &&
          HardwareKeyboard.instance.isMetaPressed) {
        unawaited(ref.read(authProvider.notifier).lock());
      }
      // Escape → close command palette
      if (ref.read(showCommandPaletteProvider) &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        _closePalette();
      }
    }
  }

  List<PlatformMenu> _buildMenus(BuildContext context, WidgetRef ref) {
    return [
      PlatformMenu(
        label: 'KeyBox',
        menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Lock Vault',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyL,
                  meta: true,
                ),
                onSelected: () =>
                    unawaited(ref.read(authProvider.notifier).lock()),
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Quit KeyBox',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyQ,
                  meta: true,
                ),
                onSelected: () => SystemNavigator.pop(),
              ),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: 'Edit',
        menus: [
          PlatformMenuItem(
            label: 'New Secret',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyN,
              meta: true,
            ),
            onSelected: () => showSecretSheetModal(context: context, ref: ref),
          ),
          PlatformMenuItem(
            label: 'Find...',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyK,
              meta: true,
            ),
            onSelected: () =>
                ref.read(showCommandPaletteProvider.notifier).state = true,
          ),
        ],
      ),
      PlatformMenu(
        label: 'View',
        menus: [
          PlatformMenu(
            label: 'Theme',
            menus: [
              PlatformMenuItem(
                label: 'Light',
                onSelected: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
              PlatformMenuItem(
                label: 'Dark',
                onSelected: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

// ─── Top Bar (draggable, with action buttons) ───

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final themeMode = ref.watch(themeModeProvider);
    final isCurrentlyDark = themeMode == ThemeMode.dark;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: AppConstants.topBarHeight,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: s.hairline)),
        ),
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          children: [
            // Traffic light safe area
            const SizedBox(width: 70),
            const Spacer(),
            // Audit Log button
            Tooltip(
              message: 'Audit Log',
              child: InkWell(
                onTap: () => context.pushNamed(RouteNames.auditLog),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(LucideIcons.scrollText, size: 16, color: s.muted),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Theme toggle button
            Tooltip(
              message: isCurrentlyDark
                  ? 'Switch to light theme'
                  : 'Switch to dark theme',
              child: InkWell(
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isCurrentlyDark ? LucideIcons.moon : LucideIcons.sun,
                    size: 16,
                    color: s.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
