import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/backup/last_backup_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../services/auto_lock_service.dart';
import 'clipboard_countdown.dart';

/// The quiet security-state signals at the detail panel's foot (보안 UX #3 —
/// 조용한 가시화, DESIGN.md §detail): the transient clipboard auto-clear
/// countdown, the auto-lock countdown, and the always-present last-backup line.
/// Information, not decoration; mono + muted, out of the way.
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
        const _AutoLockLine(),
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

/// The idle time left before the vault auto-locks. Counts down while idle and
/// jumps back to full on activity (which is correct — an active user isn't
/// about to be locked out). Ticks once a minute; hidden when auto-lock is off.
class _AutoLockLine extends ConsumerStatefulWidget {
  const _AutoLockLine();

  @override
  ConsumerState<_AutoLockLine> createState() => _AutoLockLineState();
}

class _AutoLockLineState extends ConsumerState<_AutoLockLine> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final deadline = ref.watch(autoLockDeadlineProvider);
    if (deadline == null) return const SizedBox.shrink();

    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) return const SizedBox.shrink();

    final mins = remaining.inMinutes;
    final label = mins >= 1 ? 'auto-lock in ${mins}m' : 'auto-lock in <1m';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        label,
        style: AppTypography.mono.copyWith(fontSize: 10.5, color: s.muted),
      ),
    );
  }
}
