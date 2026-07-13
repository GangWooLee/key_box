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
                onPressed: () => _confirmDevReset(context, ref, s),
                child: Text(
                  'dev: reset vault',
                  style: AppTypography.authInputLabel.copyWith(color: s.muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Destructive friction (DESIGN.md security UX #2): even the debug wipe
  // gets a confirm gate — same contract as the unlock screen's reset.
  Future<void> _confirmDevReset(
    BuildContext context,
    WidgetRef ref,
    KbSurface s,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: s.lamp,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: s.hairline),
        ),
        title: Text(
          'Reset Vault?',
          style: AppTypography.titleSmall.copyWith(color: s.ink),
        ),
        content: Text(
          'This will delete ALL data and return to initial setup.\n'
          'This action cannot be undone.',
          style: AppTypography.bodySmall.copyWith(color: s.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(color: s.muted),
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: s.error,
              side: BorderSide(color: s.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).resetAndReinitialize();
    }
  }
}
