import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../services/clipboard_service.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../domain/secrets_providers.dart';

final _clipboardService = ClipboardService();

class SecretDetail extends ConsumerStatefulWidget {
  const SecretDetail({super.key});

  @override
  ConsumerState<SecretDetail> createState() => _SecretDetailState();
}

class _SecretDetailState extends ConsumerState<SecretDetail> {
  String? _decryptedValue;
  bool _isRevealed = false;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedSecretIdProvider);
    final theme = Theme.of(context);

    if (selectedId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vpn_key, size: 64, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text('Select a secret to view details',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    final db = ref.read(databaseProvider);

    return FutureBuilder(
      future: db.secretDao.getById(selectedId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final secret = snapshot.data!;
        return _buildDetail(context, secret);
      },
    );
  }

  Widget _buildDetail(BuildContext context, dynamic secret) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(secret.name as String, style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),

          // Secret value section
          _buildSection(
            context,
            'Value',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isRevealed && _decryptedValue != null
                          ? _decryptedValue!
                          : '••••••••••••••••••••',
                      style: AppTypography.mono.copyWith(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reveal button
                  IconButton(
                    icon: Icon(_isRevealed ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => _toggleReveal(secret),
                    tooltip: _isRevealed ? 'Hide' : 'Reveal',
                  ),
                  // Copy button
                  IconButton(
                    icon: Icon(_copied ? Icons.check : Icons.copy),
                    onPressed: () => _copyToClipboard(secret),
                    tooltip: 'Copy',
                    color: _copied ? AppColors.success : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Metadata grid
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              if (secret.serviceName != null)
                _buildMetaItem(context, 'Service', secret.serviceName as String),
              _buildMetaItem(context, 'Type', (secret.secretType as String).replaceAll('_', ' ')),
              if (secret.environment != null)
                _buildMetaItem(context, 'Environment', secret.environment as String),
              _buildMetaItem(context, 'Created', DateFormatters.full(secret.createdAt as DateTime)),
              _buildMetaItem(context, 'Updated', DateFormatters.full(secret.updatedAt as DateTime)),
              _buildMetaItem(context, 'Accessed', '${secret.accessCount} times'),
            ],
          ),

          if (secret.notes != null && (secret.notes as String).isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection(context, 'Notes',
                child: Text(secret.notes as String, style: theme.textTheme.bodyMedium)),
          ],

          if (secret.tags != null && (secret.tags as String).isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection(context, 'Tags',
                child: Wrap(
                  spacing: 8,
                  children: (secret.tags as String)
                      .split(',')
                      .map((tag) => Chip(label: Text(tag.trim())))
                      .toList(),
                )),
          ],

          const SizedBox(height: 32),

          // Actions
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: edit dialog
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, secret),
                icon: const Icon(Icons.delete, size: 16, color: AppColors.error),
                label: const Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildMetaItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Future<void> _toggleReveal(dynamic secret) async {
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

  Future<void> _copyToClipboard(dynamic secret) async {
    final ops = ref.read(secretOpsProvider);
    final value = await ops.decrypt(secret);
    if (value == null) return;

    await _clipboardService.copyWithAutoClear(value);
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  void _confirmDelete(BuildContext context, dynamic secret) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Secret'),
        content: Text('Are you sure you want to delete "${secret.name}"?'),
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
