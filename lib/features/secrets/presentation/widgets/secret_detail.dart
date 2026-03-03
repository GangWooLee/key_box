import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/secrets_providers.dart';
import 'environment_badge.dart';
import 'sheet_modal.dart';

class SecretDetail extends ConsumerStatefulWidget {
  const SecretDetail({super.key});

  @override
  ConsumerState<SecretDetail> createState() => _SecretDetailState();
}

class _SecretDetailState extends ConsumerState<SecretDetail> {
  String? _decryptedValue;
  bool _isRevealed = false;
  bool _copied = false;
  bool _detailsExpanded = false;
  bool _foldersExpanded = false;

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedSecretIdProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (selectedId == null) {
      return _EmptyDetail(isDark: isDark);
    }

    final secretAsync = ref.watch(secretDetailProvider(selectedId));

    return secretAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _EmptyDetail(isDark: isDark),
      data: (secret) {
        if (secret == null) {
          return _EmptyDetail(isDark: isDark);
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(secret.id),
            child: _buildDetail(context, secret, isDark),
          ),
        );
      },
    );
  }

  Widget _buildDetail(BuildContext context, Secret secret, bool isDark) {
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Environment Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        secret.name,
                        style: AppTypography.detailName.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    EnvironmentBadge(environment: secret.environment),
                  ],
                ),
                const SizedBox(height: 8),

                // Service + Time
                Row(
                  children: [
                    if (secret.serviceName != null && secret.serviceName!.isNotEmpty) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.serviceDotColor(secret.serviceName!),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        secret.serviceName!,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    Text(
                      DateFormatters.timeAgo(secret.updatedAt),
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Value Box
                _ValueBox(
                  isDark: isDark,
                  isRevealed: _isRevealed,
                  decryptedValue: _decryptedValue,
                  copied: _copied,
                  onReveal: () => _toggleReveal(secret),
                  onCopy: () => _copyToClipboard(secret),
                ),
                const SizedBox(height: 16),

                // Divider
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkDividerMedium : AppColors.lightBorderSubtle,
                ),
                const SizedBox(height: 4),

                // Collapsible Details
                _CollapsibleSection(
                  title: 'Details',
                  isDark: isDark,
                  isExpanded: _detailsExpanded,
                  onToggle: () => setState(() => _detailsExpanded = !_detailsExpanded),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(label: 'Type', value: secret.secretType.replaceAll('_', ' '), isDark: isDark),
                      _DetailRow(label: 'Created', value: DateFormatters.full(secret.createdAt), isDark: isDark),
                      _DetailRow(label: 'Updated', value: DateFormatters.full(secret.updatedAt), isDark: isDark),
                      _DetailRow(label: 'Accessed', value: '${secret.accessCount} times', isDark: isDark),
                      if (secret.notes != null && secret.notes!.isNotEmpty)
                        _DetailRow(label: 'Notes', value: secret.notes!, isDark: isDark),
                      if (secret.tags != null && secret.tags!.isNotEmpty)
                        _DetailRow(label: 'Tags', value: secret.tags!, isDark: isDark),
                    ],
                  ),
                ),

                // Collapsible Folders (M:N)
                _CollapsibleSection(
                  title: 'Folders',
                  isDark: isDark,
                  isExpanded: _foldersExpanded,
                  onToggle: () => setState(() => _foldersExpanded = !_foldersExpanded),
                  child: _FolderLinksSection(
                    secretId: secret.id,
                    homeFolderId: secret.folderId,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Footer action bar
        _FooterBar(
          isDark: isDark,
          onEdit: () => _showEditSheet(context, secret),
          onDelete: () => _confirmDelete(context, secret),
        ),
      ],
    );
  }

  Future<void> _toggleReveal(Secret secret) async {
    if (_isRevealed) {
      setState(() {
        _isRevealed = false;
        _decryptedValue = null;
      });
    } else {
      final ops = ref.read(secretOpsProvider);
      final value = await ops.reveal(secret);
      if (mounted) {
        setState(() {
          _decryptedValue = value;
          _isRevealed = true;
        });
      }
    }
  }

  Future<void> _copyToClipboard(Secret secret) async {
    final ops = ref.read(secretOpsProvider);
    final value = await ops.decrypt(secret);
    if (value == null) return;

    await ref.read(clipboardServiceProvider).copyWithAutoClear(value);
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  void _showEditSheet(BuildContext context, Secret secret) {
    showSecretSheetModal(context: context, ref: ref, secret: secret);
  }

  void _confirmDelete(BuildContext context, Secret secret) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.authCardBg : null,
        title: Text(
          'Delete Secret',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : null,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${secret.name}"? This action cannot be undone.',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final ops = ref.read(secretOpsProvider);
              await ops.delete(secret);
              ref.read(selectedSecretIdProvider.notifier).state = null;
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Detail ───

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.keyRound,
            size: 48,
            color: isDark ? AppColors.darkTextQuaternary : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a secret to view details',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Value Box ───

class _ValueBox extends StatelessWidget {
  const _ValueBox({
    required this.isDark,
    required this.isRevealed,
    required this.decryptedValue,
    required this.copied,
    required this.onReveal,
    required this.onCopy,
  });

  final bool isDark;
  final bool isRevealed;
  final String? decryptedValue;
  final bool copied;
  final VoidCallback onReveal;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkValueBoxBg : AppColors.lightSurfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkValueBoxStroke : AppColors.lightBorderPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRevealed && decryptedValue != null
                ? decryptedValue!
                : '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
            style: AppTypography.mono.copyWith(
              color: isDark ? AppColors.darkRowText2 : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SmallButton(
                label: isRevealed ? 'Hide' : 'Reveal',
                icon: isRevealed ? LucideIcons.eyeOff : LucideIcons.eye,
                isDark: isDark,
                onTap: onReveal,
              ),
              const SizedBox(width: 6),
              _SmallButton(
                label: copied ? 'Copied!' : 'Copy',
                icon: copied ? LucideIcons.check : LucideIcons.copy,
                isDark: isDark,
                isSuccess: copied,
                onTap: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.isSuccess = false,
  });

  final String label;
  final IconData icon;
  final bool isDark;
  final bool isSuccess;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSuccess
          ? AppColors.success
          : AppColors.buttonPrimary,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.buttonPrimaryText),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.buttonPrimaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Collapsible Section ───

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.isDark,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: isDark ? AppColors.brand500 : AppColors.brand600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.brand500 : AppColors.brand600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: child,
          ),
      ],
    );
  }
}

