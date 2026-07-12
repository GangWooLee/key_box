import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/auth_state.dart';

/// Recovery screen for [AuthVaultError]: explains what is wrong with the
/// vault files and offers a confirmed full reset.
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (title, description) = _messageFor(authState.reason);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurfaceSecondary : null,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
            decoration: BoxDecoration(
              color: isDark ? AppColors.authCardBg : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.authCardStroke
                    : AppColors.lightBorderPrimary,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  LucideIcons.alertTriangle,
                  size: 40,
                  color: AppColors.errorText,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: AppTypography.authTitle.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: AppTypography.authSubtitle.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Semantics(
                  label: 'Reset vault and delete all data',
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _confirmReset(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        foregroundColor: AppColors.buttonPrimaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Reset vault',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.buttonPrimaryText,
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
  };

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
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
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
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
