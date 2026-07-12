import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/auth_notifier.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final error = await ref
          .read(authProvider.notifier)
          .unlock(password: _passwordController.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = error;
        });
        if (error != null) {
          _passwordController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unlock failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurfaceSecondary : null,
      body: Center(
        child: SingleChildScrollView(
          child: _AuthCard(
            isDark: isDark,
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.keyRound,
                      size: 28,
                      color: AppColors.brand500,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'KeyBox',
                      style: AppTypography.logoText.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Unlock Your Vault',
                  style: AppTypography.authTitle.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your master password',
                  style: AppTypography.authSubtitle.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Password input
                Text(
                  'Master Password',
                  style: AppTypography.authInputLabel.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofocus: true,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.authInputBg : null,
                      hintText: 'Enter password...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          size: 18,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _handleUnlock(),
                  ),
                ),
                const SizedBox(height: 24),

                // Error
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.errorText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Unlock button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleUnlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: AppColors.buttonPrimaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.buttonPrimaryText,
                            ),
                          )
                        : Text(
                            'Unlock',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.buttonPrimaryText,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Forgot hint
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Forgot your password?',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Data cannot be recovered without the master password.',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextQuaternary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // DEV: Reset vault (debug mode only, tree-shaken in release)
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
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
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.errorText,
                              ),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        await ref
                            .read(authProvider.notifier)
                            .resetAndReinitialize();
                      }
                    },
                    child: Text(
                      'DEV: Reset Vault',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.errorText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared auth card container with V8 dark design.
class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.isDark,
    required this.width,
    required this.child,
  });

  final bool isDark;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.authCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.authCardStroke
              : AppColors.lightBorderPrimary,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}
