import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../domain/secrets_providers.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('Folders', style: theme.textTheme.labelLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => _showCreateFolderDialog(context, ref),
                tooltip: 'New Folder',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),

        // Folder list
        Expanded(
          child: foldersAsync.when(
            data: (folders) {
              if (folders.isEmpty) {
                return Center(
                  child: Text(
                    'No folders',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }

              // Auto-select first folder if none selected
              if (selectedFolderId == null && folders.isNotEmpty) {
                Future.microtask(
                  () => ref.read(selectedFolderIdProvider.notifier).state =
                      folders.first.id,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  final isSelected = folder.id == selectedFolderId;

                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    leading: const Icon(Icons.folder_outlined, size: 18),
                    title: Text(
                      folder.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                    trailing: Text(
                      '${folder.secretsCount}',
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () {
                      ref.read(selectedFolderIdProvider.notifier).state = folder.id;
                      ref.read(selectedSecretIdProvider.notifier).state = null;
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),

        // Bottom actions
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.history, size: 18),
            title: Text('Audit Log', style: theme.textTheme.bodyMedium),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onTap: () {
              // TODO: navigate to audit log
            },
          ),
        ),
      ],
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Folder name'),
          onSubmitted: (_) => _createFolder(context, ref, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createFolder(context, ref, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref, String name) async {
    if (name.trim().isEmpty) return;
    final db = ref.read(databaseProvider);
    final auth = ref.read(authProvider);
    if (auth is! AuthUnlocked) return;

    await db.folderDao.create(vaultId: auth.vaultId, name: name.trim());
    if (context.mounted) Navigator.pop(context);
  }
}
