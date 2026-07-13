import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/auth_notifier.dart';

/// Slab splash shown while the app checks vault existence ([AuthInitial],
/// ~50-200ms). Minimal: wordmark + a quiet accent spinner. No chrome.
class LoadingScreen extends ConsumerWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;

    return Scaffold(
      backgroundColor: s.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'KEY_BOX',
              style: AppTypography.logoText.copyWith(color: s.muted),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: s.accent),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: AppSpacing.xxl),
              TextButton(
                onPressed: () =>
                    ref.read(authProvider.notifier).resetAndReinitialize(),
                child: Text(
                  'Reset Vault (Debug)',
                  style: AppTypography.authInputLabel.copyWith(color: s.muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
