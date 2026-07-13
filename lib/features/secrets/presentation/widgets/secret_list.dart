import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/secrets_providers.dart';
import 'environment_badge.dart';
import 'sheet_modal.dart';

/// Columnar table view for the middle panel of the 3-column dashboard.
///
/// Rides on the surface canvas (DESIGN.md §dashboard): rows sit directly on
/// `canvas`, hover lifts to `hover`, and the selected row rises to `lamp`
/// with a 2px `live` edge — "what you hold is under the lamp".
class SecretList extends ConsumerWidget {
  const SecretList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secrets = ref.watch(filteredSecretsProvider);
    final selectedId = ref.watch(selectedSecretIdProvider);

    return Column(
      children: [
        const _TableHeader(),
        Expanded(
          child: secrets.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  itemCount: secrets.length,
                  itemBuilder: (context, index) {
                    final secret = secrets[index];
                    return _TableRow(
                      key: ValueKey(secret.id),
                      secret: secret,
                      isSelected: secret.id == selectedId,
                      onTap: () {
                        ref.read(selectedSecretIdProvider.notifier).state =
                            secret.id;
                      },
                    );
                  },
                ),
        ),
        _BottomBar(count: secrets.length),
      ],
    );
  }
}

// ─── Table Header ───

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final style = AppTypography.tableHeader.copyWith(color: s.muted);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: s.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text('NAME', style: style)),
          SizedBox(width: 180, child: Text('SERVICE', style: style)),
          SizedBox(width: 120, child: Text('ENV', style: style)),
          SizedBox(
            width: 100,
            child: Text('LAST USED', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

// ─── Table Row ───

class _TableRow extends StatelessWidget {
  const _TableRow({
    super.key,
    required this.secret,
    required this.isSelected,
    required this.onTap,
  });

  final Secret secret;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: s.hover,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? s.lamp : Colors.transparent,
            border: Border(
              left: isSelected
                  ? BorderSide(color: s.live, width: 2)
                  : BorderSide.none,
              bottom: BorderSide(color: s.hairline),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            isSelected ? AppSpacing.md - 2 : AppSpacing.md,
            0,
            AppSpacing.md,
            0,
          ),
          child: Row(
            children: [
              // Name — mono, the ledger entry itself.
              Expanded(
                child: Text(
                  secret.name,
                  style: AppTypography.mono.copyWith(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: s.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Service
              SizedBox(
                width: 180,
                child: Text(
                  secret.serviceName ?? '',
                  style: AppTypography.bodySmall.copyWith(color: s.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Environment (weight-coded, no fill)
              SizedBox(
                width: 120,
                child: EnvironmentBadge(environment: secret.environment),
              ),
              // Last Used — mono timestamp.
              SizedBox(
                width: 100,
                child: Text(
                  secret.lastAccessedAt != null
                      ? DateFormatters.timeAgo(secret.lastAccessedAt!)
                      : '—',
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: s.muted,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty States (DESIGN.md §빈/에러/오버플로) ───

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final folderId = ref.watch(selectedFolderIdProvider);
    final category = ref.watch(selectedCategoryProvider);
    final service = ref.watch(selectedServiceProvider);

    // A filter is narrowing the view — quiet one-liner, not the hero.
    if (folderId != null) {
      return _QuietEmpty(message: 'this folder is empty', surface: s);
    }
    if (category != SecretCategory.all || service != null) {
      return _QuietEmpty(message: 'no secrets in this view', surface: s);
    }

    // Empty vault — the hero sweep's destination: the bench is clear.
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: s.accent, shape: BoxShape.circle),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'THE BENCH IS CLEAR',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 20,
              color: s.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'your first secret goes here',
            style: AppTypography.bodySmall.copyWith(color: s.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () => showSecretSheetModal(context: context, ref: ref),
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
              child: const Text('+ New Secret'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // ⌘ is an icon, not a glyph: Plex Mono lacks U+2318 (tofu).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.command, size: 11, color: s.muted),
              Text(
                'N',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: s.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuietEmpty extends StatelessWidget {
  const _QuietEmpty({required this.message, required this.surface});

  final String message;
  final KbSurface surface;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: AppTypography.mono.copyWith(
          fontSize: 12.5,
          color: surface.muted,
        ),
      ),
    );
  }
}

// ─── Bottom Bar ───

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.count});
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: ElevatedButton.icon(
              onPressed: () => showSecretSheetModal(context: context, ref: ref),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Add Secret'),
              style: ElevatedButton.styleFrom(
                backgroundColor: s.accent,
                foregroundColor: s.onAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            '$count secret${count != 1 ? 's' : ''}',
            style: AppTypography.mono.copyWith(fontSize: 11, color: s.muted),
          ),
        ],
      ),
    );
  }
}
