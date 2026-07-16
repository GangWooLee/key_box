import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../settings/domain/settings_preferences.dart';
import '../../domain/secrets_providers.dart';
import 'environment_badge.dart';
import 'sheet_modal.dart';

/// Masked value placeholder — a FIXED dot count so the mask never leaks the
/// value's length (DESIGN.md §detail).
const _maskedValue = '••••••••••••••••••••';

/// The 340px detail panel — "under the lamp" (DESIGN.md §detail).
///
/// The lamp surface comes from the dashboard container; everything inside
/// reads KbSurface tokens. Values are mono and masked by default; reveal and
/// copy are ghost actions (no fill — the value is the loudest thing here).
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
  int? _autoRevealScheduledFor;

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedSecretIdProvider);
    final revealDefault = ref.watch(revealByDefaultProvider);
    final s = Theme.of(context).extension<KbSurface>()!;

    // Switching secrets re-masks the value (security: never carry a revealed
    // value across selections) and re-arms the reveal-default auto-reveal.
    ref.listen<int?>(selectedSecretIdProvider, (_, __) {
      if (!mounted) return;
      setState(() {
        _isRevealed = false;
        _decryptedValue = null;
        _copied = false;
      });
    });

    if (selectedId == null) {
      return const _EmptyDetail();
    }

    final secretAsync = ref.watch(secretDetailProvider(selectedId));

    // Re-mask the displayed value when the underlying secret's content changes
    // (an in-place edit bumps recordVersion). Copy/reveal already re-decrypt the
    // fresh object, so this only keeps the on-screen revealed text from lagging.
    ref.listen(secretDetailProvider(selectedId), (prev, next) {
      final pv = prev?.valueOrNull?.recordVersion;
      final nv = next.valueOrNull?.recordVersion;
      if (pv != null && nv != null && pv != nv && mounted) {
        setState(() {
          _isRevealed = false;
          _decryptedValue = null;
          _copied = false;
        });
      }
    });

    return secretAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: s.accent)),
      error: (_, __) => const _EmptyDetail(),
      data: (secret) {
        if (secret == null) {
          return const _EmptyDetail();
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: KeyedSubtree(
            key: ValueKey(secret.id),
            child: _buildDetail(context, secret, s, revealDefault),
          ),
        );
      },
    );
  }

  Widget _buildDetail(
    BuildContext context,
    Secret secret,
    KbSurface s,
    bool revealDefault,
  ) {
    // Reveal-by-default: auto-reveal each newly-opened secret once (settings
    // preference; off by default — masking is the safer posture).
    if (revealDefault &&
        !_isRevealed &&
        _decryptedValue == null &&
        _autoRevealScheduledFor != secret.id) {
      _autoRevealScheduledFor = secret.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_isRevealed &&
            ref.read(selectedSecretIdProvider) == secret.id) {
          _toggleReveal(secret);
        }
      });
    }

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
                        style: AppTypography.detailName.copyWith(color: s.ink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    EnvironmentBadge(environment: secret.environment),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Service + Time
                Row(
                  children: [
                    if (secret.serviceName != null &&
                        secret.serviceName!.isNotEmpty) ...[
                      Text(
                        secret.serviceName!,
                        style: AppTypography.bodySmall.copyWith(color: s.muted),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    Text(
                      DateFormatters.timeAgo(secret.updatedAt),
                      style: AppTypography.mono.copyWith(
                        fontSize: 11,
                        color: s.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Value Well
                _ValueBox(
                  isRevealed: _isRevealed,
                  decryptedValue: _decryptedValue,
                  copied: _copied,
                  onReveal: () => _toggleReveal(secret),
                  onCopy: () => _copyToClipboard(secret),
                ),
                const SizedBox(height: AppSpacing.md),

                Divider(height: 1, color: s.hairline),
                const SizedBox(height: AppSpacing.xs),

                // Collapsible Details
                _CollapsibleSection(
                  title: 'Details',
                  isExpanded: _detailsExpanded,
                  onToggle: () =>
                      setState(() => _detailsExpanded = !_detailsExpanded),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        label: 'Type',
                        value: secret.secretType.replaceAll('_', ' '),
                      ),
                      _DetailRow(
                        label: 'Created',
                        value: DateFormatters.full(secret.createdAt),
                      ),
                      _DetailRow(
                        label: 'Updated',
                        value: DateFormatters.full(secret.updatedAt),
                      ),
                      _DetailRow(
                        label: 'Accessed',
                        value: '${secret.accessCount} times',
                      ),
                      if (secret.notes != null && secret.notes!.isNotEmpty)
                        _DetailRow(label: 'Notes', value: secret.notes!),
                      if (secret.tags != null && secret.tags!.isNotEmpty)
                        _DetailRow(label: 'Tags', value: secret.tags!),
                    ],
                  ),
                ),

                // Collapsible Folders (M:N)
                _CollapsibleSection(
                  title: 'Folders',
                  isExpanded: _foldersExpanded,
                  onToggle: () =>
                      setState(() => _foldersExpanded = !_foldersExpanded),
                  child: _FolderLinksSection(
                    secretId: secret.id,
                    homeFolderId: secret.folderId,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Footer action bar
        _FooterBar(
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
    final s = Theme.of(context).extension<KbSurface>()!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: s.lamp,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: s.hairline),
        ),
        title: Text(
          'Delete Secret',
          style: AppTypography.titleSmall.copyWith(color: s.ink),
        ),
        content: Text(
          'Are you sure you want to delete "${secret.name}"? This action cannot be undone.',
          style: AppTypography.bodySmall.copyWith(color: s.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(color: s.muted),
            ),
          ),
          // Destructive = outline error, never a fill (components matrix).
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: s.error,
              side: BorderSide(color: s.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
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

// ─── Empty Detail (standby lamp — the panel is never blank) ───

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: s.accent, shape: BoxShape.circle),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'select a secret',
            style: AppTypography.mono.copyWith(fontSize: 12.5, color: s.muted),
          ),
        ],
      ),
    );
  }
}

