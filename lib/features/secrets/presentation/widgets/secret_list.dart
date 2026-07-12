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

/// Columnar table view for the middle panel of the 3-column dashboard.
class SecretList extends ConsumerWidget {
  const SecretList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secrets = ref.watch(filteredSecretsProvider);
    final selectedId = ref.watch(selectedSecretIdProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Table Header
        _TableHeader(isDark: isDark),

        // Table Body
        Expanded(
          child: secrets.isEmpty
              ? _EmptyState(isDark: isDark)
              : ListView.builder(
                  itemCount: secrets.length,
                  itemBuilder: (context, index) {
                    final secret = secrets[index];
                    final isSelected = secret.id == selectedId;
                    return _TableRow(
                      key: ValueKey(secret.id),
                      secret: secret,
                      index: index,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () {
                        ref.read(selectedSecretIdProvider.notifier).state =
                            secret.id;
                      },
                    );
                  },
                ),
        ),

        // Bottom Bar
        _BottomBar(isDark: isDark, count: secrets.length),
      ],
    );
  }
}

// ─── Table Header ───

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final headerColor = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkTableHeaderBg : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkTableHeaderStroke
                : AppColors.lightBorderSubtle,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Name',
              style: AppTypography.tableHeader.copyWith(color: headerColor),
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              'Service',
              style: AppTypography.tableHeader.copyWith(color: headerColor),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'Env',
              style: AppTypography.tableHeader.copyWith(color: headerColor),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Last Used',
              style: AppTypography.tableHeader.copyWith(color: headerColor),
              textAlign: TextAlign.right,
            ),
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
    required this.index,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final Secret secret;
  final int index;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  Color _nameColor() {
    if (isSelected) {
      return isDark ? AppColors.darkRowText1 : AppColors.lightTextPrimary;
    }
    if (!isDark) return AppColors.lightTextPrimary;
    return switch (index) {
      0 => AppColors.darkRowText1,
      1 => AppColors.darkRowText2,
      2 => AppColors.darkRowText3,
      _ => AppColors.darkRowText4,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkTableRowSelected : AppColors.brand50)
                : Colors.transparent,
            border: Border(
              left: isSelected
                  ? const BorderSide(color: AppColors.buttonPrimary, width: 2)
                  : BorderSide.none,
              bottom: BorderSide(
                color: isDark
                    ? AppColors.darkTableRowSeparator
                    : AppColors.lightBorderSubtle,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(isSelected ? 14 : 16, 0, 16, 0),
          child: Row(
            children: [
              // Name
              Expanded(
                child: Text(
                  secret.name,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: _nameColor(),
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
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Environment Badge
              SizedBox(
                width: 120,
                child: EnvironmentBadge(environment: secret.environment),
              ),
              // Last Used
              SizedBox(
                width: 100,
                child: Text(
                  secret.lastAccessedAt != null
                      ? DateFormatters.timeAgo(secret.lastAccessedAt!)
                      : '—',
                  style: AppTypography.caption.copyWith(
                    letterSpacing: 0.2,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
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

// ─── Empty State ───

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
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
            color: isDark
                ? AppColors.darkTextQuaternary
                : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'No secrets yet',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Click "+ Add Secret" below to get started',
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? AppColors.darkTextQuaternary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Bar ───

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.isDark, required this.count});
  final bool isDark;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBottomBarBg : Colors.transparent,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkBottomBarStroke
                : AppColors.lightBorderSubtle,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Add Secret button
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateSheet(context, ref),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Add Secret'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.buttonPrimaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
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
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showSecretSheetModal(context: context, ref: ref);
  }
}
