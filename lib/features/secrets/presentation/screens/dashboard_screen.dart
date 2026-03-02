import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../widgets/sidebar.dart';
import '../widgets/secret_list.dart';
import '../widgets/secret_detail.dart';
import '../widgets/command_palette.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showCommandPalette = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth is! AuthUnlocked) return const SizedBox.shrink();

    return PlatformMenuBar(
      menus: _buildMenus(context, ref),
      child: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            _buildLayout(context),
            if (_showCommandPalette) _buildCommandPaletteOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Sidebar
        SizedBox(
          width: AppConstants.sidebarWidth,
          child: Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkSurfaceSidebar
                  : AppColors.lightSurfaceSidebar,
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor,
                ),
              ),
            ),
            child: const Sidebar(),
          ),
        ),

        // Secret List
        SizedBox(
          width: AppConstants.listPaneWidth,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: const SecretList(),
          ),
        ),

        // Detail pane
        const Expanded(
          child: SecretDetail(),
        ),
      ],
    );
  }

  Widget _buildCommandPaletteOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showCommandPalette = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: CommandPalette(
            onClose: () => setState(() => _showCommandPalette = false),
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
        setState(() => _showCommandPalette = !_showCommandPalette);
      }
      // Cmd+L → lock
      if (event.logicalKey == LogicalKeyboardKey.keyL &&
          HardwareKeyboard.instance.isMetaPressed) {
        ref.read(authProvider.notifier).lock();
      }
      // Escape → close command palette
      if (event.logicalKey == LogicalKeyboardKey.escape && _showCommandPalette) {
        setState(() => _showCommandPalette = false);
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
            onSelected: () => setState(() => _showCommandPalette = true),
          ),
        ],
      ),
    ];
  }
}
