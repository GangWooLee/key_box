import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

/// Pill-shaped environment badge: Production (red), Development (green), Staging (amber).
class EnvironmentBadge extends StatelessWidget {
  const EnvironmentBadge({super.key, required this.environment});

  final String? environment;

  @override
  Widget build(BuildContext context) {
    if (environment == null || environment!.isEmpty) {
      return const SizedBox.shrink();
    }

    final env = environment!.toLowerCase();
    final (bg, stroke, textColor, label) = switch (env) {
      'production' => (
        AppColors.envProdBg,
        AppColors.envProdStroke,
        AppColors.envProdText,
        'Production',
      ),
      'development' => (
        AppColors.envDevBg,
        AppColors.envDevStroke,
        AppColors.envDevText,
        'Development',
      ),
      'staging' => (
        AppColors.envStagingBg,
        AppColors.envStagingStroke,
        AppColors.envStagingText,
        'Staging',
      ),
      _ => (
        AppColors.darkTableHeaderBg,
        AppColors.darkBorderPrimary,
        AppColors.darkTextSecondary,
        environment!,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: stroke, width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: textColor,
        ),
      ),
    );
  }
}
