import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/secrets_providers.dart';
import 'folder_tree.dart';

// Shared icon mapping for both expanded and collapsed sidebar views.
const _categoryIcons = {
  SecretCategory.all: LucideIcons.key,
  SecretCategory.apiKey: LucideIcons.zap,
  SecretCategory.token: LucideIcons.ticket,
  SecretCategory.password: LucideIcons.lock,
  SecretCategory.certificate: LucideIcons.shieldCheck,
};

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, this.collapsed = false});
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (collapsed) return const _CollapsedSidebar();
    return const _ExpandedSidebar();
  }
}

// ─── Expanded Sidebar (200px, full content) ───

class _ExpandedSidebar extends ConsumerWidget {
  const _ExpandedSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar + Collapse Button (same row)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
          child: Row(
            children: [
              Expanded(child: _SearchBar(isDark: isDark)),
              const SizedBox(width: 4),
              _CollapseButton(isDark: isDark),
            ],
          ),
        ),

        // Categories
        _CategorySection(isDark: isDark),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.darkDividerSubtle : theme.dividerColor,
          ),
        ),

        // Folder Tree
        Expanded(child: FolderTree(isDark: isDark)),
      ],
    );
  }
}

// ─── Collapsed Sidebar (48px icon rail) ───

class _CollapsedSidebar extends ConsumerWidget {
  const _CollapsedSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selected = ref.watch(selectedCategoryProvider);

    return Column(
      children: [
        // Expand button
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Tooltip(
            message: 'Show sidebar',
            child: InkWell(
              onTap: () {
                ref.read(sidebarCollapsedProvider.notifier).state = false;
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(6),
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

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.darkDividerSubtle : theme.dividerColor,
          ),
        ),

        const SizedBox(height: 8),

        // Category icons
        ...SecretCategory.values.map((cat) {
          final isActive = cat == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Tooltip(
              message: cat.label,
              child: InkWell(
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).state = cat;
                  ref.read(selectedServiceProvider.notifier).state = null;
                  ref.read(selectedFolderIdProvider.notifier).state = null;
                  ref.read(selectedSecretIdProvider.notifier).state = null;
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark
                              ? AppColors.darkCategoryActive
                              : AppColors.brand50)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _categoryIcons[cat]!,
                    size: 16,
                    color: isActive
                        ? (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)
                        : (isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Collapse Button (panelLeftClose, 16px) ───

class _CollapseButton extends ConsumerWidget {
  const _CollapseButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Hide sidebar',
      child: InkWell(
        onTap: () {
          ref.read(sidebarCollapsedProvider.notifier).state = true;
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            LucideIcons.panelLeftClose,
            size: 16,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ),
      ),
    );
  }
}

// ─── Search Bar ───

class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(showCommandPaletteProvider.notifier).state = true;
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSidebarSearchBg : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark
                ? AppColors.darkSidebarSearchStroke
                : AppColors.lightBorderPrimary,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(
              LucideIcons.search,
              size: 14,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Search secrets...',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderPrimary
                      : AppColors.lightBorderPrimary,
                ),
              ),
              child: Text(
                '\u2318K',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkTextQuaternary
                      : AppColors.lightTextTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Section ───

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final counts = ref.watch(categoryCountsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: SecretCategory.values.map((cat) {
          final isActive = cat == selected;
          final count = counts[cat] ?? 0;
          return _CategoryItem(
            icon: _categoryIcons[cat]!,
            label: cat.label,
            count: count,
            isActive: isActive,
            isDark: isDark,
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = cat;
              ref.read(selectedServiceProvider.notifier).state = null;
              ref.read(selectedFolderIdProvider.notifier).state = null;
              ref.read(selectedSecretIdProvider.notifier).state = null;
            },
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? AppColors.darkCategoryActive : AppColors.brand50)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isActive
                  ? Border(
                      left: BorderSide(
                        color: isDark
                            ? AppColors.darkCategoryActiveBorder
                            : AppColors.brand600,
                        width: 2,
                      ),
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive
                      ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                      : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary)
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextQuaternary
                        : AppColors.lightTextTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
