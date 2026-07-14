import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/backup/last_backup_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatters.dart';
import 'clipboard_countdown.dart';

/// The quiet security-state signals at the detail panel's foot (보안 UX #3 —
/// 조용한 가시화, DESIGN.md §detail): the transient clipboard auto-clear
/// countdown, and the always-present last-backup line. Information, not
/// decoration; mono + muted, out of the way.
class VaultStatusStrip extends ConsumerWidget {
  const VaultStatusStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final lastBackup = ref.watch(lastBackupProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ClipboardCountdown(), // transient — shrinks to nothing when idle
        const SizedBox(height: AppSpacing.xs),
        Text(
          lastBackup == null
              ? 'never backed up'
              : 'backed up ${DateFormatters.timeAgo(lastBackup)}',
          style: AppTypography.mono.copyWith(fontSize: 10.5, color: s.muted),
        ),
      ],
    );
  }
}
