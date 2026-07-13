import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../domain/secrets_providers.dart';

/// V9 folder dialogs (DESIGN.md §modals): lamp cards over the surface scrim,
/// hairline edges, one filled button per dialog — and destruction is always
/// an error *outline*, never a fill.

ShapeBorder _lampCardShape(KbSurface s) => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(AppRadii.lg),
  side: BorderSide(color: s.hairline),
);

InputDecoration _folderNameDecoration(KbSurface s) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    hintText: 'Folder name',
    hintStyle: AppTypography.bodySmall.copyWith(color: s.muted),
    filled: true,
    // One tonal step down from the lamp card.
    fillColor: s.canvas,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm + 4,
      vertical: AppSpacing.sm + 2,
    ),
    border: border(s.hairline),
    enabledBorder: border(s.hairline),
    focusedBorder: border(s.accent),
  );
}

ButtonStyle _primaryButtonStyle(KbSurface s) => ElevatedButton.styleFrom(
  backgroundColor: s.accent,
  foregroundColor: s.onAccent,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
  ),
  minimumSize: const Size(kMinHitTarget, kMinHitTarget),
);

/// Show a dialog to create a new folder.
void showCreateFolderDialog(
  BuildContext context,
  WidgetRef ref, {
  int? parentId,
}) {
  final s = Theme.of(context).extension<KbSurface>()!;
  final controller = TextEditingController();

  showDialog(
    context: context,
    barrierColor: s.scrim,
    builder: (ctx) => AlertDialog(
      backgroundColor: s.lamp,
      shape: _lampCardShape(s),
      title: Text(
        parentId != null ? 'New Subfolder' : 'New Folder',
        style: AppTypography.titleSmall.copyWith(color: s.ink),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        cursorColor: s.accent,
        decoration: _folderNameDecoration(s),
        style: AppTypography.bodySmall.copyWith(color: s.ink),
        onSubmitted: (_) => _createFolder(ctx, ref, controller, parentId),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: AppTypography.bodySmall.copyWith(color: s.muted),
          ),
        ),
        ElevatedButton(
          style: _primaryButtonStyle(s),
          onPressed: () => _createFolder(ctx, ref, controller, parentId),
          child: const Text('Create'),
        ),
      ],
    ),
  ).then((_) => controller.dispose());
}

Future<void> _createFolder(
  BuildContext ctx,
  WidgetRef ref,
  TextEditingController controller,
  int? parentId,
) async {
  final name = controller.text.trim();
  if (name.isEmpty) return;

  final auth = ref.read(authProvider);
  if (auth is! AuthUnlocked) return;
  final db = ref.read(databaseProvider);

  await db.folderDao.create(
    vaultId: auth.vaultId,
    name: name,
    parentId: parentId,
  );
  if (ctx.mounted) Navigator.pop(ctx);
}

/// Show a dialog to rename a folder.
void showRenameFolderDialog(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) {
  final s = Theme.of(context).extension<KbSurface>()!;
  final controller = TextEditingController(text: folder.name);

  Future<void> rename(BuildContext ctx) async {
    final name = controller.text.trim();
    if (name.isEmpty || name == folder.name) return;
    final db = ref.read(databaseProvider);
    await db.folderDao.updateFolder(folder.id, name: name);
    if (ctx.mounted) Navigator.pop(ctx);
  }

  showDialog(
    context: context,
    barrierColor: s.scrim,
    builder: (ctx) => AlertDialog(
      backgroundColor: s.lamp,
      shape: _lampCardShape(s),
      title: Text(
        'Rename Folder',
        style: AppTypography.titleSmall.copyWith(color: s.ink),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        cursorColor: s.accent,
        decoration: _folderNameDecoration(s),
        style: AppTypography.bodySmall.copyWith(color: s.ink),
        onSubmitted: (_) => rename(ctx),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: AppTypography.bodySmall.copyWith(color: s.muted),
          ),
        ),
        ElevatedButton(
          style: _primaryButtonStyle(s),
          onPressed: () => rename(ctx),
          child: const Text('Rename'),
        ),
      ],
    ),
  ).then((_) => controller.dispose());
}

/// Show a confirmation dialog to delete a folder.
///
/// Destructive action = error outline, no fill (components matrix). The
/// confirm dialog itself is the friction — no alarm colors beyond the clay
/// outline.
void showDeleteFolderDialog(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) {
  final s = Theme.of(context).extension<KbSurface>()!;

  showDialog(
    context: context,
    barrierColor: s.scrim,
    builder: (ctx) => AlertDialog(
      backgroundColor: s.lamp,
      shape: _lampCardShape(s),
      title: Text(
        'Delete Folder',
        style: AppTypography.titleSmall.copyWith(color: s.ink),
      ),
      content: Text(
        'Delete "${folder.name}"? '
        '${folder.secretsCount > 0 ? 'This folder contains ${folder.secretsCount} secret(s). ' : ''}'
        'Secrets will not be deleted, only unlinked from this folder.',
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
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: s.error,
            side: BorderSide(color: s.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            minimumSize: const Size(kMinHitTarget, kMinHitTarget),
          ),
          onPressed: () async {
            final db = ref.read(databaseProvider);
            // Unlink all secrets from this folder
            await db.folderSecretsDao.unlinkAllForFolder(folder.id);
            // Delete the folder
            await db.folderDao.deleteFolder(folder.id);
            // If this was selected, clear selection
            if (ref.read(selectedFolderIdProvider) == folder.id) {
              ref.read(selectedFolderIdProvider.notifier).state = null;
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

/// Show a context menu for a folder (right-click).
///
/// Lamp popover + hairline; only the destructive item reads in error.
void showFolderContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Folder folder,
}) {
  final s = Theme.of(context).extension<KbSurface>()!;
  final renderBox = context.findRenderObject() as RenderBox;
  final position = renderBox.localToGlobal(Offset.zero);

  showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx + renderBox.size.width / 2,
      position.dy + renderBox.size.height,
      position.dx + renderBox.size.width,
      position.dy + renderBox.size.height + 100,
    ),
    color: s.lamp,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      side: BorderSide(color: s.hairline),
    ),
    items: [
      PopupMenuItem(
        value: 'subfolder',
        child: Text(
          'New Subfolder',
          style: AppTypography.bodySmall.copyWith(color: s.ink),
        ),
      ),
      PopupMenuItem(
        value: 'rename',
        child: Text(
          'Rename',
          style: AppTypography.bodySmall.copyWith(color: s.ink),
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Text(
          'Delete',
          style: AppTypography.bodySmall.copyWith(color: s.error),
        ),
      ),
    ],
  ).then((action) {
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'subfolder':
        showCreateFolderDialog(context, ref, parentId: folder.id);
      case 'rename':
        showRenameFolderDialog(context, ref, folder);
      case 'delete':
        showDeleteFolderDialog(context, ref, folder);
    }
  });
}
