import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/secrets_providers.dart';
import 'folder_tree.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Traffic light safe area + collapse button
        _SidebarHeader(isDark: isDark),

        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: _SearchBar(isDark: isDark),
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
        Expanded(
          child: FolderTree(isDark: isDark),
        ),
      ],
    );
  }
}

// ─── Sidebar Header (traffic light area + collapse button) ───

class _SidebarHeader extends ConsumerWidget {
  const _SidebarHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: AppConstants.trafficLightInset,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          children: [
            // Left ~70px reserved for traffic light buttons
            const SizedBox(width: 70),
            const Spacer(),
            // Collapse sidebar button
            Tooltip(
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
            ),
          ],
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
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Search secrets...',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
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
                  color: isDark ? AppColors.darkTextQuaternary : AppColors.lightTextTertiary,
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

  static const _categoryIcons = {
    SecretCategory.all: LucideIcons.key,
    SecretCategory.apiKey: LucideIcons.zap,
    SecretCategory.token: LucideIcons.ticket,
    SecretCategory.password: LucideIcons.lock,
    SecretCategory.certificate: LucideIcons.shieldCheck,
  };

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
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                      : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextQuaternary : AppColors.lightTextTertiary,
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