// ─── Detail Row ───

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Footer Bar ───

class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDividerStrong : AppColors.lightBorderPrimary,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.buttonPrimaryText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
              ),
              child: const Text('Edit'),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onDelete,
            child: Text(
              'Delete',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.errorText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Folder Links Section (M:N) ───

class _FolderLinksSection extends ConsumerWidget {
  const _FolderLinksSection({
    required this.secretId,
    required this.homeFolderId,
    required this.isDark,
  });

  final int secretId;
  final int homeFolderId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderIds = ref.watch(folderIdsBySecretProvider(secretId));

    return folderIds.when(
      data: (ids) {
        final allFolders = ref.watch(foldersProvider);
        return allFolders.when(
          data: (folders) {
            final linked = folders.where((f) => ids.contains(f.id)).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...linked.map((folder) => _FolderChip(
                      folder: folder,
                      isHome: folder.id == homeFolderId,
                      isDark: isDark,
                      onRemove: folder.id == homeFolderId
                          ? null
                          : () {
                              ref
                                  .read(secretOpsProvider)
                                  .unlinkFromFolder(secretId, folder.id);
                            },
                    )),
                const SizedBox(height: 4),
                _AddFolderButton(
                  secretId: secretId,
                  linkedFolderIds: ids,
                  isDark: isDark,
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.folder,
    required this.isHome,
    required this.isDark,
    this.onRemove,
  });

  final Folder folder;
  final bool isHome;
  final bool isDark;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isHome ? LucideIcons.home : LucideIcons.folder,
            size: 12,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              folder.name,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          if (onRemove != null)
            SizedBox(
              width: 20,
              height: 20,
              child: IconButton(
                onPressed: onRemove,
                icon: Icon(
                  LucideIcons.x,
                  size: 10,
                  color: isDark ? AppColors.darkTextQuaternary : AppColors.lightTextTertiary,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Unlink from folder',
              ),
            ),
        ],
      ),
    );
  }
}

class _AddFolderButton extends ConsumerWidget {
  const _AddFolderButton({
    required this.secretId,
    required this.linkedFolderIds,
    required this.isDark,
  });

  final int secretId;
  final List<int> linkedFolderIds;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showFolderPicker(context, ref),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                LucideIcons.plus,
                size: 12,
                color: isDark ? AppColors.brand500 : AppColors.brand600,
              ),
              const SizedBox(width: 6),
              Text(
                'Add to folder',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.brand500 : AppColors.brand600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFolderPicker(BuildContext context, WidgetRef ref) {
    final allFolders = ref.read(foldersProvider);
    final folders = allFolders.valueOrNull ?? [];
    final unlinked =
        folders.where((f) => !linkedFolderIds.contains(f.id)).toList();

    if (unlinked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already linked to all folders')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.authCardBg : null,
        title: Text(
          'Add to Folder',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : null,
          ),
        ),
        content: SizedBox(
          width: 280,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unlinked.length,
            itemBuilder: (context, index) {
              final folder = unlinked[index];
              return ListTile(
                leading: Icon(
                  LucideIcons.folder,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextSecondary,
                ),
                title: Text(
                  folder.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () {
                  ref
                      .read(secretOpsProvider)
                      .linkToFolder(secretId, folder.id);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
