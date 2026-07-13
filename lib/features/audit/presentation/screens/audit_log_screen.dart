import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/audit_providers.dart';

/// The audit ledger (DESIGN.md §audit) — an all-mono timeline on the working
/// surface (bench/terminal). The physicality of a ledger: no icons per row,
/// no color coding — action, subject, timestamp, in fixed-width type.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(auditEventsProvider);
    final s = Theme.of(context).extension<KbSurface>()!;

    return Scaffold(
      backgroundColor: s.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 18, color: s.muted),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.dashboard);
            }
          },
          tooltip: 'Back',
        ),
        title: Text(
          'AUDIT LOG',
          style: AppTypography.sectionHeader.copyWith(color: s.ink),
        ),
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Standby dot — the ledger waits; no big decorative icon.
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: s.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'the ledger is empty',
                    style: AppTypography.mono.copyWith(
                      fontSize: 12.5,
                      color: s.muted,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: events.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: s.hairline),
                  itemBuilder: (context, index) =>
                      _AuditEventRow(event: events[index]),
                ),
              ),
              // Load more button if we got a full page
              if (events.length % AppConstants.auditPageSize == 0)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
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
        loading: () => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: s.accent),
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: AppTypography.mono.copyWith(fontSize: 12.5, color: s.error),
          ),
        ),
      ),
    );
  }
}

/// One ledger line: `action  subject ........ timestamp` — all mono.
class _AuditEventRow extends StatelessWidget {
  const _AuditEventRow({required this.event});
  final AuditEvent event;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final meta = _parseMeta(event.metadata);
    final secretName = meta['name'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              _actionLabel(event.action),
              style: AppTypography.mono.copyWith(fontSize: 12.5, color: s.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              secretName ?? '—',
              style: AppTypography.mono.copyWith(
                fontSize: 12.5,
                color: s.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            DateFormatters.timeAgo(event.createdAt),
            style: AppTypography.mono.copyWith(fontSize: 11, color: s.muted),
          ),
        ],
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

  String _actionLabel(String action) {
    return switch (action) {
      'secret.create' => 'secret created',
      'secret.read' => 'secret revealed',
      'secret.update' => 'secret updated',
      'secret.delete' => 'secret deleted',
      'vault.setup' => 'vault set up',
      'vault.unlock' => 'vault unlocked',
      _ => action,
    };
  }
}
