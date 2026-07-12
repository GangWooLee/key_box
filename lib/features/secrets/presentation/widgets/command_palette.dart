import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/secrets_providers.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(
    duration: const Duration(milliseconds: AppConstants.searchDebounceMs),
  );
  final _keyFocusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    _keyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final results = ref.watch(searchResultsProvider);

    return GestureDetector(
      onTap: () {}, // Prevent tap-through
      child: Material(
        elevation: 16,
        borderRadius: BorderRadius.circular(12),
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: Container(
          width: 560,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorderStrong
                  : AppColors.lightBorderPrimary,
            ),
          ),
          child: KeyboardListener(
            focusNode: _keyFocusNode,
            onKeyEvent: (event) => _handleKeyNav(event, results),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search input
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search secrets...',
                            hintStyle: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            filled: false,
                          ),
                          onChanged: (value) {
                            _debouncer.call(() {
                              ref.read(searchQueryProvider.notifier).state =
                                  value;
                            });
                          },
                          onSubmitted: (_) => _selectCurrent(results),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkDividerMedium
                      : AppColors.lightBorderSubtle,
                ),

                // Results
                results.when(
                  data: (secrets) {
                    if (secrets.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _controller.text.isEmpty
                              ? 'Type to search...'
                              : 'No results found',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                      );
                    }

                    return Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: secrets.length,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemBuilder: (context, index) {
                          final secret = secrets[index];
                          final isSelected = index == _selectedIndex;

                          return _ResultRow(
                            secret: secret,
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () {
                              ref
                                      .read(selectedSecretIdProvider.notifier)
                                      .state =
                                  secret.id;
                              widget.onClose();
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: $err',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.errorText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleKeyNav(KeyEvent event, AsyncValue<List<Secret>> results) {
    if (event is! KeyDownEvent) return;
    results.whenData((secrets) {
      if (secrets.isEmpty) return;
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, secrets.length - 1);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(0, secrets.length - 1);
        });
      }
    });
  }

  void _selectCurrent(AsyncValue<List<Secret>> results) {
    results.whenData((secrets) {
      if (secrets.isNotEmpty && _selectedIndex < secrets.length) {
        ref.read(selectedSecretIdProvider.notifier).state =
            secrets[_selectedIndex].id;
        widget.onClose();
      }
    });
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.secret,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final Secret secret;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? (isDark ? AppColors.darkCategoryActive : AppColors.brand50)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  secret.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (secret.serviceName != null) ...[
                const SizedBox(width: 8),
                Text(
                  secret.serviceName!,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkTableHeaderBg
                      : AppColors.brand50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  secret.secretType.replaceAll('_', ' '),
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
