import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/typography.dart';

/// Environment marker distinguished by weight, not color (DESIGN.md env-badge
/// rule): PROD carries ink + SemiBold; everything else stays muted regular.
/// No fill, no border — the ledger stays quiet.
class EnvironmentBadge extends StatelessWidget {
  const EnvironmentBadge({super.key, required this.environment});

  final String? environment;

  @override
  Widget build(BuildContext context) {
    if (environment == null || environment!.isEmpty) {
      return const SizedBox.shrink();
    }

    final s = Theme.of(context).extension<KbSurface>()!;
    final (label, isProd) = switch (environment!.toLowerCase()) {
      'production' => ('PROD', true),
      'development' => ('DEV', false),
      'staging' => ('STG', false),
      _ => (environment!.toUpperCase(), false),
    };

    return Text(
      label,
      style: AppTypography.tableHeader.copyWith(
        fontSize: 10,
        fontWeight: isProd ? FontWeight.w600 : FontWeight.w400,
        color: isProd ? s.ink : s.muted,
      ),
    );
  }
}
