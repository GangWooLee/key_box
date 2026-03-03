import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
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

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Row(
        children: [
          // Sidebar — lightest in dark mode (200px fixed)
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: Semantics(
              label: 'Navigation sidebar',
              child: SizedBox(
                width: AppConstants.sidebarWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSidebarTonal
                        : AppColors.lightSurfaceSidebar,
                    border: Border(
                      right: BorderSide(
                        color: isDark
                            ? AppColors.darkBorderSubtle
                            : theme.dividerColor,
                      ),
                    ),
                  ),
                  child: const Sidebar(),
                ),
              ),
            ),
          ),

          // Table View — fluid middle column
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: Semantics(
              label: 'Secret table',
              child: Expanded(
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
                    color: isDark ? AppColors.darkSurfaceDetailTonal : null,
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
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: CommandPalette(
                onClose: _closePalette,
              ),
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
          PlatformMenuItem(
            label: 'Lock Vault',
            shortcut: const SingleActivator(LogicalKeyboardKey.keyL, meta: true),
            onSelected: () => ref.read(authProvider.notifier).lock(),
          ),
          const PlatformMenuItemGroup(members: []),
          PlatformMenuItem(
            label: 'Quit KeyBox',
            shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
            onSelected: () => SystemNavigator.pop(),
          ),
        ],
      ),
      PlatformMenu(
        label: 'Edit',
        menus: [
          PlatformMenuItem(
            label: 'Find...',
            shortcut: const SingleActivator(LogicalKeyboardKey.keyK, meta: true),
            onSelected: () => ref.read(showCommandPaletteProvider.notifier).state = true,
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
                label: 'System',
                onSelected: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
              ),
              PlatformMenuItem(
                label: 'Light',
                onSelected: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
              ),
              PlatformMenuItem(
                label: 'Dark',
                onSelected: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
