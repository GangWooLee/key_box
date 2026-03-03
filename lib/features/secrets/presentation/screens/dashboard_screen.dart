import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../widgets/sidebar.dart';
import '../widgets/secret_list.dart';
import '../widgets/secret_detail.dart';
import '../../domain/secrets_providers.dart';
import '../widgets/command_palette.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final sidebarWidth = collapsed ? 0.0 : AppConstants.sidebarWidth;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkSurfacePrimary
          : theme.scaffoldBackgroundColor,
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
                  // Table View — fluid middle column
                  Expanded(
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(2),
                      child: Semantics(
                        label: 'Secret table',
                        child: Container(
                          color: isDark ? AppColors.darkSurfaceListTonal : null,
                          child: const SecretList(),
                        ),
                      ),
                    ),
                  ),

                  // Detail Panel — 340px fixed, gradient overlay
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: Semantics(
                      label: 'Secret details',
                      child: SizedBox(
                        width: AppConstants.detailPanelWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isDark ? AppColors.darkSurfaceDetailTonal : null,
                            gradient: isDark
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.darkDetailGradientStart,
                                      AppColors.darkDetailGradientEnd,
                                    ],
                                  )
                                : null,
                            border: Border(
                              left: BorderSide(
                                color: isDark
                                    ? AppColors.darkDetailLeftBorder
                                    : theme.dividerColor,
                              ),
                            ),
                          ),
                          child: const SecretDetail(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Top bar (draggable title bar area) ───
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: sidebarWidth,
              top: 0,
              right: 0,
              height: AppConstants.topBarHeight,
              child: _TopBar(isDark: isDark),
            ),

            // ─── Translucent sidebar overlay ───
            if (!collapsed)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: AppConstants.sidebarWidth,
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: Semantics(
                    label: 'Navigation sidebar',
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: isDark
                            ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
                            : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkGlassBg
                                : AppColors.lightSurfaceSidebar,
                            border: Border(
                              right: BorderSide(
                                color: isDark
                                    ? AppColors.darkGlassBorder
                                    : theme.dividerColor,
                              ),
                            ),
                          ),
                          child: const Sidebar(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ─── Sidebar expand button (when collapsed) ───
            if (collapsed)
              Positioned(
                left: 8,
                top: 8,
                child: Tooltip(
                  message: 'Show sidebar',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ref.read(sidebarCollapsedProvider.notifier).state =
                            false;
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.panelLeftOpen,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
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
    return GestureDetector(
      onTap: _closePalette,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          color: Colors.black54,
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
      // Cmd+L → lock
      if (event.logicalKey == LogicalKeyboardKey.keyL &&
          HardwareKeyboard.instance.isMetaPressed) {
        ref.read(authProvider.notifier).lock();
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
                onSelected: () => ref.read(authProvider.notifier).lock(),
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
  const _TopBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isCurrentlyDark = themeMode == ThemeMode.dark;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: AppConstants.topBarHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? AppColors.darkDividerSubtle
                  : AppColors.lightBorderSubtle,
            ),
          ),
        ),
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          children: [
            const Spacer(),
            // Audit Log button
            Tooltip(
              message: 'Audit Log',
              child: InkWell(
                onTap: () => context.pushNamed(RouteNames.auditLog),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    LucideIcons.scrollText,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Theme toggle button
            Tooltip(
              message: isCurrentlyDark
                  ? 'Switch to light theme'
                  : 'Switch to dark theme',
              child: InkWell(
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isCurrentlyDark ? LucideIcons.moon : LucideIcons.sun,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextSecondary,
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
