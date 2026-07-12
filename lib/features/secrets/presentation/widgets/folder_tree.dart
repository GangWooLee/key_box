import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/secrets_providers.dart';
import 'folder_dialogs.dart';

class FolderTree extends ConsumerWidget {
  const FolderTree({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootFolders = ref.watch(rootFoldersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _FolderTreeHeader(isDark: isDark),
        // Body
        Expanded(
          child: rootFolders.when(
            data: (folders) {
              if (folders.isEmpty) {
                return _EmptyFolderHint(isDark: isDark);
              }
              return ListView.builder(
                itemCount: folders.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) => _FolderTreeNode(
                  key: ValueKey(folders[index].id),
                  folder: folders[index],
                  depth: 0,
                  isDark: isDark,
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
  const _FolderTreeHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'FOLDERS',
              style: AppTypography.sectionHeader.copyWith(
                color: isDark ? AppColors.brand500 : AppColors.brand600,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              onPressed: () => showCreateFolderDialog(context, ref),
              icon: Icon(
                LucideIcons.plus,
                size: 14,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
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
  const _FolderTreeNode({
    super.key,
    required this.folder,
    required this.depth,
    required this.isDark,
  });

  final Folder folder;
  final int depth;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onSelect(ref),
              onSecondaryTap: () => _showContextMenu(context, ref),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? AppColors.darkCategoryActive
                            : AppColors.brand50)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected
                      ? const Border(
                          left: BorderSide(
                            color: AppColors.darkCategoryActiveBorder,
                            width: 2,
                          ),
                        )
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
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            LucideIcons.chevronRight,
                            size: 12,
                            color: isDark
                                ? AppColors.darkTextQuaternary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                    const SizedBox(width: 4),
                    // Folder icon
                    Icon(
                      isExpanded ? LucideIcons.folderOpen : LucideIcons.folder,
                      size: 14,
                      color: isSelected
                          ? (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary)
                          : (isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 6),
                    // Name
                    Expanded(
                      child: Text(
                        folder.name,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary)
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Count
                    Text(
                      '${folder.secretsCount}',
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
                      isDark: isDark,
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
    showFolderContextMenu(
      context: context,
      ref: ref,
      folder: folder,
      isDark: isDark,
    );
  }
}

// ─── Empty hint ───

class _EmptyFolderHint extends StatelessWidget {
  const _EmptyFolderHint({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        'No folders yet',
        style: AppTypography.caption.copyWith(
          color: isDark
              ? AppColors.darkTextQuaternary
              : AppColors.lightTextTertiary,
        ),
      ),
    );
  }
}