// ─── Value Well ───

class _ValueBox extends StatelessWidget {
  const _ValueBox({
    required this.isRevealed,
    required this.decryptedValue,
    required this.copied,
    required this.onReveal,
    required this.onCopy,
  });

  final bool isRevealed;
  final String? decryptedValue;
  final bool copied;
  final VoidCallback onReveal;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final revealed = isRevealed && decryptedValue != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.smd),
      decoration: BoxDecoration(
        // One step down from the lamp — the value sits in a sunken well.
        color: s.canvas,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: s.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Long values (JWT/JSON) wrap and scroll vertically — never
          // horizontally (DESIGN.md §detail).
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Text(
                revealed ? decryptedValue! : _maskedValue,
                style: AppTypography.mono.copyWith(
                  fontSize: 12.5,
                  color: s.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _GhostButton(
                label: isRevealed ? 'Hide' : 'Reveal',
                // Icon mirrors STATE (revealed = open eye, masked = eyeOff),
                // matching the auth screens; the label carries the action.
                icon: isRevealed ? LucideIcons.eye : LucideIcons.eyeOff,
                onTap: onReveal,
              ),
              const SizedBox(width: AppSpacing.sm),
              _GhostButton(
                label: copied ? 'copied' : 'Copy',
                icon: copied ? LucideIcons.check : LucideIcons.copy,
                isLive: copied,
                onTap: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ghost action: accent text, no fill — reveal/copy stay frictionless and
/// quiet (components matrix §고스트).
class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLive = false,
  });

  final String label;
  final IconData icon;
  final bool isLive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final color = isLive ? s.live : s.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: s.hover,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: color,
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
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: s.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xsm),
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: s.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            // A distinct header→child gap (top) so the header's hover fill
            // doesn't crowd the content; bottom on the same 8pt rhythm gives
            // each section room from the next.
            padding: const EdgeInsets.only(
              left: 20,
              top: AppSpacing.smd,
              bottom: AppSpacing.md,
            ),
            child: child,
          ),
      ],
    );
  }
}

// ─── Detail Row ───

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xsm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: s.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              // Metadata values (timestamps, counts, types) are mono.
              style: AppTypography.mono.copyWith(fontSize: 12, color: s.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Footer Bar ───

class _FooterBar extends StatelessWidget {
  const _FooterBar({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: s.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: s.accent,
                foregroundColor: s.onAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                textStyle: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Edit'),
            ),
          ),
          const SizedBox(width: AppSpacing.smd),
          TextButton(
            onPressed: onDelete,
            child: Text(
              'Delete',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: s.error,
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
  });

  final int secretId;
  final int homeFolderId;

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
                ...linked.map(
                  (folder) => _FolderChip(
                    folder: folder,
                    isHome: folder.id == homeFolderId,
                    onRemove: folder.id == homeFolderId
                        ? null
                        : () async {
                            await ref
                                .read(secretOpsProvider)
                                .unlinkFromFolder(secretId, folder.id);
                            // Refresh the chips: folderIdsBySecretProvider is a
                            // one-shot cache that would otherwise show the
                            // just-removed folder.
                            ref.invalidate(folderIdsBySecretProvider(secretId));
                          },
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _AddFolderButton(secretId: secretId, linkedFolderIds: ids),
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
    this.onRemove,
  });

  final Folder folder;
  final bool isHome;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isHome ? LucideIcons.home : LucideIcons.folder,
            size: 12,
            color: s.muted,
          ),
          const SizedBox(width: AppSpacing.xsm),
          Expanded(
            child: Text(
              folder.name,
              style: AppTypography.caption.copyWith(color: s.muted),
            ),
          ),
          if (onRemove != null)
            SizedBox(
              width: 20,
              height: 20,
              child: IconButton(
                onPressed: onRemove,
                icon: Icon(LucideIcons.x, size: 10, color: s.muted),
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
  });

  final int secretId;
  final List<int> linkedFolderIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showFolderPicker(context, ref),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(LucideIcons.plus, size: 12, color: s.accent),
              const SizedBox(width: AppSpacing.xsm),
              Text(
                'Add to folder',
                style: AppTypography.caption.copyWith(color: s.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFolderPicker(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final allFolders = ref.read(foldersProvider);
    final folders = allFolders.valueOrNull ?? [];
    final unlinked = folders
        .where((f) => !linkedFolderIds.contains(f.id))
        .toList();

    if (unlinked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already linked to all folders')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: s.lamp,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: s.hairline),
        ),
        title: Text(
          'Add to Folder',
          style: AppTypography.titleSmall.copyWith(color: s.ink),
        ),
        content: SizedBox(
          width: 280,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unlinked.length,
            itemBuilder: (context, index) {
              final folder = unlinked[index];
              return ListTile(
                leading: Icon(LucideIcons.folder, size: 16, color: s.muted),
                title: Text(
                  folder.name,
                  style: AppTypography.bodySmall.copyWith(color: s.ink),
                ),
                onTap: () async {
                  await ref
                      .read(secretOpsProvider)
                      .linkToFolder(secretId, folder.id);
                  // Refresh the chips: folderIdsBySecretProvider is a one-shot
                  // cache that would otherwise omit the just-added folder.
                  ref.invalidate(folderIdsBySecretProvider(secretId));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(color: s.muted),
            ),
          ),
        ],
      ),
    );
  }
}
