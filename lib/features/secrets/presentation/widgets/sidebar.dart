import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/secrets_providers.dart';
import 'folder_tree.dart';

// Category icons for the expanded list (functional identification — the
// collapsed rail uses mono initials instead, per the silence principle).
const _categoryIcons = {
  SecretCategory.all: LucideIcons.key,
  SecretCategory.apiKey: LucideIcons.zap,
  SecretCategory.token: LucideIcons.ticket,
  SecretCategory.password: LucideIcons.lock,
  SecretCategory.certificate: LucideIcons.shieldCheck,
};

/// First two letters of the category label — the collapsed rail's mono
/// initials (DESIGN.md §접힘 사이드바 레일: no icons, no truncated text).
String _railInitials(SecretCategory cat) =>
    cat.label.substring(0, 2).toUpperCase();

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
    final s = Theme.of(context).extension<KbSurface>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar + Collapse Button (same row)
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.smd,
            AppSpacing.sm,
            AppSpacing.sm,
            10,
          ),
          child: Row(
            children: [
              Expanded(child: _SearchBar()),
              SizedBox(width: AppSpacing.xs),
              _CollapseButton(),
            ],
          ),
        ),

        // Categories
        const _CategorySection(),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(height: 1, color: s.hairline),
        ),

        // Folder Tree
        const Expanded(child: FolderTree()),
      ],
    );
  }
}

// ─── Collapsed Sidebar (48px rail — mono initials, no icons) ───

class _CollapsedSidebar extends ConsumerWidget {
  const _CollapsedSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final selected = ref.watch(selectedCategoryProvider);
    final counts = ref.watch(categoryCountsProvider);

    return Column(
      children: [
        // Expand button (functional chrome — icon allowed)
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.xs,
          ),
          child: Tooltip(
            message: 'Show sidebar',
            child: InkWell(
              onTap: () {
                ref.read(sidebarCollapsedProvider.notifier).state = false;
              },
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xsm),
                child: Icon(
                  LucideIcons.panelLeftOpen,
                  size: 16,
                  color: s.muted,
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Divider(height: 1, color: s.hairline),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Category rail items: mono initials + count.
        ...SecretCategory.values.map((cat) {
          final isActive = cat == selected;
          final count = counts[cat] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Tooltip(
              message: cat.label,
              child: InkWell(
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).state = cat;
                  ref.read(selectedFolderIdProvider.notifier).state = null;
                  ref.read(selectedSecretIdProvider.notifier).state = null;
                },
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive ? s.hover : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: isActive
                        ? Border(left: BorderSide(color: s.accent, width: 2))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _railInitials(cat),
                        style: AppTypography.sectionHeader.copyWith(
                          fontSize: 10,
                          color: isActive ? s.accent : s.muted,
                        ),
                      ),
                      Text(
                        '$count',
                        style: AppTypography.mono.copyWith(
                          fontSize: 10,
                          height: 1.2,
                          color: s.muted,
                        ),
                      ),
                    ],
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
  const _CollapseButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Tooltip(
      message: 'Hide sidebar',
      child: InkWell(
        onTap: () {
          ref.read(sidebarCollapsedProvider.notifier).state = true;
        },
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(LucideIcons.panelLeftClose, size: 16, color: s.muted),
        ),
      ),
    );
  }
}

// ─── Search Field (⌘K — persistent affordance, opens the palette) ───

class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return GestureDetector(
      onTap: () {
        ref.read(showCommandPaletteProvider.notifier).state = true;
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: s.canvas,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: s.hairline),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 14, color: s.muted),
            const SizedBox(width: AppSpacing.xsm),
            // ⌘ is an icon, not a glyph: Plex Mono lacks U+2318 (tofu).
            Icon(LucideIcons.command, size: 11, color: s.muted),
            Expanded(
              child: Text(
                'K — search…',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: s.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
  const _CategorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final counts = ref.watch(categoryCountsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.smd,
        AppSpacing.sm,
        AppSpacing.smd,
        AppSpacing.sm,
      ),
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
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = cat;
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: s.hover,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? s.hover : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: isActive
                  ? Border(left: BorderSide(color: s.accent, width: 2))
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(icon, size: 14, color: isActive ? s.accent : s.muted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? s.accent : s.ink,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: s.muted,
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
