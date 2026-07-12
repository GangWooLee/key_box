import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/database/database.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/audit_providers.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(auditEventsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.dashboard);
            }
          },
          tooltip: 'Back',
        ),
        title: const Text('Audit Log'),
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No audit events yet',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _AuditEventTile(event: events[index]),
                ),
              ),
              // Load more button if we got a full page
              if (events.length % AppConstants.auditPageSize == 0)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(auditPageProvider.notifier).state++;
                    },
                    child: const Text('Load more'),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _AuditEventTile extends StatelessWidget {
  const _AuditEventTile({required this.event});
  final AuditEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _parseMeta(event.metadata);
    final secretName = meta['name'] as String?;

    return ListTile(
      leading: Icon(_actionIcon(event.action), size: 20),
      title: Text(
        _actionLabel(event.action),
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: secretName != null
          ? Text(secretName, style: theme.textTheme.bodySmall)
          : null,
      trailing: Text(
        DateFormatters.timeAgo(event.createdAt),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  Map<String, dynamic> _parseMeta(String? metadata) {
    if (metadata == null || metadata.isEmpty) return {};
    try {
      return jsonDecode(metadata) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  IconData _actionIcon(String action) {
    return switch (action) {
      'secret.create' => Icons.add_circle_outline,
      'secret.read' => Icons.visibility_outlined,
      'secret.update' => Icons.edit_outlined,
      'secret.delete' => Icons.delete_outline,
      'vault.setup' => Icons.lock_open,
      'vault.unlock' => Icons.lock_outline,
      _ => Icons.info_outline,
    };
  }

  String _actionLabel(String action) {
    return switch (action) {
      'secret.create' => 'Secret created',
      'secret.read' => 'Secret revealed',
      'secret.update' => 'Secret updated',
      'secret.delete' => 'Secret deleted',
      'vault.setup' => 'Vault set up',
      'vault.unlock' => 'Vault unlocked',
      _ => action,
    };
  }
}
