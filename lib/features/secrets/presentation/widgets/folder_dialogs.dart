import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../domain/secrets_providers.dart';

/// Show a dialog to create a new folder.
void showCreateFolderDialog(
  BuildContext context,
  WidgetRef ref, {
  int? parentId,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.authCardBg : null,
      title: Text(
        parentId != null ? 'New Subfolder' : 'New Folder',
        style: AppTypography.titleSmall.copyWith(
          color: isDark ? AppColors.darkTextPrimary : null,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Folder name',
          filled: true,
          fillColor: isDark ? AppColors.authInputBg : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark
                  ? AppColors.darkGlassBorder
                  : AppColors.lightBorderPrimary,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark
                  ? AppColors.darkGlassBorder
                  : AppColors.lightBorderPrimary,
            ),
          ),
        ),
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.darkTextPrimary : null,
        ),
        onSubmitted: (_) => _createFolder(ctx, ref, controller, parentId),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextTertiary : null,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonPrimary,
            foregroundColor: AppColors.buttonPrimaryText,
          ),
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final controller = TextEditingController(text: folder.name);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.authCardBg : null,
      title: Text(
        'Rename Folder',
        style: AppTypography.titleSmall.copyWith(
          color: isDark ? AppColors.darkTextPrimary : null,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Folder name',
          filled: true,
          fillColor: isDark ? AppColors.authInputBg : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark
                  ? AppColors.darkGlassBorder
                  : AppColors.lightBorderPrimary,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark
                  ? AppColors.darkGlassBorder
                  : AppColors.lightBorderPrimary,
            ),
          ),
        ),
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.darkTextPrimary : null,
        ),
        onSubmitted: (_) async {
          final name = controller.text.trim();
          if (name.isEmpty || name == folder.name) return;
          final db = ref.read(databaseProvider);
          await db.folderDao.updateFolder(folder.id, name: name);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextTertiary : null,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonPrimary,
            foregroundColor: AppColors.buttonPrimaryText,
          ),
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isEmpty || name == folder.name) return;
            final db = ref.read(databaseProvider);
            await db.folderDao.updateFolder(folder.id, name: name);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Rename'),
        ),
      ],
    ),
  ).then((_) => controller.dispose());
}

/// Show a confirmation dialog to delete a folder.
void showDeleteFolderDialog(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.authCardBg : null,
      title: Text(
        'Delete Folder',
        style: AppTypography.titleSmall.copyWith(
          color: isDark ? AppColors.darkTextPrimary : null,
        ),
      ),
      content: Text(
        'Delete "${folder.name}"? '
        '${folder.secretsCount > 0 ? 'This folder contains ${folder.secretsCount} secret(s). ' : ''}'
        'Secrets will not be deleted, only unlinked from this folder.',
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
void showFolderContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Folder folder,
  required bool isDark,
}) {
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
    color: isDark ? AppColors.darkSurfaceCard : null,
    items: [
      PopupMenuItem(
        value: 'subfolder',
        child: Text(
          'New Subfolder',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : null,
          ),
        ),
      ),
      PopupMenuItem(
        value: 'rename',
        child: Text(
          'Rename',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : null,
          ),
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Text(
          'Delete',
          style: AppTypography.bodySmall.copyWith(color: AppColors.errorText),
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
