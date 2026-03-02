import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/secrets_providers.dart';

class SecretList extends ConsumerWidget {
  const SecretList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secretsAsync = ref.watch(secretsProvider);
    final selectedSecretId = ref.watch(selectedSecretIdProvider);
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Text('Secrets', style: theme.textTheme.labelLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: selectedFolderId != null
                    ? () => _showCreateSecretDialog(context, ref, selectedFolderId)
                    : null,
                tooltip: 'New Secret (Cmd+N)',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // List
        Expanded(
          child: secretsAsync.when(
            data: (secrets) {
              if (selectedFolderId == null) {
                return Center(
                  child: Text(
                    'Select a folder',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }
              if (secrets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.vpn_key_outlined, size: 48,
                          color: theme.textTheme.bodySmall?.color),
                      const SizedBox(height: 12),
                      Text('No secrets yet', style: theme.textTheme.bodySmall),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: secrets.length,
                itemBuilder: (context, index) {
                  final secret = secrets[index];
                  final isSelected = secret.id == selectedSecretId;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor:
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                    title: Text(
                      secret.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        if (secret.serviceName != null) ...[
                          Text(
                            secret.serviceName!,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          DateFormatters.timeAgo(secret.updatedAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: _SecretTypeBadge(type: secret.secretType),
                    onTap: () {
                      ref.read(selectedSecretIdProvider.notifier).state = secret.id;
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  void _showCreateSecretDialog(BuildContext context, WidgetRef ref, int folderId) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Secret'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Secret Value'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || valueController.text.isEmpty) return;
              final ops = ref.read(secretOpsProvider);
              await ops.create(
                name: nameController.text,
                value: valueController.text,
                folderId: folderId,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _SecretTypeBadge extends StatelessWidget {
  const _SecretTypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.replaceAll('_', ' '),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
      ),
    );
  }
}
