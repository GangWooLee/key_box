import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/auth_state.dart';

/// Recovery screen for [AuthVaultError] — the vault stays sealed, so this
/// remains on the Slab (DESIGN.md §vault-error). The reason reads in calm
/// clay, not an alarm; no warning iconography.
///
/// Backup restore will be wired here in a follow-up; for now the only exit
/// is an explicit, confirmed reset back to first-run.
class VaultErrorScreen extends ConsumerWidget {
  const VaultErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    // Transient render during reset transition — the router redirects away.
    if (authState is! AuthVaultError) return const Scaffold(body: SizedBox());

    final s = Theme.of(context).extension<KbSurface>()!;
    final (title, description) = _messageFor(authState.reason);

    return Scaffold(
      backgroundColor: s.canvas,
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'KEY_BOX',
                  textAlign: TextAlign.center,
                  style: AppTypography.logoText.copyWith(color: s.muted),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  title,
                  style: AppTypography.authTitle.copyWith(color: s.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  description,
                  style: AppTypography.authSubtitle.copyWith(color: s.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  label: 'Reset vault and delete all data',
                  child: Center(
                    child: OutlinedButton(
                      // Destructive = error outline, never a fill.
                      onPressed: () => _confirmReset(context, ref, s),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: s.error,
                        side: BorderSide(color: s.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        minimumSize: const Size(kMinHitTarget, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                      ),
                      child: Text(
                        'Reset vault',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: s.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, String) _messageFor(VaultErrorReason reason) => switch (reason) {
    VaultErrorReason.vaultFileMissing => (
      'Vault data file is missing',
      'Vault metadata was found, but the data file is gone. Your secrets '
          'may be lost. If you have a backup, restore it before resetting.',
    ),
    VaultErrorReason.sidecarCorrupted => (
      'Vault metadata is corrupted',
      'The vault metadata file could not be read. Resetting will delete '
          'all data and return to initial setup.',
    ),
    VaultErrorReason.configMissing => (
      'Vault configuration is missing',
      'The vault data file exists but holds no configuration. Resetting '
          'will delete all data and return to initial setup.',
    ),
    VaultErrorReason.sidecarMissing => (
      'Vault metadata is missing',
      'The vault is encrypted but its metadata file is gone, so no '
          'password can unlock it. Restore from a backup if you have one; '
          'otherwise resetting is the only way forward.',
    ),
    VaultErrorReason.migrationFailed => (
      'Vault encryption upgrade failed',
      'The upgrade to an encrypted vault could not be completed. Your '
          'original data is untouched — free up disk space or try again by '
          'restarting the app before considering a reset.',
    ),
    VaultErrorReason.mekUnwrapFailed => (
      'Vault master key is corrupted',
      'Your password is correct, but the stored master key data is '
          'damaged and cannot be recovered. Restore from a backup if you '
          'have one before resetting.',
    ),
  };

  Future<void> _confirmReset(
    BuildContext context,
    WidgetRef ref,
    KbSurface s,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Vault?'),
        content: const Text(
          'This will delete ALL data and return to initial setup.\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: s.error),
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
