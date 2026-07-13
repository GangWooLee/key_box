import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/secrets_providers.dart';
import 'folder_dialogs.dart';

/// The FOLDERS section of the tray sidebar. Header is a muted mono caption
/// (silence principle — nothing in the tray begs for attention); selection
/// mirrors the category items: hover fill + accent text + left accent edge.
class FolderTree extends ConsumerWidget {
  const FolderTree({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootFolders = ref.watch(rootFoldersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FolderTreeHeader(),
        Expanded(
          child: rootFolders.when(
            data: (folders) {
              if (folders.isEmpty) {
                return const _EmptyFolderHint();
              }
              return ListView.builder(
                itemCount: folders.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) => _FolderTreeNode(
                  key: ValueKey(folders[index].id),
                  folder: folders[index],
                  depth: 0,
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

// ─── Header ───

class _FolderTreeHeader extends ConsumerWidget {
  const _FolderTreeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xsm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'FOLDERS',
              style: AppTypography.sectionHeader.copyWith(color: s.muted),
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              onPressed: () => showCreateFolderDialog(context, ref),
              icon: Icon(LucideIcons.plus, size: 14, color: s.muted),
              padding: EdgeInsets.zero,
              tooltip: 'New folder',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recursive Tree Node ───

class _FolderTreeNode extends ConsumerWidget {
  const _FolderTreeNode({super.key, required this.folder, required this.depth});

  final Folder folder;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final expandedIds = ref.watch(expandedFolderIdsProvider);
    final isSelected = selectedFolderId == folder.id;
    final isExpanded = expandedIds.contains(folder.id);
    final children = ref.watch(folderChildrenProvider(folder.id));
    final hasChildren = children.whenOrNull(data: (c) => c.isNotEmpty) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // This node row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onSelect(ref),
              onSecondaryTap: () => _showContextMenu(context, ref),
              hoverColor: s.hover,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? s.hover : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: isSelected
                      ? Border(left: BorderSide(color: s.accent, width: 2))
                      : null,
                ),
                padding: EdgeInsets.only(left: 10.0 + depth * 16.0, right: 10),
                child: Row(
                  children: [
                    // Expand/collapse chevron
                    if (hasChildren)
                      GestureDetector(
                        onTap: () => _toggleExpand(ref),
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: Icon(
                            LucideIcons.chevronRight,
                            size: 12,
                            color: s.muted,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                    const SizedBox(width: AppSpacing.xs),
                    // Folder icon (functional identification)
                    Icon(
                      isExpanded ? LucideIcons.folderOpen : LucideIcons.folder,
                      size: 14,
                      color: isSelected ? s.accent : s.muted,
                    ),
                    const SizedBox(width: AppSpacing.xsm),
                    // Name
                    Expanded(
                      child: Text(
                        folder.name,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? s.accent : s.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Count — mono, the ledger's numerals.
                    Text(
                      '${folder.secretsCount}',
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
        ),
        // Children (if expanded)
        if (isExpanded)
          children.when(
            data: (childFolders) => Column(
              children: childFolders
                  .map(
                    (child) => _FolderTreeNode(
                      key: ValueKey(child.id),
                      folder: child,
                      depth: depth + 1,
                    ),
                  )
                  .toList(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  void _onSelect(WidgetRef ref) {
    final current = ref.read(selectedFolderIdProvider);
    if (current == folder.id) {
      // Deselect → revert to "All Keys" category
      ref.read(selectedFolderIdProvider.notifier).state = null;
      ref.read(selectedCategoryProvider.notifier).state = SecretCategory.all;
    } else {
      // Select folder → clear category/service
      ref.read(selectedFolderIdProvider.notifier).state = folder.id;
      ref.read(selectedCategoryProvider.notifier).state = SecretCategory.all;
      ref.read(selectedServiceProvider.notifier).state = null;
    }
    ref.read(selectedSecretIdProvider.notifier).state = null;
  }

  void _toggleExpand(WidgetRef ref) {
    final notifier = ref.read(expandedFolderIdsProvider.notifier);
    final current = Set<int>.from(notifier.state);
    if (current.contains(folder.id)) {
      current.remove(folder.id);
    } else {
      current.add(folder.id);
    }
    notifier.state = current;
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showFolderContextMenu(context: context, ref: ref, folder: folder);
  }
}

// ─── Empty hint ───

class _EmptyFolderHint extends StatelessWidget {
  const _EmptyFolderHint();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Text(
        'No folders yet',
        style: AppTypography.mono.copyWith(fontSize: 11, color: s.muted),
      ),
    );
  }
}
